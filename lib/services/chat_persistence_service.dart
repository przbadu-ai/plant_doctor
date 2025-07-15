import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/chat_message.dart';

class ChatPersistenceService {
  static const String _chatHistoryKey = 'chat_history';
  static const int _maxMessagesToStore = 100; // Limit storage to prevent excessive memory usage
  
  static final ChatPersistenceService _instance = ChatPersistenceService._internal();
  factory ChatPersistenceService() => _instance;
  ChatPersistenceService._internal();
  
  Future<void> saveMessages(List<ChatMessage> messages) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Limit the number of messages to store (keep most recent)
      final messagesToSave = messages.length > _maxMessagesToStore 
          ? messages.sublist(messages.length - _maxMessagesToStore)
          : messages;
      
      // Convert messages to JSON
      final jsonMessages = messagesToSave.map((msg) => msg.toJson()).toList();
      final jsonString = jsonEncode(jsonMessages);
      
      // Save to SharedPreferences
      await prefs.setString(_chatHistoryKey, jsonString);
    } catch (e) {
      // Silently fail - chat history is not critical
      print('Failed to save chat history: $e');
    }
  }
  
  Future<List<ChatMessage>> loadMessages() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_chatHistoryKey);
      
      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }
      
      final jsonMessages = jsonDecode(jsonString) as List;
      return jsonMessages.map((json) => ChatMessage.fromJson(json)).toList();
    } catch (e) {
      // If loading fails, return empty list
      print('Failed to load chat history: $e');
      return [];
    }
  }
  
  Future<void> clearHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_chatHistoryKey);
    } catch (e) {
      print('Failed to clear chat history: $e');
    }
  }
  
  Future<void> addMessage(ChatMessage message, List<ChatMessage> currentMessages) async {
    final updatedMessages = [...currentMessages, message];
    await saveMessages(updatedMessages);
  }
}