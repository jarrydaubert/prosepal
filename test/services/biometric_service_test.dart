import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prosepal/core/services/biometric_service.dart';

/// BiometricService Unit Tests
///
/// Tests REAL BiometricService singleton and persistence.
/// Each test answers: "What bug does this catch?"
///
/// Note: LocalAuthentication cannot be injected (singleton design),
/// so platform-specific behavior is tested via MockBiometricService in widgets.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('BiometricService Singleton', () {
    setUp(() async {
      FlutterSecureStorage.setMockInitialValues({});
    });

    test('returns singleton instance', () {
      // Bug: Multiple instances cause inconsistent state
      final instance1 = BiometricService.instance;
      final instance2 = BiometricService.instance;
      expect(identical(instance1, instance2), isTrue);
    });

    test('defaults to biometrics disabled', () async {
      // Bug: Biometrics enabled by default blocks user on first launch
      final enabled = await BiometricService.instance.isEnabled;
      expect(enabled, isFalse);
    });

    test('persists enabled state', () async {
      // Bug: User enables biometrics, reopens app, setting is lost
      await BiometricService.instance.setEnabled(true);
      final enabled = await BiometricService.instance.isEnabled;
      expect(enabled, isTrue);
    });

    test('toggles enabled state', () async {
      // Bug: Toggle doesn't work, user can't disable biometrics
      await BiometricService.instance.setEnabled(true);
      expect(await BiometricService.instance.isEnabled, isTrue);

      await BiometricService.instance.setEnabled(false);
      expect(await BiometricService.instance.isEnabled, isFalse);
    });
  });
}
