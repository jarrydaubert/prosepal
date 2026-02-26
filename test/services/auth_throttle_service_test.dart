import 'package:flutter_test/flutter_test.dart';
import 'package:prosepal/core/services/auth_throttle_service.dart';

void main() {
  group('AuthThrottleService', () {
    late AuthThrottleService service;

    setUp(() {
      service = AuthThrottleService();
    });

    tearDown(() {
      service.clear();
    });

    group('checkThrottle', () {
      test('allows first attempt', () {
        final result = service.checkThrottle('test@example.com');
        expect(result.allowed, isTrue);
        expect(result.waitSeconds, equals(0));
      });

      test('allows attempts under threshold', () {
        service.recordFailure('test@example.com');
        service.recordFailure('test@example.com');

        final result = service.checkThrottle('test@example.com');
        expect(result.allowed, isTrue);
      });

      test('throttles after 3 failures', () {
        for (var i = 0; i < 3; i++) {
          service.recordFailure('test@example.com');
        }

        final result = service.checkThrottle('test@example.com');
        expect(result.allowed, isFalse);
        expect(result.waitSeconds, greaterThan(0));
      });

      test('is case insensitive', () {
        for (var i = 0; i < 3; i++) {
          service.recordFailure('Test@Example.com');
        }

        final result = service.checkThrottle('test@example.com');
        expect(result.allowed, isFalse);
      });

      test('tracks different identifiers separately', () {
        for (var i = 0; i < 3; i++) {
          service.recordFailure('user1@example.com');
        }

        final result = service.checkThrottle('user2@example.com');
        expect(result.allowed, isTrue);
      });
    });

    group('recordSuccess', () {
      test('resets throttle state', () {
        for (var i = 0; i < 5; i++) {
          service.recordFailure('test@example.com');
        }

        service.recordSuccess('test@example.com');

        final result = service.checkThrottle('test@example.com');
        expect(result.allowed, isTrue);
        expect(service.getFailureCount('test@example.com'), equals(0));
      });
    });

    group('getFailureCount', () {
      test('returns 0 for unknown identifier', () {
        expect(service.getFailureCount('unknown@example.com'), equals(0));
      });

      test('tracks failure count correctly', () {
        service.recordFailure('test@example.com');
        expect(service.getFailureCount('test@example.com'), equals(1));

        service.recordFailure('test@example.com');
        expect(service.getFailureCount('test@example.com'), equals(2));
      });
    });

    group('exponential backoff', () {
      test('delay increases with each failure', () {
        // Record failures beyond threshold
        for (var i = 0; i < 4; i++) {
          service.recordFailure('test@example.com');
        }
        final result1 = service.checkThrottle('test@example.com');

        service.clear();
        for (var i = 0; i < 5; i++) {
          service.recordFailure('test@example.com');
        }
        final result2 = service.checkThrottle('test@example.com');

        // More failures = longer wait
        expect(result2.waitSeconds, greaterThan(result1.waitSeconds));
      });
    });
  });
}
