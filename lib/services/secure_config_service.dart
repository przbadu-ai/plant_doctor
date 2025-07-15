import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SecureConfigService {
  static final SecureConfigService _instance = SecureConfigService._internal();
  factory SecureConfigService() => _instance;
  SecureConfigService._internal();

  String? _huggingFaceToken;

  // Option 1: Get from environment variable (for CI/CD)
  String? get huggingFaceToken {
    return _huggingFaceToken ?? 
           const String.fromEnvironment('HUGGING_FACE_TOKEN');
  }

  // Option 2: Store securely in SharedPreferences (user enters once)
  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('hf_token', token);
    _huggingFaceToken = token;
  }

  Future<String?> loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _huggingFaceToken = prefs.getString('hf_token');
    return _huggingFaceToken;
  }

  Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('hf_token');
    _huggingFaceToken = null;
  }

  bool get hasToken => huggingFaceToken != null && huggingFaceToken!.isNotEmpty;
}