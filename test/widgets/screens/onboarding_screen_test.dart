import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:prosepal/core/providers/providers.dart';
import 'package:prosepal/features/onboarding/onboarding_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../mocks/mock_auth_service.dart';

/// OnboardingScreen Widget Tests
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockAuthService mockAuth;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    mockAuth = MockAuthService();
  });

  tearDown(() {
    mockAuth.dispose();
  });

  Widget createTestableOnboardingScreen({GoRouter? router}) {
    final testRouter =
        router ??
        GoRouter(
          initialLocation: '/onboarding',
          routes: [
            GoRoute(
              path: '/onboarding',
              builder: (context, state) => const OnboardingScreen(),
            ),
            GoRoute(
              path: '/paywall',
              builder: (context, state) =>
                  const Scaffold(body: Text('Paywall Screen')),
            ),
            GoRoute(
              path: '/home',
              builder: (context, state) =>
                  const Scaffold(body: Text('Home Screen')),
            ),
            GoRoute(
              path: '/auth',
              builder: (context, state) =>
                  const Scaffold(body: Text('Auth Screen')),
            ),
          ],
        );

    // Pre-initialize initStatusNotifier for tests (services ready)
    final initStatusNotifier = InitStatusNotifier()
      ..markSupabaseReady()
      ..markRevenueCatReady();

    return ProviderScope(
      overrides: [
        initStatusProvider.overrideWith((ref) => initStatusNotifier),
        // Mock isProProvider to return false (no subscription)
        isProProvider.overrideWith((ref) => false),
        // Mock auth service to avoid Supabase initialization
        authServiceProvider.overrideWithValue(mockAuth),
      ],
      child: MaterialApp.router(routerConfig: testRouter),
    );
  }

  group('OnboardingScreen', () {
    testWidgets('skip button removed - onboarding as init cover', (
      tester,
    ) async {
      // Skip button intentionally removed - onboarding covers init time
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestableOnboardingScreen());
      await tester.pump(const Duration(milliseconds: 500));

      // Verify skip button is NOT present (intentional removal)
      final skipButton = find.textContaining('Skip');
      expect(skipButton, findsNothing);

      // Verify Continue button IS present
      final continueButton = find.text('Continue');
      expect(continueButton, findsOneWidget);
    });

    testWidgets('can navigate through all pages', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestableOnboardingScreen());
      await tester.pump(const Duration(milliseconds: 500));

      // Page 1 - Continue
      expect(find.text('Continue'), findsOneWidget);
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Page 2 - Continue
      expect(find.text('Continue'), findsOneWidget);
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Page 3 - Get Started (final page)
      expect(find.text('Get Started'), findsOneWidget);
    });

    testWidgets('completion persists - no repeat onboarding', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestableOnboardingScreen());
      await tester.pump(const Duration(milliseconds: 500));

      // Navigate through all pages
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Tap Get Started
      await tester.tap(find.text('Get Started'));
      await tester.pumpAndSettle();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('hasCompletedOnboarding'), isTrue);
    });
  });
}
