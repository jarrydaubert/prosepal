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
  static String? _currentUserId;

  /// In-memory buffer of recent logs for export (raw values retained for
  /// optional user-controlled verbose diagnostics).
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
    final analyticsParams = normalizeAnalyticsParams(params);
    try {
      await _analyticsInstance?.logEvent(
        name: name,
        parameters: analyticsParams,
      );
      if (kDebugMode) {
        final formatted = _format(
          'EVENT',
          name,
          analyticsParams?.cast<String, dynamic>(),
        );
        debugPrint(formatted);
      }
    } on Exception catch (e) {
      if (kDebugMode) debugPrint('[EVENT ERROR] $name: $e');
    }
  }

  /// Firebase Analytics only accepts String/num event parameter values.
  ///
  /// We normalize booleans to `0/1` and stringify other non-supported values
  /// to prevent runtime assertion crashes in debug and release runs.
  @visibleForTesting
  static Map<String, Object>? normalizeAnalyticsParams(
    Map<String, Object>? params,
  ) {
    if (params == null || params.isEmpty) return params;
    final normalized = <String, Object>{};
    for (final entry in params.entries) {
      final value = _normalizeAnalyticsValue(entry.value);
      if (value != null) {
        normalized[entry.key] = value;
      }
    }
    return normalized.isEmpty ? null : normalized;
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
  static String getExportableLog({bool includeSensitive = false}) {
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
      buffer.writeln(
        entry.toExportString(
          paramsOverride: _sanitizeForExport(
            entry.params,
            includeSensitive: includeSensitive,
          ),
        ),
      );
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
    _currentUserId = userId;
    await _instance?.setUserIdentifier(userId);
    await _analyticsInstance?.setUserId(id: userId);
    info('User identified', {'userId': _truncate(userId, 8)});
  }

  /// Clear user identifier on logout
  static Future<void> clearUserId() async {
    _currentUserId = null;
    await _instance?.setUserIdentifier('');
    await _analyticsInstance?.setUserId();
    info('User identity cleared');
  }

  /// Current app-level telemetry identity snapshot.
  ///
  /// This mirrors the last ID passed to [setUserId] and is cleared on
  /// [clearUserId]. It is used for support diagnostics and identity mapping
  /// validation.
  static String? get currentUserId => _currentUserId;

  /// Set custom key-value for crash context
  static Future<void> setCustomKey(String key, Object value) async {
    await _instance?.setCustomKey(key, value);
  }

  /// Keys that are always redacted, even in verbose exports.
  static const _alwaysRedactKeys = {
    'password',
    'token',
    'accessToken',
    'refreshToken',
    'idToken',
  };

  /// Keys redacted in standard (non-verbose) exports.
  static const _privacyRedactKeys = {
    'email',
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

  static final RegExp _emailPattern = RegExp(
    r'\b[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}\b',
    caseSensitive: false,
  );
  static final RegExp _jwtPattern = RegExp(
    r'\b[A-Za-z0-9\-_]{8,}\.[A-Za-z0-9\-_]{8,}\.[A-Za-z0-9\-_]{8,}\b',
  );
  static final RegExp _secretLikePattern = RegExp(
    r'\b(sk_(live|test)_[A-Za-z0-9]+|AIza[0-9A-Za-z\-_]+)\b',
  );

  /// Sanitize params for user-exportable logs.
  ///
  /// `includeSensitive=true` keeps non-secret values for deeper troubleshooting.
  static Map<String, dynamic>? _sanitizeForExport(
    Map<String, dynamic>? params, {
    required bool includeSensitive,
  }) {
    if (params == null) return null;
    return params.map((key, value) {
      final lowerKey = key.toLowerCase();
      if (_alwaysRedactKeys.any((k) => lowerKey.contains(k.toLowerCase()))) {
        return MapEntry(key, '[REDACTED]');
      }
      if (!includeSensitive &&
          _privacyRedactKeys.any((k) => lowerKey.contains(k.toLowerCase()))) {
        return MapEntry(key, '[REDACTED]');
      }
      return MapEntry(
        key,
        _sanitizeValue(value, includeSensitive: includeSensitive),
      );
    });
  }

  /// Sanitize params for Crashlytics logs.
  ///
  /// Keep debug-mode values visible for local debugging. Release builds are
  /// redacted for privacy.
  static Map<String, dynamic> _sanitizeForCrashLog(
    Map<String, dynamic> params,
  ) {
    if (kDebugMode) return params;
    return _sanitizeForExport(params, includeSensitive: false) ?? const {};
  }

  static dynamic _sanitizeValue(
    dynamic value, {
    required bool includeSensitive,
  }) {
    if (value is String) {
      return _sanitizeString(value, includeSensitive: includeSensitive);
    }
    if (value is Map) {
      return value.map(
        (k, v) =>
            MapEntry(k, _sanitizeValue(v, includeSensitive: includeSensitive)),
      );
    }
    if (value is Iterable) {
      return value
          .map(
            (item) => _sanitizeValue(item, includeSensitive: includeSensitive),
          )
          .toList(growable: false);
    }
    return value;
  }

  static String _sanitizeString(
    String value, {
    required bool includeSensitive,
  }) {
    var sanitized = value;
    if (!includeSensitive) {
      sanitized = sanitized.replaceAll(_emailPattern, '[REDACTED_EMAIL]');
    }
    sanitized = sanitized.replaceAll(_jwtPattern, '[REDACTED_TOKEN]');
    sanitized = sanitized.replaceAll(_secretLikePattern, '[REDACTED_SECRET]');
    return sanitized;
  }

  static Object? _normalizeAnalyticsValue(Object? value) {
    if (value == null) return null;
    if (value is String || value is num) return value;
    if (value is bool) return value ? 1 : 0;
    if (value is DateTime) return value.toUtc().toIso8601String();
    if (value is Duration) return value.inMilliseconds;
    final textValue = value.toString();
    if (textValue.isEmpty) return null;
    return _truncate(textValue, 100);
  }

  static String _format(
    String level,
    String message,
    Map<String, dynamic>? params,
  ) {
    final buffer = StringBuffer('[$level] $message');
    if (params != null && params.isNotEmpty) {
      final sanitized = _sanitizeForCrashLog(params);
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
  String toExportString({Map<String, dynamic>? paramsOverride}) {
    final time = timestamp.toIso8601String().substring(11, 23); // HH:mm:ss.SSS
    final buffer = StringBuffer('$time [$_levelPrefix] $message');
    final effectiveParams = paramsOverride ?? params;
    if (effectiveParams != null && effectiveParams.isNotEmpty) {
      buffer.write(' | ');
      buffer.write(
        effectiveParams.entries.map((e) => '${e.key}=${e.value}').join(', '),
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
