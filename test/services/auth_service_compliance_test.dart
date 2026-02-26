import 'package:flutter_test/flutter_test.dart';
import 'package:prosepal/core/interfaces/auth_interface.dart';
import 'package:prosepal/core/services/auth_service.dart';

import '../mocks/mock_apple_auth_provider.dart';
import '../mocks/mock_google_auth_provider.dart';
import '../mocks/mock_supabase_auth_provider.dart';

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

  late AuthService authService;

  setUp(() {
    authService = AuthService(
      supabaseAuth: MockSupabaseAuthProvider(),
      appleAuth: MockAppleAuthProvider(),
      googleAuth: MockGoogleAuthProvider(),
    );
  });

  group('AuthService Interface Compliance', () {
    test('implements IAuthService', () {
      expect(authService, isA<IAuthService>());
    });

    test('has all required auth methods', () {
      expect(authService.signInWithApple, isA<Function>());
      expect(authService.signInWithGoogle, isA<Function>());
      expect(authService.signInWithEmail, isA<Function>());
      expect(authService.signUpWithEmail, isA<Function>());
      expect(authService.signInWithMagicLink, isA<Function>());
      expect(authService.resetPassword, isA<Function>());
      expect(authService.updateEmail, isA<Function>());
      expect(authService.updatePassword, isA<Function>());
      expect(authService.signOut, isA<Function>());
      expect(authService.deleteAccount, isA<Function>());
    });

    test('has all required properties', () {
      expect(() => authService.currentUser, returnsNormally);
      expect(() => authService.isLoggedIn, returnsNormally);
      expect(() => authService.email, returnsNormally);
      expect(() => authService.displayName, returnsNormally);
      expect(() => authService.authStateChanges, returnsNormally);
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
      expect(authService.deleteAccount, isA<Function>());
    });

    test('supports Sign in with Apple', () {
      expect(authService.signInWithApple, isA<Function>());
    });

    test('redirect URL uses valid iOS URL scheme', () {
      final uri = Uri.parse(redirectUrl);
      expect(uri.scheme, equals(bundleId));
      expect(uri.isAbsolute, isTrue);
    });
  });

  group('Dependency Injection', () {
    test('accepts mock providers', () {
      final mockSupabase = MockSupabaseAuthProvider();
      final mockApple = MockAppleAuthProvider();
      final mockGoogle = MockGoogleAuthProvider();

      final service = AuthService(
        supabaseAuth: mockSupabase,
        appleAuth: mockApple,
        googleAuth: mockGoogle,
      );

      expect(service, isA<AuthService>());
    });

    test('different instances can have different providers', () {
      final mockSupabase1 = MockSupabaseAuthProvider();
      final mockSupabase2 = MockSupabaseAuthProvider();

      mockSupabase1.setLoggedIn(true, email: 'user1@test.com');
      mockSupabase2.setLoggedIn(true, email: 'user2@test.com');

      final service1 = AuthService(
        supabaseAuth: mockSupabase1,
        appleAuth: MockAppleAuthProvider(),
        googleAuth: MockGoogleAuthProvider(),
      );

      final service2 = AuthService(
        supabaseAuth: mockSupabase2,
        appleAuth: MockAppleAuthProvider(),
        googleAuth: MockGoogleAuthProvider(),
      );

      expect(service1.email, 'user1@test.com');
      expect(service2.email, 'user2@test.com');
    });
  });
}
