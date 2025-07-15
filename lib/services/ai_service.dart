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

      // Create model without vision support to avoid initialization errors
      _model = await _gemma.createModel(
        modelType: ModelType.gemmaIt,
        supportImage: false, // Disable vision to fix initialization error
        maxNumImages: 0,
        preferredBackend: PreferredBackend.cpu,
        maxTokens: 2048,
      );

      _isInitialized = true;
    } catch (e) {
      print('Error initializing AI model: $e');
      _isInitialized = false;
      _model = null;
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
      await _currentChat!.addQueryChunk(Message.text(
        text: '''I have uploaded an image of a plant that may have disease issues. 
        Since I cannot process images directly, please help me by:
        
        1. Asking me to describe what I see in the plant (color changes, spots, wilting, etc.)
        2. Based on my description, identify possible diseases
        3. Suggest treatments and preventive measures
        
        Please start by asking me to describe the plant's symptoms.''',
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
          text: question + '\n\n(Note: An image was provided but I cannot process images directly. Please describe what you see in the image.)',
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