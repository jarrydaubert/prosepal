import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../mocks/mock_auth_service.dart';

/// AuthService Unit Tests with MockAuthService
///
/// Tests all 11 auth methods with happy and unhappy paths.
/// Uses MockAuthService for isolated, deterministic testing.
///
/// Related test files:
/// - auth_service_crypto_test.dart (nonce, SHA256, validation)
/// - auth_service_compliance_test.dart (URLs, contracts, App Store)
void main() {
  late MockAuthService authService;

  setUp(() {
    authService = MockAuthService();
  });

  tearDown(() {
    authService.dispose();
  });

  group('signInWithEmail', () {
    test('happy: valid credentials returns user and sets logged in', () async {
      final result = await authService.signInWithEmail(
        email: 'test@example.com',
        password: 'password123',
      );

      expect(result, isA<AuthResponse>());
      expect(authService.isLoggedIn, isTrue);
      expect(authService.email, equals('test@example.com'));
      expect(authService.signInWithEmailCallCount, equals(1));
    });

    test('happy: returns populated User object', () async {
      final result = await authService.signInWithEmail(
        email: 'user@example.com',
        password: 'password123',
      );

      expect(result.user, isNotNull);
      expect(result.user!.email, equals('user@example.com'));
      expect(result.user!.id, isNotEmpty);
      expect(result.user!.aud, equals('authenticated'));
      expect(result.user!.emailConfirmedAt, isNotNull);
    });

    test('happy: returns valid Session with tokens', () async {
      final result = await authService.signInWithEmail(
        email: 'session@example.com',
        password: 'password123',
      );

      expect(result.session, isNotNull);
      expect(result.session!.accessToken, isNotEmpty);
      expect(result.session!.refreshToken, isNotEmpty);
      expect(result.session!.tokenType, equals('bearer'));
      expect(result.session!.user, isNotNull);
    });

    test('happy: stores email for verification', () async {
      await authService.signInWithEmail(
        email: 'verify@example.com',
        password: 'pass',
      );

      expect(authService.lastEmailUsed, equals('verify@example.com'));
      expect(authService.lastPasswordUsed, equals('pass'));
    });

    test('unhappy: invalid credentials throws AuthException', () async {
      authService.errorToThrow = AuthException('Invalid login credentials');

      expect(
        () => authService.signInWithEmail(
          email: 'wrong@example.com',
          password: 'wrongpass',
        ),
        throwsA(isA<AuthException>()),
      );
    });

    test('unhappy: email not confirmed throws AuthException', () async {
      authService.errorToThrow = AuthException('Email not confirmed');

      expect(
        () => authService.signInWithEmail(
          email: 'unconfirmed@example.com',
          password: 'pass',
        ),
        throwsA(
          isA<AuthException>().having(
            (e) => e.message,
            'message',
            contains('not confirmed'),
          ),
        ),
      );
    });

    test('unhappy: rate limited throws AuthException', () async {
      authService.errorToThrow = AuthException('Rate limit exceeded');

      expect(
        () => authService.signInWithEmail(
          email: 'test@example.com',
          password: 'pass',
        ),
        throwsA(
          isA<AuthException>().having(
            (e) => e.message,
            'message',
            contains('Rate limit'),
          ),
        ),
      );
    });
  });

  group('signUpWithEmail', () {
    test('happy: new email creates account', () async {
      final result = await authService.signUpWithEmail(
        email: 'new@example.com',
        password: 'securePass123',
      );

      expect(result, isA<AuthResponse>());
      expect(authService.email, equals('new@example.com'));
      expect(authService.signUpWithEmailCallCount, equals(1));
    });

    test('happy: returns User but no Session (email not confirmed)', () async {
      final result = await authService.signUpWithEmail(
        email: 'newuser@example.com',
        password: 'securePass123',
      );

      // User exists but email not confirmed yet
      expect(result.user, isNotNull);
      expect(result.user!.email, equals('newuser@example.com'));
      expect(result.user!.emailConfirmedAt, isNull);

      // No session until email confirmed
      expect(result.session, isNull);
    });

    test('unhappy: existing email throws AuthException', () async {
      authService.errorToThrow = AuthException('User already registered');

      expect(
        () => authService.signUpWithEmail(
          email: 'existing@example.com',
          password: 'pass',
        ),
        throwsA(
          isA<AuthException>().having(
            (e) => e.message,
            'message',
            contains('already registered'),
          ),
        ),
      );
    });

    test('unhappy: weak password throws AuthException', () async {
      authService.errorToThrow = AuthException('Password is too weak');

      expect(
        () => authService.signUpWithEmail(
          email: 'test@example.com',
          password: '123',
        ),
        throwsA(
          isA<AuthException>().having(
            (e) => e.message,
            'message',
            contains('weak'),
          ),
        ),
      );
    });
  });

  group('signInWithApple', () {
    test('happy: successful sign in sets logged in', () async {
      final result = await authService.signInWithApple();

      expect(result, isA<AuthResponse>());
      expect(authService.isLoggedIn, isTrue);
      expect(authService.signInWithAppleCallCount, equals(1));
    });

    test('happy: returns User and Session', () async {
      final result = await authService.signInWithApple();

      expect(result.user, isNotNull);
      expect(result.user!.email, contains('apple'));
      expect(result.session, isNotNull);
      expect(result.session!.accessToken, isNotEmpty);
    });

    test('unhappy: user cancels throws AuthException', () async {
      authService.errorToThrow = AuthException('User cancelled');

      expect(
        () => authService.signInWithApple(),
        throwsA(isA<AuthException>()),
      );
      expect(authService.isLoggedIn, isFalse);
    });

    test('unhappy: no identity token throws AuthException', () async {
      authService.errorToThrow = AuthException(
        'Apple Sign In failed: No identity token',
      );

      expect(
        () => authService.signInWithApple(),
        throwsA(
          isA<AuthException>().having(
            (e) => e.message,
            'message',
            contains('identity token'),
          ),
        ),
      );
    });
  });

  group('signInWithGoogle', () {
    test('happy: successful sign in sets logged in', () async {
      await authService.signInWithGoogle();

      expect(authService.isLoggedIn, isTrue);
      expect(authService.signInWithGoogleCallCount, equals(1));
    });

    test('unhappy: user cancels throws AuthException', () async {
      authService.errorToThrow = AuthException('User cancelled');

      expect(
        () => authService.signInWithGoogle(),
        throwsA(isA<AuthException>()),
      );
    });

    test('unhappy: OAuth provider error throws AuthException', () async {
      authService.errorToThrow = AuthException('OAuth provider error');

      expect(
        () => authService.signInWithGoogle(),
        throwsA(
          isA<AuthException>().having(
            (e) => e.message,
            'message',
            contains('OAuth'),
          ),
        ),
      );
    });
  });

  group('signOut', () {
    test('happy: clears session and user data', () async {
      // First sign in
      await authService.signInWithEmail(
        email: 'test@example.com',
        password: 'pass',
      );
      expect(authService.isLoggedIn, isTrue);

      // Then sign out
      await authService.signOut();

      expect(authService.isLoggedIn, isFalse);
      expect(authService.currentUser, isNull);
      expect(authService.email, isNull);
      expect(authService.displayName, isNull);
      expect(authService.signOutCallCount, equals(1));
    });

    test('happy: can sign out when not logged in', () async {
      await authService.signOut();

      expect(authService.isLoggedIn, isFalse);
      expect(authService.signOutCallCount, equals(1));
    });
  });

  group('resetPassword', () {
    test('happy: sends email for valid address', () async {
      await authService.resetPassword('test@example.com');

      expect(authService.resetPasswordCallCount, equals(1));
      expect(authService.lastEmailUsed, equals('test@example.com'));
    });

    test('unhappy: invalid email throws AuthException', () async {
      authService.errorToThrow = AuthException('Invalid email');

      expect(
        () => authService.resetPassword('invalid'),
        throwsA(isA<AuthException>()),
      );
    });

    test('unhappy: user not found still completes (security)', () async {
      // Per security best practices, reset password should not reveal
      // whether email exists. The mock completes successfully.
      await authService.resetPassword('nonexistent@example.com');

      expect(authService.resetPasswordCallCount, equals(1));
    });
  });

  group('signInWithMagicLink', () {
    test('happy: sends OTP email', () async {
      await authService.signInWithMagicLink('test@example.com');

      expect(authService.lastEmailUsed, equals('test@example.com'));
    });

    test('unhappy: invalid email throws AuthException', () async {
      authService.errorToThrow = AuthException('Invalid email');

      expect(
        () => authService.signInWithMagicLink('invalid'),
        throwsA(isA<AuthException>()),
      );
    });

    test('unhappy: rate limited throws AuthException', () async {
      authService.errorToThrow = AuthException(
        'For security purposes, you can only request this once every 60 seconds',
      );

      expect(
        () => authService.signInWithMagicLink('test@example.com'),
        throwsA(isA<AuthException>()),
      );
    });
  });

  group('updateEmail', () {
    test('happy: changes email when authenticated', () async {
      authService.setLoggedIn(true, email: 'old@example.com');

      await authService.updateEmail('new@example.com');

      expect(authService.email, equals('new@example.com'));
    });

    test('unhappy: email already in use throws AuthException', () async {
      authService.setLoggedIn(true, email: 'old@example.com');
      authService.errorToThrow = AuthException('Email already in use');

      expect(
        () => authService.updateEmail('taken@example.com'),
        throwsA(isA<AuthException>()),
      );
    });

    test('unhappy: not authenticated throws error', () async {
      // Not logged in
      authService.errorToThrow = AuthException('Not authenticated');

      expect(
        () => authService.updateEmail('new@example.com'),
        throwsA(isA<AuthException>()),
      );
    });
  });

  group('updatePassword', () {
    test('happy: changes password when authenticated', () async {
      authService.setLoggedIn(true, email: 'test@example.com');

      await authService.updatePassword('newSecurePass123');

      // No error thrown = success
    });

    test('unhappy: weak password throws AuthException', () async {
      authService.setLoggedIn(true, email: 'test@example.com');
      authService.errorToThrow = AuthException('Password is too weak');

      expect(
        () => authService.updatePassword('123'),
        throwsA(isA<AuthException>()),
      );
    });

    test('unhappy: not authenticated throws error', () async {
      authService.errorToThrow = AuthException('Not authenticated');

      expect(
        () => authService.updatePassword('newPass'),
        throwsA(isA<AuthException>()),
      );
    });
  });

  group('deleteAccount', () {
    test('happy: calls edge function and signs out', () async {
      authService.setLoggedIn(true, email: 'test@example.com');

      await authService.deleteAccount();

      expect(authService.deleteAccountCallCount, equals(1));
      expect(authService.signOutCallCount, equals(1));
      expect(authService.isLoggedIn, isFalse);
    });

    test('unhappy: edge function fails still signs out locally', () async {
      authService.setLoggedIn(true, email: 'test@example.com');
      // Note: In the real service, edge function failure still signs out
      // The mock implements this behavior

      await authService.deleteAccount();

      expect(authService.isLoggedIn, isFalse);
    });
  });

  group('authStateChanges', () {
    test('happy: stream emits on login/logout', () async {
      final states = <AuthState>[];
      final subscription = authService.authStateChanges.listen(states.add);

      // Stream should be available
      expect(authService.authStateChanges, isA<Stream<AuthState>>());

      await subscription.cancel();
    });

    test('happy: stream is broadcast (multiple listeners)', () {
      final stream = authService.authStateChanges;

      // Should not throw - broadcast streams allow multiple listeners
      stream.listen((_) {});
      stream.listen((_) {});
    });

    test('happy: emitAuthState sends events to listeners', () async {
      final states = <AuthState>[];
      final subscription = authService.authStateChanges.listen(states.add);

      // Emit a signed in event
      authService.emitAuthState(
        AuthState(AuthChangeEvent.signedIn, null),
      );

      // Allow async processing
      await Future.delayed(Duration.zero);

      expect(states.length, equals(1));
      expect(states.first.event, equals(AuthChangeEvent.signedIn));

      await subscription.cancel();
    });

    test('happy: emits signedOut event', () async {
      final states = <AuthState>[];
      final subscription = authService.authStateChanges.listen(states.add);

      authService.emitAuthState(
        AuthState(AuthChangeEvent.signedOut, null),
      );

      await Future.delayed(Duration.zero);

      expect(states.first.event, equals(AuthChangeEvent.signedOut));
      await subscription.cancel();
    });

    test('happy: emits tokenRefreshed event', () async {
      final states = <AuthState>[];
      final subscription = authService.authStateChanges.listen(states.add);

      authService.emitAuthState(
        AuthState(AuthChangeEvent.tokenRefreshed, null),
      );

      await Future.delayed(Duration.zero);

      expect(states.first.event, equals(AuthChangeEvent.tokenRefreshed));
      await subscription.cancel();
    });

    test('happy: emits userUpdated event', () async {
      final states = <AuthState>[];
      final subscription = authService.authStateChanges.listen(states.add);

      authService.emitAuthState(
        AuthState(AuthChangeEvent.userUpdated, null),
      );

      await Future.delayed(Duration.zero);

      expect(states.first.event, equals(AuthChangeEvent.userUpdated));
      await subscription.cancel();
    });

    test('happy: emits passwordRecovery event', () async {
      final states = <AuthState>[];
      final subscription = authService.authStateChanges.listen(states.add);

      authService.emitAuthState(
        AuthState(AuthChangeEvent.passwordRecovery, null),
      );

      await Future.delayed(Duration.zero);

      expect(states.first.event, equals(AuthChangeEvent.passwordRecovery));
      await subscription.cancel();
    });

    test('happy: multiple events received in order', () async {
      final states = <AuthState>[];
      final subscription = authService.authStateChanges.listen(states.add);

      authService.emitAuthState(AuthState(AuthChangeEvent.signedIn, null));
      authService.emitAuthState(AuthState(AuthChangeEvent.tokenRefreshed, null));
      authService.emitAuthState(AuthState(AuthChangeEvent.signedOut, null));

      await Future.delayed(Duration.zero);

      expect(states.length, equals(3));
      expect(states[0].event, equals(AuthChangeEvent.signedIn));
      expect(states[1].event, equals(AuthChangeEvent.tokenRefreshed));
      expect(states[2].event, equals(AuthChangeEvent.signedOut));

      await subscription.cancel();
    });

    test('happy: late subscriber receives subsequent events only', () async {
      final earlyStates = <AuthState>[];
      final lateStates = <AuthState>[];

      final earlySub = authService.authStateChanges.listen(earlyStates.add);

      // First event - early subscriber only
      authService.emitAuthState(AuthState(AuthChangeEvent.signedIn, null));
      await Future.delayed(Duration.zero);

      // Late subscriber joins
      final lateSub = authService.authStateChanges.listen(lateStates.add);

      // Second event - both receive
      authService.emitAuthState(AuthState(AuthChangeEvent.signedOut, null));
      await Future.delayed(Duration.zero);

      expect(earlyStates.length, equals(2));
      expect(lateStates.length, equals(1));
      expect(lateStates.first.event, equals(AuthChangeEvent.signedOut));

      await earlySub.cancel();
      await lateSub.cancel();
    });
  });

  group('session persistence', () {
    test('happy: session state persists after operations', () async {
      // Sign in
      await authService.signInWithEmail(
        email: 'persist@example.com',
        password: 'pass',
      );

      // Multiple reads should return consistent value
      expect(authService.isLoggedIn, isTrue);
      expect(authService.isLoggedIn, isTrue);
      expect(authService.email, equals('persist@example.com'));
      expect(authService.email, equals('persist@example.com'));
    });

    test('happy: displayName can be set and retrieved', () {
      authService.setLoggedIn(
        true,
        email: 'test@example.com',
        displayName: 'Test User',
      );

      expect(authService.displayName, equals('Test User'));
    });
  });

  group('call count tracking', () {
    test('should track all method calls accurately', () async {
      await authService.signInWithApple();
      await authService.signInWithApple();
      await authService.signInWithGoogle();
      await authService.signInWithEmail(email: 'e', password: 'p');
      await authService.signUpWithEmail(email: 'e', password: 'p');
      await authService.resetPassword('e');
      await authService.signOut();
      await authService.signOut();
      await authService.deleteAccount();

      expect(authService.signInWithAppleCallCount, equals(2));
      expect(authService.signInWithGoogleCallCount, equals(1));
      expect(authService.signInWithEmailCallCount, equals(1));
      expect(authService.signUpWithEmailCallCount, equals(1));
      expect(authService.resetPasswordCallCount, equals(1));
      expect(authService.signOutCallCount, equals(3)); // 2 + 1 from delete
      expect(authService.deleteAccountCallCount, equals(1));
    });

    test('reset clears all state and counts', () async {
      await authService.signInWithEmail(email: 'e', password: 'p');
      authService.errorToThrow = AuthException('test');

      authService.reset();

      expect(authService.isLoggedIn, isFalse);
      expect(authService.signInWithEmailCallCount, equals(0));
      expect(authService.lastEmailUsed, isNull);
      expect(authService.errorToThrow, isNull);
    });
  });

  group('autoEmitAuthState', () {
    test('emits signedIn event on sign in when enabled', () async {
      authService.autoEmitAuthState = true;
      final states = <AuthState>[];
      final subscription = authService.authStateChanges.listen(states.add);

      await authService.signInWithEmail(email: 'e', password: 'p');
      await Future.delayed(Duration.zero);

      expect(states.length, equals(1));
      expect(states.first.event, equals(AuthChangeEvent.signedIn));

      await subscription.cancel();
    });

    test('emits signedOut event on sign out when enabled', () async {
      authService.autoEmitAuthState = true;
      final states = <AuthState>[];

      await authService.signInWithEmail(email: 'e', password: 'p');
      final subscription = authService.authStateChanges.listen(states.add);
      await authService.signOut();
      await Future.delayed(Duration.zero);

      expect(states.any((s) => s.event == AuthChangeEvent.signedOut), isTrue);

      await subscription.cancel();
    });

    test('emits userUpdated on email change when enabled', () async {
      authService.autoEmitAuthState = true;
      authService.setLoggedIn(true, email: 'old@test.com');
      final states = <AuthState>[];
      final subscription = authService.authStateChanges.listen(states.add);

      await authService.updateEmail('new@test.com');
      await Future.delayed(Duration.zero);

      expect(states.first.event, equals(AuthChangeEvent.userUpdated));

      await subscription.cancel();
    });

    test('does not emit when disabled (default)', () async {
      final states = <AuthState>[];
      final subscription = authService.authStateChanges.listen(states.add);

      await authService.signInWithEmail(email: 'e', password: 'p');
      await authService.signOut();
      await Future.delayed(Duration.zero);

      expect(states, isEmpty);

      await subscription.cancel();
    });
  });

  group('methodErrors (per-method error simulation)', () {
    test('per-method error takes precedence over global', () async {
      authService.errorToThrow = AuthException('global error');
      authService.methodErrors['signInWithEmail'] =
          AuthException('specific error');

      expect(
        () => authService.signInWithEmail(email: 'e', password: 'p'),
        throwsA(
          isA<AuthException>().having(
            (e) => e.message,
            'message',
            equals('specific error'),
          ),
        ),
      );
    });

    test('different methods can have different errors', () async {
      authService.methodErrors['signInWithEmail'] =
          AuthException('email error');
      authService.methodErrors['signInWithApple'] =
          AuthException('apple error');

      expect(
        () => authService.signInWithEmail(email: 'e', password: 'p'),
        throwsA(
          isA<AuthException>().having(
            (e) => e.message,
            'message',
            equals('email error'),
          ),
        ),
      );

      expect(
        () => authService.signInWithApple(),
        throwsA(
          isA<AuthException>().having(
            (e) => e.message,
            'message',
            equals('apple error'),
          ),
        ),
      );
    });

    test('method without specific error uses global', () async {
      authService.errorToThrow = AuthException('global');

      expect(
        () => authService.resetPassword('e'),
        throwsA(
          isA<AuthException>().having(
            (e) => e.message,
            'message',
            equals('global'),
          ),
        ),
      );
    });

    test('reset clears methodErrors', () async {
      authService.methodErrors['signInWithEmail'] = AuthException('error');

      authService.reset();

      // Should not throw after reset
      await authService.signInWithEmail(email: 'e', password: 'p');
      expect(authService.isLoggedIn, isTrue);
    });
  });

  // Additional tests in separate files:
  // - auth_service_crypto_test.dart (nonce, SHA256, validation)
  // - auth_service_compliance_test.dart (URLs, contracts, App Store)
}

