import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:prosepal/features/onboarding/onboarding_screen.dart';

/// OnboardingScreen Widget Tests
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
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
          ],
        );

    return MaterialApp.router(routerConfig: testRouter);
  }

  group('OnboardingScreen', () {
    testWidgets('skip button works - user not stuck', (tester) async {
      // BUG: Skip button broken, user forced to swipe through all pages
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestableOnboardingScreen());
      await tester.pump(const Duration(milliseconds: 500));

      final skipButton = find.textContaining('Skip');
      expect(skipButton, findsOneWidget);

      await tester.tap(skipButton);
      await tester.pumpAndSettle();

      // Navigates to paywall (Day 0 conversion capture)
      expect(find.text('Paywall Screen'), findsOneWidget);
    });

    testWidgets('completion persists - no repeat onboarding', (tester) async {
      // BUG: User sees onboarding every app launch
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestableOnboardingScreen());
      await tester.pump(const Duration(milliseconds: 500));

      await tester.tap(find.textContaining('Skip'));
      await tester.pumpAndSettle();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('hasCompletedOnboarding'), isTrue);
    });
  });
}
