import 'dart:typed_data';
import 'dart:io';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:flutter_gemma/core/model.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:path_provider/path_provider.dart';
import '../providers/language_provider.dart';
import '../utils/logger.dart';

class AIService {
  static final AIService _instance = AIService._internal();
  factory AIService() => _instance;
  AIService._internal();

  final _gemma = FlutterGemmaPlugin.instance;
  InferenceModel? _textModel;
  InferenceModel? _visionModel;
  InferenceChat? _currentChat;
  bool _isInitialized = false;
  bool _isVisionAvailable = false;
  bool _isUsingVisionMode = false;
  LanguageProvider? _languageProvider;
  
  // Context management
  int _messageCount = 0;
  int _approximateTokenCount = 0;
  static const int _maxMessages = 20;
  static const int _maxTokens = 3000;
  static const int _warningTokens = 2500;

  bool get isInitialized => _isInitialized;
  bool get isVisionAvailable => _isVisionAvailable;
  bool get isUsingVisionMode => _isUsingVisionMode;
  bool get isContextNearLimit => _approximateTokenCount > _warningTokens;
  bool get isContextFull => _messageCount >= _maxMessages || _approximateTokenCount >= _maxTokens;
  
  void setLanguageProvider(LanguageProvider provider) {
    _languageProvider = provider;
  }

  Future<void> _cleanupCache(String modelPath) async {
    try {
      // Clean up XNNPack cache files
      final cacheFile = File('$modelPath.xnnpack_cache');
      if (await cacheFile.exists()) {
        await cacheFile.delete();
        Logger.log('Deleted XNNPack cache file');
      }
      
      // Clean up temp cache in app directory
      final appDir = await getApplicationDocumentsDirectory();
      final cacheDir = Directory('${appDir.path}/xnnpack_cache');
      if (await cacheDir.exists()) {
        await cacheDir.delete(recursive: true);
        Logger.log('Deleted XNNPack cache directory');
      }
    } catch (e) {
      Logger.log('Error cleaning cache: $e');
    }
  }

  Future<void> initialize(String modelPath) async {
    // Log model initialization
    await FirebaseCrashlytics.instance.log('Initializing AI model: $modelPath');
    
    // Verify model file exists
    final modelFile = File(modelPath);
    if (!await modelFile.exists()) {
      throw Exception('Model file not found at: $modelPath');
    }
    
    // Clean up cache files
    await _cleanupCache(modelPath);
    
    // Set model path
    await _gemma.modelManager.setModelPath(modelPath);

    // Check if this is a vision-capable model
    final modelPathLower = modelPath.toLowerCase();
    _isVisionAvailable = modelPathLower.contains('gemma-3n') || 
                        modelPathLower.contains('gemma3n') || 
                        modelPathLower.contains('e2b') || 
                        modelPathLower.contains('e4b');
    
    Logger.log('Model path: $modelPath');
    Logger.log('Vision available: $_isVisionAvailable');
    
    // Initialize text-only model first (always needed)
    try {
      Logger.log('Initializing text model...');
      _textModel = await _gemma.createModel(
        modelType: ModelType.gemmaIt,
        supportImage: false,
        maxTokens: 512, // Optimized for fast text responses
      );
      _isInitialized = true;
      Logger.log('Text model initialized successfully');
      
      // Don't initialize vision model yet - wait until needed
      _visionModel = null;
      
    } catch (error, stackTrace) {
      Logger.log('Model initialization error: $error');
      await FirebaseCrashlytics.instance.recordError(error, stackTrace);
      _isInitialized = false;
      throw Exception('Failed to initialize model: $error');
    }
  }

  // Lazy load vision model only when needed
  Future<void> _ensureVisionModel() async {
    if (!_isVisionAvailable || _visionModel != null) return;
    
    try {
      Logger.log('Lazy loading vision model...');
      _visionModel = await _gemma.createModel(
        modelType: ModelType.gemmaIt,
        maxTokens: 1024, // Higher for vision processing
      );
      Logger.log('Vision model loaded successfully');
    } catch (e) {
      Logger.log('Failed to load vision model: $e');
      _isVisionAvailable = false;
    }
  }

