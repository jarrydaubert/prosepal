/// Firebase Test Lab Integration Tests (critical deterministic subset)
///
/// This suite is intentionally small and deterministic for virtualized Android
/// device execution in Firebase Test Lab.
///
/// Build:
///   JAVA_HOME=/Library/Java/JavaVirtualMachines/temurin-17.jdk/Contents/Home \
///     flutter build apk --debug -t integration_test/ftl_test.dart
///   JAVA_HOME=/Library/Java/JavaVirtualMachines/temurin-17.jdk/Contents/Home \
///     (cd android && ./gradlew app:assembleAndroidTest \
///       -Ptarget=../integration_test/ftl_test.dart)
///
/// Run on FTL:
///   gcloud firebase test android run \
///     --type instrumentation \
///     --app build/app/outputs/flutter-apk/app-debug.apk \
///     --test build/app/outputs/apk/androidTest/debug/app-debug-androidTest.apk \
///     --device model=oriole,version=33,locale=en,orientation=portrait \
///     --timeout 12m \
///     --no-use-orchestrator
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:prosepal/app/app.dart';
import 'package:prosepal/core/providers/providers.dart';
import 'package:prosepal/core/services/usage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../test/mocks/mock_ai_service.dart';
import '../test/mocks/mock_auth_service.dart';
import '../test/mocks/mock_device_fingerprint_service.dart';
import '../test/mocks/mock_rate_limit_service.dart';
import '../test/mocks/mock_subscription_service.dart';

late IntegrationTestWidgetsFlutterBinding binding;

void main() {
  binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('FTL Critical', () {
    late SharedPreferences prefs;
    late MockAuthService mockAuth;
    late MockSubscriptionService mockSubscription;
    late MockAiService mockAi;
    late MockDeviceFingerprintService mockDeviceFingerprint;
    late MockRateLimitService mockRateLimit;
    late InitStatusNotifier initStatusNotifier;

    setUp(() async {
      SharedPreferences.setMockInitialValues({'hasCompletedOnboarding': true});
      prefs = await SharedPreferences.getInstance();
      mockAuth = MockAuthService()
        ..setLoggedIn(true, email: 'test@example.com');
      mockSubscription = MockSubscriptionService()..setIsPro(false);
      mockAi = MockAiService();
      mockDeviceFingerprint = MockDeviceFingerprintService();
      mockRateLimit = MockRateLimitService(
        deviceFingerprint: mockDeviceFingerprint,
      );
      initStatusNotifier = InitStatusNotifier()
        ..markSupabaseReady()
        ..markRevenueCatReady()
        ..markRemoteConfigReady();
    });

    Widget buildApp({bool isPro = false}) {
      mockSubscription.setIsPro(isPro);
      return ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          authServiceProvider.overrideWithValue(mockAuth),
          subscriptionServiceProvider.overrideWithValue(mockSubscription),
          aiServiceProvider.overrideWithValue(mockAi),
          deviceFingerprintServiceProvider.overrideWithValue(
            mockDeviceFingerprint,
          ),
          rateLimitServiceProvider.overrideWithValue(mockRateLimit),
          usageServiceProvider.overrideWith(
            (ref) => UsageService(prefs, mockDeviceFingerprint, mockRateLimit),
          ),
          initStatusProvider.overrideWith((ref) => initStatusNotifier),
          isProProvider.overrideWith((ref) => isPro),
          remainingGenerationsProvider.overrideWith((ref) => isPro ? 999 : 1),
        ],
        child: const ProsepalApp(),
      );
    }

    Future<void> pumpUntilVisible(
      WidgetTester tester,
      Finder finder, {
      int maxTicks = 30,
      Duration step = const Duration(milliseconds: 200),
    }) async {
      for (var i = 0; i < maxTicks; i++) {
        if (finder.evaluate().isNotEmpty) {
          return;
        }
        await tester.pump(step);
      }
      fail('Timed out waiting for expected widget');
    }

    void registerAppCleanup(WidgetTester tester) {
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump(const Duration(milliseconds: 50));
      });
    }

    testWidgets('S1: Launches and renders home', (tester) async {
      registerAppCleanup(tester);
      await tester.pumpWidget(buildApp());
      await pumpUntilVisible(tester, find.text('Prosepal'));
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('S2: Occasion opens wizard', (tester) async {
      registerAppCleanup(tester);
      await tester.pumpWidget(buildApp());
      await pumpUntilVisible(tester, find.text('Birthday'));

      await tester.tap(find.text('Birthday'));
      await tester.pump(const Duration(milliseconds: 300));
      await pumpUntilVisible(tester, find.text('Close Friend'));
      expect(find.text('Close Friend'), findsOneWidget);
    });

    testWidgets('S3: Settings open and return', (tester) async {
      registerAppCleanup(tester);
      await tester.pumpWidget(buildApp());
      await pumpUntilVisible(tester, find.byIcon(Icons.settings_outlined));

      await tester.tap(find.byIcon(Icons.settings_outlined));
      await tester.pump(const Duration(milliseconds: 300));
      await pumpUntilVisible(tester, find.text('Settings'));
      expect(find.text('Settings'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pump(const Duration(milliseconds: 300));
      await pumpUntilVisible(tester, find.text('Birthday'));
    });

    testWidgets('S4: Pro override renders without crash', (tester) async {
      registerAppCleanup(tester);
      await tester.pumpWidget(buildApp(isPro: true));
      await pumpUntilVisible(tester, find.text('Prosepal'));
      expect(find.byType(MaterialApp), findsOneWidget);
    });
  });
}
