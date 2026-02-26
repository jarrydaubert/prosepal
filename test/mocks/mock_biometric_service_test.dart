import 'package:flutter_test/flutter_test.dart';
import 'package:local_auth/local_auth.dart';
import 'package:prosepal/core/services/biometric_service.dart';

import 'mock_biometric_service.dart';

void main() {
  group('MockBiometricService', () {
    late MockBiometricService mockBiometric;

    setUp(() {
      mockBiometric = MockBiometricService();
    });

    group('initial state', () {
      test('should default to supported', () async {
        expect(await mockBiometric.isSupported, isTrue);
      });

      test('should default to disabled', () async {
        expect(await mockBiometric.isEnabled, isFalse);
      });

      test('should default to Face ID available', () async {
        expect(await mockBiometric.hasFaceId, isTrue);
        expect(await mockBiometric.hasTouchId, isFalse);
      });

      test('should have zero call counts', () {
        expect(mockBiometric.authenticateCallCount, equals(0));
        expect(mockBiometric.setEnabledCallCount, equals(0));
      });
    });

    group('setSupported', () {
      test('should update isSupported', () async {
        mockBiometric.setSupported(false);

        expect(await mockBiometric.isSupported, isFalse);
      });
    });

    group('setMockEnabled and setEnabled', () {
      test('setMockEnabled should update isEnabled directly', () async {
        mockBiometric.setMockEnabled(true);

        expect(await mockBiometric.isEnabled, isTrue);
      });

      test('setEnabled should update isEnabled and track calls', () async {
        await mockBiometric.setEnabled(true);

        expect(await mockBiometric.isEnabled, isTrue);
        expect(mockBiometric.setEnabledCallCount, equals(1));
      });

      test('should track multiple setEnabled calls', () async {
        await mockBiometric.setEnabled(true);
        await mockBiometric.setEnabled(false);
        await mockBiometric.setEnabled(true);

        expect(mockBiometric.setEnabledCallCount, equals(3));
      });
    });

    group('setHasFaceId and setHasTouchId', () {
      test('should update Face ID availability', () async {
        mockBiometric.setHasFaceId(false);

        expect(await mockBiometric.hasFaceId, isFalse);
      });

      test('should update Touch ID availability', () async {
        mockBiometric.setHasTouchId(true);

        expect(await mockBiometric.hasTouchId, isTrue);
      });

      test('should affect biometricTypeName', () async {
        mockBiometric.setHasFaceId(true);
        mockBiometric.setHasTouchId(false);
        expect(await mockBiometric.biometricTypeName, equals('Face ID'));

        mockBiometric.setHasFaceId(false);
        mockBiometric.setHasTouchId(true);
        expect(await mockBiometric.biometricTypeName, equals('Touch ID'));

        mockBiometric.setHasFaceId(false);
        mockBiometric.setHasTouchId(false);
        expect(await mockBiometric.biometricTypeName, equals('Biometrics'));
      });
    });

    group('setAvailableBiometrics', () {
      test('should update available biometrics list', () async {
        mockBiometric.setAvailableBiometrics([
          BiometricType.fingerprint,
          BiometricType.iris,
        ]);

        final biometrics = await mockBiometric.availableBiometrics;
        expect(biometrics, contains(BiometricType.fingerprint));
        expect(biometrics, contains(BiometricType.iris));
      });

      test('should handle empty list', () async {
        mockBiometric.setAvailableBiometrics([]);

        final biometrics = await mockBiometric.availableBiometrics;
        expect(biometrics, isEmpty);
      });
    });

    group('authenticate', () {
      test('should return success by default', () async {
        final result = await mockBiometric.authenticate();

        expect(result.success, isTrue);
        expect(result.error, isNull);
      });

      test('should increment call count', () async {
        await mockBiometric.authenticate();
        await mockBiometric.authenticate();

        expect(mockBiometric.authenticateCallCount, equals(2));
      });

      test('should store reason', () async {
        await mockBiometric.authenticate(reason: 'Test reason');

        expect(mockBiometric.lastAuthenticateReason, equals('Test reason'));
      });

      test('should return configured result', () async {
        mockBiometric.setAuthenticateResult(
          const BiometricResult(
            success: false,
            error: BiometricError.cancelled,
          ),
        );

        final result = await mockBiometric.authenticate();

        expect(result.success, isFalse);
        expect(result.error, equals(BiometricError.cancelled));
      });

      test('should return failure with message', () async {
        mockBiometric.setAuthenticateResult(
          const BiometricResult(
            success: false,
            error: BiometricError.lockedOut,
            message: 'Too many attempts',
          ),
        );

        final result = await mockBiometric.authenticate();

        expect(result.success, isFalse);
        expect(result.error, equals(BiometricError.lockedOut));
        expect(result.message, equals('Too many attempts'));
      });
    });

    group('authenticateIfEnabled', () {
      test('should return success if not enabled', () async {
        mockBiometric.setEnabled(false);

        final result = await mockBiometric.authenticateIfEnabled();

        expect(result.success, isTrue);
        expect(mockBiometric.authenticateCallCount, equals(0));
      });

      test('should return success if not supported', () async {
        await mockBiometric.setEnabled(true);
        mockBiometric.setSupported(false);

        final result = await mockBiometric.authenticateIfEnabled();

        expect(result.success, isTrue);
        expect(mockBiometric.authenticateCallCount, equals(0));
      });

      test('should call authenticate if enabled and supported', () async {
        await mockBiometric.setEnabled(true);
        mockBiometric.setSupported(true);

        final result = await mockBiometric.authenticateIfEnabled();

        expect(result.success, isTrue);
        expect(mockBiometric.authenticateCallCount, equals(1));
      });

      test('should return authenticate result if enabled', () async {
        await mockBiometric.setEnabled(true);
        mockBiometric.setAuthenticateResult(
          const BiometricResult(
            success: false,
            error: BiometricError.cancelled,
          ),
        );

        final result = await mockBiometric.authenticateIfEnabled();

        expect(result.success, isFalse);
        expect(result.error, equals(BiometricError.cancelled));
      });
    });

    group('reset', () {
      test('should reset all state to defaults', () async {
        // Modify state
        mockBiometric.setSupported(false);
        await mockBiometric.setEnabled(true);
        mockBiometric.setHasFaceId(false);
        mockBiometric.setHasTouchId(true);
        await mockBiometric.authenticate(reason: 'test');

        // Reset
        mockBiometric.reset();

        // Verify defaults
        expect(await mockBiometric.isSupported, isTrue);
        expect(await mockBiometric.isEnabled, isFalse);
        expect(await mockBiometric.hasFaceId, isTrue);
        expect(await mockBiometric.hasTouchId, isFalse);
        expect(mockBiometric.authenticateCallCount, equals(0));
        expect(mockBiometric.setEnabledCallCount, equals(0));
        expect(mockBiometric.lastAuthenticateReason, isNull);
      });
    });
  });

  group('BiometricResult', () {
    test('should create success result', () {
      const result = BiometricResult(success: true);

      expect(result.success, isTrue);
      expect(result.error, isNull);
      expect(result.message, isNull);
    });

    test('should create failure result with error', () {
      const result = BiometricResult(
        success: false,
        error: BiometricError.notAvailable,
      );

      expect(result.success, isFalse);
      expect(result.error, equals(BiometricError.notAvailable));
    });

    test('should create failure result with message', () {
      const result = BiometricResult(
        success: false,
        error: BiometricError.notEnrolled,
        message: 'No biometrics enrolled',
      );

      expect(result.success, isFalse);
      expect(result.error, equals(BiometricError.notEnrolled));
      expect(result.message, equals('No biometrics enrolled'));
    });
  });

  group('BiometricError', () {
    test('should have all expected error types', () {
      expect(BiometricError.values, contains(BiometricError.notAvailable));
      expect(BiometricError.values, contains(BiometricError.notEnrolled));
      expect(BiometricError.values, contains(BiometricError.lockedOut));
      expect(
        BiometricError.values,
        contains(BiometricError.permanentlyLockedOut),
      );
      expect(BiometricError.values, contains(BiometricError.passcodeNotSet));
      expect(BiometricError.values, contains(BiometricError.cancelled));
      expect(BiometricError.values, contains(BiometricError.unknown));
    });

    test('should have 7 error types', () {
      expect(BiometricError.values.length, equals(7));
    });
  });
}
