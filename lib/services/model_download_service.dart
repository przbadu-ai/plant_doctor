import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'secure_config_service.dart';
import '../utils/file_size_formatter.dart';
import '../utils/logger.dart';

class ModelInfo {
  final String id;
  final String name;
  final String url;
  final int? estimatedSize; // Optional, for display purposes only
  final String description;
  final bool supportsVision;

  ModelInfo({
    required this.id,
    required this.name,
    required this.url,
    this.estimatedSize,
    required this.description,
    required this.supportsVision,
  });
}

class ModelDownloadService {
  static final ModelDownloadService _instance = ModelDownloadService._internal();
  factory ModelDownloadService() => _instance;
  ModelDownloadService._internal();

  final Dio _dio = Dio();
  
  // Cache for actual file sizes fetched from server
  final Map<String, int> _actualFileSizes = {};
  
  // Helper method to get platform-specific model path
  String _getModelPath(String dirPath, String modelId, String extension) {
    // On iOS, flutter_gemma expects files directly in Documents directory
    // On Android, it works fine with subdirectories
    if (Platform.isIOS) {
      return '$dirPath/$modelId.$extension';
    } else {
      return '$dirPath/models/$modelId.$extension';
    }
  }
  
  final List<ModelInfo> availableModels = [
    // Gemma 3 Nano models with vision support - CORRECT .task files
    ModelInfo(
      id: 'gemma3n-e2b-task',
      name: 'Gemma 3n E2B Vision',
      url: 'https://huggingface.co/google/gemma-3n-E2B-it-litert-preview/resolve/main/gemma-3n-E2B-it-int4.task',
      estimatedSize: 3865470464, // ~3.6GB
      description: 'Gemma 3 Nano E2B with vision support for plant disease detection',
      supportsVision: true,
    ),
    ModelInfo(
      id: 'gemma3n-e4b-task',
      name: 'Gemma 3n E4B Vision',
      url: 'https://huggingface.co/google/gemma-3n-E4B-it-litert-preview/resolve/main/gemma-3n-E4B-it-int4.task',
      estimatedSize: 4831838720, // ~4.5GB
      description: 'Higher quality Gemma 3 Nano E4B with vision capabilities',
      supportsVision: true,
    ),
    // Alternative: Smaller Gemma models without vision (for testing)
    // ModelInfo(
    //   id: 'gemma-2b-test',
    //   name: 'Gemma 2B (No Vision)',
    //   url: 'https://storage.googleapis.com/jmstore/kaggleweb/grader_models/gemma/gemma-2b-it-cpu-int4.bin',
    //   estimatedSize: 1300000000, // ~1.3GB estimated
    //   description: 'Smaller Gemma 2B for testing (no vision support)',
    //   supportsVision: false,
    // ),
    // // Small test download
    // ModelInfo(
    //   id: 'test-download',
    //   name: 'Test Download',
    //   url: 'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf',
    //   estimatedSize: 13000, // ~13KB estimated
    //   description: 'Small file to test download functionality',
    //   supportsVision: false,
    // ),
  ];

  Future<int?> getActualFileSize(String url) async {
    try {
      // Try HEAD request first (more efficient)
      final response = await _dio.head(
        url,
        options: Options(
          headers: {
            'Accept': '*/*',
            'User-Agent': 'PlantDoctor/1.0',
            if (url.contains('huggingface.co') && 
                SecureConfigService().huggingFaceToken != null)
              'Authorization': 'Bearer ${SecureConfigService().huggingFaceToken}',
          },
          validateStatus: (status) => status! < 500,
        ),
      );
      
      if (response.statusCode == 200) {
        final contentLength = response.headers.value('content-length');
        if (contentLength != null) {
          return int.tryParse(contentLength);
        }
      }
      
      // If HEAD fails, try GET with range header
      final rangeResponse = await _dio.get(
        url,
        options: Options(
          headers: {
            'Accept': '*/*',
            'User-Agent': 'PlantDoctor/1.0',
            'Range': 'bytes=0-0', // Request only first byte
            if (url.contains('huggingface.co') && 
                SecureConfigService().huggingFaceToken != null)
              'Authorization': 'Bearer ${SecureConfigService().huggingFaceToken}',
          },
          validateStatus: (status) => status! < 500,
        ),
      );
      
      if (rangeResponse.statusCode == 206) {
        final contentRange = rangeResponse.headers.value('content-range');
        if (contentRange != null) {
          // Parse "bytes 0-0/12345" to get total size
          final match = RegExp(r'bytes \d+-\d+/(\d+)').firstMatch(contentRange);
          if (match != null) {
            return int.tryParse(match.group(1)!);
          }
        }
      }
      
      return null;
    } catch (e) {
      Logger.log('Error fetching file size: $e');
      return null;
    }
  }

