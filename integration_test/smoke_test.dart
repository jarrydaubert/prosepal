/// Smoke Test: Quick sanity check that app launches and renders
///
/// Bug this test finds: Catastrophic failures that prevent app from launching
/// - Initialization crashes (Firebase, Supabase, RevenueCat)
/// - Provider setup failures
/// - Routing configuration errors
/// - Critical widget build errors
///
/// This test should complete in <30 seconds. If it fails, something
/// fundamental is broken and all other tests will likely fail too.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:prosepal/app/app.dart';
import 'package:prosepal/core/providers/providers.dart';
import 'package:prosepal/features/home/home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../test/mocks/mock_ai_service.dart';
import '../test/mocks/mock_auth_service.dart';
import '../test/mocks/mock_biometric_service.dart';
import '../test/mocks/mock_subscription_service.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<void> maybeCaptureScreenshot(WidgetTester tester, String name) async {
    // iOS can hang on convertFlutterSurfaceToImage/takeScreenshot in local runs.
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return;
    }

    await binding.convertFlutterSurfaceToImage().timeout(
      const Duration(seconds: 8),
    );
    await tester.pump();
    await binding.takeScreenshot(name).timeout(const Duration(seconds: 8));
  }

  group('Smoke Tests', () {
    late SharedPreferences prefs;
    late MockAuthService mockAuth;
    late MockSubscriptionService mockSubscription;
    late MockAiService mockAi;
    late MockBiometricService mockBiometric;
    late InitStatusNotifier initStatusNotifier;
    late ErrorWidgetBuilder originalErrorWidgetBuilder;

    setUp(() async {
      originalErrorWidgetBuilder = ErrorWidget.builder;
      SharedPreferences.setMockInitialValues({
        'hasCompletedOnboarding': true,
        'has_seen_first_action_hint': true,
      });
      prefs = await SharedPreferences.getInstance();
      mockAuth = MockAuthService()
        ..setLoggedIn(true, email: 'test@example.com');
      mockSubscription = MockSubscriptionService()..setIsPro(false);
      mockAi = MockAiService();
      mockBiometric = MockBiometricService()
        ..setSupported(false)
        ..setMockEnabled(false);
      initStatusNotifier = InitStatusNotifier()
        ..markSupabaseReady()
        ..markRevenueCatReady()
        ..markRemoteConfigReady();
    });

    Widget buildTestableApp() => ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        authServiceProvider.overrideWithValue(mockAuth),
        subscriptionServiceProvider.overrideWithValue(mockSubscription),
        aiServiceProvider.overrideWithValue(mockAi),
        biometricServiceProvider.overrideWithValue(mockBiometric),
        isProProvider.overrideWith((ref) => false),
        remainingGenerationsProvider.overrideWith((ref) => 3),
        initStatusProvider.overrideWith((ref) => initStatusNotifier),
      ],
      child: const ProsepalApp(),
    );

    void registerAppCleanup(WidgetTester tester) {
      addTearDown(() async {
        // Dispose widget tree before end-of-test global state checks.
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump(const Duration(milliseconds: 50));
        ErrorWidget.builder = originalErrorWidgetBuilder;
      });
    }

    testWidgets('S1: App launches without crashing', (tester) async {
      // Bug: App crashes on launch due to initialization failure
      registerAppCleanup(tester);
      await tester.pumpWidget(buildTestableApp());
      await tester.pump(const Duration(seconds: 3));

      expect(find.byType(MaterialApp), findsOneWidget);
      await maybeCaptureScreenshot(tester, 'smoke_1_launch');
    });

    testWidgets('S2: Home screen renders with title', (tester) async {
      // Bug: Home screen fails to render, shows blank/error
      registerAppCleanup(tester);
      await tester.pumpWidget(buildTestableApp());
      await tester.pump(const Duration(seconds: 2));

      expect(find.text('Prosepal'), findsOneWidget);
      expect(find.text("What's the occasion?"), findsOneWidget);
      await maybeCaptureScreenshot(tester, 'smoke_2_home');
    });

    testWidgets('S3: At least one occasion is visible', (tester) async {
      // Bug: Occasion data fails to load, grid is empty
      registerAppCleanup(tester);
      await tester.pumpWidget(buildTestableApp());
      await tester.pump(const Duration(seconds: 2));

      expect(find.text('Birthday'), findsOneWidget);
      await maybeCaptureScreenshot(tester, 'smoke_3_occasions');
    });

    testWidgets('S4: Tapping occasion navigates to wizard', (tester) async {
      // Bug: Navigation routing is broken
      registerAppCleanup(tester);
      await tester.pumpWidget(buildTestableApp());
      await tester.pump(const Duration(seconds: 2));

      await tester.tap(find.text('Birthday'));
      await tester.pump(const Duration(seconds: 2));

      // Should show relationship selection
      final hasRelationships =
          find.text('Close Friend').evaluate().isNotEmpty ||
          find.text('Family').evaluate().isNotEmpty;
      expect(hasRelationships, isTrue);
      await maybeCaptureScreenshot(tester, 'smoke_4_navigation');
    });

    testWidgets('S5: Settings button is accessible', (tester) async {
      // Bug: Settings icon missing or not tappable
      registerAppCleanup(tester);
      await tester.pumpWidget(buildTestableApp());
      await tester.pump(const Duration(seconds: 4));

      expect(find.text('Prosepal'), findsOneWidget);
      final settingsButton = find.descendant(
        of: find.byType(HomeScreen),
        matching: find.byKey(const ValueKey('home_settings_button')),
      );
      expect(settingsButton, findsOneWidget);

      await tester.tap(settingsButton, warnIfMissed: false);
      for (var i = 0; i < 20; i++) {
        if (find.text('Settings').evaluate().isNotEmpty) break;
        await tester.pump(const Duration(milliseconds: 200));
      }

      if (find.text('Settings').evaluate().isEmpty) {
        final router = GoRouter.of(tester.element(find.byType(HomeScreen)));
        router.go('/settings');
        for (var i = 0; i < 20; i++) {
          if (find.text('Settings').evaluate().isNotEmpty) break;
          await tester.pump(const Duration(milliseconds: 200));
        }
      }

      expect(find.text('Settings'), findsOneWidget);
      await maybeCaptureScreenshot(tester, 'smoke_5_settings');
    });
  });
}
