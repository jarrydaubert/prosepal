/// Shared test helpers for integration tests
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:prosepal/core/config/preference_keys.dart';
import 'package:prosepal/main.dart' as app;
import 'package:shared_preferences/shared_preferences.dart';

/// Binding for screenshots in Firebase Test Lab
late IntegrationTestWidgetsFlutterBinding binding;
const captureIntegrationScreenshots = bool.fromEnvironment(
  'INTEGRATION_CAPTURE_SCREENSHOTS',
);

/// Initialize the test binding
void initBinding() {
  binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.onlyPumps;
}

/// Take a screenshot with the given name (Android requires convertFlutterSurfaceToImage first)
Future<void> screenshot(WidgetTester tester, String name) async {
  if (!captureIntegrationScreenshots) return;
  if (kIsWeb) return;

  try {
    if (defaultTargetPlatform == TargetPlatform.android) {
      await binding.convertFlutterSurfaceToImage().timeout(
        const Duration(seconds: 8),
      );
      await tester.pump();
    }
    await binding.takeScreenshot(name).timeout(const Duration(seconds: 8));
  } on Exception catch (error) {
    // Screenshot capture is diagnostic-only and should not fail the journey.
    debugPrint('[WARN] Screenshot skipped for $name: $error');
  }
}

/// Launch app and wait for initial screen
Future<void> launchApp(WidgetTester tester) async {
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 50));
  });

  await _resetPersistentState();
  app.main();
  await _pumpFor(tester, const Duration(seconds: 3));
}

/// Skip onboarding screens until home is visible
Future<void> skipOnboarding(WidgetTester tester) async {
  var attempts = 0;
  while (attempts < 10) {
    // Check if we've reached home
    if (find.text('Birthday').evaluate().isNotEmpty ||
        find.text("What's the occasion?").evaluate().isNotEmpty) {
      break;
    }

    // Tap "Get Started" to complete onboarding (final carousel page)
    if (find.text('Get Started').evaluate().isNotEmpty) {
      await tester.tap(find.text('Get Started'));
      await _pumpFor(tester, const Duration(seconds: 2));
      break;
    }

    // Tap "Continue" to advance carousel
    if (find.text('Continue').evaluate().isNotEmpty) {
      await tester.tap(find.text('Continue'));
      await _pumpFor(tester, const Duration(seconds: 1));
      attempts++;
    } else {
      break;
    }
  }
}

/// Navigate to home screen (launch + skip onboarding)
Future<bool> navigateToHome(WidgetTester tester) async {
  await launchApp(tester);
  await skipOnboarding(tester);
  return find.text('Birthday').evaluate().isNotEmpty;
}

/// Navigate to settings screen
Future<bool> navigateToSettings(WidgetTester tester) async {
  if (!await navigateToHome(tester)) return false;

  if (find.byIcon(Icons.settings_outlined).evaluate().isEmpty) return false;

  await tester.tap(find.byIcon(Icons.settings_outlined));
  await _pumpFor(tester, const Duration(seconds: 1));

  return find.text('Settings').evaluate().isNotEmpty;
}

/// Complete wizard through all steps (occasion -> relationship -> tone -> final)
Future<bool> completeWizard(
  WidgetTester tester, {
  String occasion = 'Birthday',
  String relationship = 'Close Friend',
  String tone = 'Heartfelt',
}) async {
  // Tap occasion
  if (find.text(occasion).evaluate().isEmpty) {
    final scrollable = find.byType(Scrollable).first;
    try {
      await tester.scrollUntilVisible(
        find.text(occasion),
        200,
        scrollable: scrollable,
      );
      await _pumpFor(tester, const Duration(seconds: 1));
    } on Exception catch (_) {
      return false;
    }
  }

  await tester.tap(find.text(occasion));
  await _pumpFor(tester, const Duration(seconds: 1));

  // Select relationship
  if (find.text(relationship).evaluate().isNotEmpty) {
    await tester.tap(find.text(relationship));
    await _pumpFor(tester, const Duration(seconds: 1));
  }
  if (find.text('Continue').evaluate().isNotEmpty) {
    await tester.tap(find.text('Continue'));
    await _pumpFor(tester, const Duration(seconds: 1));
  }

  // Select tone
  if (find.text(tone).evaluate().isNotEmpty) {
    await tester.tap(find.text(tone));
    await _pumpFor(tester, const Duration(seconds: 1));
  }
  if (find.text('Continue').evaluate().isNotEmpty) {
    await tester.tap(find.text('Continue'));
    await _pumpFor(tester, const Duration(seconds: 1));
  }

  // Check final step
  return find.text('Generate Messages').evaluate().isNotEmpty ||
      find.text('Upgrade to Continue').evaluate().isNotEmpty;
}

/// Navigate to auth screen via upgrade path
Future<bool> navigateToAuth(WidgetTester tester) async {
  if (!await navigateToHome(tester)) return false;
  if (!await completeWizard(tester)) return false;

  if (find.text('Upgrade to Continue').evaluate().isNotEmpty) {
    await tester.tap(find.text('Upgrade to Continue'));
    await _pumpFor(tester, const Duration(seconds: 2));
    return find.text('Continue with Email').evaluate().isNotEmpty ||
        find.text('Continue with Apple').evaluate().isNotEmpty;
  }

  return false;
}

/// Check if element exists
bool exists(Finder finder) => finder.evaluate().isNotEmpty;

/// Check if any of the given texts exist
bool anyTextExists(List<String> texts) =>
    texts.any((text) => find.text(text).evaluate().isNotEmpty);

/// Scroll until text is visible, returns true if found
Future<bool> scrollToText(
  WidgetTester tester,
  String text, {
  double delta = 200,
}) async {
  final scrollable = find.byType(Scrollable).first;
  try {
    await tester.scrollUntilVisible(
      find.text(text),
      delta,
      scrollable: scrollable,
    );
    await _pumpFor(tester, const Duration(seconds: 1));
    return true;
  } on Exception catch (_) {
    return false;
  }
}

/// Tap back button if visible
Future<bool> tapBack(WidgetTester tester) async {
  if (find.byIcon(Icons.arrow_back).evaluate().isNotEmpty) {
    await tester.tap(find.byIcon(Icons.arrow_back));
    await _pumpFor(tester, const Duration(seconds: 1));
    return true;
  }
  return false;
}

Future<void> _resetPersistentState() async {
  SharedPreferences.setMockInitialValues({
    PreferenceKeys.hasCompletedOnboarding: false,
    PreferenceKeys.hasSeenFirstActionHint: false,
    PreferenceKeys.analyticsEnabled: false,
  });
  FlutterSecureStorage.setMockInitialValues(const <String, String>{});
}

Future<void> _pumpFor(
  WidgetTester tester,
  Duration duration, {
  Duration step = const Duration(milliseconds: 100),
}) async {
  var elapsed = Duration.zero;
  while (elapsed < duration) {
    await tester.pump(step);
    elapsed += step;
  }
}
