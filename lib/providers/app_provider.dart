import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/chat_message.dart';
import '../services/ai_service.dart';
import '../services/model_download_service.dart';

class AppProvider extends ChangeNotifier {
  final AIService _aiService = AIService();
  final ModelDownloadService _modelService = ModelDownloadService();
  
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  String? _error;
  String? _currentModelId;
  double _downloadProgress = 0.0;
  bool _isDownloading = false;
  String _downloadStatus = '';

  List<ChatMessage> get messages => _messages;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get currentModelId => _currentModelId;
  double get downloadProgress => _downloadProgress;
  bool get isDownloading => _isDownloading;
  String get downloadStatus => _downloadStatus;
  bool get isModelReady => _aiService.isInitialized;
  List<ModelInfo> get availableModels => _modelService.availableModels;

  AppProvider() {
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Check if model is already downloaded
    final modelPath = await _modelService.getCurrentModelPath();
    final modelId = await _modelService.getCurrentModelId();
    
    print('App initialization - Model path: $modelPath, Model ID: $modelId');
    
    if (modelPath != null && modelId != null) {
      final modelExists = await _modelService.isModelDownloaded(modelId);
      print('Model exists check: $modelExists');
      
      if (modelExists) {
        _currentModelId = modelId;
        print('Initializing AI with model: $modelPath');
        await _initializeAI(modelPath);
      } else {
        print('Model file not found at expected location');
        // Clear invalid preferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('current_model_path');
        await prefs.remove('current_model_id');
      }
    } else {
      print('No saved model information found');
    }
    
    notifyListeners();
  }

  Future<void> downloadModel(String modelId) async {
    print('Starting download for model: $modelId');
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
      }
    } catch (e) {
      print('Download error: $e');
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
      await _aiService.initialize(modelPath);
      await _aiService.createNewChat();
      
      // Add welcome message
      _messages.add(ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: 'Welcome to PlantDoctor! I can help you identify plant diseases, suggest treatments, and answer farming questions. Upload a photo of your plant or ask me anything!',
        isUser: false,
        timestamp: DateTime.now(),
      ));
      
      notifyListeners();
    } catch (e) {
      print('AI initialization error: $e');
      _error = 'Failed to initialize AI: $e';
      
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
      text: 'Analyze this plant for diseases',
      isUser: true,
      timestamp: DateTime.now(),
      imageBytes: imageBytes,
    ));

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
    } catch (e) {
      _error = 'Failed to analyze image: $e';
      _messages.add(ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: 'Sorry, I encountered an error analyzing the image. Please try again.',
        isUser: false,
        timestamp: DateTime.now(),
      ));
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
    } catch (e) {
      _error = 'Failed to get response: $e';
      _messages.add(ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: 'Sorry, I encountered an error. Please try again.',
        isUser: false,
        timestamp: DateTime.now(),
      ));
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
    _messages.clear();
    _aiService.createNewChat().then((_) {
      _messages.add(ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: 'Chat cleared. How can I help you with your plants today?',
        isUser: false,
        timestamp: DateTime.now(),
      ));
      notifyListeners();
    });
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

  @override
  void dispose() {
    _aiService.dispose();
    super.dispose();
  }
}