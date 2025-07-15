class PlantDisease {
  final String id;
  final String name;
  final String description;
  final List<String> symptoms;
  final List<String> remedies;
  final double confidence;
  final String? imageUrl;

  PlantDisease({
    required this.id,
    required this.name,
    required this.description,
    required this.symptoms,
    required this.remedies,
    required this.confidence,
    this.imageUrl,
  });

  factory PlantDisease.fromJson(Map<String, dynamic> json) {
    return PlantDisease(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      symptoms: List<String>.from(json['symptoms'] ?? []),
      remedies: List<String>.from(json['remedies'] ?? []),
      confidence: (json['confidence'] ?? 0).toDouble(),
      imageUrl: json['imageUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'symptoms': symptoms,
      'remedies': remedies,
      'confidence': confidence,
      'imageUrl': imageUrl,
    };
  }
}