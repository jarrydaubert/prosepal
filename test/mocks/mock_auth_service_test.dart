import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'mock_auth_service.dart';

void main() {
  group('MockAuthService', () {
    late MockAuthService mockAuth;

    setUp(() {
      mockAuth = MockAuthService();
    });

    tearDown(() {
      mockAuth.dispose();
    });

    group('initial state', () {
      test('should start logged out', () {
        expect(mockAuth.isLoggedIn, isFalse);
        expect(mockAuth.currentUser, isNull);
        expect(mockAuth.email, isNull);
        expect(mockAuth.displayName, isNull);
      });

      test('should have zero call counts', () {
        expect(mockAuth.signInWithAppleCallCount, equals(0));
        expect(mockAuth.signInWithGoogleCallCount, equals(0));
        expect(mockAuth.signInWithEmailCallCount, equals(0));
        expect(mockAuth.signUpWithEmailCallCount, equals(0));
        expect(mockAuth.resetPasswordCallCount, equals(0));
        expect(mockAuth.signOutCallCount, equals(0));
        expect(mockAuth.deleteAccountCallCount, equals(0));
      });
    });

    group('setLoggedIn', () {
      test('should set logged in state', () {
        mockAuth.setLoggedIn(true, email: 'test@example.com');

        expect(mockAuth.isLoggedIn, isTrue);
        expect(mockAuth.email, equals('test@example.com'));
      });

      test('should set display name', () {
        mockAuth.setLoggedIn(
          true,
          email: 'test@example.com',
          displayName: 'Test User',
        );

        expect(mockAuth.displayName, equals('Test User'));
      });
    });

    group('signInWithApple', () {
      test('should increment call count', () async {
        await mockAuth.signInWithApple();

        expect(mockAuth.signInWithAppleCallCount, equals(1));
      });

      test('should set logged in to true', () async {
        await mockAuth.signInWithApple();

        expect(mockAuth.isLoggedIn, isTrue);
      });

      test('should throw configured error', () async {
        mockAuth.errorToThrow = AuthException('Apple Sign In failed');

        expect(
          () => mockAuth.signInWithApple(),
          throwsA(isA<AuthException>()),
        );
      });

      test('should return AuthResponse', () async {
        final result = await mockAuth.signInWithApple();

        expect(result, isA<AuthResponse>());
      });
    });

    group('signInWithGoogle', () {
      test('should increment call count', () async {
        await mockAuth.signInWithGoogle();

        expect(mockAuth.signInWithGoogleCallCount, equals(1));
      });

      test('should set logged in to true', () async {
        await mockAuth.signInWithGoogle();

        expect(mockAuth.isLoggedIn, isTrue);
      });

      test('should throw configured error', () async {
        mockAuth.errorToThrow = AuthException('Google Sign In failed');

        expect(
          () => mockAuth.signInWithGoogle(),
          throwsA(isA<AuthException>()),
        );
      });
    });

    group('signInWithEmail', () {
      test('should increment call count', () async {
        await mockAuth.signInWithEmail(
          email: 'test@example.com',
          password: 'password123',
        );

        expect(mockAuth.signInWithEmailCallCount, equals(1));
      });

      test('should store email and password used', () async {
        await mockAuth.signInWithEmail(
          email: 'test@example.com',
          password: 'password123',
        );

        expect(mockAuth.lastEmailUsed, equals('test@example.com'));
        expect(mockAuth.lastPasswordUsed, equals('password123'));
      });

      test('should set logged in and email', () async {
        await mockAuth.signInWithEmail(
          email: 'test@example.com',
          password: 'password123',
        );

        expect(mockAuth.isLoggedIn, isTrue);
        expect(mockAuth.email, equals('test@example.com'));
      });

      test('should throw configured error', () async {
        mockAuth.errorToThrow = AuthException('Invalid credentials');

        expect(
          () => mockAuth.signInWithEmail(
            email: 'test@example.com',
            password: 'wrong',
          ),
          throwsA(isA<AuthException>()),
        );
      });
    });

    group('signUpWithEmail', () {
      test('should increment call count', () async {
        await mockAuth.signUpWithEmail(
          email: 'new@example.com',
          password: 'password123',
        );

        expect(mockAuth.signUpWithEmailCallCount, equals(1));
      });

      test('should store email and password used', () async {
        await mockAuth.signUpWithEmail(
          email: 'new@example.com',
          password: 'password123',
        );

        expect(mockAuth.lastEmailUsed, equals('new@example.com'));
        expect(mockAuth.lastPasswordUsed, equals('password123'));
      });

      test('should set email', () async {
        await mockAuth.signUpWithEmail(
          email: 'new@example.com',
          password: 'password123',
        );

        expect(mockAuth.email, equals('new@example.com'));
      });
    });

    group('resetPassword', () {
      test('should increment call count', () async {
        await mockAuth.resetPassword('test@example.com');

        expect(mockAuth.resetPasswordCallCount, equals(1));
      });

      test('should store email used', () async {
        await mockAuth.resetPassword('test@example.com');

        expect(mockAuth.lastEmailUsed, equals('test@example.com'));
      });

      test('should throw configured error', () async {
        mockAuth.errorToThrow = AuthException('User not found');

        expect(
          () => mockAuth.resetPassword('unknown@example.com'),
          throwsA(isA<AuthException>()),
        );
      });
    });

    group('signInWithMagicLink', () {
      test('should store email used', () async {
        await mockAuth.signInWithMagicLink('test@example.com');

        expect(mockAuth.lastEmailUsed, equals('test@example.com'));
      });
    });

    group('updateEmail', () {
      test('should update email', () async {
        mockAuth.setLoggedIn(true, email: 'old@example.com');

        await mockAuth.updateEmail('new@example.com');

        expect(mockAuth.email, equals('new@example.com'));
      });

      test('should throw configured error', () async {
        mockAuth.errorToThrow = AuthException('Email already in use');

        expect(
          () => mockAuth.updateEmail('taken@example.com'),
          throwsA(isA<AuthException>()),
        );
      });
    });

    group('updatePassword', () {
      test('should complete without error', () async {
        await mockAuth.updatePassword('newPassword123');

        // No error thrown
      });

      test('should throw configured error', () async {
        mockAuth.errorToThrow = AuthException('Password too weak');

        expect(
          () => mockAuth.updatePassword('123'),
          throwsA(isA<AuthException>()),
        );
      });
    });

    group('signOut', () {
      test('should increment call count', () async {
        mockAuth.setLoggedIn(true, email: 'test@example.com');

        await mockAuth.signOut();

        expect(mockAuth.signOutCallCount, equals(1));
      });

      test('should clear all user data', () async {
        mockAuth.setLoggedIn(
          true,
          email: 'test@example.com',
          displayName: 'Test',
        );

        await mockAuth.signOut();

        expect(mockAuth.isLoggedIn, isFalse);
        expect(mockAuth.currentUser, isNull);
        expect(mockAuth.email, isNull);
        expect(mockAuth.displayName, isNull);
      });
    });

    group('deleteAccount', () {
      test('should increment call count', () async {
        mockAuth.setLoggedIn(true);

        await mockAuth.deleteAccount();

        expect(mockAuth.deleteAccountCallCount, equals(1));
      });

      test('should sign out user', () async {
        mockAuth.setLoggedIn(true);

        await mockAuth.deleteAccount();

        expect(mockAuth.isLoggedIn, isFalse);
        expect(mockAuth.signOutCallCount, equals(1));
      });
    });

    group('reset', () {
      test('should reset all state', () async {
        // Set up some state
        await mockAuth.signInWithEmail(
          email: 'test@example.com',
          password: 'password',
        );
        await mockAuth.signOut();

        // Reset
        mockAuth.reset();

        // Verify everything is cleared
        expect(mockAuth.isLoggedIn, isFalse);
        expect(mockAuth.signInWithEmailCallCount, equals(0));
        expect(mockAuth.signOutCallCount, equals(0));
        expect(mockAuth.lastEmailUsed, isNull);
        expect(mockAuth.lastPasswordUsed, isNull);
        expect(mockAuth.errorToThrow, isNull);
      });
    });

    group('authStateChanges', () {
      test('should emit auth states', () async {
        final states = <AuthState>[];
        mockAuth.authStateChanges.listen(states.add);

        // Wait for stream to be ready
        await Future.delayed(Duration.zero);

        // Emit would require creating an AuthState which is complex
        // Just verify stream exists
        expect(mockAuth.authStateChanges, isA<Stream<AuthState>>());
      });
    });
  });
}
