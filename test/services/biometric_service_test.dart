import 'dart:async';

import 'package:flutter/services.dart';
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
  const localAuthChannel = MethodChannel('plugins.flutter.io/local_auth');

  group('BiometricService Singleton', () {
    setUp(() async {
      FlutterSecureStorage.setMockInitialValues({});
      BiometricService.instance.resetAuthStateForTests();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(localAuthChannel, (call) async {
            switch (call.method) {
              case 'isDeviceSupported':
                return true;
              case 'getAvailableBiometrics':
                return <String>['fingerprint'];
              case 'authenticate':
                return true;
              default:
                return null;
            }
          });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(localAuthChannel, null);
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

    test('authenticate is single-flight while request is in progress', () async {
      // Bug: Rapid lifecycle/toggle events trigger overlapping biometric prompts
      var authenticateCalls = 0;
      final authResult = Completer<bool>();

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(localAuthChannel, (call) async {
            switch (call.method) {
              case 'authenticate':
                authenticateCalls++;
                return authResult.future;
              case 'isDeviceSupported':
                return true;
              case 'getAvailableBiometrics':
                return <String>['face'];
              default:
                return null;
            }
          });

      final first = BiometricService.instance.authenticate();
      final second = BiometricService.instance.authenticate();
      try {
        await Future<void>.delayed(const Duration(milliseconds: 10));
        expect(authenticateCalls, 1);

        authResult.complete(true);
        final results = await Future.wait([first, second]);

        expect(authenticateCalls, 1);
        expect(results.every((r) => r.success), isTrue);
      } finally {
        if (!authResult.isCompleted) {
          authResult.complete(true);
        }
        await first;
        await second;
      }
    });

    test(
      'authenticate debounces rapid re-requests right after completion',
      () async {
        // Bug: lifecycle jitter triggers repeated prompts within milliseconds.
        var authenticateCalls = 0;

        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(localAuthChannel, (call) async {
              switch (call.method) {
                case 'authenticate':
                  authenticateCalls++;
                  return true;
                case 'isDeviceSupported':
                  return true;
                case 'getAvailableBiometrics':
                  return <String>['face'];
                default:
                  return null;
              }
            });

        final first = await BiometricService.instance.authenticate();
        final immediateRetry = await BiometricService.instance.authenticate();

        expect(first.success, isTrue);
        expect(
          immediateRetry.success,
          isFalse,
          reason: 'debounced calls must not inherit prior auth success',
        );
        expect(immediateRetry.error, BiometricError.cancelled);
        expect(
          authenticateCalls,
          1,
          reason: 'second call should be absorbed by debounce window',
        );

        await Future<void>.delayed(const Duration(milliseconds: 2100));
        final afterDebounce = await BiometricService.instance.authenticate();
        expect(afterDebounce.success, isTrue);
        expect(authenticateCalls, 2);
      },
    );
  });
}
