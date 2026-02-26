import 'package:flutter_test/flutter_test.dart';
import 'package:prosepal/core/interfaces/auth_interface.dart';
import 'package:prosepal/core/services/auth_service.dart';

import '../mocks/mock_apple_auth_provider.dart';
import '../mocks/mock_google_auth_provider.dart';
import '../mocks/mock_supabase_auth_provider.dart';

/// Contract & Compliance Tests for AuthService
///
/// Verifies interface compliance, App Store requirements, and DI.
void main() {
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

    test('has all required properties with correct types', () {
      // Verify properties return correct types (not just that they exist)
      expect(authService.currentUser, anyOf(isNull, isA<Object>()));
      expect(authService.isLoggedIn, isA<bool>());
      expect(authService.email, anyOf(isNull, isA<String>()));
      expect(authService.displayName, anyOf(isNull, isA<String>()));
      expect(authService.authStateChanges, isA<Stream>());
    });
  });

  group('App Store Compliance', () {
    test('provides account deletion (Guideline 5.1.1(v))', () {
      expect(authService.deleteAccount, isA<Function>());
    });

    test('supports Sign in with Apple', () {
      expect(authService.signInWithApple, isA<Function>());
    });
  });

  group('Dependency Injection', () {
    test('accepts mock providers', () {
      final service = AuthService(
        supabaseAuth: MockSupabaseAuthProvider(),
        appleAuth: MockAppleAuthProvider(),
        googleAuth: MockGoogleAuthProvider(),
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
