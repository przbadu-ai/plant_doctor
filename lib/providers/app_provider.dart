import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import '../models/chat_message.dart';
import '../models/chat_thread.dart';
import '../services/ai_service.dart';
import '../services/model_download_service.dart';
import '../services/chat_persistence_service.dart';
import 'language_provider.dart';
import '../utils/logger.dart';

class AppProvider extends ChangeNotifier {
  final AIService _aiService = AIService();
  final ModelDownloadService _modelService = ModelDownloadService();
  final ChatPersistenceService _chatPersistence = ChatPersistenceService();
  LanguageProvider? _languageProvider;
  
  final List<ChatMessage> _messages = [];
  List<ChatThread> _chatThreads = [];
  ChatThread? _currentThread;
  String? _currentThreadId;
  bool _isLoading = false;
  bool _isLoadingThreads = false;
  String? _error;
  String? _currentModelId;
  double _downloadProgress = 0.0;
  bool _isDownloading = false;
  String _downloadStatus = '';

  List<ChatMessage> get messages => _messages;
  List<ChatThread> get chatThreads => _chatThreads;
  ChatThread? get currentThread => _currentThread;
  String? get currentThreadId => _currentThreadId;
  bool get isLoading => _isLoading;
  bool get isLoadingThreads => _isLoadingThreads;
  String? get error => _error;
  String? get currentModelId => _currentModelId;
  double get downloadProgress => _downloadProgress;
  bool get isDownloading => _isDownloading;
  String get downloadStatus => _downloadStatus;
  bool get isModelReady => _aiService.isInitialized;
  List<ModelInfo> get availableModels => _modelService.availableModels;
  bool get isContextNearLimit => _aiService.isContextNearLimit;
  bool get isContextFull => _aiService.isContextFull;
  Map<String, dynamic> get contextStatus => _aiService.getContextStatus();
  
  ModelInfo? get currentModelInfo {
    if (_currentModelId == null) return null;
    try {
      return _modelService.availableModels.firstWhere(
        (model) => model.id == _currentModelId,
      );
    } catch (e) {
      return null;
    }
  }
  
  void setLanguageProvider(LanguageProvider provider) {
    _languageProvider = provider;
    _aiService.setLanguageProvider(provider);
  }

  AppProvider() {
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Load all chat threads
    await loadChatThreads();
    
    // Check if model is already downloaded
    final modelPath = await _modelService.getCurrentModelPath();
    final modelId = await _modelService.getCurrentModelId();
    
    Logger.log('App initialization - Model path: $modelPath, Model ID: $modelId');
    
    if (modelPath != null && modelId != null) {
      final modelExists = await _modelService.isModelDownloaded(modelId);
      Logger.log('Model exists check: $modelExists');
      
      if (modelExists) {
        _currentModelId = modelId;
        Logger.log('Initializing AI with model: $modelPath');
        await _initializeAI(modelPath);
      } else {
        Logger.log('Model file not found at expected location');
        // Clear invalid preferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('current_model_path');
        await prefs.remove('current_model_id');
      }
    } else {
      Logger.log('No saved model information found');
    }
    
    notifyListeners();
  }

  Future<void> downloadModel(String modelId) async {
    Logger.log('Starting download for model: $modelId');
    _isDownloading = true;
    _downloadProgress = 0.0;
    _error = null;
    _downloadStatus = 'Initializing download...';
    notifyListeners();

    try {
      await for (final progress in _modelService.downloadModel(modelId, (status) {
        // Progress callback
        _downloadStatus = status;
        notifyListeners();
      })) {
        _downloadProgress = progress;
        notifyListeners();
      }

      // Initialize AI after download
      final modelPath = await _modelService.getCurrentModelPath();
      if (modelPath != null) {
        await _initializeAI(modelPath);
        _currentModelId = modelId;
        
        // Check if this model supports vision
        final model = _modelService.availableModels.firstWhere((m) => m.id == modelId);
        if (!model.supportsVision) {
          Logger.log('Warning: Downloaded model does not support vision analysis');
        }
      }
    } catch (e) {
      Logger.log('Download error: $e');
      _error = 'Failed to download model: $e';
      _downloadStatus = 'Download failed';
    } finally {
      _isDownloading = false;
      _downloadStatus = '';
      notifyListeners();
    }
  }

