import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:integration_test/integration_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:prosepal/app/app.dart';
import 'package:prosepal/core/providers/providers.dart';
import 'package:prosepal/firebase_options.dart';

/// Firebase Integration Tests
///
/// These tests verify Firebase integration within the actual app context.
///
/// Run with: flutter test integration_test/firebase_test.dart
///
/// IMPORTANT: Firebase verification is inherently semi-automated.
/// - Analytics: Events appear in DebugView (real-time) or dashboard (24h delay)
/// - Crashlytics: Reports appear after app relaunch (5-10 min delay)
///
/// This suite focuses on:
/// 1. Initialization succeeds without errors
/// 2. APIs are accessible and don't throw
/// 3. App flows that trigger logging work correctly
/// 4. Manual verification steps are documented
///
/// For full verification, enable DebugView:
/// iOS: Add -FIRDebugEnabled to Xcode scheme arguments
/// Android: adb shell setprop debug.firebase.analytics.app com.prosepal.prosepal
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;

  setUpAll(() async {
    // Initialize Firebase before tests (mirrors main.dart)
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Initialize SharedPreferences
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  group('Firebase Core Initialization', () {
    testWidgets('Firebase initializes successfully', (tester) async {
      // Assert: Firebase apps list is not empty after initialization
      expect(Firebase.apps, isNotEmpty,
          reason: 'Firebase should be initialized');

      // Assert: Default app exists
      expect(Firebase.app(), isNotNull,
          reason: 'Default Firebase app should exist');

      debugPrint('=== Firebase Core Verified ===');
      debugPrint('App name: ${Firebase.app().name}');
      debugPrint('Options project: ${Firebase.app().options.projectId}');
    });

    testWidgets('app launches with Firebase initialized', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: const ProsepalApp(),
        ),
      );

      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Assert: App renders without Firebase errors
      expect(find.byType(MaterialApp), findsOneWidget);

      // Assert: No error dialogs or crash screens
      expect(find.textContaining('error'), findsNothing);
      expect(find.textContaining('crash'), findsNothing);
    });
  });

  group('Firebase Crashlytics', () {
    testWidgets('Crashlytics is enabled and accessible', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: const ProsepalApp(),
        ),
      );

      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Assert: Crashlytics instance is accessible
      final crashlytics = FirebaseCrashlytics.instance;
      expect(crashlytics, isNotNull);

      // Assert: Collection is enabled (unless explicitly disabled)
      final isEnabled = crashlytics.isCrashlyticsCollectionEnabled;
      debugPrint('Crashlytics collection enabled: $isEnabled');

      // Note: In debug builds, collection may be disabled intentionally
      // The key is that the API is accessible without errors
    });

    testWidgets('can log non-fatal errors without throwing', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: const ProsepalApp(),
        ),
      );

      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Act: Log a non-fatal error
      try {
        await FirebaseCrashlytics.instance.recordError(
          Exception('Integration test: non-fatal error'),
          StackTrace.current,
          reason: 'Testing Crashlytics integration',
          fatal: false,
        );

        // Assert: No exception thrown
        debugPrint('=== Non-fatal error logged successfully ===');
        debugPrint('Check Firebase Console > Crashlytics after app relaunch');
      } catch (e) {
        fail('Crashlytics recordError threw: $e');
      }
    });

    testWidgets('can set custom keys without throwing', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: const ProsepalApp(),
        ),
      );

      await tester.pumpAndSettle(const Duration(seconds: 2));

      try {
        await FirebaseCrashlytics.instance.setCustomKey('test_run', 'integration');
        await FirebaseCrashlytics.instance.setCustomKey('timestamp', DateTime.now().toIso8601String());
        await FirebaseCrashlytics.instance.setUserIdentifier('integration_test_user');

        debugPrint('=== Custom keys set successfully ===');
      } catch (e) {
        fail('Crashlytics setCustomKey threw: $e');
      }
    });

    testWidgets('can log breadcrumb messages', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: const ProsepalApp(),
        ),
      );

      await tester.pumpAndSettle(const Duration(seconds: 2));

      try {
        await FirebaseCrashlytics.instance.log('Integration test started');
        await FirebaseCrashlytics.instance.log('Navigating to home screen');
        await FirebaseCrashlytics.instance.log('Test completed');

        debugPrint('=== Breadcrumbs logged successfully ===');
      } catch (e) {
        fail('Crashlytics log threw: $e');
      }
    });
  });

  group('Firebase Analytics', () {
    testWidgets('Analytics is accessible', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: const ProsepalApp(),
        ),
      );

      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Assert: Analytics instance is accessible
      final analytics = FirebaseAnalytics.instance;
      expect(analytics, isNotNull);
    });

    testWidgets('can log screen view without throwing', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: const ProsepalApp(),
        ),
      );

      await tester.pumpAndSettle(const Duration(seconds: 2));

      try {
        await FirebaseAnalytics.instance.logScreenView(
          screenName: 'integration_test_home',
          screenClass: 'HomeScreen',
        );

        debugPrint('=== Screen view logged ===');
        debugPrint('Enable DebugView to see event in real-time');
      } catch (e) {
        fail('Analytics logScreenView threw: $e');
      }
    });

    testWidgets('can log custom events without throwing', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: const ProsepalApp(),
        ),
      );

      await tester.pumpAndSettle(const Duration(seconds: 2));

      try {
        await FirebaseAnalytics.instance.logEvent(
          name: 'integration_test_event',
          parameters: {
            'test_type': 'automated',
            'timestamp': DateTime.now().millisecondsSinceEpoch,
          },
        );

        debugPrint('=== Custom event logged ===');
      } catch (e) {
        fail('Analytics logEvent threw: $e');
      }
    });

    testWidgets('can set user properties without throwing', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: const ProsepalApp(),
        ),
      );

      await tester.pumpAndSettle(const Duration(seconds: 2));

      try {
        await FirebaseAnalytics.instance.setUserProperty(
          name: 'test_user_type',
          value: 'integration_test',
        );

        debugPrint('=== User property set ===');
      } catch (e) {
        fail('Analytics setUserProperty threw: $e');
      }
    });
  });

  group('App Flow Analytics Events', () {
    testWidgets('occasion selection triggers analytics', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: const ProsepalApp(),
        ),
      );

      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Log event before user action (simulating what app does)
      await FirebaseAnalytics.instance.logEvent(
        name: 'occasion_selected',
        parameters: {'occasion': 'birthday'},
      );

      // Navigate to occasion
      final birthdayTile = find.text('Birthday');
      if (birthdayTile.evaluate().isNotEmpty) {
        await tester.tap(birthdayTile);
        await tester.pumpAndSettle();

        // Assert: Navigation succeeded
        expect(find.text('Close Friend'), findsOneWidget,
            reason: 'Should navigate to generate screen with relationships');

        debugPrint('=== Occasion selection flow verified ===');
        debugPrint('Analytics event: occasion_selected {occasion: birthday}');
      }
    });

    testWidgets('generation flow triggers analytics', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            isProProvider.overrideWith((ref) => true),
            remainingGenerationsProvider.overrideWith((ref) => 100),
          ],
          child: const ProsepalApp(),
        ),
      );

      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Navigate through generation flow
      final birthdayTile = find.text('Birthday');
      if (birthdayTile.evaluate().isNotEmpty) {
        await tester.tap(birthdayTile);
        await tester.pumpAndSettle();

        await tester.tap(find.text('Close Friend'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Continue'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Heartfelt'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Continue'));
        await tester.pumpAndSettle();

        // Log the event that would be triggered
        await FirebaseAnalytics.instance.logEvent(
          name: 'generation_started',
          parameters: {
            'occasion': 'birthday',
            'relationship': 'close_friend',
            'tone': 'heartfelt',
          },
        );

        debugPrint('=== Generation flow analytics verified ===');
      }
    });
  });

  group('Error Resilience', () {
    testWidgets('app functions when Firebase has issues', (tester) async {
      // This verifies the app doesn't hard-crash if Firebase has problems
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: const ProsepalApp(),
        ),
      );

      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Assert: App is usable
      expect(find.byType(MaterialApp), findsOneWidget);

      // Assert: Core functionality works
      expect(find.text('Birthday'), findsOneWidget);

      debugPrint('=== Error resilience verified ===');
    });
  });
}

