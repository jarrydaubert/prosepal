/// Tests for AppConfig compile-time configuration.
///
/// ## Testing Limitations
/// AppConfig uses `const String.fromEnvironment()` which are compile-time
/// constants. Values are baked into the binary at build time, so:
/// - Tests run without `--dart-define` flags have empty strings
/// - We cannot "mock" these values at runtime
/// - Tests focus on behavior with empty values (test environment default)
///
/// ## What We CAN Test
/// - Getters don't throw exceptions
/// - Boolean checks work correctly with empty strings
/// - validate() behavior in debug mode (warns, doesn't throw)
/// - Format validators (extracted as testable functions)
/// - assertNoTestStoreInRelease() assertion logic
///
/// ## CI/CD Testing
/// For full config validation, run:
/// ```bash
/// flutter test --dart-define=SUPABASE_URL=https://test.supabase.co ...
/// ```
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:prosepal/core/config/app_config.dart';

// =============================================================================
// Format Validators (extracted for testability)
// =============================================================================

/// Validates Supabase URL format.
/// Returns null if valid, error message if invalid.
String? validateSupabaseUrl(String url) {
  if (url.isEmpty) return 'URL is required';
  if (!url.startsWith('https://')) return 'URL must use HTTPS';
  if (!url.contains('supabase')) return 'URL should contain supabase domain';
  return null;
}

/// Validates RevenueCat iOS API key format.
String? validateRevenueCatIosKey(String key) {
  if (key.isEmpty) return 'Key is required';
  if (!key.startsWith('appl_')) return 'iOS key must start with appl_';
  return null;
}

/// Validates RevenueCat Android API key format.
String? validateRevenueCatAndroidKey(String key) {
  if (key.isEmpty) return 'Key is required';
  if (!key.startsWith('goog_')) return 'Android key must start with goog_';
  return null;
}

/// Validates Google OAuth client ID format.
String? validateGoogleClientId(String clientId) {
  if (clientId.isEmpty) return 'Client ID is required';
  if (!clientId.endsWith('.apps.googleusercontent.com')) {
    return 'Client ID must end with .apps.googleusercontent.com';
  }
  return null;
}

// =============================================================================
// Test Data
// =============================================================================

/// Valid format test cases: (value, validatorFn, description)
final _validFormatCases = <(String, String? Function(String), String)>[
  ('https://abc123.supabase.co', validateSupabaseUrl, 'valid Supabase URL'),
  (
    'appl_abcdefghijklmnop',
    validateRevenueCatIosKey,
    'valid RevenueCat iOS key',
  ),
  (
    'goog_abcdefghijklmnop',
    validateRevenueCatAndroidKey,
    'valid RevenueCat Android key',
  ),
  (
    '123456789.apps.googleusercontent.com',
    validateGoogleClientId,
    'valid Google client ID',
  ),
];

/// Invalid format test cases: (value, validatorFn, expectedError, description)
final _invalidFormatCases =
    <(String, String? Function(String), String, String)>[
      // Supabase URL
      ('', validateSupabaseUrl, 'URL is required', 'empty Supabase URL'),
      (
        'http://abc.supabase.co',
        validateSupabaseUrl,
        'URL must use HTTPS',
        'HTTP Supabase URL',
      ),
      (
        'https://example.com',
        validateSupabaseUrl,
        'URL should contain supabase domain',
        'non-Supabase URL',
      ),
      // RevenueCat iOS
      ('', validateRevenueCatIosKey, 'Key is required', 'empty iOS key'),
      (
        'goog_wrong',
        validateRevenueCatIosKey,
        'iOS key must start with appl_',
        'wrong prefix iOS key',
      ),
      // RevenueCat Android
      (
        '',
        validateRevenueCatAndroidKey,
        'Key is required',
        'empty Android key',
      ),
      (
        'appl_wrong',
        validateRevenueCatAndroidKey,
        'Android key must start with goog_',
        'wrong prefix Android key',
      ),
      // Google Client ID
      ('', validateGoogleClientId, 'Client ID is required', 'empty client ID'),
      (
        'invalid-client-id',
        validateGoogleClientId,
        'Client ID must end with .apps.googleusercontent.com',
        'malformed client ID',
      ),
    ];

