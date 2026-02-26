import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

/// Production-grade logging service using Firebase Crashlytics
///
/// Logs are:
/// - Visible in Firebase Console under Crashlytics > Logs
/// - Attached to crash reports for context
/// - Available in both debug and release builds
///
/// Usage:
/// ```dart
/// Log.info('User signed in', {'provider': 'google'});
/// Log.warning('Paywall dismissed');
/// Log.error('Purchase failed', error, stackTrace);
/// ```
abstract final class Log {
  static FirebaseCrashlytics? _crashlytics;

  /// Get Crashlytics instance, or null if Firebase not initialized
  static FirebaseCrashlytics? get _instance {
    if (_crashlytics != null) return _crashlytics;
    try {
      // Check if Firebase is initialized
      Firebase.app();
      _crashlytics = FirebaseCrashlytics.instance;
      return _crashlytics;
    } catch (_) {
      // Firebase not initialized (e.g., in tests)
      return null;
    }
  }

  /// Log informational message (appears in Crashlytics logs)
  static void info(String message, [Map<String, dynamic>? params]) {
    final formatted = _format('INFO', message, params);
    _instance?.log(formatted);
    if (kDebugMode) debugPrint(formatted);
  }

  /// Log warning (appears in Crashlytics logs)
  static void warning(String message, [Map<String, dynamic>? params]) {
    final formatted = _format('WARN', message, params);
    _instance?.log(formatted);
    if (kDebugMode) debugPrint(formatted);
  }

  /// Log error with optional exception (recorded as non-fatal in Crashlytics)
  static void error(
    String message, [
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? params,
  ]) {
    final formatted = _format('ERROR', message, params);
    _instance?.log(formatted);
    if (kDebugMode) debugPrint(formatted);

    if (error != null) {
      _instance?.recordError(
        error,
        stackTrace ?? StackTrace.current,
        reason: message,
        fatal: false,
      );
    }
  }

  /// Set user identifier for crash reports
  static Future<void> setUserId(String userId) async {
    await _instance?.setUserIdentifier(userId);
    info('User identified', {'userId': _truncate(userId, 8)});
  }

  /// Clear user identifier on logout
  static Future<void> clearUserId() async {
    await _instance?.setUserIdentifier('');
  }

  /// Set custom key-value for crash context
  static Future<void> setCustomKey(String key, Object value) async {
    await _instance?.setCustomKey(key, value);
  }

  static String _format(
    String level,
    String message,
    Map<String, dynamic>? params,
  ) {
    final buffer = StringBuffer('[$level] $message');
    if (params != null && params.isNotEmpty) {
      buffer.write(' | ');
      buffer.write(params.entries.map((e) => '${e.key}=${e.value}').join(', '));
    }
    return buffer.toString();
  }

  static String _truncate(String s, int length) {
    return s.length > length ? '${s.substring(0, length)}...' : s;
  }
}
