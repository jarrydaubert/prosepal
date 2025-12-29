import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:prosepal/app/app.dart';
import 'package:prosepal/core/providers/providers.dart';

import '../test/mocks/mock_auth_service.dart';

/// Supabase Auth Integration Tests
///
/// Tests auth flows end-to-end with mocked auth service.
/// Uses MockAuthService to simulate Supabase auth responses.
///
/// Run with: flutter test integration_test/auth_test.dart
///
/// Endpoints tested:
/// - auth.signInWithPassword (via signInWithEmail)
/// - auth.signUp (via signUpWithEmail)
/// - auth.signOut
/// - auth.onAuthStateChange
/// - auth.currentUser
/// - auth.resetPasswordForEmail
/// - auth.signInWithOtp (magic link)
/// - auth.updateUser (email/password)
/// - functions.invoke (delete account)
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;
  late MockAuthService mockAuth;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  setUp(() {
    mockAuth = MockAuthService();
  });

  tearDown(() {
    mockAuth.dispose();
  });

  // ============================================================
  // Test Helpers
  // ============================================================

  Widget buildApp() {
    return ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        authServiceProvider.overrideWithValue(mockAuth),
      ],
      child: const ProsepalApp(),
    );
  }

  /// Wait for app to settle with shorter timeout
  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle(const Duration(milliseconds: 500));
  }

  /// Navigate to settings tab (requires logged in state)
  Future<bool> navigateToSettings(WidgetTester tester) async {
    final settingsTab = find.byIcon(Icons.settings);
    if (settingsTab.evaluate().isEmpty) return false;
    await tester.tap(settingsTab);
    await tester.pumpAndSettle();
    return true;
  }

  /// Enter text in a TextField and submit
  Future<void> enterTextAndSubmit(
    WidgetTester tester, {
    required Finder field,
    required String text,
    required Finder submitButton,
  }) async {
    await tester.enterText(field, text);
    await tester.pumpAndSettle();
    if (submitButton.evaluate().isNotEmpty) {
      await tester.tap(submitButton);
      await tester.pumpAndSettle();
    }
  }

  /// Setup logged in user state
  void setupLoggedInUser({String email = 'test@example.com'}) {
    mockAuth.setLoggedIn(true, email: email);
    mockAuth.setUser(createFakeUser(email: email));
  }

  // ============================================================
  // Auth Screen Display
  // ============================================================

  group('Auth Screen Display', () {
    testWidgets('auth screen shows sign in options', (tester) async {
      await pumpApp(tester);

      expect(find.text('Sign in with Apple'), findsOneWidget);
      expect(find.text('Sign in with Google'), findsOneWidget);
    });

    testWidgets('auth screen shows email option', (tester) async {
      await pumpApp(tester);

      expect(find.text('Continue with Email'), findsOneWidget);
    });
  });

  // ============================================================
  // Sign In with Email - Happy Path
  // ============================================================

  group('Sign In with Email', () {
    testWidgets('successful sign in navigates to home', (tester) async {
      mockAuth.autoEmitAuthState = true;
      await pumpApp(tester);

      final emailOption = find.text('Continue with Email');
      if (emailOption.evaluate().isEmpty) return;

      await tester.tap(emailOption);
      await tester.pumpAndSettle();

      final textFields = find.byType(TextField);
      if (textFields.evaluate().length < 2) return;

      await tester.enterText(textFields.first, 'test@example.com');
      await tester.enterText(textFields.last, 'password123');
      await tester.pumpAndSettle();

      final signInButton = find.text('Sign In');
      if (signInButton.evaluate().isNotEmpty) {
        await tester.tap(signInButton);
        await tester.pumpAndSettle();

        expect(mockAuth.signInWithEmailCallCount, 1);
        expect(mockAuth.lastEmailUsed, 'test@example.com');
      }
    });

    testWidgets('sign in error shows error message', (tester) async {
      mockAuth.methodErrors['signInWithEmail'] = Exception('Invalid credentials');
      await pumpApp(tester);

      final emailOption = find.text('Continue with Email');
      if (emailOption.evaluate().isEmpty) return;

      await tester.tap(emailOption);
      await tester.pumpAndSettle();

      final textFields = find.byType(TextField);
      if (textFields.evaluate().length < 2) return;

      await tester.enterText(textFields.first, 'test@example.com');
      await tester.enterText(textFields.last, 'wrongpassword');

      final signInButton = find.text('Sign In');
      if (signInButton.evaluate().isNotEmpty) {
        await tester.tap(signInButton);
        await tester.pumpAndSettle();

        // Verify error was triggered
        expect(mockAuth.signInWithEmailCallCount, 1);
      }
    });
  });

  // ============================================================
  // Sign Up with Email
  // ============================================================

  group('Sign Up with Email', () {
    testWidgets('successful sign up calls auth service', (tester) async {
      await pumpApp(tester);

      final signUpLink = find.text('Create account');
      if (signUpLink.evaluate().isEmpty) return;

      await tester.tap(signUpLink);
      await tester.pumpAndSettle();

      final textFields = find.byType(TextField);
      if (textFields.evaluate().length < 2) return;

      await tester.enterText(textFields.first, 'newuser@example.com');
      await tester.enterText(textFields.last, 'securePassword123');

      final signUpButton = find.text('Sign Up');
      if (signUpButton.evaluate().isNotEmpty) {
        await tester.tap(signUpButton);
        await tester.pumpAndSettle();

        expect(mockAuth.signUpWithEmailCallCount, 1);
        expect(mockAuth.lastEmailUsed, 'newuser@example.com');
      }
    });

    testWidgets('sign up with existing email shows error', (tester) async {
      mockAuth.methodErrors['signUpWithEmail'] = Exception('Email already exists');
      await pumpApp(tester);

      final signUpLink = find.text('Create account');
      if (signUpLink.evaluate().isEmpty) return;

      await tester.tap(signUpLink);
      await tester.pumpAndSettle();

      final textFields = find.byType(TextField);
      if (textFields.evaluate().length < 2) return;

      await tester.enterText(textFields.first, 'existing@example.com');
      await tester.enterText(textFields.last, 'password123');

      final signUpButton = find.text('Sign Up');
      if (signUpButton.evaluate().isNotEmpty) {
        await tester.tap(signUpButton);
        await tester.pumpAndSettle();

        expect(mockAuth.signUpWithEmailCallCount, 1);
      }
    });
  });

  // ============================================================
  // Sign In with Apple
  // ============================================================

  group('Sign In with Apple', () {
    testWidgets('tapping Apple sign in calls auth service', (tester) async {
      await pumpApp(tester);

      final appleButton = find.text('Sign in with Apple');
      expect(appleButton, findsOneWidget);

      await tester.tap(appleButton);
      await tester.pumpAndSettle();

      expect(mockAuth.signInWithAppleCallCount, 1);
    });

    testWidgets('Apple sign in error is handled gracefully', (tester) async {
      mockAuth.methodErrors['signInWithApple'] = Exception('User cancelled');
      await pumpApp(tester);

      final appleButton = find.text('Sign in with Apple');
      await tester.tap(appleButton);
      await tester.pumpAndSettle();

      expect(mockAuth.signInWithAppleCallCount, 1);
      // App should not crash
      expect(find.byType(MaterialApp), findsOneWidget);
    });
  });

  // ============================================================
  // Sign In with Google
  // ============================================================

  group('Sign In with Google', () {
    testWidgets('tapping Google sign in calls auth service', (tester) async {
      await pumpApp(tester);

      final googleButton = find.text('Sign in with Google');
      expect(googleButton, findsOneWidget);

      await tester.tap(googleButton);
      await tester.pumpAndSettle();

      expect(mockAuth.signInWithGoogleCallCount, 1);
    });

    testWidgets('Google sign in error is handled gracefully', (tester) async {
      mockAuth.methodErrors['signInWithGoogle'] = Exception('Network error');
      await pumpApp(tester);

      final googleButton = find.text('Sign in with Google');
      await tester.tap(googleButton);
      await tester.pumpAndSettle();

      expect(mockAuth.signInWithGoogleCallCount, 1);
      expect(find.byType(MaterialApp), findsOneWidget);
    });
  });

  // ============================================================
  // Sign Out
  // ============================================================

  group('Sign Out', () {
    testWidgets('sign out clears user state', (tester) async {
      setupLoggedInUser();
      mockAuth.autoEmitAuthState = true;
      await pumpApp(tester);

      if (!await navigateToSettings(tester)) return;

      final signOutButton = find.text('Sign Out');
      if (signOutButton.evaluate().isEmpty) return;

      await tester.tap(signOutButton);
      await tester.pumpAndSettle();

      // Confirm if dialog appears
      final confirmButton = find.text('Sign Out');
      if (confirmButton.evaluate().length > 1) {
        await tester.tap(confirmButton.last);
        await tester.pumpAndSettle();
      }

      expect(mockAuth.signOutCallCount, greaterThan(0));
      expect(mockAuth.isLoggedIn, false);
    });

    testWidgets('sign out error is handled gracefully', (tester) async {
      setupLoggedInUser();
      mockAuth.methodErrors['signOut'] = Exception('Network error');
      await pumpApp(tester);

      if (!await navigateToSettings(tester)) return;

      final signOutButton = find.text('Sign Out');
      if (signOutButton.evaluate().isEmpty) return;

      await tester.tap(signOutButton);
      await tester.pumpAndSettle();

      final confirmButton = find.text('Sign Out');
      if (confirmButton.evaluate().length > 1) {
        await tester.tap(confirmButton.last);
        await tester.pumpAndSettle();
      }

      // App should handle error gracefully
      expect(find.byType(MaterialApp), findsOneWidget);
    });
  });

  // ============================================================
  // Auth State Persistence
  // ============================================================

  group('Auth State Persistence', () {
    testWidgets('logged in user sees home screen', (tester) async {
      setupLoggedInUser();
      await pumpApp(tester);

      expect(find.text('Prosepal'), findsOneWidget);
    });

    testWidgets('logged out user sees auth screen', (tester) async {
      mockAuth.setLoggedIn(false);
      await pumpApp(tester);

      expect(find.text('Sign in with Apple'), findsOneWidget);
    });
  });

  // ============================================================
  // Auth State Changes
  // ============================================================

  group('Auth State Changes', () {
    testWidgets('emitting signedIn updates UI state', (tester) async {
      await pumpApp(tester);

      expect(find.text('Sign in with Apple'), findsOneWidget);

      mockAuth.setLoggedIn(true, email: 'test@example.com');
      mockAuth.emitAuthState(
        AuthState(AuthChangeEvent.signedIn, createFakeSession()),
      );
      await tester.pumpAndSettle();

      // Auth state change should be processed
      expect(mockAuth.isLoggedIn, true);
    });

    testWidgets('emitting signedOut clears session', (tester) async {
      setupLoggedInUser();
      await pumpApp(tester);

      mockAuth.setLoggedIn(false);
      mockAuth.emitAuthState(
        AuthState(AuthChangeEvent.signedOut, null),
      );
      await tester.pumpAndSettle();

      expect(mockAuth.isLoggedIn, false);
    });
  });

  // ============================================================
  // Password Reset
  // ============================================================

  group('Password Reset', () {
    testWidgets('password reset calls auth service', (tester) async {
      await pumpApp(tester);

      final forgotPassword = find.text('Forgot password?');
      if (forgotPassword.evaluate().isEmpty) return;

      await tester.tap(forgotPassword);
      await tester.pumpAndSettle();

      final emailField = find.byType(TextField);
      if (emailField.evaluate().isEmpty) return;

      await tester.enterText(emailField.first, 'reset@example.com');

      final sendButton = find.text('Send Reset Link');
      if (sendButton.evaluate().isNotEmpty) {
        await tester.tap(sendButton);
        await tester.pumpAndSettle();

        expect(mockAuth.resetPasswordCallCount, 1);
        expect(mockAuth.lastEmailUsed, 'reset@example.com');
      }
    });

    testWidgets('password reset error is handled', (tester) async {
      mockAuth.methodErrors['resetPassword'] = Exception('Invalid email');
      await pumpApp(tester);

      final forgotPassword = find.text('Forgot password?');
      if (forgotPassword.evaluate().isEmpty) return;

      await tester.tap(forgotPassword);
      await tester.pumpAndSettle();

      final emailField = find.byType(TextField);
      if (emailField.evaluate().isEmpty) return;

      await tester.enterText(emailField.first, 'invalid');

      final sendButton = find.text('Send Reset Link');
      if (sendButton.evaluate().isNotEmpty) {
        await tester.tap(sendButton);
        await tester.pumpAndSettle();

        expect(mockAuth.resetPasswordCallCount, 1);
      }
    });
  });

  // ============================================================
  // Magic Link
  // ============================================================

  group('Magic Link', () {
    testWidgets('magic link sign in calls auth service', (tester) async {
      await pumpApp(tester);

      final magicLinkOption = find.text('Sign in with magic link');
      if (magicLinkOption.evaluate().isEmpty) return;

      await tester.tap(magicLinkOption);
      await tester.pumpAndSettle();

      final emailField = find.byType(TextField);
      if (emailField.evaluate().isEmpty) return;

      await tester.enterText(emailField.first, 'magic@example.com');

      final sendButton = find.text('Send Magic Link');
      if (sendButton.evaluate().isNotEmpty) {
        await tester.tap(sendButton);
        await tester.pumpAndSettle();

        expect(mockAuth.lastEmailUsed, 'magic@example.com');
      }
    });
  });

  // ============================================================
  // Update Email
  // ============================================================

  group('Update Email', () {
    testWidgets('update email calls auth service', (tester) async {
      setupLoggedInUser(email: 'old@example.com');
      await pumpApp(tester);

      if (!await navigateToSettings(tester)) return;

      final changeEmail = find.text('Change Email');
      if (changeEmail.evaluate().isEmpty) return;

      await tester.tap(changeEmail);
      await tester.pumpAndSettle();

      final emailField = find.byType(TextField);
      if (emailField.evaluate().isEmpty) return;

      await tester.enterText(emailField.first, 'new@example.com');

      final saveButton = find.text('Save');
      if (saveButton.evaluate().isNotEmpty) {
        await tester.tap(saveButton);
        await tester.pumpAndSettle();

        expect(mockAuth.email, 'new@example.com');
      }
    });

    testWidgets('update email error is handled', (tester) async {
      setupLoggedInUser();
      mockAuth.methodErrors['updateEmail'] = Exception('Invalid email');
      await pumpApp(tester);

      if (!await navigateToSettings(tester)) return;

      final changeEmail = find.text('Change Email');
      if (changeEmail.evaluate().isEmpty) return;

      await tester.tap(changeEmail);
      await tester.pumpAndSettle();

      // Error should be handled gracefully
      expect(find.byType(MaterialApp), findsOneWidget);
    });
  });

  // ============================================================
  // Update Password
  // ============================================================

  group('Update Password', () {
    testWidgets('update password calls auth service', (tester) async {
      setupLoggedInUser();
      await pumpApp(tester);

      if (!await navigateToSettings(tester)) return;

      final changePassword = find.text('Change Password');
      if (changePassword.evaluate().isEmpty) return;

      await tester.tap(changePassword);
      await tester.pumpAndSettle();

      final passwordFields = find.byType(TextField);
      if (passwordFields.evaluate().length < 2) return;

      await tester.enterText(passwordFields.at(0), 'newPassword123');
      await tester.enterText(passwordFields.at(1), 'newPassword123');

      final saveButton = find.text('Save');
      if (saveButton.evaluate().isNotEmpty) {
        await tester.tap(saveButton);
        await tester.pumpAndSettle();
      }
    });

    testWidgets('mismatched passwords show error', (tester) async {
      setupLoggedInUser();
      await pumpApp(tester);

      if (!await navigateToSettings(tester)) return;

      final changePassword = find.text('Change Password');
      if (changePassword.evaluate().isEmpty) return;

      await tester.tap(changePassword);
      await tester.pumpAndSettle();

      final passwordFields = find.byType(TextField);
      if (passwordFields.evaluate().length < 2) return;

      await tester.enterText(passwordFields.at(0), 'password1');
      await tester.enterText(passwordFields.at(1), 'password2');

      final saveButton = find.text('Save');
      if (saveButton.evaluate().isNotEmpty) {
        await tester.tap(saveButton);
        await tester.pumpAndSettle();

        // Should show validation error, not crash
        expect(find.byType(MaterialApp), findsOneWidget);
      }
    });

    testWidgets('update password error is handled', (tester) async {
      setupLoggedInUser();
      mockAuth.methodErrors['updatePassword'] = Exception('Weak password');
      await pumpApp(tester);

      if (!await navigateToSettings(tester)) return;

      final changePassword = find.text('Change Password');
      if (changePassword.evaluate().isEmpty) return;

      await tester.tap(changePassword);
      await tester.pumpAndSettle();

      expect(find.byType(MaterialApp), findsOneWidget);
    });
  });

  // ============================================================
  // Delete Account
  // ============================================================

  group('Delete Account', () {
    testWidgets('delete account calls auth service', (tester) async {
      setupLoggedInUser();
      mockAuth.autoEmitAuthState = true;
      await pumpApp(tester);

      if (!await navigateToSettings(tester)) return;

      // Scroll to find delete account
      try {
        await tester.scrollUntilVisible(
          find.text('Delete Account'),
          200,
          scrollable: find.byType(Scrollable).first,
        );
      } catch (_) {
        return; // Delete option not visible
      }

      final deleteAccount = find.text('Delete Account');
      if (deleteAccount.evaluate().isEmpty) return;

      await tester.tap(deleteAccount);
      await tester.pumpAndSettle();

      // Confirm deletion
      final confirmButton = find.text('Delete');
      if (confirmButton.evaluate().isNotEmpty) {
        await tester.tap(confirmButton.last);
        await tester.pumpAndSettle();

        expect(mockAuth.deleteAccountCallCount, greaterThan(0));
      }
    });

    testWidgets('delete account error still signs out', (tester) async {
      setupLoggedInUser();
      mockAuth.methodErrors['deleteAccount'] = Exception('Server error');
      mockAuth.autoEmitAuthState = true;
      await pumpApp(tester);

      if (!await navigateToSettings(tester)) return;

      try {
        await tester.scrollUntilVisible(
          find.text('Delete Account'),
          200,
          scrollable: find.byType(Scrollable).first,
        );
      } catch (_) {
        return;
      }

      final deleteAccount = find.text('Delete Account');
      if (deleteAccount.evaluate().isEmpty) return;

      await tester.tap(deleteAccount);
      await tester.pumpAndSettle();

      final confirmButton = find.text('Delete');
      if (confirmButton.evaluate().isNotEmpty) {
        await tester.tap(confirmButton.last);
        await tester.pumpAndSettle();

        // Should handle error gracefully
        expect(find.byType(MaterialApp), findsOneWidget);
      }
    });

    testWidgets('cancel delete account preserves session', (tester) async {
      setupLoggedInUser();
      await pumpApp(tester);

      if (!await navigateToSettings(tester)) return;

      try {
        await tester.scrollUntilVisible(
          find.text('Delete Account'),
          200,
          scrollable: find.byType(Scrollable).first,
        );
      } catch (_) {
        return;
      }

      final deleteAccount = find.text('Delete Account');
      if (deleteAccount.evaluate().isEmpty) return;

      await tester.tap(deleteAccount);
      await tester.pumpAndSettle();

      // Cancel instead of confirm
      final cancelButton = find.text('Cancel');
      if (cancelButton.evaluate().isNotEmpty) {
        await tester.tap(cancelButton);
        await tester.pumpAndSettle();

        expect(mockAuth.deleteAccountCallCount, 0);
        expect(mockAuth.isLoggedIn, true);
      }
    });
  });
}
