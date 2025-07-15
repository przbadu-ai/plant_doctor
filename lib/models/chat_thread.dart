import 'dart:convert';
import 'dart:typed_data';
import 'chat_message.dart';

class ChatThread {
  final String id;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Uint8List? thumbnailImage; // First plant image in the thread
  final String? plantType;
  final String? lastMessage;
  final List<ChatMessage> messages;

  ChatThread({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    this.thumbnailImage,
    this.plantType,
    this.lastMessage,
    required this.messages,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'thumbnailImage': thumbnailImage != null ? base64Encode(thumbnailImage!) : null,
      'plantType': plantType,
      'lastMessage': lastMessage,
      'messages': messages.map((m) => m.toJson()).toList(),
    };
  }

  factory ChatThread.fromJson(Map<String, dynamic> json) {
    return ChatThread(
      id: json['id'],
      title: json['title'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      thumbnailImage: json['thumbnailImage'] != null ? base64Decode(json['thumbnailImage']) : null,
      plantType: json['plantType'],
      lastMessage: json['lastMessage'],
      messages: (json['messages'] as List).map((m) => ChatMessage.fromJson(m)).toList(),
    );
  }

  ChatThread copyWith({
    String? title,
    DateTime? updatedAt,
    Uint8List? thumbnailImage,
    String? plantType,
    String? lastMessage,
    List<ChatMessage>? messages,
  }) {
    return ChatThread(
      id: id,
      title: title ?? this.title,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      thumbnailImage: thumbnailImage ?? this.thumbnailImage,
      plantType: plantType ?? this.plantType,
      lastMessage: lastMessage ?? this.lastMessage,
      messages: messages ?? this.messages,
    );
  }
}