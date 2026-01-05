/// Shared test helpers for integration tests
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:prosepal/main.dart' as app;

/// Binding for screenshots in Firebase Test Lab
late IntegrationTestWidgetsFlutterBinding binding;

/// Initialize the test binding
void initBinding() {
  binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
}

/// Take a screenshot with the given name
Future<void> screenshot(String name) async {
  await binding.takeScreenshot(name);
}

/// Launch app and wait for initial screen
Future<void> launchApp(WidgetTester tester) async {
  app.main();
  await tester.pumpAndSettle(const Duration(seconds: 5));
}

/// Skip onboarding screens until home is visible
Future<void> skipOnboarding(WidgetTester tester) async {
  int attempts = 0;
  while (find.text('Continue').evaluate().isNotEmpty &&
      find.text('Birthday').evaluate().isEmpty &&
      attempts < 5) {
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle(const Duration(seconds: 1));
    attempts++;
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
      await tester.scrollUntilVisible(find.text(occasion), 200, scrollable: scrollable);
      await tester.pumpAndSettle();
    } catch (_) {
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
bool anyTextExists(List<String> texts) {
  return texts.any((text) => find.text(text).evaluate().isNotEmpty);
}

/// Scroll until text is visible, returns true if found
Future<bool> scrollToText(WidgetTester tester, String text, {double delta = 200}) async {
  final scrollable = find.byType(Scrollable).first;
  try {
    await tester.scrollUntilVisible(find.text(text), delta, scrollable: scrollable);
    await tester.pumpAndSettle();
    return true;
  } catch (_) {
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
