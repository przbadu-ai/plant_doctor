import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/chat_thread.dart';

class ChatPersistenceService {
  static const String _chatThreadsKey = 'chat_threads';
  static const String _currentThreadKey = 'current_thread_id';
  static const int _maxThreadsToStore = 50;
  static const int _maxMessagesPerThread = 100;
  
  static final ChatPersistenceService _instance = ChatPersistenceService._internal();
  factory ChatPersistenceService() => _instance;
  ChatPersistenceService._internal();
  
  // Thread management
  Future<List<ChatThread>> loadAllThreads() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_chatThreadsKey);
      
      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }
      
      final jsonThreads = jsonDecode(jsonString) as List;
      final threads = jsonThreads.map((json) => ChatThread.fromJson(json)).toList();
      
      // Sort by updatedAt descending (most recent first)
      threads.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      
      return threads;
    } catch (e) {
      print('Failed to load chat threads: $e');
      return [];
    }
  }
  
  Future<void> saveThread(ChatThread thread) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final threads = await loadAllThreads();
      
      // Update or add thread
      final existingIndex = threads.indexWhere((t) => t.id == thread.id);
      if (existingIndex >= 0) {
        threads[existingIndex] = thread;
      } else {
        threads.insert(0, thread); // Add new thread at beginning
      }
      
      // Limit number of threads
      if (threads.length > _maxThreadsToStore) {
        threads.removeRange(_maxThreadsToStore, threads.length);
      }
      
      // Limit messages per thread
      final limitedThreads = threads.map((t) {
        if (t.messages.length > _maxMessagesPerThread) {
          return t.copyWith(
            messages: t.messages.sublist(t.messages.length - _maxMessagesPerThread),
          );
        }
        return t;
      }).toList();
      
      final jsonThreads = limitedThreads.map((t) => t.toJson()).toList();
      final jsonString = jsonEncode(jsonThreads);
      
      await prefs.setString(_chatThreadsKey, jsonString);
    } catch (e) {
      print('Failed to save chat thread: $e');
    }
  }
  
  Future<void> deleteThread(String threadId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final threads = await loadAllThreads();
      
      threads.removeWhere((t) => t.id == threadId);
      
      final jsonThreads = threads.map((t) => t.toJson()).toList();
      final jsonString = jsonEncode(jsonThreads);
      
      await prefs.setString(_chatThreadsKey, jsonString);
      
      // If this was the current thread, clear it
      final currentThreadId = await getCurrentThreadId();
      if (currentThreadId == threadId) {
        await setCurrentThreadId(null);
      }
    } catch (e) {
      print('Failed to delete chat thread: $e');
    }
  }
  
  Future<ChatThread?> loadThread(String threadId) async {
    try {
      final threads = await loadAllThreads();
      return threads.firstWhere((t) => t.id == threadId);
    } catch (e) {
      print('Failed to load chat thread: $e');
      return null;
    }
  }
  
  // Current thread management
  Future<String?> getCurrentThreadId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_currentThreadKey);
    } catch (e) {
      print('Failed to get current thread ID: $e');
      return null;
    }
  }
  
  Future<void> setCurrentThreadId(String? threadId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (threadId != null) {
        await prefs.setString(_currentThreadKey, threadId);
      } else {
        await prefs.remove(_currentThreadKey);
      }
    } catch (e) {
      print('Failed to set current thread ID: $e');
    }
  }
  
  // Legacy methods for backward compatibility
  Future<void> clearHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_chatThreadsKey);
      await prefs.remove(_currentThreadKey);
    } catch (e) {
      print('Failed to clear chat history: $e');
    }
  }
}