  Future<InferenceChat> _createChat({required bool useVision}) async {
    Logger.log('Creating chat (vision: $useVision)...');
    
    if (_textModel == null) {
      throw Exception('AI Service not initialized. Please initialize before creating chat.');
    }
    
    try {
      final model = useVision && _visionModel != null ? _visionModel! : _textModel!;
      
      _currentChat = await model.createChat(
        temperature: 0.7,
        topK: 40,
        topP: 0.9,
      );
      
      _isUsingVisionMode = useVision;
      
      // Add role prompt
      final rolePrompt = _languageProvider?.getLocalizedPrompt('ai_role') ?? 
        '''You are PlantDoctor AI, specializing in plant disease identification and treatment. 
        Provide concise, practical advice for farmers. Focus on: disease identification, 
        treatments (organic/chemical), and prevention.''';
      
      await _currentChat!.addQueryChunk(Message.text(
        text: rolePrompt,
        isUser: false,
      ));
      
      // Reset context tracking
      _messageCount = 1; // Role prompt counts as one message
      _approximateTokenCount = rolePrompt.length ~/ 4; // Rough token estimate
      
      Logger.log('Chat created successfully');
      return _currentChat!;
    } catch (e) {
      Logger.log('Error creating chat: $e');
      rethrow;
    }
  }

  // Get or create appropriate chat based on input type
  Future<InferenceChat> _getOrCreateChat({required bool needsVision}) async {
    // If we need vision but are in text mode, create new vision chat
    if (needsVision && !_isUsingVisionMode) {
      await _ensureVisionModel();
      if (_visionModel != null) {
        Logger.log('Switching to vision mode for image processing');
        return await _createChat(useVision: true);
      }
    }
    
    // If we don't need vision but are in vision mode, switch to text mode
    if (!needsVision && _isUsingVisionMode) {
      Logger.log('Switching to text mode for better performance');
      return await _createChat(useVision: false);
    }
    
    // Otherwise, reuse existing chat if available
    if (_currentChat != null) {
      Logger.log('Reusing existing chat');
      return _currentChat!;
    }
    
    // Create new chat with appropriate mode
    return await _createChat(useVision: needsVision);
  }

  // Track context usage
  void _updateContextUsage(String text) {
    _messageCount++;
    _approximateTokenCount += text.length ~/ 4; // Rough estimate: 4 chars = 1 token
    
    Logger.log('Context usage - Messages: $_messageCount/$_maxMessages, Tokens: ~$_approximateTokenCount/$_maxTokens');
  }

  // Check if we should warn about context limits
  Map<String, dynamic> getContextStatus() {
    return {
      'messageCount': _messageCount,
      'maxMessages': _maxMessages,
      'approximateTokens': _approximateTokenCount,
      'maxTokens': _maxTokens,
      'isNearLimit': isContextNearLimit,
      'isFull': isContextFull,
    };
  }

