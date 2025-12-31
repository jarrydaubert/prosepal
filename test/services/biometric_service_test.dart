import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:prosepal/core/services/biometric_service.dart';

/// BiometricService Test Suite
///
/// Tests singleton behavior, persistence, and result types.
/// Note: LocalAuthentication cannot be injected (singleton design),
/// so platform-specific behavior is tested via MockBiometricService in widgets.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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
  });

  group('BiometricResult', () {
    test('creates success result', () {
      const result = BiometricResult(success: true);

      expect(result.success, isTrue);
      expect(result.error, isNull);
      expect(result.message, isNull);
    });

    test('creates failure with error and message', () {
      const result = BiometricResult(
        success: false,
        error: BiometricError.notAvailable,
        message: 'Biometrics not available on this device.',
      );

      expect(result.success, isFalse);
      expect(result.error, equals(BiometricError.notAvailable));
      expect(result.message, isNotNull);
    });

    test('creates cancelled result without message', () {
      const result = BiometricResult(
        success: false,
        error: BiometricError.cancelled,
      );

      expect(result.error, equals(BiometricError.cancelled));
      expect(result.message, isNull);
    });
  });

  group('BiometricError', () {
    test('has all expected error types', () {
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
  });
}
