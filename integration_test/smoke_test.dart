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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:prosepal/app/app.dart';
import 'package:prosepal/core/providers/providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../test/mocks/mock_ai_service.dart';
import '../test/mocks/mock_auth_service.dart';
import '../test/mocks/mock_subscription_service.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Smoke Tests', () {
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

    Widget buildTestableApp() => ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        authServiceProvider.overrideWithValue(mockAuth),
        subscriptionServiceProvider.overrideWithValue(mockSubscription),
        aiServiceProvider.overrideWithValue(mockAi),
        isProProvider.overrideWith((ref) => false),
        remainingGenerationsProvider.overrideWith((ref) => 3),
      ],
      child: const ProsepalApp(),
    );

    testWidgets('S1: App launches without crashing', (tester) async {
      // Bug: App crashes on launch due to initialization failure
      await tester.pumpWidget(buildTestableApp());
      await tester.pumpAndSettle(const Duration(seconds: 3));

      expect(find.byType(MaterialApp), findsOneWidget);
      await binding.convertFlutterSurfaceToImage();
      await tester.pump();
      await binding.takeScreenshot('smoke_1_launch');
    });

    testWidgets('S2: Home screen renders with title', (tester) async {
      // Bug: Home screen fails to render, shows blank/error
      await tester.pumpWidget(buildTestableApp());
      await tester.pumpAndSettle();

      expect(find.text('Prosepal'), findsOneWidget);
      expect(find.text("What's the occasion?"), findsOneWidget);
      await binding.convertFlutterSurfaceToImage();
      await tester.pump();
      await binding.takeScreenshot('smoke_2_home');
    });

    testWidgets('S3: At least one occasion is visible', (tester) async {
      // Bug: Occasion data fails to load, grid is empty
      await tester.pumpWidget(buildTestableApp());
      await tester.pumpAndSettle();

      expect(find.text('Birthday'), findsOneWidget);
      await binding.convertFlutterSurfaceToImage();
      await tester.pump();
      await binding.takeScreenshot('smoke_3_occasions');
    });

    testWidgets('S4: Tapping occasion navigates to wizard', (tester) async {
      // Bug: Navigation routing is broken
      await tester.pumpWidget(buildTestableApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Birthday'));
      await tester.pumpAndSettle();

      // Should show relationship selection
      final hasRelationships =
          find.text('Close Friend').evaluate().isNotEmpty ||
          find.text('Family').evaluate().isNotEmpty;
      expect(hasRelationships, isTrue);
      await binding.convertFlutterSurfaceToImage();
      await tester.pump();
      await binding.takeScreenshot('smoke_4_navigation');
    });

    testWidgets('S5: Settings button is accessible', (tester) async {
      // Bug: Settings icon missing or not tappable
      await tester.pumpWidget(buildTestableApp());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.settings_outlined), findsOneWidget);

      await tester.tap(find.byIcon(Icons.settings_outlined));
      await tester.pumpAndSettle();

      expect(find.text('Settings'), findsOneWidget);
      await binding.convertFlutterSurfaceToImage();
      await tester.pump();
      await binding.takeScreenshot('smoke_5_settings');
    });
  });
}
