import 'dart:typed_data';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:flutter_gemma/core/chat.dart';
import 'package:flutter_gemma/core/model.dart';
import 'package:flutter_gemma/pigeon.g.dart';

class AIService {
  static final AIService _instance = AIService._internal();
  factory AIService() => _instance;
  AIService._internal();

  final _gemma = FlutterGemmaPlugin.instance;
  InferenceModel? _model;
  InferenceChat? _currentChat;
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;

  Future<void> initialize(String modelPath) async {
    try {
      // Set model path
      await _gemma.modelManager.setModelPath(modelPath);

      // Create model with vision support for plant disease detection
      _model = await _gemma.createModel(
        modelType: ModelType.gemmaIt,
        supportImage: true,
        maxNumImages: 1,
        preferredBackend: PreferredBackend.gpu,
        maxTokens: 4096,
      );

      _isInitialized = true;
    } catch (e) {
      // Log error initializing AI model: $e
      throw Exception('Failed to initialize AI model');
    }
  }

  Future<InferenceChat> createNewChat() async {
    if (_model == null) {
      throw Exception('Model not initialized');
    }

    _currentChat = await _model!.createChat(
      temperature: 0.8,
      topK: 40,
      topP: 0.9,
      supportImage: true,
    );

    // Add initial context for plant disease detection
    await _currentChat!.addQueryChunk(Message.text(
      text: '''You are PlantDoctor AI, an expert in plant diseases and agricultural practices. 
      Your role is to:
      1. Identify plant diseases from images
      2. Provide detailed analysis of symptoms
      3. Suggest organic and chemical remedies
      4. Give preventive measures
      5. Answer farming-related questions
      
      Always be helpful, accurate, and provide practical advice for farmers.''',
      isUser: false,
    ));

    return _currentChat!;
  }

  Future<String> analyzePlantImage(Uint8List imageBytes) async {
    if (_currentChat == null) {
      await createNewChat();
    }

    // Send image with analysis request
    await _currentChat!.addQueryChunk(Message.withImage(
      text: '''Analyze this plant image and provide:
      1. Plant type identification
      2. Any visible diseases or pests
      3. Severity assessment (mild/moderate/severe)
      4. Recommended treatments (organic and chemical)
      5. Preventive measures
      6. Expected recovery time
      
      Format the response in a clear, structured way.''',
      imageBytes: imageBytes,
      isUser: true,
    ));

    final response = await _currentChat!.generateChatResponse();
    return response;
  }

  Future<String> askQuestion(String question, {Uint8List? imageBytes}) async {
    if (_currentChat == null) {
      await createNewChat();
    }

    if (imageBytes != null) {
      await _currentChat!.addQueryChunk(Message.withImage(
        text: question,
        imageBytes: imageBytes,
        isUser: true,
      ));
    } else {
      await _currentChat!.addQueryChunk(Message.text(
        text: question,
        isUser: true,
      ));
    }

    final response = await _currentChat!.generateChatResponse();
    return response;
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