  Future<void> _initializeAI(String modelPath) async {
    try {
      await FirebaseCrashlytics.instance.log('Starting AI initialization with path: $modelPath');
      await _aiService.initialize(modelPath);
      // Don't create chat immediately - let it be created on demand
      await FirebaseCrashlytics.instance.log('AI initialization completed successfully');
      notifyListeners();
    } catch (e, stackTrace) {
      Logger.log('AI initialization error: $e');
      _error = 'Failed to initialize AI: $e';
      
      // Report to Crashlytics with device context
      await FirebaseCrashlytics.instance.recordError(
        e,
        stackTrace,
        reason: 'AI initialization failed in AppProvider',
        information: [
          'modelPath: $modelPath',
          'currentModelId: $_currentModelId',
          'error: $e',
        ],
      );
      
      // Check for x86_64 emulator issue
      if (e.toString().contains('SIGSEGV') || e.toString().contains('libvndksupport.so')) {
        _error = 'AI model not supported on x86_64 emulators. Please use:\n'
            '• ARM64 emulator (slower but compatible)\n'
            '• Physical Android device (recommended)\n'
            '• Or test with the smaller test model first';
      }
      
      // Clear the model selection to allow re-download
      _currentModelId = null;
      notifyListeners();
    }
  }

  Future<void> analyzePlantImage(Uint8List imageBytes) async {
    if (!_aiService.isInitialized) {
      _error = 'Please download a model first';
      notifyListeners();
      return;
    }

    // Add user message with image
    _messages.add(ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: _languageProvider?.getLocalizedPrompt('analyze_plant') ?? 'Analyze this plant for diseases',
      isUser: true,
      timestamp: DateTime.now(),
      imageBytes: imageBytes,
    ));
    _updateCurrentThread();

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _aiService.analyzePlantImage(imageBytes);
      
      // Parse response and create analysis
      final analysis = _parseAnalysisResponse(response);
      
