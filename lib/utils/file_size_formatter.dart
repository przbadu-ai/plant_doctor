class FileSizeFormatter {
  static const int _bytesPerKB = 1000;
  static const int _bytesPerMB = 1000 * 1000;
  static const int _bytesPerGB = 1000 * 1000 * 1000;

  /// Converts bytes to MB using decimal (1 MB = 1,000,000 bytes)
  static double bytesToMB(int bytes) {
    return bytes / _bytesPerMB;
  }

  /// Converts bytes to GB using decimal (1 GB = 1,000,000,000 bytes)
  static double bytesToGB(int bytes) {
    return bytes / _bytesPerGB;
  }

  /// Formats bytes into a human-readable string with appropriate unit
  static String formatBytes(int bytes, {int decimals = 1}) {
    if (bytes < _bytesPerKB) {
      return '$bytes B';
    } else if (bytes < _bytesPerMB) {
      return '${(bytes / _bytesPerKB).toStringAsFixed(decimals)} KB';
    } else if (bytes < _bytesPerGB) {
      return '${(bytes / _bytesPerMB).toStringAsFixed(decimals)} MB';
    } else {
      return '${(bytes / _bytesPerGB).toStringAsFixed(decimals)} GB';
    }
  }

  /// Formats bytes to MB string with specified decimals
  static String formatBytesAsMB(int bytes, {int decimals = 1}) {
    return '${bytesToMB(bytes).toStringAsFixed(decimals)} MB';
  }

  /// Formats bytes to GB string with specified decimals
  static String formatBytesAsGB(int bytes, {int decimals = 1}) {
    return '${bytesToGB(bytes).toStringAsFixed(decimals)} GB';
  }
}