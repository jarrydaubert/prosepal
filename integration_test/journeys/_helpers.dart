/// Shared test helpers for integration tests
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:prosepal/main.dart' as app;

/// Binding for screenshots in Firebase Test Lab
late IntegrationTestWidgetsFlutterBinding binding;
const captureIntegrationScreenshots = bool.fromEnvironment(
  'INTEGRATION_CAPTURE_SCREENSHOTS',
  defaultValue: false,
);

/// Initialize the test binding
void initBinding() {
  binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
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
  app.main();
  await tester.pumpAndSettle(const Duration(seconds: 5));
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
      await tester.pumpAndSettle(const Duration(seconds: 2));
      break;
    }

    // Tap "Continue" to advance carousel
    if (find.text('Continue').evaluate().isNotEmpty) {
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle(const Duration(seconds: 1));
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
  await tester.pumpAndSettle();

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
      await tester.pumpAndSettle();
    } on Exception catch (_) {
      return false;
    }
  }

  await tester.tap(find.text(occasion));
  await tester.pumpAndSettle();

  // Select relationship
  if (find.text(relationship).evaluate().isNotEmpty) {
    await tester.tap(find.text(relationship));
    await tester.pumpAndSettle();
  }
  if (find.text('Continue').evaluate().isNotEmpty) {
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
  }

  // Select tone
  if (find.text(tone).evaluate().isNotEmpty) {
    await tester.tap(find.text(tone));
    await tester.pumpAndSettle();
  }
  if (find.text('Continue').evaluate().isNotEmpty) {
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
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
    await tester.pumpAndSettle(const Duration(seconds: 2));
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
    await tester.pumpAndSettle();
    return true;
  } on Exception catch (_) {
    return false;
  }
}

/// Tap back button if visible
Future<bool> tapBack(WidgetTester tester) async {
  if (find.byIcon(Icons.arrow_back).evaluate().isNotEmpty) {
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
    return true;
  }
  return false;
}
