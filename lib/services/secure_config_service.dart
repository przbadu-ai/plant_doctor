import 'package:shared_preferences/shared_preferences.dart';
import 'package:plant_doctor/config/env_config.dart';

class SecureConfigService {
  static final SecureConfigService _instance = SecureConfigService._internal();
  factory SecureConfigService() => _instance;
  SecureConfigService._internal();

  String? _huggingFaceToken;

  // Check in order: 1) User saved token, 2) EnvConfig, 3) Environment variable
  String? get huggingFaceToken {
    return _huggingFaceToken ?? 
           (EnvConfig.huggingFaceToken.isNotEmpty ? EnvConfig.huggingFaceToken : null) ??
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