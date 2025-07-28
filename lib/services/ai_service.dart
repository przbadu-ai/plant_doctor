import 'dart:typed_data';
import 'dart:io';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:flutter_gemma/core/chat.dart';
import 'package:flutter_gemma/core/model.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:path_provider/path_provider.dart';
import '../providers/language_provider.dart';

class AIService {
  static final AIService _instance = AIService._internal();
  factory AIService() => _instance;
  AIService._internal();

  final _gemma = FlutterGemmaPlugin.instance;
  InferenceModel? _model;
  InferenceChat? _currentChat;
  bool _isInitialized = false;
  bool _supportsVision = true;
  LanguageProvider? _languageProvider;

  bool get isInitialized => _isInitialized;
  bool get supportsVision => _supportsVision;
  
  void setLanguageProvider(LanguageProvider provider) {
    _languageProvider = provider;
  }

  Future<void> _cleanupXNNPackCache(String modelPath) async {
    try {
      // Clean up XNNPack cache files that might be corrupted
      final cacheFile = File('$modelPath.xnnpack_cache');
      if (await cacheFile.exists()) {
        await cacheFile.delete();
        print('Deleted XNNPack cache file: ${cacheFile.path}');
      }
      
      // Also clean up any temp cache in app directory
      final appDir = await getApplicationDocumentsDirectory();
      final cacheDir = Directory('${appDir.path}/xnnpack_cache');
      if (await cacheDir.exists()) {
        await cacheDir.delete(recursive: true);
        print('Deleted XNNPack cache directory');
      }
    } catch (e) {
      print('Error cleaning XNNPack cache: $e');
    }
  }

  Future<void> initialize(String modelPath) async {
    // Log model initialization attempt
    await FirebaseCrashlytics.instance.log('Initializing AI model: $modelPath');
    
    // Verify model file exists
    final modelFile = File(modelPath);
    if (!await modelFile.exists()) {
      throw Exception('Model file not found at: $modelPath');
    }
    
    // Get file size for logging
    final fileSize = await modelFile.length();
    await FirebaseCrashlytics.instance.log('Model file size: ${fileSize / 1024 / 1024} MB');
    
    // Clean up any corrupted XNNPack cache - IMPORTANT for vision models
    await _cleanupXNNPackCache(modelPath);
    
    // Also clean up any TFLite cache that might be corrupted
    try {
      final tfliteCacheFile = File('$modelPath.tflite_cache');
      if (await tfliteCacheFile.exists()) {
        await tfliteCacheFile.delete();
        print('Deleted TFLite cache file');
      }
      
      // Clean up any vision-specific cache
      final visionCacheFile = File('$modelPath.vision_cache');
      if (await visionCacheFile.exists()) {
        await visionCacheFile.delete();
        print('Deleted vision cache file');
      }
    } catch (e) {
      print('Error cleaning cache files: $e');
    }
    
    // Set model path
    await _gemma.modelManager.setModelPath(modelPath);

    // Try to create model with vision support first
    try {
      print('Attempting to initialize model with vision support...');
      _model = await _gemma.createModel(
        modelType: ModelType.gemmaIt,
        supportImage: true,
        maxNumImages: 1,
        maxTokens: 2048,
      );
      _supportsVision = true;
      _isInitialized = true;
      print('Vision support enabled successfully');
    } catch (visionError) {
      print('Vision initialization failed: $visionError');
      print('Falling back to text-only mode...');
      
      // Fall back to text-only mode
      try {
        _model = await _gemma.createModel(
          modelType: ModelType.gemmaIt,
          supportImage: false,
          maxTokens: 2048,
        );
        _supportsVision = false;
        _isInitialized = true;
        print('Model initialized in text-only mode');
        await FirebaseCrashlytics.instance.log('Model initialized without vision support due to: $visionError');
      } catch (textError) {
        _isInitialized = false;
        throw Exception('Failed to initialize model in both vision and text modes. Vision error: $visionError, Text error: $textError');
      }
    }
  }

