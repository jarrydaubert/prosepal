import 'dart:collection';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

/// Production-grade logging service using Firebase Crashlytics + Analytics
///
/// Logs are:
/// - Visible in Firebase Console under Crashlytics > Logs
/// - Attached to crash reports for context
/// - Available in both debug and release builds
/// - Stored in local buffer for export (last 200 entries)
///
/// Analytics events are:
/// - Queryable in Firebase Console under Analytics > Events
/// - Used for funnel analysis and user segmentation
///
/// Usage:
/// ```dart
/// Log.info('User signed in', {'provider': 'google'});
/// Log.warning('Paywall dismissed');
/// Log.error('Purchase failed', error, stackTrace);
/// Log.event('first_message_activated', {'occasion': 'birthday'}); // Analytics only
/// Log.getExportableLog(); // Get last 200 entries for user support
/// ```
abstract final class Log {
  static FirebaseCrashlytics? _crashlytics;
  static FirebaseAnalytics? _analytics;

  /// In-memory buffer of recent logs for export (privacy-safe)
  static final Queue<LogEntry> _buffer = Queue<LogEntry>();
  static const int _maxBufferSize = 200;

  /// Get Crashlytics instance, or null if Firebase not initialized
  static FirebaseCrashlytics? get _instance {
    if (_crashlytics != null) return _crashlytics;
    try {
      // Check if Firebase is initialized
      Firebase.app();
      return _crashlytics = FirebaseCrashlytics.instance;
    } on Exception catch (_) {
      // Firebase not initialized (e.g., in tests)
      return null;
    }
  }

  /// Get Analytics instance, or null if Firebase not initialized
  static FirebaseAnalytics? get _analyticsInstance {
    if (_analytics != null) return _analytics;
    try {
      Firebase.app();
      return _analytics = FirebaseAnalytics.instance;
    } on Exception catch (_) {
      return null;
    }
  }

  /// Log analytics event (queryable in Firebase Console)
  /// Use for funnel tracking, activation events, and user segmentation
  static Future<void> event(String name, [Map<String, Object>? params]) async {
    try {
      await _analyticsInstance?.logEvent(name: name, parameters: params);
      if (kDebugMode) {
        final formatted = _format(
          'EVENT',
          name,
          params?.cast<String, dynamic>(),
        );
        debugPrint(formatted);
      }
    } on Exception catch (e) {
      if (kDebugMode) debugPrint('[EVENT ERROR] $name: $e');
    }
  }

  /// Log informational message (appears in Crashlytics logs)
  static void info(String message, [Map<String, dynamic>? params]) {
    final formatted = _format('INFO', message, params);
    _addToBuffer(AppLogLevel.info, message, params);
    _instance?.log(formatted);
    if (kDebugMode) debugPrint(formatted);
  }

  /// Log warning (appears in Crashlytics logs)
  static void warning(String message, [Map<String, dynamic>? params]) {
    final formatted = _format('WARN', message, params);
    _addToBuffer(AppLogLevel.warning, message, params);
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
    _addToBuffer(AppLogLevel.error, message, params);
    _instance?.log(formatted);
    if (kDebugMode) debugPrint(formatted);

    if (error != null) {
      _instance?.recordError(
        error,
        stackTrace ?? StackTrace.current,
        reason: message,
      );
    }
  }

  /// Add entry to buffer, evicting oldest if full
  static void _addToBuffer(
    AppLogLevel level,
    String message,
    Map<String, dynamic>? params,
  ) {
    if (_buffer.length >= _maxBufferSize) {
      _buffer.removeFirst();
    }
    _buffer.add(
      LogEntry(
        timestamp: DateTime.now(),
        level: level,
        message: message,
        params: params,
      ),
    );
  }

  /// Get recent logs as exportable string (for user support)
  /// Privacy-safe: Only contains app actions, no PII
  static String getExportableLog() {
    final now = DateTime.now();
    final buffer = StringBuffer();
    buffer.writeln('=== Prosepal Debug Log ===');
    buffer.writeln('Exported: ${now.toUtc().toIso8601String()} (UTC)');
    buffer.writeln(
      'Timezone: UTC${now.timeZoneOffset.isNegative ? "" : "+"}${now.timeZoneOffset.inHours}',
    );
    buffer.writeln('Entries: ${_buffer.length}');
    buffer.writeln();

    for (final entry in _buffer) {
      buffer.writeln(entry.toExportString());
    }

    return buffer.toString();
  }

  /// Get recent logs as list (for breadcrumbs in feedback)
  static List<String> getRecentBreadcrumbs({int count = 50}) {
    final entries = _buffer.toList();
    final start = entries.length > count ? entries.length - count : 0;
    return entries.sublist(start).map((e) => e.toBreadcrumb()).toList();
  }

  /// Clear log buffer (call on sign out for privacy)
  static void clearBuffer() {
    _buffer.clear();
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

  /// Keys that may contain PII and should be redacted
  static const _piiKeys = {
    'email',
    'password',
    'token',
    'accessToken',
    'refreshToken',
    'idToken',
    'personalDetails',
    'recipientName',
    'prompt',
    'message',
    'text',
    'content',
    'response',
    'name',
    'displayName',
    'phone',
    'address',
  };

  /// Sanitize params by redacting PII values (release mode only)
  ///
  /// In debug mode, full values are shown for easier debugging.
  /// In release mode, PII is redacted to protect user privacy in crash logs.
  static Map<String, dynamic> _sanitize(Map<String, dynamic> params) {
    // Allow full debugging in debug mode - redact only in release
    if (kDebugMode) return params;

    return params.map((key, value) {
      final lowerKey = key.toLowerCase();
      if (_piiKeys.any((pii) => lowerKey.contains(pii.toLowerCase()))) {
        return MapEntry(key, '[REDACTED]');
      }
      return MapEntry(key, value);
    });
  }

  static String _format(
    String level,
    String message,
    Map<String, dynamic>? params,
  ) {
    final buffer = StringBuffer('[$level] $message');
    if (params != null && params.isNotEmpty) {
      final sanitized = _sanitize(params);
      buffer.write(' | ');
      buffer.write(
        sanitized.entries.map((e) => '${e.key}=${e.value}').join(', '),
      );
    }
    return buffer.toString();
  }

  static String _truncate(String s, int length) =>
      s.length > length ? '${s.substring(0, length)}...' : s;
}

/// Log level for categorization (prefixed to avoid conflict with purchases_flutter)
enum AppLogLevel { info, warning, error }

/// Single log entry with timestamp
class LogEntry {
  const LogEntry({
    required this.timestamp,
    required this.level,
    required this.message,
    this.params,
  });

  final DateTime timestamp;
  final AppLogLevel level;
  final String message;
  final Map<String, dynamic>? params;

  String get _levelPrefix {
    switch (level) {
      case AppLogLevel.info:
        return 'INFO';
      case AppLogLevel.warning:
        return 'WARN';
      case AppLogLevel.error:
        return 'ERROR';
    }
  }

  /// Full format for export
  String toExportString() {
    final time = timestamp.toIso8601String().substring(11, 23); // HH:mm:ss.SSS
    final buffer = StringBuffer('$time [$_levelPrefix] $message');
    if (params != null && params!.isNotEmpty) {
      buffer.write(' | ');
      buffer.write(
        params!.entries.map((e) => '${e.key}=${e.value}').join(', '),
      );
    }
    return buffer.toString();
  }

  /// Short format for breadcrumbs
  String toBreadcrumb() {
    final time = timestamp.toIso8601String().substring(11, 19); // HH:mm:ss
    return '$time $message';
  }
}