// =============================================================================
// Tests
// =============================================================================

void main() {
  group('AppConfig', () {
    group('configuration accessors', () {
      test('all string configs are accessible without throwing', () {
        // Compile-time constants should never throw, even when empty
        expect(() => AppConfig.supabaseUrl, returnsNormally);
        expect(() => AppConfig.supabaseAnonKey, returnsNormally);
        expect(() => AppConfig.revenueCatIosKey, returnsNormally);
        expect(() => AppConfig.revenueCatAndroidKey, returnsNormally);
        expect(() => AppConfig.revenueCatTestStoreKey, returnsNormally);
        expect(() => AppConfig.googleWebClientId, returnsNormally);
        expect(() => AppConfig.googleIosClientId, returnsNormally);
      });

      test('useRevenueCatTestStore defaults to false when not set', () {
        // bool.fromEnvironment defaults to false
        // In test environment without dart-define, this should be false
        expect(AppConfig.useRevenueCatTestStore, isFalse);
      });
    });

    group('configuration checks in test environment', () {
      test(
        'hasSupabaseConfig returns false when URL and key are empty (test env)',
        () {
          // In test environment without dart-define, both are empty strings
          // Empty string + empty string = no config
          expect(AppConfig.hasSupabaseConfig, isFalse);
        },
      );

      test(
        'hasRevenueCatConfig returns false when platform keys are empty (test env)',
        () {
          // Without dart-define, platform keys are empty
          expect(AppConfig.hasRevenueCatConfig, isFalse);
        },
      );

      test(
        'hasGoogleSignInConfig returns false when client ID is empty (test env)',
        () {
          expect(AppConfig.hasGoogleSignInConfig, isFalse);
        },
      );
    });

    group('validation behavior', () {
      test(
        'validate() warns but does not throw in debug mode with missing config',
        () {
          // Debug mode (test environment) should log warning but not throw
          // This allows development with partial configuration
          expect(() => AppConfig.validate(), returnsNormally);
        },
      );

      test('assertNoTestStoreInRelease() passes when test store is false', () {
        // In test environment, useRevenueCatTestStore is false
        // Assertion should pass regardless of build mode
        expect(() => AppConfig.assertNoTestStoreInRelease(), returnsNormally);
      });
    });

    group('format validators', () {
      group('should accept valid formats', () {
        for (final (value, validator, description) in _validFormatCases) {
          test(description, () {
            expect(
              validator(value),
              isNull,
              reason: '$description should be valid',
            );
          });
        }
      });

      group('should reject invalid formats', () {
        for (final (value, validator, expectedError, description)
            in _invalidFormatCases) {
          test(description, () {
            expect(
              validator(value),
              expectedError,
              reason: '$description should fail with: $expectedError',
            );
          });
        }
      });
    });

    group('live config format validation (when set)', () {
      test('supabaseUrl follows expected format when configured', () {
        final url = AppConfig.supabaseUrl;
        if (url.isNotEmpty) {
          expect(
            validateSupabaseUrl(url),
            isNull,
            reason: 'Configured Supabase URL should be valid',
          );
        }
      });

      test('revenueCatIosKey follows expected format when configured', () {
        final key = AppConfig.revenueCatIosKey;
        if (key.isNotEmpty) {
          expect(
            validateRevenueCatIosKey(key),
            isNull,
            reason: 'Configured iOS key should be valid',
          );
        }
      });

      test('revenueCatAndroidKey follows expected format when configured', () {
        final key = AppConfig.revenueCatAndroidKey;
        if (key.isNotEmpty) {
          expect(
            validateRevenueCatAndroidKey(key),
            isNull,
            reason: 'Configured Android key should be valid',
          );
        }
      });

      test('googleWebClientId follows expected format when configured', () {
        final clientId = AppConfig.googleWebClientId;
        if (clientId.isNotEmpty) {
          expect(
            validateGoogleClientId(clientId),
            isNull,
            reason: 'Configured Google client ID should be valid',
          );
        }
      });
    });
  });
}
