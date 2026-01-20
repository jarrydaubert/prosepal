import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:prosepal/core/models/models.dart';
import 'package:prosepal/core/providers/providers.dart';
import 'package:prosepal/features/home/home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../mocks/mock_auth_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences mockPrefs;
  late MockAuthService mockAuth;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    mockPrefs = await SharedPreferences.getInstance();
    mockAuth = MockAuthService();
  });

  tearDown(() {
    mockAuth.dispose();
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
            GoRoute(
              path: '/auth',
              name: 'auth',
              builder: (context, state) =>
                  const Scaffold(body: Text('Auth Screen')),
            ),
          ],
        );

    // Create a pre-initialized initStatusNotifier for tests
    final initStatusNotifier = InitStatusNotifier()
      ..markSupabaseReady()
      ..markRevenueCatReady();

    return ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(mockPrefs),
        isProProvider.overrideWith((ref) => isPro),
        remainingGenerationsProvider.overrideWith((ref) => remaining),
        authServiceProvider.overrideWithValue(mockAuth),
        initStatusProvider.overrideWith((ref) => initStatusNotifier),
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

    testWidgets('should display all occasions', (tester) async {
      await tester.pumpWidget(createTestableHomeScreen());
      await tester.pumpAndSettle();

      // Check each occasion is displayed (13 total: 10 original + 3 new)
      // Need to scroll to find items that may be off-screen
      for (final occasion in Occasion.values) {
        final finder = find.text(occasion.label);
        await tester.scrollUntilVisible(
          finder,
          100,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();
        expect(
          finder,
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
      await tester.pumpWidget(createTestableHomeScreen());
      await tester.pumpAndSettle();

      expect(find.text('3'), findsOneWidget);
      expect(find.text('Free messages remaining'), findsOneWidget);
      expect(find.text('Tap to unlock 500/month'), findsOneWidget);
    });

    testWidgets('exhausted user sees trial ended message', (tester) async {
      await tester.pumpWidget(createTestableHomeScreen(remaining: 0));
      await tester.pumpAndSettle();

      expect(find.text('0'), findsOneWidget);
      expect(find.text('Free trial ended'), findsOneWidget);
      expect(find.text('Tap to unlock 500/month'), findsOneWidget);
    });

    testWidgets('pro user sees PRO badge instead of usage card', (
      tester,
    ) async {
      await tester.pumpWidget(createTestableHomeScreen(isPro: true));
      await tester.pumpAndSettle();

      // PRO badge shown as compact amber pill next to title
      expect(find.text('PRO'), findsOneWidget);
      // Should NOT show free user elements
      expect(find.text('Free messages remaining'), findsNothing);
      expect(find.text('Tap to unlock 500/month'), findsNothing);
    });

    // NOTE: "returning user -> auth" flow removed - paywall now handles all
    // upgrade flows with inline auth. Testing paywall modal requires more
    // complex setup, covered by paywall_sheet_test.dart
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

        // Find and tap the occasion (scroll if needed)
        final occasionFinder = find.text(occasion.label);

        // Scroll to make sure the occasion is visible
        await tester.scrollUntilVisible(
          occasionFinder,
          100,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();

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

      // Button should be tappable (wrapped in GestureDetector)
      // Note: May find multiple GestureDetectors (button wrapper + root keyboard dismiss)
      final gestureDetector = find.ancestor(
        of: settingsButton,
        matching: find.byType(GestureDetector),
      );
      expect(gestureDetector, findsWidgets);
    });

    testWidgets('should have scrollable content', (tester) async {
      await tester.pumpWidget(createTestableHomeScreen());
      await tester.pumpAndSettle();

      // Verify CustomScrollView exists
      expect(find.byType(CustomScrollView), findsOneWidget);
    });
  });
}