      _messages.add(ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: response,
        isUser: false,
        timestamp: DateTime.now(),
        analysis: analysis,
      ));
      _updateCurrentThread();
    } catch (e) {
      Logger.log('Error analyzing plant image: $e');
      Logger.log('Error type: ${e.runtimeType}');
      _error = 'Failed to analyze image: $e';
      
      // For any error, we'll provide helpful guidance
      _messages.add(ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: _languageProvider?.getLocalizedPrompt('image_upload_help') ?? 
              'I see you\'ve uploaded an image. While I cannot directly analyze images, '
              'I can still help you identify plant diseases!\n\n'
              'Please describe what you see:\n'
              '• What type of plant is it?\n'
              '• What color are the affected areas?\n'
              '• Are there spots, wilting, or discoloration?\n'
              '• Which parts are affected (leaves, stems, roots)?\n'
              '• How widespread is the problem?\n\n'
              'The more details you provide, the better I can help diagnose and suggest treatments.',
        isUser: false,
        timestamp: DateTime.now(),
      ));
      _updateCurrentThread();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> sendMessage(String message, {Uint8List? imageBytes}) async {
    if (!_aiService.isInitialized) {
      _error = 'Please download a model first';
      notifyListeners();
      return;
    }

    // Add user message
    _messages.add(ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: message,
      isUser: true,
      timestamp: DateTime.now(),
      imageBytes: imageBytes,
    ));
    _updateCurrentThread();

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _aiService.askQuestion(message, imageBytes: imageBytes);
      
      _messages.add(ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: response,
        isUser: false,
        timestamp: DateTime.now(),
      ));
      _updateCurrentThread();
    } catch (e) {
      Logger.log('Error sending message: $e');
      Logger.log('Error type: ${e.runtimeType}');
      _error = 'Failed to get response: $e';
      _messages.add(ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: _languageProvider?.getLocalizedPrompt('error_message') ?? 'Sorry, I encountered an error. Please try again.',
        isUser: false,
        timestamp: DateTime.now(),
      ));
      _updateCurrentThread();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  PlantDiseaseAnalysis? _parseAnalysisResponse(String response) {
    // This is a simplified parser - you might want to use a more sophisticated approach
    // or ask the AI to return structured JSON
    try {
      final diseases = <DetectedDisease>[];
      
      // Extract disease information from the response
      // This is a placeholder - implement actual parsing logic based on your AI response format
      
      return PlantDiseaseAnalysis(
        diseases: diseases,
        plantType: 'Unknown', // Extract from response
        healthStatus: 'Unknown', // Extract from response
        recommendations: [], // Extract from response
      );
    } catch (e) {
      // Error parsing analysis response: $e
      return null;
    }
  }

  void clearChat() {
    if (_currentThreadId != null) {
      // Start a new thread when clearing chat
      createNewThread();
      _aiService.resetChat();
    }
  }

  Future<Map<String, dynamic>> getModelStatus() async {
    final modelPath = await _modelService.getCurrentModelPath();
    final modelId = await _modelService.getCurrentModelId();
    final modelExists = modelId != null ? await _modelService.isModelDownloaded(modelId) : false;
    
    return {
      'modelPath': modelPath,
      'modelId': modelId,
      'modelExists': modelExists,
      'isModelReady': isModelReady,
      'currentModelId': _currentModelId,
    };
  }

  Map<String, dynamic> getVisionStatus() {
    return _aiService.getVisionStatus();
  }

  // Thread management methods
  Future<void> loadChatThreads() async {
    _isLoadingThreads = true;
    notifyListeners();
    
    try {
      _chatThreads = await _chatPersistence.loadAllThreads();
    } catch (e) {
      Logger.log('Error loading chat threads: $e');
      _chatThreads = [];
    } finally {
      _isLoadingThreads = false;
      notifyListeners();
    }
  }
  
  Future<void> loadChatThread(String threadId) async {
    _currentThreadId = threadId;
    await _chatPersistence.setCurrentThreadId(threadId);
    
    final thread = await _chatPersistence.loadThread(threadId);
    if (thread != null) {
      _currentThread = thread;
      _messages.clear();
      _messages.addAll(thread.messages);
      notifyListeners();
    }
  }
  
  void createNewThread() {
    final threadId = DateTime.now().millisecondsSinceEpoch.toString();
    _currentThreadId = threadId;
    _chatPersistence.setCurrentThreadId(threadId);
    
    _currentThread = ChatThread(
      id: threadId,
      title: _languageProvider?.currentLanguage == AppLanguage.spanish ? 'Nueva consulta' :
             _languageProvider?.currentLanguage == AppLanguage.hindi ? 'नई चैट' : 'New Chat',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      messages: [],
    );
    
    _messages.clear();
    
    // Add welcome message
    _messages.add(ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: _languageProvider?.getLocalizedPrompt('welcome') ?? 'Welcome to PlantDoctor! I can help you identify plant diseases, suggest treatments, and answer farming questions. Upload a photo of your plant or ask me anything!',
      isUser: false,
      timestamp: DateTime.now(),
    ));
    
    _updateCurrentThread();
    notifyListeners();
  }
  
  Future<void> deleteThread(String threadId) async {
    await _chatPersistence.deleteThread(threadId);
    _chatThreads.removeWhere((t) => t.id == threadId);
    
    if (_currentThreadId == threadId) {
      _currentThreadId = null;
      _currentThread = null;
      _messages.clear();
    }
    
    notifyListeners();
  }
  
  void _updateCurrentThread() {
    if (_currentThread == null || _currentThreadId == null) return;
    
    // Get first plant image for thumbnail
    Uint8List? thumbnailImage;
    for (final message in _messages) {
      if (message.imageBytes != null) {
        thumbnailImage = message.imageBytes;
        break;
      }
    }
    
    // Update thread
    _currentThread = _currentThread!.copyWith(
      messages: List.from(_messages),
      updatedAt: DateTime.now(),
      lastMessage: _messages.isNotEmpty ? _messages.last.text : null,
      thumbnailImage: thumbnailImage ?? _currentThread!.thumbnailImage,
    );
    
    // Save thread
    _chatPersistence.saveThread(_currentThread!);
    
    // Update local threads list
    final existingIndex = _chatThreads.indexWhere((t) => t.id == _currentThreadId);
    if (existingIndex >= 0) {
      _chatThreads[existingIndex] = _currentThread!;
    } else {
      _chatThreads.insert(0, _currentThread!);
    }
  }

  // Create a new chat when context is full
  Future<void> createNewChat() async {
    // Reset AI chat
    _aiService.resetChat();
    
    // Clear messages
    _messages.clear();
    _currentThread = null;
    _currentThreadId = null;
    _error = null;
    
    notifyListeners();
  }
  
  // Get AI status for debugging (including vision and context)
  Map<String, dynamic> getAIStatus() {
    return _aiService.getVisionStatus();
  }

  @override
  void dispose() {
    _aiService.dispose();
    super.dispose();
  }
}