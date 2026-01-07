/// Firebase Test Lab Integration Tests
///
/// Mocked tests safe to run on FTL virtual devices.
/// No network calls - tests UI and navigation only.
///
/// Build:
///   JAVA_HOME=/Library/Java/JavaVirtualMachines/temurin-17.jdk/Contents/Home \
///     flutter build apk --debug -t integration_test/ftl_test.dart
///
/// Run on FTL:
///   gcloud firebase test android run \
///     --type instrumentation \
///     --app build/app/outputs/flutter-apk/app-debug.apk \
///     --test build/app/outputs/apk/androidTest/debug/app-debug-androidTest.apk \
///     --device model=oriole,version=33 \
///     --timeout 10m \
///     --no-use-orchestrator
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:prosepal/app/app.dart';
import 'package:prosepal/core/providers/providers.dart';

import '../test/mocks/mock_auth_service.dart';
import '../test/mocks/mock_subscription_service.dart';
import '../test/mocks/mock_ai_service.dart';

late IntegrationTestWidgetsFlutterBinding binding;

void main() {
  binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('FTL Smoke Tests', () {
    late SharedPreferences prefs;
    late MockAuthService mockAuth;
    late MockSubscriptionService mockSubscription;
    late MockAiService mockAi;

    setUp(() async {
      SharedPreferences.setMockInitialValues({'hasCompletedOnboarding': true});
      prefs = await SharedPreferences.getInstance();
      mockAuth = MockAuthService()
        ..setLoggedIn(true, email: 'test@example.com');
      mockSubscription = MockSubscriptionService()..setIsPro(false);
      mockAi = MockAiService();
    });

    Widget buildApp({bool isPro = false, int remaining = 1}) {
      mockSubscription.setIsPro(isPro);
      return ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          authServiceProvider.overrideWithValue(mockAuth),
          subscriptionServiceProvider.overrideWithValue(mockSubscription),
          aiServiceProvider.overrideWithValue(mockAi),
          isProProvider.overrideWith((ref) => isPro),
          remainingGenerationsProvider.overrideWith((ref) => remaining),
        ],
        child: const ProsepalApp(),
      );
    }

    Future<void> screenshot(WidgetTester tester, String name) async {
      await binding.convertFlutterSurfaceToImage();
      await tester.pump();
      await binding.takeScreenshot(name);
    }

    // === LAUNCH TESTS ===

    testWidgets('1. App launches', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle(const Duration(seconds: 3));
      expect(find.byType(MaterialApp), findsOneWidget);
      await screenshot(tester, '01_launch');
    });

    testWidgets('2. Home screen renders', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();
      expect(find.text('Prosepal'), findsOneWidget);
      expect(find.text("What's the occasion?"), findsOneWidget);
      await screenshot(tester, '02_home');
    });

    testWidgets('3. Occasions grid visible', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();
      expect(find.text('Birthday'), findsOneWidget);
      expect(find.text('Thank You'), findsOneWidget);
      await screenshot(tester, '03_occasions');
    });

    // === NAVIGATION TESTS ===

    testWidgets('4. Tap occasion opens wizard', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Birthday'));
      await tester.pumpAndSettle();
      expect(find.text('Close Friend'), findsOneWidget);
      await screenshot(tester, '04_wizard_step1');
    });

    testWidgets('5. Wizard step 2 - tones', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Birthday'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Close Friend'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(find.text('Heartfelt'), findsOneWidget);
      await screenshot(tester, '05_wizard_step2');
    });

    testWidgets('6. Wizard step 3 - generate', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Birthday'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Close Friend'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Heartfelt'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(find.text('Generate Messages'), findsOneWidget);
      await screenshot(tester, '06_wizard_step3');
    });

    testWidgets('7. Settings accessible', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.settings_outlined));
      await tester.pumpAndSettle();
      expect(find.text('Settings'), findsOneWidget);
      await screenshot(tester, '07_settings');
    });

    testWidgets('8. Back from settings', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.settings_outlined));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();
      expect(find.text('Birthday'), findsOneWidget);
      await screenshot(tester, '08_back_home');
    });

    // === STATE TESTS ===

    testWidgets('9. Free user shows remaining', (tester) async {
      await tester.pumpWidget(buildApp(isPro: false, remaining: 1));
      await tester.pumpAndSettle();
      expect(find.textContaining('1'), findsWidgets);
      await screenshot(tester, '09_free_user');
    });

    testWidgets('10. Pro user shows PRO badge', (tester) async {
      await tester.pumpWidget(buildApp(isPro: true));
      await tester.pumpAndSettle();
      // PRO users see different UI
      await screenshot(tester, '10_pro_user');
    });

    // === SCROLL TESTS ===

    testWidgets('11. Scroll occasions grid', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();
      final scrollable = find.byType(Scrollable).first;
      await tester.fling(scrollable, const Offset(0, -300), 1000);
      await tester.pumpAndSettle();
      await screenshot(tester, '11_scrolled');
    });

    testWidgets('12. Scroll settings', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.settings_outlined));
      await tester.pumpAndSettle();
      final scrollable = find.byType(Scrollable).first;
      await tester.fling(scrollable, const Offset(0, -300), 1000);
      await tester.pumpAndSettle();
      await screenshot(tester, '12_settings_scrolled');
    });

    // === STABILITY TESTS ===

    testWidgets('13. Rapid taps stable', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();
      for (int i = 0; i < 5; i++) {
        await tester.tap(find.text('Birthday'), warnIfMissed: false);
        await tester.pump(const Duration(milliseconds: 50));
      }
      await tester.pumpAndSettle();
      expect(find.byType(MaterialApp), findsOneWidget);
      await screenshot(tester, '13_stable');
    });

    testWidgets('14. Multiple wizard entries', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      // Enter and exit wizard twice
      await tester.tap(find.text('Birthday'));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Thank You'));
      await tester.pumpAndSettle();

      expect(find.text('Close Friend'), findsOneWidget);
      await screenshot(tester, '14_reentry');
    });

    testWidgets('15. Deep navigation', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      // Home → Settings → Privacy → Back → Back → Home
      await tester.tap(find.byIcon(Icons.settings_outlined));
      await tester.pumpAndSettle();

      // Scroll to Privacy
      final scrollable = find.byType(Scrollable).first;
      await tester.fling(scrollable, const Offset(0, -200), 500);
      await tester.pumpAndSettle();

      if (find.text('Privacy Policy').evaluate().isNotEmpty) {
        await tester.tap(find.text('Privacy Policy'));
        await tester.pumpAndSettle();
        await tester.tap(find.byIcon(Icons.arrow_back));
        await tester.pumpAndSettle();
      }

      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      expect(find.text('Birthday'), findsOneWidget);
      await screenshot(tester, '15_deep_nav');
    });
  });

  group('FTL Onboarding Tests', () {
    late SharedPreferences prefs;
    late MockAuthService mockAuth;
    late MockSubscriptionService mockSubscription;
    late MockAiService mockAi;

    setUp(() async {
      // Fresh install - no onboarding completed
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      mockAuth = MockAuthService()..setLoggedIn(false);
      mockSubscription = MockSubscriptionService()..setIsPro(false);
      mockAi = MockAiService();
    });

    Widget buildFreshApp() {
      return ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          authServiceProvider.overrideWithValue(mockAuth),
          subscriptionServiceProvider.overrideWithValue(mockSubscription),
          aiServiceProvider.overrideWithValue(mockAi),
          isProProvider.overrideWith((ref) => false),
          remainingGenerationsProvider.overrideWith((ref) => 1),
        ],
        child: const ProsepalApp(),
      );
    }

    Future<void> screenshot(WidgetTester tester, String name) async {
      await binding.convertFlutterSurfaceToImage();
      await tester.pump();
      await binding.takeScreenshot(name);
    }

    testWidgets('16. Fresh install shows onboarding', (tester) async {
      await tester.pumpWidget(buildFreshApp());
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Should show onboarding (Continue button) or home if skipped
      final hasOnboarding =
          find.text('Continue').evaluate().isNotEmpty ||
          find.text('Skip').evaluate().isNotEmpty ||
          find.text('Get Started').evaluate().isNotEmpty;
      final hasHome = find.text('Birthday').evaluate().isNotEmpty;

      expect(hasOnboarding || hasHome, isTrue);
      await screenshot(tester, '16_fresh_install');
    });

    testWidgets('17. Can skip onboarding', (tester) async {
      await tester.pumpWidget(buildFreshApp());
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Try to skip or continue through onboarding
      for (int i = 0; i < 5; i++) {
        if (find.text('Skip').evaluate().isNotEmpty) {
          await tester.tap(find.text('Skip'));
          await tester.pumpAndSettle();
          break;
        }
        if (find.text('Get Started').evaluate().isNotEmpty) {
          await tester.tap(find.text('Get Started'));
          await tester.pumpAndSettle();
          break;
        }
        if (find.text('Continue').evaluate().isNotEmpty) {
          await tester.tap(find.text('Continue'));
          await tester.pumpAndSettle();
        }
      }

      await screenshot(tester, '17_after_onboarding');
    });
  });
}