  Future<String> analyzePlantImage(Uint8List imageBytes) async {
    Logger.log('=== analyzePlantImage called ===');
    
    // Check context limits
    if (isContextFull) {
      return '''⚠️ Chat context is full. Please start a new chat to continue.
      
Your conversation has reached the maximum length. To ensure optimal performance and accurate responses, please:
1. Tap the menu (⋮) 
2. Select "New Chat"
3. Upload your plant image again''';
    }
    
    // Use vision mode for image analysis
    final chat = await _getOrCreateChat(needsVision: true);
    
    // If vision is not available, fall back to guided text analysis
    if (!_isVisionAvailable || _visionModel == null) {
      Logger.log('Vision not available - using guided text analysis');
      
      final demoDescription = '''I'm analyzing a maize (corn) plant with the following symptoms:
      
1. **Plant type**: Maize/Corn plant
2. **Symptoms**: 
   - Brown to gray spots on the lower leaves
   - Circular to oval-shaped lesions with concentric rings
   - Yellowing (chlorosis) around the spots
   - Some leaves showing wilting
3. **Location**: Primarily affecting lower and middle leaves, spreading upward
4. **Pattern**: Multiple spots on each affected leaf, disease appears to be spreading
5. **Timeline**: Symptoms first noticed about 5-7 days ago

Based on these symptoms, what disease is affecting my maize plant and how should I treat it?''';
      
      _updateContextUsage(demoDescription);
      return await askQuestion(demoDescription);
    }
    
    // Use vision for analysis
    Logger.log('Using vision-enabled analysis...');
    
    final imageAnalysisPrompt = _languageProvider?.getLocalizedPrompt('image_analysis_prompt') ?? 
      'Identify the plant and any diseases. List symptoms, diagnosis, and treatments (organic/chemical). Be concise.';
    
    try {
      await chat.addQueryChunk(Message.withImage(
        imageBytes: imageBytes,
        text: imageAnalysisPrompt,
        isUser: true,
      ));
      
      _updateContextUsage(imageAnalysisPrompt);
      
      final response = await chat.generateChatResponse();
      final responseText = response.toString();
      
      _updateContextUsage(responseText);
      
      // Add context warning if needed
      if (isContextNearLimit) {
        return '$responseText\n\n⚠️ Note: You\'re approaching the chat limit. Consider starting a new chat soon for best performance.';
      }
      
      return responseText;
    } catch (e) {
      Logger.log('ERROR during vision analysis: $e');
      
      // Fall back to text mode
      _isUsingVisionMode = false;
      return '''I encountered an error analyzing your image. Let me help you with text-based analysis instead.

Please describe what you see in the plant:
1. Plant type and symptoms
2. Affected parts
3. Any visible patterns

I'll provide diagnosis and treatment recommendations based on your description.''';
    }
  }

  Future<String> askQuestion(String question, {Uint8List? imageBytes}) async {
    Logger.log('Processing question: $question');
    
    // Check context limits
    if (isContextFull) {
      return '''⚠️ Chat context is full. Please start a new chat to continue.
      
Your conversation has reached the maximum length. To ensure optimal performance and accurate responses, please:
1. Tap the menu (⋮) 
2. Select "New Chat"''';
    }
    
    // Determine if we need vision (only if image is provided)
    final needsVision = imageBytes != null && _isVisionAvailable;
    final chat = await _getOrCreateChat(needsVision: needsVision);
    
    try {
      if (imageBytes != null && needsVision) {
        // Process with vision
        await chat.addQueryChunk(Message.withImage(
          imageBytes: imageBytes,
          text: question,
          isUser: true,
        ));
      } else {
        // Process as text only
        await chat.addQueryChunk(Message.text(
          text: question,
          isUser: true,
        ));
      }
      
      _updateContextUsage(question);
      
      final response = await chat.generateChatResponse();
      final responseText = response.toString();
      
      _updateContextUsage(responseText);
      
      // Add context warning if needed
      if (isContextNearLimit) {
        return '$responseText\n\n⚠️ Note: You\'re approaching the chat limit. Consider starting a new chat soon for best performance.';
      }
      
      return responseText;
    } catch (e) {
      Logger.log('Error processing question: $e');
      return 'I apologize, but I encountered an error processing your question. Please try again or start a new chat if the problem persists.';
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

  void resetChat() {
    _currentChat = null;
    _messageCount = 0;
    _approximateTokenCount = 0;
    _isUsingVisionMode = false;
    Logger.log('Chat reset');
  }

  void dispose() {
    _currentChat = null;
    _textModel = null;
    _visionModel = null;
    _isInitialized = false;
    _messageCount = 0;
    _approximateTokenCount = 0;
  }

  // Debug method to get current status
  Map<String, dynamic> getVisionStatus() {
    return {
      'isInitialized': _isInitialized,
      'isVisionAvailable': _isVisionAvailable,
      'isUsingVisionMode': _isUsingVisionMode,
      'hasTextModel': _textModel != null,
      'hasVisionModel': _visionModel != null,
      'hasChat': _currentChat != null,
      'contextStatus': getContextStatus(),
    };
  }
}