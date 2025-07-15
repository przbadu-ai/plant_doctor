import 'dart:typed_data';
import 'package:flutter/material.dart';
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

  List<ChatMessage> get messages => _messages;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get currentModelId => _currentModelId;
  double get downloadProgress => _downloadProgress;
  bool get isDownloading => _isDownloading;
  bool get isModelReady => _aiService.isInitialized;
  List<ModelInfo> get availableModels => _modelService.availableModels;

  AppProvider() {
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Check if model is already downloaded
    final modelPath = await _modelService.getCurrentModelPath();
    final modelId = await _modelService.getCurrentModelId();
    
    if (modelPath != null && modelId != null) {
      final modelExists = await _modelService.isModelDownloaded(modelId);
      if (modelExists) {
        _currentModelId = modelId;
        await _initializeAI(modelPath);
      }
    }
    
    notifyListeners();
  }

  Future<void> downloadModel(String modelId) async {
    _isDownloading = true;
    _downloadProgress = 0.0;
    _error = null;
    notifyListeners();

    try {
      await for (final progress in _modelService.downloadModel(modelId, (status) {
        // Progress callback
        // Progress: status
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
      _error = 'Failed to download model: $e';
    } finally {
      _isDownloading = false;
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
      _error = 'Failed to initialize AI: $e';
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

  @override
  void dispose() {
    _aiService.dispose();
    super.dispose();
  }
}