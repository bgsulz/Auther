import 'package:flutter/foundation.dart';

/// Simple logging service that only prints in debug mode.
/// Can be extended later to support crashlytics or other logging backends.
class Logger {
  static final Logger _instance = Logger._internal();
  factory Logger() => _instance;
  Logger._internal();

  /// Log debug-level messages (development only)
  void debug(String message, [String? tag]) {
    if (kDebugMode) {
      final prefix = tag != null ? '[$tag] ' : '';
      debugPrint('DEBUG: $prefix$message');
    }
  }

  /// Log info-level messages
  void info(String message, [String? tag]) {
    if (kDebugMode) {
      final prefix = tag != null ? '[$tag] ' : '';
      debugPrint('INFO: $prefix$message');
    }
  }

  /// Log error-level messages with optional error and stack trace
  void error(String message, [Object? error, StackTrace? stackTrace, String? tag]) {
    if (kDebugMode) {
      final prefix = tag != null ? '[$tag] ' : '';
      debugPrint('ERROR: $prefix$message');
      if (error != null) {
        debugPrint('  Error: $error');
      }
      if (stackTrace != null) {
        debugPrint('  Stack trace:\n$stackTrace');
      }
    }
  }

  /// Log warning-level messages
  void warn(String message, [String? tag]) {
    if (kDebugMode) {
      final prefix = tag != null ? '[$tag] ' : '';
      debugPrint('WARN: $prefix$message');
    }
  }
}

/// Global logger instance for convenience
final logger = Logger();