  Future<InferenceChat> createNewChat() async {
    print('Creating chat...');
    _currentChat = await _model!.createChat(
      temperature: 0.8,
      supportImage: true, // Enable vision support for Gemma 3n
    );

    // Add initial context for plant disease detection
    final rolePrompt = _languageProvider?.getLocalizedPrompt('ai_role') ?? '''You are PlantDoctor AI, an expert in plant diseases and agricultural practices. 
      Your role is to:
      1. Identify plant diseases from descriptions
      2. Provide detailed analysis of symptoms
      3. Suggest organic and chemical remedies
      4. Give preventive measures
      5. Answer farming-related questions
      
      Always be helpful, accurate, and provide practical advice for farmers.''';
    
    await _currentChat!.addQueryChunk(Message.text(
      text: rolePrompt,
      isUser: false,
    ));

    print('Chat created successfully');
    return _currentChat!;
  }

  Future<String> analyzePlantImage(Uint8List imageBytes) async {
    if (_currentChat == null) {
      print('Creating new chat...');
      await createNewChat();
    }

    // Check if vision is actually supported
    if (!_supportsVision) {
      print('WARNING: Vision not supported - falling back to text-based analysis');
      return '''I apologize, but I'm currently unable to analyze images directly due to technical limitations. 
      
However, I can still help you! Please describe what you see:

1. **Plant type**: What kind of plant is it?
2. **Symptoms**: What problems do you notice? (e.g., yellow leaves, spots, wilting, pests)
3. **Location**: Which parts are affected? (leaves, stems, roots, flowers)
4. **Pattern**: How widespread is the issue?
5. **Timeline**: When did you first notice the problem?

With this information, I can provide detailed diagnosis and treatment recommendations for your plant.''';
    }

    // Use vision support for Gemma 3n models
    print('Using vision-enabled analysis with Gemma 3n...');
    final imageAnalysisPrompt = _languageProvider?.getLocalizedPrompt('image_analysis_prompt') ?? '''Analyze this plant image for any diseases or health issues. Provide:
      
      1. Identified plant type (if possible)
      2. Observed symptoms or abnormalities
      3. Likely diseases or problems
      4. Treatment recommendations
      5. Preventive measures
      
      Be specific and practical in your recommendations.''';
    
    // Add image with analysis prompt
    await _currentChat!.addQueryChunk(Message.withImage(
      imageBytes: imageBytes,
      text: imageAnalysisPrompt,
      isUser: true,
    ));

    print('Generating response...');
    final response = await _currentChat!.generateChatResponse();
    final responseText = response.toString();
    print('Response received: ${responseText.substring(0, responseText.length > 100 ? 100 : responseText.length)}...');
    return responseText;
  }

  Future<String> askQuestion(String question, {Uint8List? imageBytes}) async {
    print('Processing question: $question');
    
    if (_currentChat == null) {
      print('Creating new chat...');
      await createNewChat();
    }

    if (imageBytes != null) {
      print('Adding question with image using vision support...');
      await _currentChat!.addQueryChunk(Message.withImage(
        imageBytes: imageBytes,
        text: question,
        isUser: true,
      ));
    } else {
      print('Adding text-only question...');
      await _currentChat!.addQueryChunk(Message.text(
        text: question,
        isUser: true,
      ));
    }

    print('Generating response...');
    final response = await _currentChat!.generateChatResponse();
    final responseText = response.toString();
    print('Response received: ${responseText.substring(0, responseText.length > 100 ? 100 : responseText.length)}...');
    return responseText;
  }

  Future<String> getPlantCareAdvice(String plantType) async {
    return askQuestion(
      '''Provide comprehensive care guide for $plantType including:
      1. Optimal growing conditions
      2. Watering schedule
      3. Common diseases and prevention
      4. Fertilization requirements
      5. Harvest timing (if applicable)'''
    );
  }

  void dispose() {
    _currentChat = null;
    _model = null;
    _isInitialized = false;
  }
}