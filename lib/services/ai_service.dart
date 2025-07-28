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
  bool _supportsVision = false; // Default to false until proven otherwise
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
    
    // Temporarily disable cache cleanup to test if it's causing vision issues
    // TODO: Re-enable if needed after testing
    /*
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
    */
    
    // Set model path
    await _gemma.modelManager.setModelPath(modelPath);

    // Check if this is a vision-enabled model (Gemma 3n models)
    final modelPathLower = modelPath.toLowerCase();
    final isVisionModel = modelPathLower.contains('gemma-3n') || 
                         modelPathLower.contains('gemma3n') || 
                         modelPathLower.contains('e2b') || 
                         modelPathLower.contains('e4b');
    
    print('=== Model Detection ===');
    print('Model path: $modelPath');
    print('Model path (lowercase): $modelPathLower');
    print('Is vision model detected: $isVisionModel');
    
    // Try to create model with appropriate settings
    try {
      if (isVisionModel) {
        print('Initializing Gemma 3n model...');
        // Don't specify vision support in createModel, let it auto-detect
        _model = await _gemma.createModel(
          modelType: ModelType.gemmaIt,
          maxTokens: 4096, // Increased for vision models
        );
        _supportsVision = true; // Assume vision support for Gemma 3n models
        _isInitialized = true;
        print('Gemma 3n model initialized successfully');
        print('_supportsVision is now: $_supportsVision');
      } else {
        print('Initializing text-only model...');
        _model = await _gemma.createModel(
          modelType: ModelType.gemmaIt,
          supportImage: false,
          maxTokens: 2048,
        );
        _supportsVision = false;
        _isInitialized = true;
        print('Text-only model initialized successfully');
      }
    } catch (error, stackTrace) {
      print('Model initialization error: $error');
      print('Stack trace: $stackTrace');
      await FirebaseCrashlytics.instance.recordError(error, stackTrace);
      
      // Log more details about the error
      final errorDetails = 'Model: $modelPath, Vision: $isVisionModel, Error type: ${error.runtimeType}, Message: $error';
      print(errorDetails);
      await FirebaseCrashlytics.instance.log(errorDetails);
      
      // If it's a vision model but failed, try without vision as fallback
      if (isVisionModel) {
        try {
          print('Vision model failed, attempting text-only fallback...');
          _model = await _gemma.createModel(
            modelType: ModelType.gemmaIt,
            supportImage: false,
            maxTokens: 2048,
          );
          _supportsVision = false;
          _isInitialized = true;
          print('Fallback to text-only mode successful');
          await FirebaseCrashlytics.instance.log('Vision model fell back to text mode due to: $error');
        } catch (fallbackError) {
          _isInitialized = false;
          throw Exception('Failed to initialize model: $error, Fallback error: $fallbackError');
        }
      } else {
        _isInitialized = false;
        throw Exception('Failed to initialize model: $error');
      }
    }
  }

  Future<InferenceChat> createNewChat() async {
    print('Creating chat...');
    
    try {
      // Create chat without specifying supportImage - let it auto-detect
      _currentChat = await _model!.createChat(
        temperature: 0.8,
      );
      print('Chat created successfully');
    } catch (e) {
      print('Error creating chat: $e');
      rethrow;
    }

    // Add initial context for plant disease detection
    final rolePrompt = _languageProvider?.getLocalizedPrompt('ai_role') ?? '''You are PlantDoctor AI, an expert in plant diseases and agricultural practices. 
      Your role is to:
      1. Identify plant diseases from descriptions and images
      2. Provide detailed analysis of symptoms
      3. Suggest organic and chemical remedies
      4. Give preventive measures
      5. Answer farming-related questions
      
      Always be helpful, accurate, and provide practical advice for farmers.''';
    
    await _currentChat!.addQueryChunk(Message.text(
      text: rolePrompt,
      isUser: false,
    ));

    print('Chat initialization completed');
    return _currentChat!;
  }

  Future<String> analyzePlantImage(Uint8List imageBytes) async {
    print('=== analyzePlantImage called ===');
    print('Image size: ${imageBytes.length} bytes');
    print('Current vision support: $_supportsVision');
    print('Model initialized: $_isInitialized');
    print('Has model: ${_model != null}');
    print('Has chat: ${_currentChat != null}');
    
    if (_currentChat == null) {
      print('Creating new chat...');
      await createNewChat();
    }

    // Check if vision is actually supported
    if (!_supportsVision) {
      print('WARNING: Vision not supported - falling back to text-based analysis');
      print('This should not happen with Gemma 3n models!');
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
    
    // Get the correct prompt for image analysis
    final imageAnalysisPrompt = _languageProvider?.getLocalizedPrompt('image_analysis_prompt') ?? '''Analyze this plant image for any diseases or health issues. Provide:
      
      1. Identified plant type (if possible)
      2. Observed symptoms or abnormalities
      3. Likely diseases or problems
      4. Treatment recommendations
      5. Preventive measures
      
      Be specific and practical in your recommendations.''';
    
    try {
      // Add image with analysis prompt
      print('Adding image to chat...');
      print('Image bytes length: ${imageBytes.length}');
      
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
    } catch (e, stackTrace) {
      print('ERROR during vision analysis: $e');
      print('Stack trace: $stackTrace');
      
      // Check if it's a vision-specific error
      final errorMessage = e.toString().toLowerCase();
      if (errorMessage.contains('vision') || errorMessage.contains('image')) {
        print('Vision-specific error detected, falling back to text mode');
        _supportsVision = false;
        
        // Return text-based fallback
        return '''I apologize, but I encountered an error analyzing your image. 

Error details: $e

Please describe what you see in the plant image:
1. **Plant type**: What kind of plant is it?
2. **Symptoms**: What problems do you notice?
3. **Location**: Which parts are affected?

I'll help diagnose the issue based on your description.''';
      }
      
      // Re-throw if it's not a vision-specific error
      rethrow;
    }
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

  // Debug method to get current vision status
  Map<String, dynamic> getVisionStatus() {
    return {
      'isInitialized': _isInitialized,
      'supportsVision': _supportsVision,
      'hasModel': _model != null,
      'hasChat': _currentChat != null,
    };
  }
}