import 'dart:convert';
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
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'isUser': isUser,
      'timestamp': timestamp.toIso8601String(),
      'imageBytes': imageBytes != null ? base64Encode(imageBytes!) : null,
      'analysis': analysis?.toJson(),
    };
  }
  
  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'],
      text: json['text'],
      isUser: json['isUser'],
      timestamp: DateTime.parse(json['timestamp']),
      imageBytes: json['imageBytes'] != null ? base64Decode(json['imageBytes']) : null,
      analysis: json['analysis'] != null ? PlantDiseaseAnalysis.fromJson(json['analysis']) : null,
    );
  }
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
  
  Map<String, dynamic> toJson() {
    return {
      'diseases': diseases.map((d) => d.toJson()).toList(),
      'plantType': plantType,
      'healthStatus': healthStatus,
      'recommendations': recommendations,
    };
  }
  
  factory PlantDiseaseAnalysis.fromJson(Map<String, dynamic> json) {
    return PlantDiseaseAnalysis(
      diseases: (json['diseases'] as List).map((d) => DetectedDisease.fromJson(d)).toList(),
      plantType: json['plantType'],
      healthStatus: json['healthStatus'],
      recommendations: List<String>.from(json['recommendations']),
    );
  }
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
  
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'confidence': confidence,
      'severity': severity,
      'remedies': remedies,
    };
  }
  
  factory DetectedDisease.fromJson(Map<String, dynamic> json) {
    return DetectedDisease(
      name: json['name'],
      confidence: json['confidence'].toDouble(),
      severity: json['severity'],
      remedies: List<String>.from(json['remedies']),
    );
  }
}