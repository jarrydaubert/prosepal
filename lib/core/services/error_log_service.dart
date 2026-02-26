import 'package:flutter/foundation.dart';

/// Simple in-memory error log for attaching to feedback emails
class ErrorLogService {
  ErrorLogService._();
  static final instance = ErrorLogService._();

  final List<_ErrorEntry> _errors = [];
  static const _maxErrors = 10;

  /// Log an error with optional stacktrace
  void log(Object error, [StackTrace? stackTrace]) {
    _errors.add(
      _ErrorEntry(
        timestamp: DateTime.now(),
        error: error.toString(),
        stackTrace: stackTrace?.toString(),
      ),
    );

    // Keep only recent errors
    if (_errors.length > _maxErrors) {
      _errors.removeAt(0);
    }

    if (kDebugMode) {
      debugPrint('Error logged: $error');
    }
  }

  /// Get formatted error log for feedback
  String getFormattedLog() {
    if (_errors.isEmpty) return 'No recent errors';

    final buffer = StringBuffer();
    buffer.writeln('--- Recent Errors (${_errors.length}) ---');

    for (final entry in _errors.reversed.take(5)) {
      buffer.writeln('[${entry.timestamp.toIso8601String()}]');
      buffer.writeln(entry.error);
      if (entry.stackTrace != null) {
        // Only include first few lines of stacktrace
        final lines = entry.stackTrace!.split('\n').take(5).join('\n');
        buffer.writeln(lines);
      }
      buffer.writeln();
    }

    return buffer.toString();
  }

  /// Clear all logged errors
  void clear() => _errors.clear();
}

class _ErrorEntry {
  _ErrorEntry({required this.timestamp, required this.error, this.stackTrace});

  final DateTime timestamp;
  final String error;
  final String? stackTrace;
}
