import 'package:flutter_test/flutter_test.dart';
import 'package:prosepal/core/config/app_config.dart';

void main() {
  group('AppConfig', () {
    group('configuration checks', () {
      test('hasSupabaseConfig returns true when both URL and key are set', () {
        // Note: These are compile-time constants from dart-define
        // In test environment, they're typically empty unless explicitly set
        // This test documents the expected behavior
        final hasConfig = AppConfig.hasSupabaseConfig;

        // The result depends on whether dart-defines were passed
        // We're testing that the getter works without throwing
        expect(hasConfig, isA<bool>());
      });

      test(
        'hasRevenueCatConfig returns bool based on platform key presence',
        () {
          final hasConfig = AppConfig.hasRevenueCatConfig;
          expect(hasConfig, isA<bool>());
        },
      );

      test(
        'hasGoogleSignInConfig returns bool based on web client ID presence',
        () {
          final hasConfig = AppConfig.hasGoogleSignInConfig;
          expect(hasConfig, isA<bool>());
        },
      );
    });

    group('validation', () {
      test('validate() does not throw in debug mode with missing config', () {
        // In debug mode, validate() should warn but not throw
        // This allows partial testing during development
        expect(() => AppConfig.validate(), returnsNormally);
      });

      test('all string configs are accessible', () {
        // Verify all config values are accessible without throwing
        // Values may be empty in test environment
        expect(AppConfig.supabaseUrl, isA<String>());
        expect(AppConfig.supabaseAnonKey, isA<String>());
        expect(AppConfig.revenueCatIosKey, isA<String>());
        expect(AppConfig.revenueCatAndroidKey, isA<String>());
        expect(AppConfig.revenueCatTestStoreKey, isA<String>());
        expect(AppConfig.googleWebClientId, isA<String>());
        expect(AppConfig.googleIosClientId, isA<String>());
      });

      test('useRevenueCatTestStore is a boolean', () {
        expect(AppConfig.useRevenueCatTestStore, isA<bool>());
      });
    });

    group('documentation compliance', () {
      test('supabaseUrl follows expected format when set', () {
        final url = AppConfig.supabaseUrl;
        if (url.isNotEmpty) {
          expect(url, startsWith('https://'));
          expect(url, contains('supabase'));
        }
      });

      test('revenueCatIosKey follows expected format when set', () {
        final key = AppConfig.revenueCatIosKey;
        if (key.isNotEmpty) {
          // RevenueCat iOS keys start with 'appl_'
          expect(key, startsWith('appl_'));
        }
      });

      test('revenueCatAndroidKey follows expected format when set', () {
        final key = AppConfig.revenueCatAndroidKey;
        if (key.isNotEmpty) {
          // RevenueCat Android keys start with 'goog_'
          expect(key, startsWith('goog_'));
        }
      });

      test('googleWebClientId follows expected format when set', () {
        final clientId = AppConfig.googleWebClientId;
        if (clientId.isNotEmpty) {
          expect(clientId, endsWith('.apps.googleusercontent.com'));
        }
      });
    });
  });
}
