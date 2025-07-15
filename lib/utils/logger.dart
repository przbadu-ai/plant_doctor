/// Simple logger utility for development
/// In production, these logs can be disabled or replaced with a proper logging framework
class Logger {
  static const bool _enableLogging = true; // Set to false in production

  static void log(String message) {
    if (_enableLogging) {
      // ignore: avoid_print
      print(message);
    }
  }

  static void error(String message, [Object? error]) {
    if (_enableLogging) {
      // ignore: avoid_print
      print('ERROR: $message${error != null ? ' - $error' : ''}');
    }
  }
}