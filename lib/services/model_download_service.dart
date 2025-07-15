import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ModelInfo {
  final String id;
  final String name;
  final String url;
  final int size;
  final String description;
  final bool supportsVision;

  ModelInfo({
    required this.id,
    required this.name,
    required this.url,
    required this.size,
    required this.description,
    required this.supportsVision,
  });
}

class ModelDownloadService {
  static final ModelDownloadService _instance = ModelDownloadService._internal();
  factory ModelDownloadService() => _instance;
  ModelDownloadService._internal();

  final Dio _dio = Dio();
  final List<ModelInfo> availableModels = [
    ModelInfo(
      id: 'gemma-3n-e2b',
      name: 'Gemma 3n E2B Vision',
      url: 'https://huggingface.co/google/gemma-3n-E2B-it-litert-preview/resolve/main/gemma-3n-E2B-it-q4_k_m.task',
      size: 1500000000, // ~1.5GB
      description: 'Optimized for plant disease detection with vision capabilities',
      supportsVision: true,
    ),
    ModelInfo(
      id: 'gemma-3n-e4b',
      name: 'Gemma 3n E4B Vision',
      url: 'https://huggingface.co/google/gemma-3n-E4B-it-litert-preview/resolve/main/gemma-3n-E4B-it-q4_k_m.task',
      size: 1500000000, // ~1.5GB
      description: 'Higher quality model for accurate disease identification',
      supportsVision: true,
    ),
  ];

  Stream<double> downloadModel(String modelId, Function(String) onProgress) async* {
    final model = availableModels.firstWhere((m) => m.id == modelId);
    final dir = await getApplicationDocumentsDirectory();
    final modelPath = '${dir.path}/models/${model.id}.task';
    final modelFile = File(modelPath);

    // Create models directory if it doesn't exist
    await Directory('${dir.path}/models').create(recursive: true);

    // Check if model already exists
    if (await modelFile.exists()) {
      final fileSize = await modelFile.length();
      if (fileSize == model.size) {
        yield 1.0;
        return;
      }
    }

    // Download model
    onProgress('Downloading ${model.name}...');
    
    await for (final progress in _downloadFile(model.url, modelPath, model.size, onProgress)) {
      yield progress;
    }

    // Save model path
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('current_model_path', modelPath);
    await prefs.setString('current_model_id', modelId);
  }

  Stream<double> _downloadFile(String url, String savePath, int totalSize, Function(String) onProgress) async* {
    int received = 0;
    
    await _dio.download(
      url,
      savePath,
      onReceiveProgress: (count, total) {
        received = count;
        final progress = received / totalSize;
        onProgress('Downloaded ${(progress * 100).toStringAsFixed(1)}%');
      },
      options: Options(
        headers: {
          'Accept': '*/*',
        },
      ),
    );

    yield 1.0;
  }

  Future<String?> getCurrentModelPath() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('current_model_path');
  }

  Future<String?> getCurrentModelId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('current_model_id');
  }

  Future<bool> isModelDownloaded(String modelId) async {
    final dir = await getApplicationDocumentsDirectory();
    final modelPath = '${dir.path}/models/$modelId.task';
    final modelFile = File(modelPath);
    
    if (await modelFile.exists()) {
      final model = availableModels.firstWhere((m) => m.id == modelId);
      final fileSize = await modelFile.length();
      return fileSize == model.size;
    }
    
    return false;
  }

  Future<void> deleteModel(String modelId) async {
    final dir = await getApplicationDocumentsDirectory();
    final modelPath = '${dir.path}/models/$modelId.task';
    final modelFile = File(modelPath);
    
    if (await modelFile.exists()) {
      await modelFile.delete();
    }
    
    // Clear preferences if this was the current model
    final prefs = await SharedPreferences.getInstance();
    final currentModelId = prefs.getString('current_model_id');
    if (currentModelId == modelId) {
      await prefs.remove('current_model_path');
      await prefs.remove('current_model_id');
    }
  }
}