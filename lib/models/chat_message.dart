import 'dart:typed_data';

class ChatMessage {
  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final Uint8List? imageBytes;
  final PlantDiseaseAnalysis? analysis;

  ChatMessage({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.imageBytes,
    this.analysis,
  });

  bool get hasImage => imageBytes != null;
  bool get hasAnalysis => analysis != null;
}

class PlantDiseaseAnalysis {
  final List<DetectedDisease> diseases;
  final String plantType;
  final String healthStatus;
  final List<String> recommendations;

  PlantDiseaseAnalysis({
    required this.diseases,
    required this.plantType,
    required this.healthStatus,
    required this.recommendations,
  });
}

class DetectedDisease {
  final String name;
  final double confidence;
  final String severity;
  final List<String> remedies;

  DetectedDisease({
    required this.name,
    required this.confidence,
    required this.severity,
    required this.remedies,
  });
}