import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:prosepal/core/providers/providers.dart';
import 'package:prosepal/features/auth/auth_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../mocks/mock_auth_service.dart';
import '../../mocks/mock_biometric_service.dart';
import '../../mocks/mock_subscription_service.dart';

/// AuthScreen Widget Tests
///
/// Bugs these tests prevent:
/// - BUG-001: Social login buttons missing or broken
/// - BUG-002: Error messages not shown after failed auth
/// - BUG-003: Loading state stuck after auth attempt
/// - BUG-004: Close/back button missing (user trapped)
/// - BUG-005: Unexpected auth method shown in simplified onboarding
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences mockPrefs;
  late MockAuthService mockAuth;
  late MockBiometricService mockBiometric;
  late MockSubscriptionService mockSubscription;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    mockPrefs = await SharedPreferences.getInstance();
    mockAuth = MockAuthService();
    mockBiometric = MockBiometricService();
    mockSubscription = MockSubscriptionService();
  });

  tearDown(() {
    mockAuth.dispose();
  });

  Widget createTestableAuthScreen({
    String? redirectTo,
    bool isProRestore = false,
    GoRouter? router,
  }) {
    final testRouter =
        router ??
        GoRouter(
          initialLocation: '/auth',
          routes: [
            GoRoute(
              path: '/auth',
              builder: (context, state) => AuthScreen(
                redirectTo: redirectTo,
                isProRestore: isProRestore,
              ),
            ),
            GoRoute(
              path: '/home',
              builder: (context, state) =>
                  const Scaffold(body: Text('Home Screen')),
            ),
            GoRoute(
              path: '/biometric-setup',
              builder: (context, state) =>
                  const Scaffold(body: Text('Biometric Setup')),
            ),
          ],
        );

    return ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(mockPrefs),
        authServiceProvider.overrideWithValue(mockAuth),
        biometricServiceProvider.overrideWithValue(mockBiometric),
        subscriptionServiceProvider.overrideWithValue(mockSubscription),
      ],
      child: MaterialApp.router(routerConfig: testRouter),
    );
  }

  group('AuthScreen', () {
    testWidgets('shows only social sign-in options on onboarding auth', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestableAuthScreen());
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Sign in with Google'), findsOneWidget);
      expect(find.textContaining('Email'), findsNothing);
    });

    testWidgets('redirect flow has dismiss button (non-paywall)', (
      tester,
    ) async {
      // Non-paywall redirects allow dismissal
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestableAuthScreen(redirectTo: 'home'));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byIcon(Icons.close), findsOneWidget);
    });

    testWidgets('paywall redirect flow has NO dismiss button', (tester) async {
      // Paywall redirect requires auth - no escape (by design)
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestableAuthScreen(redirectTo: 'paywall'));
      await tester.pump(const Duration(milliseconds: 500));

      // Close button should NOT be present for paywall redirect
      expect(find.byIcon(Icons.close), findsNothing);
    });

    testWidgets('shows loading then navigates on successful Google sign-in', (
      tester,
    ) async {
      mockAuth.simulateDelay = const Duration(milliseconds: 300);

      await tester.pumpWidget(createTestableAuthScreen());
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.text('Sign in with Google'));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(mockAuth.signInWithGoogleCallCount, 1);

      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      expect(find.text('Home Screen'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('shows error banner when Google sign-in fails', (tester) async {
      mockAuth.simulateRateLimit();

      await tester.pumpWidget(createTestableAuthScreen());
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.text('Sign in with Google'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(mockAuth.signInWithGoogleCallCount, 1);
      expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
      expect(find.text('Home Screen'), findsNothing);

      // Flush auto-dismiss timer started by AuthScreen._showError.
      await tester.pump(const Duration(seconds: 11));
    });

    testWidgets('shows pro-restore banner when isProRestore is true', (
      tester,
    ) async {
      await tester.pumpWidget(createTestableAuthScreen(isProRestore: true));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Pro subscription found!'), findsOneWidget);
      expect(find.text('Sign in to restore your Pro access'), findsOneWidget);
    });
  });
}
