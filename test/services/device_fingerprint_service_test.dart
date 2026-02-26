import 'package:flutter_test/flutter_test.dart';
import 'package:prosepal/core/services/device_fingerprint_service.dart';

import '../mocks/mock_device_fingerprint_service.dart';

/// DeviceFingerprintService Unit Tests
///
/// Tests mock implementation behavior. Real device tests require integration tests.
/// Each test answers: "What bug does this catch?"
void main() {
  group('DeviceFingerprintService', () {
    late MockDeviceFingerprintService service;

    setUp(() {
      service = MockDeviceFingerprintService();
    });

    group('getDeviceFingerprint', () {
      test('returns mock fingerprint', () async {
        final fingerprint = await service.getDeviceFingerprint();
        expect(fingerprint, equals('mock-device-fingerprint-12345'));
      });

      test('returns null when simulating no fingerprint', () async {
        service.simulateNoFingerprint();
        final fingerprint = await service.getDeviceFingerprint();
        expect(fingerprint, isNull);
      });
    });

    group('getPlatform', () {
      test('returns default platform', () {
        expect(service.getPlatform(), equals('ios'));
      });

      test('returns configured platform', () {
        service.mockPlatform = 'android';
        expect(service.getPlatform(), equals('android'));
      });
    });

    group('canUseFreeTier', () {
      test('returns allowed=true for new device', () async {
        final result = await service.canUseFreeTier();
        expect(result.allowed, isTrue);
        expect(result.reason, equals(DeviceCheckReason.newDevice));
      });

      test('returns allowed=false after device used free tier', () async {
        service.simulateFreeTierUsed();
        final result = await service.canUseFreeTier();
        expect(result.allowed, isFalse);
        expect(result.reason, equals(DeviceCheckReason.alreadyUsed));
      });

      test('tracks call count', () async {
        expect(service.canUseFreeTierCallCount, equals(0));
        await service.canUseFreeTier();
        expect(service.canUseFreeTierCallCount, equals(1));
        await service.canUseFreeTier();
        expect(service.canUseFreeTierCallCount, equals(2));
      });

      test('returns allowed=true on server error (graceful degradation)', () async {
        service.simulateServerError();
        final result = await service.canUseFreeTier();
        expect(result.allowed, isTrue);
        expect(result.reason, equals(DeviceCheckReason.serverError));
      });

      test('returns allowed=true when fingerprint unavailable', () async {
        service.simulateNoFingerprint();
        final result = await service.canUseFreeTier();
        expect(result.allowed, isTrue);
        expect(result.reason, equals(DeviceCheckReason.fingerprintUnavailable));
      });
    });

    group('markFreeTierUsed', () {
      test('marks device as used', () async {
        expect(service.markFreeTierUsedCalled, isFalse);
        await service.markFreeTierUsed();
        expect(service.markFreeTierUsedCalled, isTrue);
      });

      test('subsequent canUseFreeTier returns false', () async {
        // Initial state - can use
        var result = await service.canUseFreeTier();
        expect(result.allowed, isTrue);

        // Mark as used
        await service.markFreeTierUsed();

        // Now blocked
        result = await service.canUseFreeTier();
        expect(result.allowed, isFalse);
        expect(result.reason, equals(DeviceCheckReason.alreadyUsed));
      });
    });

    group('reset', () {
      test('resets all state', () async {
        // Modify state
        service.simulateFreeTierUsed();
        await service.canUseFreeTier();
        await service.markFreeTierUsed();

        // Verify state is modified
        expect(service.allowFreeTier, isFalse);
        expect(service.canUseFreeTierCallCount, greaterThan(0));
        expect(service.markFreeTierUsedCalled, isTrue);

        // Reset
        service.reset();

        // Verify state is reset
        expect(service.allowFreeTier, isTrue);
        expect(service.canUseFreeTierCallCount, equals(0));
        expect(service.markFreeTierUsedCalled, isFalse);
        expect(service.mockFingerprint, equals('mock-device-fingerprint-12345'));
      });
    });
  });

  group('DeviceCheckResult', () {
    test('toString includes all fields', () {
      const result = DeviceCheckResult(
        allowed: true,
        reason: DeviceCheckReason.newDevice,
      );
      expect(
        result.toString(),
        equals('DeviceCheckResult(allowed: true, reason: DeviceCheckReason.newDevice)'),
      );
    });
  });

  group('DeviceCheckReason', () {
    test('has all expected values', () {
      expect(DeviceCheckReason.values, containsAll([
        DeviceCheckReason.newDevice,
        DeviceCheckReason.notUsedYet,
        DeviceCheckReason.alreadyUsed,
        DeviceCheckReason.fingerprintUnavailable,
        DeviceCheckReason.serverUnavailable,
        DeviceCheckReason.serverError,
      ]));
    });
  });
}
