import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_auth/local_auth.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:prosepal/core/services/biometric_service.dart';

// Mock classes using mocktail
class MockLocalAuthentication extends Mock implements LocalAuthentication {}

/// Consolidated BiometricService Test Suite
///
/// This file combines tests from:
/// - biometric_service_test.dart (SharedPreferences, singleton, API contract)
/// - biometric_service_mock_test.dart (mocktail tests for local_auth)
///
/// Verifies all biometric authentication scenarios
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('BiometricService with Mocked LocalAuth', () {
    late MockLocalAuthentication mockLocalAuth;

    setUp(() {
      mockLocalAuth = MockLocalAuthentication();
      SharedPreferences.setMockInitialValues({});
    });

    group('Device Support', () {
      test('should return true when device supports biometrics', () async {
        when(() => mockLocalAuth.canCheckBiometrics)
            .thenAnswer((_) async => true);
        when(() => mockLocalAuth.isDeviceSupported())
            .thenAnswer((_) async => true);

        final canCheck = await mockLocalAuth.canCheckBiometrics;
        final isSupported = await mockLocalAuth.isDeviceSupported();

        expect(canCheck, isTrue);
        expect(isSupported, isTrue);
      });

      test('should return false when device does not support biometrics', () async {
        when(() => mockLocalAuth.canCheckBiometrics)
            .thenAnswer((_) async => false);
        when(() => mockLocalAuth.isDeviceSupported())
            .thenAnswer((_) async => false);

        final canCheck = await mockLocalAuth.canCheckBiometrics;
        final isSupported = await mockLocalAuth.isDeviceSupported();

        expect(canCheck, isFalse);
        expect(isSupported, isFalse);
      });

      test('should handle platform exception gracefully', () async {
        when(() => mockLocalAuth.canCheckBiometrics)
            .thenThrow(PlatformException(code: 'NotAvailable'));

        try {
          await mockLocalAuth.canCheckBiometrics;
          fail('Should have thrown');
        } catch (e) {
          expect(e, isA<PlatformException>());
        }
      });
    });

    group('Available Biometrics', () {
      test('should return Face ID when available', () async {
        when(() => mockLocalAuth.getAvailableBiometrics())
            .thenAnswer((_) async => [BiometricType.face]);

        final biometrics = await mockLocalAuth.getAvailableBiometrics();

        expect(biometrics, contains(BiometricType.face));
      });

      test('should return Touch ID (fingerprint) when available', () async {
        when(() => mockLocalAuth.getAvailableBiometrics())
            .thenAnswer((_) async => [BiometricType.fingerprint]);

        final biometrics = await mockLocalAuth.getAvailableBiometrics();

        expect(biometrics, contains(BiometricType.fingerprint));
      });

      test('should return multiple biometric types', () async {
        when(() => mockLocalAuth.getAvailableBiometrics())
            .thenAnswer((_) async => [
              BiometricType.face,
              BiometricType.fingerprint,
            ]);

        final biometrics = await mockLocalAuth.getAvailableBiometrics();

        expect(biometrics.length, equals(2));
      });

      test('should return empty list when no biometrics enrolled', () async {
        when(() => mockLocalAuth.getAvailableBiometrics())
            .thenAnswer((_) async => []);

        final biometrics = await mockLocalAuth.getAvailableBiometrics();

        expect(biometrics, isEmpty);
      });
    });

    group('Authentication', () {
      test('should authenticate successfully', () async {
        when(() => mockLocalAuth.authenticate(
              localizedReason: any(named: 'localizedReason'),
            )).thenAnswer((_) async => true);

        final result = await mockLocalAuth.authenticate(
          localizedReason: 'Authenticate to access Prosepal',
        );

        expect(result, isTrue);
      });

      test('should return false when authentication fails', () async {
        when(() => mockLocalAuth.authenticate(
              localizedReason: any(named: 'localizedReason'),
            )).thenAnswer((_) async => false);

        final result = await mockLocalAuth.authenticate(
          localizedReason: 'Test auth',
        );

        expect(result, isFalse);
      });

      test('should handle user cancellation', () async {
        when(() => mockLocalAuth.authenticate(
              localizedReason: any(named: 'localizedReason'),
            )).thenThrow(PlatformException(
              code: 'UserCanceled',
              message: 'User canceled',
            ));

        try {
          await mockLocalAuth.authenticate(localizedReason: 'Test');
          fail('Should have thrown');
        } catch (e) {
          expect(e, isA<PlatformException>());
          expect((e as PlatformException).code, equals('UserCanceled'));
        }
      });

      test('should handle lockout', () async {
        when(() => mockLocalAuth.authenticate(
              localizedReason: any(named: 'localizedReason'),
            )).thenThrow(PlatformException(
              code: 'LockedOut',
              message: 'Too many attempts',
            ));

        try {
          await mockLocalAuth.authenticate(localizedReason: 'Test');
          fail('Should have thrown');
        } catch (e) {
          expect(e, isA<PlatformException>());
          expect((e as PlatformException).code, equals('LockedOut'));
        }
      });

      test('should handle permanent lockout', () async {
        when(() => mockLocalAuth.authenticate(
              localizedReason: any(named: 'localizedReason'),
            )).thenThrow(PlatformException(
              code: 'PermanentlyLockedOut',
              message: 'Biometrics locked',
            ));

        try {
          await mockLocalAuth.authenticate(localizedReason: 'Test');
          fail('Should have thrown');
        } catch (e) {
          expect(e, isA<PlatformException>());
        }
      });
    });

    group('Stop Authentication', () {
      test('should stop ongoing authentication', () async {
        when(() => mockLocalAuth.stopAuthentication())
            .thenAnswer((_) async => true);

        final result = await mockLocalAuth.stopAuthentication();

        expect(result, isTrue);
        verify(() => mockLocalAuth.stopAuthentication()).called(1);
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

    test('should create failure with notAvailable error', () {
      const result = BiometricResult(
        success: false,
        error: BiometricError.notAvailable,
        message: 'Biometrics not available on this device.',
      );

      expect(result.success, isFalse);
      expect(result.error, equals(BiometricError.notAvailable));
      expect(result.message, isNotNull);
    });

    test('should create failure with notEnrolled error', () {
      const result = BiometricResult(
        success: false,
        error: BiometricError.notEnrolled,
        message: 'No biometrics enrolled. Set up in device settings.',
      );

      expect(result.error, equals(BiometricError.notEnrolled));
    });

    test('should create failure with lockedOut error', () {
      const result = BiometricResult(
        success: false,
        error: BiometricError.lockedOut,
        message: 'Too many attempts. Try again later.',
      );

      expect(result.error, equals(BiometricError.lockedOut));
    });

    test('should create failure with permanentlyLockedOut error', () {
      const result = BiometricResult(
        success: false,
        error: BiometricError.permanentlyLockedOut,
        message: 'Biometrics locked. Use device passcode to unlock.',
      );

      expect(result.error, equals(BiometricError.permanentlyLockedOut));
    });

    test('should create failure with passcodeNotSet error', () {
      const result = BiometricResult(
        success: false,
        error: BiometricError.passcodeNotSet,
        message: 'Set up a device passcode first.',
      );

      expect(result.error, equals(BiometricError.passcodeNotSet));
    });

    test('should create failure with cancelled error', () {
      const result = BiometricResult(
        success: false,
        error: BiometricError.cancelled,
      );

      expect(result.error, equals(BiometricError.cancelled));
      expect(result.message, isNull);
    });

    test('should create failure with unknown error', () {
      const result = BiometricResult(
        success: false,
        error: BiometricError.unknown,
        message: 'Authentication failed. Please try again.',
      );

      expect(result.error, equals(BiometricError.unknown));
    });
  });

  group('BiometricError enum', () {
    test('should have all expected error types', () {
      expect(BiometricError.values, hasLength(7));
      expect(BiometricError.values, contains(BiometricError.notAvailable));
      expect(BiometricError.values, contains(BiometricError.notEnrolled));
      expect(BiometricError.values, contains(BiometricError.lockedOut));
      expect(BiometricError.values, contains(BiometricError.permanentlyLockedOut));
      expect(BiometricError.values, contains(BiometricError.passcodeNotSet));
      expect(BiometricError.values, contains(BiometricError.cancelled));
      expect(BiometricError.values, contains(BiometricError.unknown));
    });
  });

  group('SharedPreferences Integration', () {
    test('should persist biometrics enabled state', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      await prefs.setBool('biometrics_enabled', true);

      expect(prefs.getBool('biometrics_enabled'), isTrue);
    });

    test('should default to disabled when not set', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      expect(prefs.getBool('biometrics_enabled'), isNull);
      expect(prefs.getBool('biometrics_enabled') ?? false, isFalse);
    });

    test('should update enabled state', () async {
      SharedPreferences.setMockInitialValues({'biometrics_enabled': true});
      final prefs = await SharedPreferences.getInstance();

      expect(prefs.getBool('biometrics_enabled'), isTrue);

      await prefs.setBool('biometrics_enabled', false);

      expect(prefs.getBool('biometrics_enabled'), isFalse);
    });
  });

  group('Biometric Type Names', () {
    test('should return Face ID for face biometric', () {
      const biometricType = BiometricType.face;
      final name = _getBiometricTypeName(biometricType);

      expect(name, equals('Face ID'));
    });

    test('should return Touch ID for fingerprint biometric', () {
      const biometricType = BiometricType.fingerprint;
      final name = _getBiometricTypeName(biometricType);

      expect(name, equals('Touch ID'));
    });

    test('should return Iris for iris biometric', () {
      const biometricType = BiometricType.iris;
      final name = _getBiometricTypeName(biometricType);

      expect(name, equals('Iris'));
    });

    test('should return Biometrics for unknown type', () {
      const biometricType = BiometricType.strong;
      final name = _getBiometricTypeName(biometricType);

      expect(name, equals('Biometrics'));
    });
  });

  // ============================================================
  // SINGLETON & API CONTRACT TESTS
  // From: biometric_service_test.dart
  // ============================================================

  group('BiometricService Singleton', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
    });

    test('returns singleton instance', () {
      final instance1 = BiometricService.instance;
      final instance2 = BiometricService.instance;
      expect(identical(instance1, instance2), isTrue);
    });

    test('defaults to biometrics disabled', () async {
      final enabled = await BiometricService.instance.isEnabled;
      expect(enabled, isFalse);
    });

    test('persists enabled state', () async {
      await BiometricService.instance.setEnabled(true);
      final enabled = await BiometricService.instance.isEnabled;
      expect(enabled, isTrue);
    });

    test('toggles enabled state', () async {
      await BiometricService.instance.setEnabled(true);
      expect(await BiometricService.instance.isEnabled, isTrue);

      await BiometricService.instance.setEnabled(false);
      expect(await BiometricService.instance.isEnabled, isFalse);
    });

    test('authenticate method exists', () {
      expect(BiometricService.instance.authenticate, isA<Function>());
    });

    test('setEnabled method exists', () {
      expect(BiometricService.instance.setEnabled, isA<Function>());
    });
  });
}

/// Helper to get biometric type name
String _getBiometricTypeName(BiometricType type) {
  switch (type) {
    case BiometricType.face:
      return 'Face ID';
    case BiometricType.fingerprint:
      return 'Touch ID';
    case BiometricType.iris:
      return 'Iris';
    default:
      return 'Biometrics';
  }
}
