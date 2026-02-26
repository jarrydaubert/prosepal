import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:prosepal/core/services/biometric_service.dart';

void main() {
  group('BiometricService', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
    });

    test('should return singleton instance', () {
      final instance1 = BiometricService.instance;
      final instance2 = BiometricService.instance;
      expect(identical(instance1, instance2), isTrue);
    });

    test('should default to biometrics disabled', () async {
      final enabled = await BiometricService.instance.isEnabled;
      expect(enabled, isFalse);
    });

    test('should persist enabled state', () async {
      await BiometricService.instance.setEnabled(true);
      final enabled = await BiometricService.instance.isEnabled;
      expect(enabled, isTrue);
    });

    test('should toggle enabled state', () async {
      await BiometricService.instance.setEnabled(true);
      expect(await BiometricService.instance.isEnabled, isTrue);

      await BiometricService.instance.setEnabled(false);
      expect(await BiometricService.instance.isEnabled, isFalse);
    });
  });
}
