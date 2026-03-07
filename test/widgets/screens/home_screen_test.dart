import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
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

  Future<void> pumpUntilFound(
    WidgetTester tester,
    Finder finder, {
    Duration step = const Duration(milliseconds: 100),
    int maxPumps = 20,
  }) async {
    for (var i = 0; i < maxPumps; i++) {
      await tester.pump(step);
      if (finder.evaluate().isNotEmpty) {
        return;
      }
    }
  }

  group('HomeScreen Rendering', () {
    testWidgets('can scroll to deep occasion entries', (tester) async {
      await tester.pumpWidget(createTestableHomeScreen());
      await tester.pump(const Duration(milliseconds: 300));

      final deepOccasion = find.text('Pet Loss');
      await tester.scrollUntilVisible(
        deepOccasion,
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(deepOccasion, findsOneWidget);
    });

    testWidgets('search field uses expected keyboard hints', (tester) async {
      await tester.pumpWidget(createTestableHomeScreen());
      await tester.pump(const Duration(milliseconds: 300));

      final searchField = tester.widget<TextField>(
        find.byWidgetPredicate(
          (widget) =>
              widget is TextField &&
              widget.decoration?.hintText == 'Search occasions...',
        ),
      );

      expect(searchField.textCapitalization, TextCapitalization.words);
      expect(searchField.keyboardType, TextInputType.text);
    });

    testWidgets('dismisses stale search focus when return-home signal is set', (
      tester,
    ) async {
      await tester.pumpWidget(createTestableHomeScreen());
      await tester.pump(const Duration(milliseconds: 300));

      final searchField = find.byWidgetPredicate(
        (widget) =>
            widget is TextField &&
            widget.decoration?.hintText == 'Search occasions...',
      );

      await tester.tap(searchField);
      await tester.pump();

      expect(
        tester
            .widget<EditableText>(find.byType(EditableText))
            .focusNode
            .hasFocus,
        isTrue,
      );

      final container = ProviderScope.containerOf(
        tester.element(find.byType(HomeScreen)),
      );
      container.read(dismissHomeKeyboardProvider.notifier).state = true;
      await tester.pump();
      await tester.pump();

      expect(
        tester
            .widget<EditableText>(find.byType(EditableText))
            .focusNode
            .hasFocus,
        isFalse,
      );
      expect(container.read(dismissHomeKeyboardProvider), isFalse);
    });
  });

  group('HomeScreen Usage Indicator', () {
    testWidgets('free user sees remaining count and upgrade prompt', (
      tester,
    ) async {
      await tester.pumpWidget(createTestableHomeScreen());
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('3'), findsOneWidget);
      expect(find.text('Free messages remaining'), findsOneWidget);
      expect(find.text('Tap to unlock unlimited'), findsOneWidget);
    });

    testWidgets('exhausted user sees trial ended message', (tester) async {
      await tester.pumpWidget(createTestableHomeScreen(remaining: 0));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('0'), findsOneWidget);
      expect(find.text('Free trial ended'), findsOneWidget);
      expect(find.text('Tap to unlock unlimited'), findsOneWidget);
    });

    testWidgets('pro user sees PRO badge instead of usage card', (
      tester,
    ) async {
      await tester.pumpWidget(createTestableHomeScreen(isPro: true));
      await tester.pump(const Duration(milliseconds: 300));

      // PRO badge shown as compact amber pill next to title
      expect(find.text('PRO'), findsOneWidget);
      // Should NOT show free user elements
      expect(find.text('Free messages remaining'), findsNothing);
      expect(find.text('Tap to unlock unlimited'), findsNothing);
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
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.byIcon(Icons.settings_outlined));
      await pumpUntilFound(tester, find.text('Settings Screen'));

      expect(find.text('Settings Screen'), findsOneWidget);
    });

    testWidgets('should navigate to generate when occasion tapped', (
      tester,
    ) async {
      await tester.pumpWidget(createTestableHomeScreen());
      await tester.pump(const Duration(milliseconds: 300));

      // Tap on Birthday occasion
      await tester.tap(find.text('Birthday'));
      await pumpUntilFound(tester, find.text('Generate Screen'));

      expect(find.text('Generate Screen'), findsOneWidget);
    });

    testWidgets(
      'should navigate to generate for an off-screen occasion after scrolling',
      (tester) async {
        await tester.pumpWidget(createTestableHomeScreen());
        await tester.pump(const Duration(milliseconds: 300));

        final occasionFinder = find.text('Pet Loss');
        await tester.scrollUntilVisible(
          occasionFinder,
          100,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pump();

        await tester.tap(occasionFinder);
        await pumpUntilFound(tester, find.text('Generate Screen'));

        expect(find.text('Generate Screen'), findsOneWidget);
      },
    );

    testWidgets('clears occasion search query when occasion is selected', (
      tester,
    ) async {
      await tester.pumpWidget(createTestableHomeScreen());
      await tester.pump(const Duration(milliseconds: 300));

      final container = ProviderScope.containerOf(
        tester.element(find.byType(HomeScreen)),
      );

      await tester.enterText(find.byType(TextField).first, 'birt');
      await tester.pump();
      expect(container.read(occasionSearchProvider), 'birt');

      await tester.tap(find.text('Birthday'));
      await pumpUntilFound(tester, find.text('Generate Screen'));

      expect(container.read(occasionSearchProvider), isEmpty);
    });
  });

  group('HomeScreen Accessibility', () {
    testWidgets('should have accessible settings button', (tester) async {
      await tester.pumpWidget(createTestableHomeScreen());
      await tester.pump(const Duration(milliseconds: 300));

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
      await tester.pump(const Duration(milliseconds: 300));

      // Verify CustomScrollView exists
      expect(find.byType(CustomScrollView), findsOneWidget);
    });
  });
}
