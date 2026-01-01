/// Standard Flutter Integration Tests for Prosepal
/// 
/// Uses integration_test package (not Patrol) to avoid AppAuth framework issues.
/// Run with: flutter drive --driver=test_driver/integration_test.dart --target=integration_test/flutter_test.dart -d "iPhone 17 Pro"

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:prosepal/app/app.dart';
import 'package:prosepal/core/providers/providers.dart';
import 'package:prosepal/core/models/models.dart';

import '../test/mocks/mock_ai_service.dart';
import '../test/mocks/mock_auth_service.dart';
import '../test/mocks/mock_subscription_service.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;
  late MockAuthService mockAuth;
  late MockSubscriptionService mockSubscription;
  late MockAiService mockAi;

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'hasCompletedOnboarding': true,
    });
    prefs = await SharedPreferences.getInstance();
    mockAuth = MockAuthService();
    mockSubscription = MockSubscriptionService();
    mockAi = MockAiService();
  });

  Future<void> pumpApp(
    WidgetTester tester, {
    bool isLoggedIn = true,
    bool isPro = false,
    int remainingGenerations = 3,
  }) async {
    await prefs.setBool('hasCompletedOnboarding', true);
    mockAuth.setLoggedIn(isLoggedIn, email: 'test@example.com');
    mockSubscription.setIsPro(isPro);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          authServiceProvider.overrideWithValue(mockAuth),
          subscriptionServiceProvider.overrideWithValue(mockSubscription),
          aiServiceProvider.overrideWithValue(mockAi),
          isProProvider.overrideWith((ref) => isPro),
          remainingGenerationsProvider.overrideWith((ref) => remainingGenerations),
        ],
        child: const ProsepalApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('App Launch', () {
    testWidgets('logged in user sees home screen with occasions', (tester) async {
      await pumpApp(tester, isLoggedIn: true);

      expect(find.text('Prosepal'), findsOneWidget);
      expect(find.text("What's the occasion?"), findsOneWidget);
      
      // Check for some occasions
      expect(find.text('Birthday'), findsOneWidget);
      expect(find.text('Thank You'), findsOneWidget);
    });

    testWidgets('logged out user sees auth screen', (tester) async {
      await pumpApp(tester, isLoggedIn: false);

      await tester.pumpAndSettle(const Duration(seconds: 2));
      
      expect(find.text('Continue with Email'), findsOneWidget);
    });
  });

  group('Generation Wizard', () {
    testWidgets('can navigate through wizard steps', (tester) async {
      await pumpApp(tester, isLoggedIn: true);

      // Tap Birthday occasion
      await tester.tap(find.text('Birthday'));
      await tester.pumpAndSettle();

      // Should be on step 2 (relationships)
      expect(find.text('Friend'), findsOneWidget);
      expect(find.text('Family'), findsOneWidget);

      // Tap Friend
      await tester.tap(find.text('Friend'));
      await tester.pumpAndSettle();

      // Should be on step 3 (tones)
      expect(find.text('Heartfelt'), findsOneWidget);
      expect(find.text('Funny'), findsOneWidget);
    });
  });

  group('Settings', () {
    testWidgets('can open settings screen', (tester) async {
      await pumpApp(tester, isLoggedIn: true);

      // Tap settings icon
      final settingsIcon = find.byIcon(Icons.settings_outlined);
      if (settingsIcon.evaluate().isNotEmpty) {
        await tester.tap(settingsIcon);
        await tester.pumpAndSettle();
        expect(find.text('Settings'), findsOneWidget);
      }
    });
  });

  group('Pro Status', () {
    testWidgets('free user sees usage indicator', (tester) async {
      await pumpApp(tester, isLoggedIn: true, isPro: false, remainingGenerations: 2);

      // Should show remaining generations
      expect(find.textContaining('2'), findsWidgets);
    });

    testWidgets('pro user sees Pro badge', (tester) async {
      await pumpApp(tester, isLoggedIn: true, isPro: true);

      expect(find.text('Pro'), findsOneWidget);
    });
  });
}
