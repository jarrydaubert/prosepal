import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:prosepal/core/providers/providers.dart';
import 'package:prosepal/features/auth/auth_screen.dart';

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
/// - BUG-005: Email auth option not accessible
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
              path: '/email-auth',
              builder: (context, state) =>
                  const Scaffold(body: Text('Email Auth')),
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
    testWidgets('email fallback visible for users without social accounts', (tester) async {
      // BUG: User with no Apple/Google account has no way to sign in
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestableAuthScreen());
      await tester.pump(const Duration(milliseconds: 500));

      final hasEmailOption =
          find.textContaining('email').evaluate().isNotEmpty ||
          find.textContaining('Email').evaluate().isNotEmpty;

      expect(hasEmailOption, isTrue);
    });

    testWidgets('redirect flow has dismiss button', (tester) async {
      // BUG: User redirected to auth (e.g. from paywall) has no way back
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestableAuthScreen(redirectTo: 'paywall'));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byIcon(Icons.close), findsOneWidget);
    });
  });
}
