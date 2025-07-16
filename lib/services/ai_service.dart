import 'dart:typed_data';
import 'dart:io';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:flutter_gemma/core/chat.dart';
import 'package:flutter_gemma/core/model.dart';
import 'package:flutter_gemma/pigeon.g.dart';
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
  LanguageProvider? _languageProvider;

  bool get isInitialized => _isInitialized;
  
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
    try {
      // Log model initialization attempt
      await FirebaseCrashlytics.instance.log('Initializing AI model: $modelPath');
      
      // Clean up any corrupted XNNPack cache
      await _cleanupXNNPackCache(modelPath);
      
      // Set model path
      await _gemma.modelManager.setModelPath(modelPath);

      // Create model without vision support to avoid initialization errors
      _model = await _gemma.createModel(
        modelType: ModelType.gemmaIt,
        supportImage: false, // Disable vision to fix initialization error
        maxNumImages: 0,
        preferredBackend: PreferredBackend.cpu,
        maxTokens: 2048,
      );

      _isInitialized = true;
      await FirebaseCrashlytics.instance.log('AI model initialized successfully');
    } catch (e, stackTrace) {
      print('Error initializing AI model: $e');
      _isInitialized = false;
      _model = null;
      
      // Report to Crashlytics with context
      await FirebaseCrashlytics.instance.recordError(
        e,
        stackTrace,
        reason: 'AI model initialization failed',
        information: [
          'modelPath: $modelPath',
          'error: $e',
        ],
      );
      
      throw Exception('Failed to initialize AI model: $e');
    }
  }

  Future<InferenceChat> createNewChat() async {
    if (_model == null) {
      throw Exception('Model not initialized');
    }

    print('Creating chat...');
    _currentChat = await _model!.createChat(
      temperature: 0.8,
      topK: 40,
      topP: 0.9,
      supportImage: false, // Disable vision support
    );

    // Add initial context for plant disease detection
    print('Adding initial context...');
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
    try {
      print('Starting plant image analysis...');
      print('Image size: ${imageBytes.length} bytes');
      
      if (_currentChat == null) {
        print('Creating new chat...');
        await createNewChat();
      }

      // Since vision is not supported, we'll analyze based on text description
      print('Vision not supported - using text-based analysis...');
      final imageAnalysisPrompt = _languageProvider?.getLocalizedPrompt('image_analysis_prompt') ?? '''I have uploaded an image of a plant that may have disease issues. 
        Since I cannot process images directly, please help me by:
        
        1. Asking me to describe what I see in the plant (color changes, spots, wilting, etc.)
        2. Based on my description, identify possible diseases
        3. Suggest treatments and preventive measures
        
        Please start by asking me to describe the plant's symptoms.''';
      
      await _currentChat!.addQueryChunk(Message.text(
        text: imageAnalysisPrompt,
        isUser: true,
      ));

      print('Generating response...');
      final response = await _currentChat!.generateChatResponse();
      print('Response received: ${response.substring(0, response.length > 100 ? 100 : response.length)}...');
      return response;
    } catch (e) {
      print('Error in analyzePlantImage: $e');
      print('Stack trace: ${StackTrace.current}');
      rethrow;
    }
  }

  Future<String> askQuestion(String question, {Uint8List? imageBytes}) async {
    try {
      print('Processing question: $question');
      
      if (_currentChat == null) {
        print('Creating new chat...');
        await createNewChat();
      }

      if (imageBytes != null) {
        print('Image provided but vision not supported - using text only...');
        await _currentChat!.addQueryChunk(Message.text(
          text: '$question\n\n(Note: An image was provided but I cannot process images directly. Please describe what you see in the image.)',
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
      print('Response received: ${response.substring(0, response.length > 100 ? 100 : response.length)}...');
      return response;
    } catch (e) {
      print('Error in askQuestion: $e');
      print('Stack trace: ${StackTrace.current}');
      rethrow;
    }
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