import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:prosepal/core/models/models.dart';
import 'package:prosepal/core/providers/providers.dart';
import 'package:prosepal/features/home/home_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences mockPrefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    mockPrefs = await SharedPreferences.getInstance();
  });

  /// Helper to create a testable HomeScreen with all required providers
  Widget createTestableHomeScreen({
    bool isPro = false,
    int remaining = 3,
    GoRouter? router,
  }) {
    final testRouter =
        router ??
        GoRouter(
          initialLocation: '/',
          routes: [
            GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
            GoRoute(
              path: '/generate',
              name: 'generate',
              builder: (context, state) =>
                  const Scaffold(body: Text('Generate Screen')),
            ),
            GoRoute(
              path: '/settings',
              name: 'settings',
              builder: (context, state) =>
                  const Scaffold(body: Text('Settings Screen')),
            ),
            GoRoute(
              path: '/paywall',
              name: 'paywall',
              builder: (context, state) =>
                  const Scaffold(body: Text('Paywall Screen')),
            ),
          ],
        );

    return ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(mockPrefs),
        isProProvider.overrideWith((ref) => isPro),
        remainingGenerationsProvider.overrideWith((ref) => remaining),
      ],
      child: MaterialApp.router(routerConfig: testRouter),
    );
  }

  group('HomeScreen Rendering', () {
    testWidgets('should display app title and tagline', (tester) async {
      await tester.pumpWidget(createTestableHomeScreen());
      await tester.pumpAndSettle();

      expect(find.text('Prosepal'), findsOneWidget);
      expect(find.text('The right words, right now'), findsOneWidget);
    });

    testWidgets('should display settings button', (tester) async {
      await tester.pumpWidget(createTestableHomeScreen());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.settings_outlined), findsOneWidget);
    });

    testWidgets('should display "What\'s the occasion?" section', (
      tester,
    ) async {
      await tester.pumpWidget(createTestableHomeScreen());
      await tester.pumpAndSettle();

      expect(find.text("What's the occasion?"), findsOneWidget);
    });

    testWidgets('should display all 10 occasions', (tester) async {
      await tester.pumpWidget(createTestableHomeScreen());
      await tester.pumpAndSettle();

      // Check each occasion is displayed
      for (final occasion in Occasion.values) {
        expect(
          find.text(occasion.label),
          findsOneWidget,
          reason: 'Should find ${occasion.label} occasion',
        );
      }
    });

    testWidgets('should display occasion emojis', (tester) async {
      await tester.pumpWidget(createTestableHomeScreen());
      await tester.pumpAndSettle();

      // Check a few key emojis are displayed
      expect(find.text('🎂'), findsOneWidget); // Birthday
      expect(find.text('🙏'), findsOneWidget); // Thank You
      expect(find.text('💒'), findsOneWidget); // Wedding
    });
  });

  group('HomeScreen Usage Indicator', () {
    testWidgets('free user sees remaining count and upgrade prompt', (
      tester,
    ) async {
      await tester.pumpWidget(createTestableHomeScreen(remaining: 3));
      await tester.pumpAndSettle();

      expect(find.text('3'), findsOneWidget);
      expect(find.text('Free messages remaining'), findsOneWidget);
      expect(find.text('Upgrade for unlimited'), findsOneWidget);
    });

    testWidgets('exhausted user sees trial ended message', (tester) async {
      await tester.pumpWidget(createTestableHomeScreen(remaining: 0));
      await tester.pumpAndSettle();

      expect(find.text('0'), findsOneWidget);
      expect(find.text('Free trial ended'), findsOneWidget);
      expect(find.text('Upgrade for unlimited'), findsOneWidget);
    });

    testWidgets('pro user sees PRO badge instead of usage card', (
      tester,
    ) async {
      await tester.pumpWidget(createTestableHomeScreen(isPro: true));
      await tester.pumpAndSettle();

      expect(find.text('PRO'), findsOneWidget);
      expect(find.byIcon(Icons.star), findsOneWidget);
      // Should NOT show free user elements
      expect(find.text('Free messages remaining'), findsNothing);
      expect(find.text('Upgrade for unlimited'), findsNothing);
    });

    testWidgets('tapping usage card navigates to paywall', (tester) async {
      await tester.pumpWidget(createTestableHomeScreen(remaining: 2));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Upgrade for unlimited'));
      await tester.pumpAndSettle();

      expect(find.text('Paywall Screen'), findsOneWidget);
    });
  });

  group('HomeScreen Navigation', () {
    testWidgets('should navigate to settings when settings button tapped', (
      tester,
    ) async {
      await tester.pumpWidget(createTestableHomeScreen());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.settings_outlined));
      await tester.pumpAndSettle();

      expect(find.text('Settings Screen'), findsOneWidget);
    });

    testWidgets('should navigate to generate when occasion tapped', (
      tester,
    ) async {
      await tester.pumpWidget(createTestableHomeScreen());
      await tester.pumpAndSettle();

      // Tap on Birthday occasion
      await tester.tap(find.text('Birthday'));
      await tester.pumpAndSettle();

      expect(find.text('Generate Screen'), findsOneWidget);
    });

    testWidgets('should navigate to generate for each occasion type', (
      tester,
    ) async {
      for (final occasion in Occasion.values) {
        // Reset for each occasion
        await tester.pumpWidget(createTestableHomeScreen());
        await tester.pumpAndSettle();

        // Find and tap the occasion
        final occasionFinder = find.text(occasion.label);
        expect(occasionFinder, findsOneWidget);

        await tester.tap(occasionFinder);
        await tester.pumpAndSettle();

        expect(
          find.text('Generate Screen'),
          findsOneWidget,
          reason: '${occasion.label} should navigate to generate screen',
        );
      }
    });
  });

  group('HomeScreen Accessibility', () {
    testWidgets('should have accessible settings button', (tester) async {
      await tester.pumpWidget(createTestableHomeScreen());
      await tester.pumpAndSettle();

      final settingsButton = find.byIcon(Icons.settings_outlined);
      expect(settingsButton, findsOneWidget);

      // Button should be tappable
      final buttonWidget = tester.widget<IconButton>(
        find.ancestor(of: settingsButton, matching: find.byType(IconButton)),
      );
      expect(buttonWidget.onPressed, isNotNull);
    });

    testWidgets('should have scrollable content', (tester) async {
      await tester.pumpWidget(createTestableHomeScreen());
      await tester.pumpAndSettle();

      // Verify CustomScrollView exists
      expect(find.byType(CustomScrollView), findsOneWidget);
    });
  });
}
