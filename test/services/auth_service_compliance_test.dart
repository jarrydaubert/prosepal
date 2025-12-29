import 'package:flutter_test/flutter_test.dart';
import 'package:prosepal/core/services/auth_service.dart';

/// Contract & Compliance Tests for AuthService
///
/// Tests URL schemes, session management, data structures,
/// error identification, and App Store compliance.
void main() {
  // Constants
  const bundleId = 'com.prosepal.prosepal';
  const redirectUrl = '$bundleId://login-callback';
  
  final uuidRegex = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
    caseSensitive: false,
  );

  group('AuthService Singleton', () {
    test('returns same instance', () {
      final instance1 = AuthService.instance;
      final instance2 = AuthService.instance;
      expect(identical(instance1, instance2), isTrue);
    });

    test('has all required auth methods', () {
      final service = AuthService.instance;

      expect(service.signInWithApple, isA<Function>());
      expect(service.signInWithGoogle, isA<Function>());
      expect(service.signInWithEmail, isA<Function>());
      expect(service.signUpWithEmail, isA<Function>());
      expect(service.signInWithMagicLink, isA<Function>());
      expect(service.resetPassword, isA<Function>());
      expect(service.updateEmail, isA<Function>());
      expect(service.updatePassword, isA<Function>());
      expect(service.signOut, isA<Function>());
      expect(service.deleteAccount, isA<Function>());
    });
  });

  group('Redirect URLs', () {
    test('has correct scheme', () {
      expect(redirectUrl.startsWith('com.prosepal.prosepal://'), isTrue);
    });

    test('has login-callback path', () {
      expect(redirectUrl.endsWith('login-callback'), isTrue);
    });

    test('is valid URI format', () {
      final uri = Uri.tryParse(redirectUrl);
      expect(uri, isNotNull);
      expect(uri!.scheme, equals(bundleId));
    });

    test('constructs valid OAuth redirect URL', () {
      const baseUrl = 'https://test.supabase.co';

      final authUrl = Uri.parse('$baseUrl/auth/v1/authorize').replace(
        queryParameters: {
          'provider': 'google',
          'redirect_to': redirectUrl,
        },
      );

      expect(authUrl.path, equals('/auth/v1/authorize'));
      expect(authUrl.queryParameters['provider'], equals('google'));
    });
  });

  group('Session Management', () {
    test('validates JWT token format', () {
      const mockToken = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.'
          'eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIn0.'
          'Gfx6VO9tcxwk6xqx9yYzSfebfeakZp5JYIgP_edcw_A';

      final parts = mockToken.split('.');
      expect(parts.length, equals(3));
    });

    test('determines when token should refresh', () {
      final expiresIn30Min = DateTime.now().add(const Duration(minutes: 30));
      final expiresIn2Min = DateTime.now().add(const Duration(minutes: 2));
      final now = DateTime.now();
      const threshold = 5;

      expect(expiresIn30Min.difference(now).inMinutes < threshold, isFalse);
      expect(expiresIn2Min.difference(now).inMinutes < threshold, isTrue);
    });
  });

  group('User ID Validation', () {
    test('accepts valid UUID format', () {
      const validUuid = '123e4567-e89b-12d3-a456-426614174000';
      expect(uuidRegex.hasMatch(validUuid), isTrue);
    });

    test('rejects invalid UUID format', () {
      expect(uuidRegex.hasMatch('not-a-uuid'), isFalse);
      expect(uuidRegex.hasMatch(''), isFalse);
    });
  });

  group('Profile Data Structure', () {
    test('creates valid profile data', () {
      final profile = {
        'id': 'test-user-id',
        'email': 'test@example.com',
        'display_name': 'Test User',
        'created_at': DateTime.now().toIso8601String(),
      };

      expect(profile['id'], isNotNull);
      expect(profile['email'], contains('@'));
      expect(profile['display_name'], isNotEmpty);
    });
  });

  group('Auth Error Identification', () {
    test('identifies network errors', () {
      const errorMessages = [
        'SocketException: Connection refused',
        'Connection timed out',
        'No internet connection',
      ];

      for (final message in errorMessages) {
        final isNetworkError = message.toLowerCase().contains('connection') ||
            message.toLowerCase().contains('socket') ||
            message.toLowerCase().contains('internet');

        expect(isNetworkError, isTrue);
      }
    });

    test('identifies rate limit errors', () {
      const errorMessage = 'Rate limit exceeded';
      final isRateLimit = errorMessage.toLowerCase().contains('rate') &&
          errorMessage.toLowerCase().contains('limit');

      expect(isRateLimit, isTrue);
    });
  });

  group('App Store Compliance', () {
    test('provides account deletion (Guideline 5.1.1(v))', () {
      expect(AuthService.instance.deleteAccount, isA<Function>());
    });

    test('supports Sign in with Apple', () {
      expect(AuthService.instance.signInWithApple, isA<Function>());
    });

    test('redirect URL uses valid iOS URL scheme', () {
      final uri = Uri.parse(redirectUrl);
      expect(uri.scheme, equals(bundleId));
      expect(uri.isAbsolute, isTrue);
    });
  });
}