  Stream<double> downloadModel(String modelId, Function(String) onProgress) async* {
    try {
      final model = availableModels.firstWhere((m) => m.id == modelId);
      final dir = await getApplicationDocumentsDirectory();
      
      // Get file extension from URL
      final uri = Uri.parse(model.url);
      final pathSegments = uri.pathSegments;
      final fileName = pathSegments.isNotEmpty ? pathSegments.last : '${model.id}.bin';
      final extension = fileName.contains('.') ? fileName.split('.').last : 'bin';
      
      final modelPath = _getModelPath(dir.path, model.id, extension);
      final modelFile = File(modelPath);
      
      // Create models directory if it doesn't exist (for Android)
      if (!Platform.isIOS) {
        await Directory('${dir.path}/models').create(recursive: true);
      }
      
      // Get actual file size from server
      onProgress('Checking model size...');
      final actualSize = await getActualFileSize(model.url);
      if (actualSize == null) {
        throw Exception('Could not determine file size from server');
      }
      
      // Cache the actual size for this model
      _actualFileSizes[modelId] = actualSize;
      Logger.log('Model $modelId actual size: $actualSize bytes');

      // Check if model already exists
      if (await modelFile.exists()) {
        final fileSize = await modelFile.length();
        
        if (fileSize == actualSize) {
          onProgress('Model already downloaded');
          yield 1.0;
          // Save model path even if already exists
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('current_model_path', modelPath);
          await prefs.setString('current_model_id', modelId);
          await prefs.setInt('model_size_$modelId', actualSize);
          return;
        } else {
          // Delete incomplete download
          onProgress('Removing incomplete download...');
          await modelFile.delete();
        }
      }

      // Download model with progress updates
      onProgress('Starting download of ${model.name}...');
      yield 0.0;
      
      final completer = StreamController<double>();
      
      _dio.download(
        model.url,
        modelPath,
        onReceiveProgress: (count, total) {
          final progress = count / (total > 0 ? total : actualSize);
          completer.add(progress);
          onProgress('Downloaded ${(progress * 100).toStringAsFixed(1)}% (${FileSizeFormatter.formatBytesAsMB(count)} / ${FileSizeFormatter.formatBytesAsMB(total > 0 ? total : actualSize)})');
        },
        options: Options(
          headers: {
            'Accept': '*/*',
            'User-Agent': 'PlantDoctor/1.0',
            if (model.url.contains('huggingface.co') && 
                SecureConfigService().huggingFaceToken != null)
              'Authorization': 'Bearer ${SecureConfigService().huggingFaceToken}',
          },
          receiveTimeout: const Duration(minutes: 30),
          sendTimeout: const Duration(minutes: 5),
        ),
      ).then((_) async {
        // Verify the downloaded file
        final downloadedFile = File(modelPath);
        if (await downloadedFile.exists()) {
          final downloadedSize = await downloadedFile.length();
          
          // Verify file size matches expected
          if (downloadedSize != actualSize) {
            throw Exception('Downloaded file size ($downloadedSize) does not match expected size ($actualSize)');
          }
          
          completer.add(1.0);
          // Save model path and size after successful download
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('current_model_path', modelPath);
          await prefs.setString('current_model_id', modelId);
          await prefs.setInt('model_size_$modelId', actualSize);
          onProgress('Download complete! Verified ${FileSizeFormatter.formatBytes(downloadedSize)}');
          completer.close();
        } else {
          throw Exception('Downloaded file not found after completion');
        }
      }).catchError((error, stackTrace) async {
        onProgress('Download failed: ${error.toString()}');
        
        // Report download error to Crashlytics
        await FirebaseCrashlytics.instance.recordError(
          error,
          stackTrace,
          reason: 'Model download failed',
          information: [
            'modelId: $modelId',
            'modelUrl: ${model.url}',
            'error: $error',
          ],
        );
        
        completer.addError(error);
        completer.close();
      });
      
      yield* completer.stream;
    } catch (e, stackTrace) {
      onProgress('Error: ${e.toString()}');
      
      // Report download error to Crashlytics
      await FirebaseCrashlytics.instance.recordError(
        e,
        stackTrace,
        reason: 'Model download error',
        information: [
          'modelId: $modelId',
          'error: $e',
        ],
      );
      
      rethrow;
    }
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
    try {
      final model = availableModels.firstWhere((m) => m.id == modelId);
      final dir = await getApplicationDocumentsDirectory();
      
      // Get file extension from URL (same logic as downloadModel method)
      final uri = Uri.parse(model.url);
      final pathSegments = uri.pathSegments;
      final fileName = pathSegments.isNotEmpty ? pathSegments.last : '${model.id}.bin';
      final extension = fileName.contains('.') ? fileName.split('.').last : 'bin';
      
      final modelPath = _getModelPath(dir.path, model.id, extension);
      final modelFile = File(modelPath);
      
      Logger.log('Checking model at: $modelPath');
      
      if (await modelFile.exists()) {
        final fileSize = await modelFile.length();
        
        // Get saved size from SharedPreferences or cache
        final prefs = await SharedPreferences.getInstance();
        final savedSize = prefs.getInt('model_size_$modelId');
        
        if (savedSize != null) {
          // Use saved size for comparison
          Logger.log('Model file exists with size: $fileSize bytes (expected from saved: $savedSize bytes)');
          final isValid = fileSize == savedSize;
          Logger.log('Model validation: $isValid');
          return isValid;
        } else if (_actualFileSizes.containsKey(modelId)) {
          // Use cached size
          final cachedSize = _actualFileSizes[modelId]!;
          Logger.log('Model file exists with size: $fileSize bytes (expected from cache: $cachedSize bytes)');
          final isValid = fileSize == cachedSize;
          Logger.log('Model validation: $isValid');
          return isValid;
        } else {
          // Fetch actual size from server
          Logger.log('No saved size found, fetching from server...');
          final actualSize = await getActualFileSize(model.url);
          if (actualSize != null) {
            _actualFileSizes[modelId] = actualSize;
            await prefs.setInt('model_size_$modelId', actualSize);
            Logger.log('Model file exists with size: $fileSize bytes (expected from server: $actualSize bytes)');
            final isValid = fileSize == actualSize;
            Logger.log('Model validation: $isValid');
            return isValid;
          } else {
            Logger.log('Could not determine expected size');
            return false;
          }
        }
      } else {
        Logger.log('Model file does not exist at: $modelPath');
      }
      
      return false;
    } catch (e) {
      Logger.log('Error checking model: $e');
      return false;
    }
  }

  Future<void> deleteModel(String modelId) async {
    try {
      final model = availableModels.firstWhere((m) => m.id == modelId);
      final dir = await getApplicationDocumentsDirectory();
      
      // Get file extension from URL (same logic as downloadModel method)
      final uri = Uri.parse(model.url);
      final pathSegments = uri.pathSegments;
      final fileName = pathSegments.isNotEmpty ? pathSegments.last : '${model.id}.bin';
      final extension = fileName.contains('.') ? fileName.split('.').last : 'bin';
      
      final modelPath = _getModelPath(dir.path, model.id, extension);
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
      // Always remove the saved size for this model
      await prefs.remove('model_size_$modelId');
      // Remove from cache as well
      _actualFileSizes.remove(modelId);
    } catch (e) {
      // Error deleting model: $e
    }
  }
}