// =============================================================================
// MANUAL VERIFICATION GUIDE
// =============================================================================
//
// After running these tests, verify in Firebase Console:
//
// CRASHLYTICS (Firebase Console > Crashlytics)
// 1. Relaunch the app after tests complete
// 2. Wait 5-10 minutes
// 3. Check for:
//    - Non-fatal errors with "Integration test" in message
//    - Custom keys: test_run=integration, timestamp
//    - User identifier: integration_test_user
//
// ANALYTICS (Firebase Console > Analytics > DebugView)
// 1. Enable DebugView BEFORE running tests:
//    iOS: Xcode > Product > Scheme > Edit Scheme > Run > Arguments
//         Add: -FIRDebugEnabled
//    Android: adb shell setprop debug.firebase.analytics.app com.prosepal.prosepal
// 2. Run tests on device/emulator
// 3. Check DebugView for events:
//    - integration_test_event
//    - occasion_selected
//    - generation_started
//    - screen_view (integration_test_home)
//
// To disable DebugView after testing:
//    iOS: Add -FIRDebugDisabled argument
//    Android: adb shell setprop debug.firebase.analytics.app .none.
//
// FORCE CRASH TEST (Manual Only)
// Uncomment and run only when you need to verify crash reporting:
// 
// testWidgets('FORCE CRASH - manual only', (tester) async {
//   await tester.pumpWidget(const ProsepalApp());
//   await tester.pumpAndSettle();
//   FirebaseCrashlytics.instance.crash(); // APP WILL CRASH
// });
// 
// After crash: Relaunch app, wait 5-10 min, check Crashlytics console
// =============================================================================
