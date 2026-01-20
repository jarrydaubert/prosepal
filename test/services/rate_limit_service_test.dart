import 'package:flutter_test/flutter_test.dart';
import 'package:prosepal/core/services/rate_limit_service.dart';

import '../mocks/mock_device_fingerprint_service.dart';

/// RateLimitService Unit Tests
///
/// Bugs these tests prevent:
/// - BUG-001: Users unfairly blocked from generating messages
/// - BUG-002: API abuse when rate limiting fails silently
/// - BUG-003: Confusing error messages when rate limited
/// - BUG-004: App crash when Supabase not initialized
void main() {
  group('RateLimitService', () {
    group('RateLimitResult', () {
      test('allowed result has empty error message', () {
        // BUG-003: Showing error message when not rate limited
        const result = RateLimitResult(allowed: true);

        expect(result.allowed, isTrue);
        expect(result.errorMessage, isEmpty);
        expect(result.retryAfter, 0);
        expect(result.reason, isNull);
      });

      test('blocked result has user-friendly error with retry time', () {
        // BUG-003: Confusing "try again later" without specific time
        const result = RateLimitResult(
          allowed: false,
          retryAfter: 30,
          reason: RateLimitReason.userLimit,
        );

        expect(result.allowed, isFalse);
        expect(result.errorMessage, contains('30 seconds'));
        expect(result.retryAfter, 30);
      });

      test('blocked result without retry time shows generic message', () {
        // BUG-003: Crash when retryAfter is 0
        const result = RateLimitResult(
          allowed: false,
          reason: RateLimitReason.userLimit,
        );

        expect(
          result.errorMessage,
          'Too many requests. Please try again later.',
        );
      });

      test('toString provides debug info', () {
        const result = RateLimitResult(
          allowed: false,
          retryAfter: 60,
          reason: RateLimitReason.deviceLimit,
        );

        expect(result.toString(), contains('allowed: false'));
        expect(result.toString(), contains('retryAfter: 60'));
        expect(result.toString(), contains('deviceLimit'));
      });
    });

    group('RateLimitReason', () {
      test('all reasons are defined', () {
        // BUG: Missing enum case causes crash
        expect(RateLimitReason.values, hasLength(6));
        expect(RateLimitReason.values, contains(RateLimitReason.userLimit));
        expect(RateLimitReason.values, contains(RateLimitReason.deviceLimit));
        expect(RateLimitReason.values, contains(RateLimitReason.ipLimit));
        expect(RateLimitReason.values, contains(RateLimitReason.globalLimit));
        expect(RateLimitReason.values, contains(RateLimitReason.localFallback));
        expect(RateLimitReason.values, contains(RateLimitReason.unknown));
      });
    });

    group('Service Initialization', () {
      test('can be instantiated with device fingerprint service', () {
        // BUG-004: Constructor throws when dependencies missing
        final fingerprint = MockDeviceFingerprintService();
        final service = RateLimitService(fingerprint);

        expect(service, isNotNull);
      });
    });

    group('Graceful Degradation with Local Fallback', () {
      late RateLimitService service;
      late MockDeviceFingerprintService mockFingerprint;

      setUp(() async {
        mockFingerprint = MockDeviceFingerprintService();
        service = RateLimitService(mockFingerprint);
        await service.clearLocalHistory(); // Reset for each test
      });

      test(
        'allows requests when Supabase not initialized (uses local fallback)',
        () async {
          // BUG-004: App crashes or blocks users when Supabase unavailable
          // Now uses local fallback instead of allowing unlimited
          final result = await service.checkRateLimit();

          expect(result.allowed, isTrue);
          expect(result.reason, RateLimitReason.localFallback);
        },
      );

      test('allows requests with custom endpoint', () async {
        // BUG-002: Different endpoints not tracked separately
        final result = await service.checkRateLimit(endpoint: 'custom_action');

        expect(result.allowed, isTrue);
      });
    });

    group('Local Rate Limiting (Fail Closed)', () {
      late RateLimitService service;
      late MockDeviceFingerprintService mockFingerprint;

      setUp(() async {
        mockFingerprint = MockDeviceFingerprintService();
        service = RateLimitService(mockFingerprint);
        await service.clearLocalHistory();
      });

      test('allows first 10 requests in local fallback mode', () async {
        // Local limit is 10 requests per minute (conservative)
        for (var i = 0; i < 10; i++) {
          final result = await service.checkRateLimit();
          expect(
            result.allowed,
            isTrue,
            reason: 'Request ${i + 1} should be allowed',
          );
        }
      });

      test('blocks 11th request in local fallback mode', () async {
        // Exhaust the local limit
        for (var i = 0; i < 10; i++) {
          await service.checkRateLimit();
        }

        // 11th request should be blocked
        final result = await service.checkRateLimit();
        expect(result.allowed, isFalse);
        expect(result.reason, RateLimitReason.localFallback);
        expect(result.retryAfter, greaterThan(0));
      });

      test('provides retry time when locally rate limited', () async {
        // Exhaust the local limit
        for (var i = 0; i < 10; i++) {
          await service.checkRateLimit();
        }

        final result = await service.checkRateLimit();
        expect(result.allowed, isFalse);
        expect(result.retryAfter, greaterThanOrEqualTo(1));
        expect(
          result.retryAfter,
          lessThanOrEqualTo(60),
        ); // Within 1 minute window
      });

      test('clearLocalHistory resets the rate limit', () async {
        // Use up the limit
        for (var i = 0; i < 10; i++) {
          await service.checkRateLimit();
        }

        // Should be blocked
        var result = await service.checkRateLimit();
        expect(result.allowed, isFalse);

        // Clear history
        await service.clearLocalHistory();

        // Should be allowed again
        result = await service.checkRateLimit();
        expect(result.allowed, isTrue);
      });

      test('local fallback has user-friendly error message', () async {
        // Exhaust the local limit
        for (var i = 0; i < 10; i++) {
          await service.checkRateLimit();
        }

        final result = await service.checkRateLimit();
        expect(result.errorMessage, contains('Too many requests'));
        expect(result.errorMessage, contains('seconds'));
      });
    });
  });
}
