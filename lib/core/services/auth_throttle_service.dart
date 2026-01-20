import 'dart:math';

import 'log_service.dart';

/// Result of a throttle check
class ThrottleResult {
  const ThrottleResult({required this.allowed, this.waitSeconds = 0});

  final bool allowed;
  final int waitSeconds;

  static const allowed_ = ThrottleResult(allowed: true);
}

/// Client-side exponential backoff for auth attempts
///
/// Prevents brute force attacks by throttling repeated failures.
/// Uses exponential backoff: 1s, 2s, 4s, 8s, 16s, 32s, 60s max.
///
/// ## Usage
/// ```dart
/// final throttle = AuthThrottleService();
///
/// // Before attempting login
/// final check = throttle.checkThrottle('user@example.com');
/// if (!check.allowed) {
///   showError('Too many attempts. Wait ${check.waitSeconds}s');
///   return;
/// }
///
/// // After failed login
/// throttle.recordFailure('user@example.com');
///
/// // After successful login
/// throttle.recordSuccess('user@example.com');
/// ```
class AuthThrottleService {
  final Map<String, _AttemptRecord> _attempts = {};

  /// Base delay in seconds (doubles with each failure)
  static const int _baseDelaySeconds = 1;

  /// Maximum delay in seconds (1 minute cap)
  static const int _maxDelaySeconds = 60;

  /// Number of failures before throttling kicks in
  static const int _failureThreshold = 3;

  /// Check if an auth attempt is allowed
  ///
  /// Returns [ThrottleResult] with allowed=false and waitSeconds if throttled.
  ThrottleResult checkThrottle(String identifier) {
    final record = _attempts[identifier.toLowerCase()];
    if (record == null) return ThrottleResult.allowed_;

    // Allow if under threshold
    if (record.failureCount < _failureThreshold) {
      return ThrottleResult.allowed_;
    }

    // Calculate required wait time
    final now = DateTime.now();
    final elapsed = now.difference(record.lastAttempt);
    final requiredWait = _calculateDelay(record.failureCount);

    if (elapsed.inSeconds >= requiredWait) {
      return ThrottleResult.allowed_;
    }

    final remaining = requiredWait - elapsed.inSeconds;
    Log.info('Auth throttled', {
      'identifier': _maskIdentifier(identifier),
      'failures': record.failureCount,
      'waitSeconds': remaining,
    });

    return ThrottleResult(allowed: false, waitSeconds: remaining);
  }

  /// Record a failed auth attempt
  void recordFailure(String identifier) {
    final key = identifier.toLowerCase();
    final existing = _attempts[key];

    if (existing == null) {
      _attempts[key] = _AttemptRecord(
        failureCount: 1,
        lastAttempt: DateTime.now(),
      );
    } else {
      _attempts[key] = _AttemptRecord(
        failureCount: existing.failureCount + 1,
        lastAttempt: DateTime.now(),
      );
    }

    final count = _attempts[key]!.failureCount;
    if (count >= _failureThreshold) {
      Log.warning('Auth failures reached threshold', {
        'identifier': _maskIdentifier(identifier),
        'failures': count,
        'nextDelay': _calculateDelay(count),
      });
    }
  }

  /// Record a successful auth attempt (resets throttle)
  void recordSuccess(String identifier) {
    _attempts.remove(identifier.toLowerCase());
    Log.info('Auth throttle reset', {
      'identifier': _maskIdentifier(identifier),
    });
  }

  /// Calculate delay based on failure count (exponential backoff)
  int _calculateDelay(int failureCount) {
    if (failureCount < _failureThreshold) return 0;

    // Exponential: 2^(failures - threshold) * base
    final exponent = failureCount - _failureThreshold;
    final delay = _baseDelaySeconds * pow(2, exponent).toInt();

    return min(delay, _maxDelaySeconds);
  }

  /// Mask identifier for logging (privacy)
  String _maskIdentifier(String identifier) {
    if (identifier.contains('@')) {
      final parts = identifier.split('@');
      final name = parts[0];
      final masked = name.length > 2 ? '${name.substring(0, 2)}***' : '***';
      return '$masked@${parts[1]}';
    }
    return '***';
  }

  /// Get current failure count for an identifier (for testing/UI)
  int getFailureCount(String identifier) =>
      _attempts[identifier.toLowerCase()]?.failureCount ?? 0;

  /// Clear all throttle state (for testing)
  void clear() {
    _attempts.clear();
  }
}

class _AttemptRecord {
  const _AttemptRecord({required this.failureCount, required this.lastAttempt});

  final int failureCount;
  final DateTime lastAttempt;
}
