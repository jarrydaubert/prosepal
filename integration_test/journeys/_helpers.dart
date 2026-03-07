/// Shared test helpers for integration tests
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:prosepal/core/config/preference_keys.dart';
import 'package:prosepal/core/services/biometric_service.dart';
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
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.benchmarkLive;
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
Future<void> launchApp(
  WidgetTester tester, {
  bool seedFreeTierUsed = false,
  bool seedOnboardingCompleted = false,
}) async {
  await _resetPersistentState(
    seedFreeTierUsed: seedFreeTierUsed,
    seedOnboardingCompleted: seedOnboardingCompleted,
  );
  app.main();
  binding.scheduleWarmUpFrame();
  final reachedReadySurface = await waitForAnyText(tester, const [
    'Prosepal',
    'Preparing your workspace...',
    'Securing sign-in...',
    'Syncing subscriptions...',
    'Tap to unlock',
    'Unlock with Biometrics',
    'Unlock with Face ID',
    'Unlock with Fingerprint',
    'Unlock with Touch ID',
    'Continue',
    'Get Started',
    'Sign in with Google',
    'Sign in with Apple',
    "What's the occasion?",
    'Birthday',
  ], timeout: const Duration(seconds: 45));

  expect(
    reachedReadySurface,
    isTrue,
    reason: 'App did not reach onboarding/auth/home surface after launch',
  );
}

/// Skip onboarding screens until home is visible
Future<void> skipOnboarding(WidgetTester tester) async {
  var attempts = 0;
  while (attempts < 60) {
    await _pumpFor(tester, const Duration(milliseconds: 400));

    // Check if we've reached home
    if (find.text('Birthday').evaluate().isNotEmpty ||
        find.text("What's the occasion?").evaluate().isNotEmpty) {
      break;
    }

    // Tap "Get Started" to complete onboarding (final carousel page)
    if (find.text('Get Started').evaluate().isNotEmpty) {
      await tester.tap(find.text('Get Started'), warnIfMissed: false);
      await _pumpFor(tester, const Duration(seconds: 2));
      break;
    }

    // Tap "Continue" to advance carousel
    if (find.text('Continue').evaluate().isNotEmpty) {
      await tester.tap(find.text('Continue'), warnIfMissed: false);
      await _pumpFor(tester, const Duration(milliseconds: 800));
      attempts++;
      continue;
    }

    attempts++;
  }
}

/// Navigate to home screen (launch + skip onboarding)
Future<bool> navigateToHome(
  WidgetTester tester, {
  bool seedFreeTierUsed = false,
}) async {
  await launchApp(tester, seedFreeTierUsed: seedFreeTierUsed);
  await skipOnboarding(tester);
  final homeSignalsVisible = await waitForAnyText(tester, const [
    "What's the occasion?",
    'Birthday',
  ], timeout: const Duration(seconds: 8));
  return homeSignalsVisible ||
      find.byKey(const ValueKey('home_settings_button')).evaluate().isNotEmpty;
}

/// Navigate to settings screen
Future<bool> navigateToSettings(
  WidgetTester tester, {
  bool seedFreeTierUsed = false,
}) async {
  final atHome = await navigateToHome(
    tester,
    seedFreeTierUsed: seedFreeTierUsed,
  );
  expect(atHome, isTrue, reason: 'Expected to reach home before settings');

  final settingsByKey = find.byKey(const ValueKey('home_settings_button'));
  final settingsByIcon = find.byIcon(Icons.settings_outlined);
  expect(
    settingsByKey.evaluate().isNotEmpty || settingsByIcon.evaluate().isNotEmpty,
    isTrue,
    reason: 'Expected home settings trigger to be visible',
  );

  await tester.tap(
    settingsByKey.evaluate().isNotEmpty ? settingsByKey : settingsByIcon.first,
    warnIfMissed: false,
  );
  await _pumpFor(tester, const Duration(seconds: 1));

  return waitForText(tester, 'Settings', timeout: const Duration(seconds: 8));
}

/// Complete wizard through all steps (occasion -> relationship -> tone -> final)
Future<bool> completeWizard(
  WidgetTester tester, {
  String occasion = 'Birthday',
  String relationship = 'Close Friend',
  String tone = 'Heartfelt',
}) async {
  final occasionVisible =
      find.text(occasion).evaluate().isNotEmpty ||
      await scrollToText(tester, occasion);
  expect(
    occasionVisible,
    isTrue,
    reason: 'Expected occasion "$occasion" to be visible in wizard flow',
  );

  await tester.tap(find.text(occasion));
  await _pumpFor(tester, const Duration(seconds: 1));

  final relationshipVisible =
      find.text(relationship).evaluate().isNotEmpty ||
      await scrollToText(tester, relationship);
  expect(
    relationshipVisible,
    isTrue,
    reason:
        'Expected relationship "$relationship" to be visible in wizard flow',
  );
  await tester.tap(find.text(relationship));
  await _pumpFor(tester, const Duration(seconds: 1));

  expect(
    find.text('Continue').evaluate().isNotEmpty,
    isTrue,
    reason: 'Expected Continue button after relationship selection',
  );
  await tester.tap(find.text('Continue'));
  await _pumpFor(tester, const Duration(seconds: 1));

  final toneVisible =
      find.text(tone).evaluate().isNotEmpty || await scrollToText(tester, tone);
  expect(
    toneVisible,
    isTrue,
    reason: 'Expected tone "$tone" to be visible in wizard flow',
  );
  await tester.tap(find.text(tone));
  await _pumpFor(tester, const Duration(seconds: 1));

  expect(
    find.text('Continue').evaluate().isNotEmpty,
    isTrue,
    reason: 'Expected Continue button after tone selection',
  );
  await tester.tap(find.text('Continue'));
  await _pumpFor(tester, const Duration(seconds: 1));

  // Check final step
  final reachedFinalStep =
      find.text('Generate Messages').evaluate().isNotEmpty ||
      find.text('Upgrade to Continue').evaluate().isNotEmpty;
  expect(
    reachedFinalStep,
    isTrue,
    reason: 'Expected wizard to reach Generate or Upgrade action on final step',
  );
  return reachedFinalStep;
}

/// Navigate to auth screen via upgrade path
Future<bool> navigateToAuth(WidgetTester tester) async {
  final atHome = await navigateToHome(tester, seedFreeTierUsed: true);
  expect(
    atHome,
    isTrue,
    reason: 'Expected to reach home before navigating to auth',
  );
  await completeWizardOrFail(tester);

  if (find.text('Upgrade to Continue').evaluate().isNotEmpty) {
    await tester.tap(find.text('Upgrade to Continue'));
    await _pumpFor(tester, const Duration(seconds: 2));
    final reachedAuth =
        find.text('Sign in with Google').evaluate().isNotEmpty ||
        find.text('Sign in with Apple').evaluate().isNotEmpty;
    expect(
      reachedAuth,
      isTrue,
      reason: 'Expected upgrade flow to reach auth providers',
    );
    return reachedAuth;
  }

  fail('Expected Upgrade to Continue CTA after exhausting free tier');
}

/// Check if element exists
bool exists(Finder finder) => finder.evaluate().isNotEmpty;

/// Assert that at least one text from [texts] is visible.
void expectAnyTextVisible(List<String> texts, {required String reason}) {
  expect(anyTextExists(texts), isTrue, reason: reason);
}

/// Assert that [text] is visible (scrolling if needed) and tap it.
Future<void> tapTextOrFail(
  WidgetTester tester,
  String text, {
  Duration settleDuration = const Duration(seconds: 1),
  String? reason,
}) async {
  final visible =
      find.text(text).evaluate().isNotEmpty || await scrollToText(tester, text);
  expect(visible, isTrue, reason: reason ?? 'Expected "$text" to be visible');
  await tester.tap(find.text(text).first);
  await _pumpFor(tester, settleDuration);
}

/// Assert that the wizard reaches final step and expose Generate/Upgrade action.
Future<void> completeWizardOrFail(
  WidgetTester tester, {
  String occasion = 'Birthday',
  String relationship = 'Close Friend',
  String tone = 'Heartfelt',
}) async {
  final completed = await completeWizard(
    tester,
    occasion: occasion,
    relationship: relationship,
    tone: tone,
  );
  expect(completed, isTrue, reason: 'Wizard did not reach final step');
  expectAnyTextVisible([
    'Generate Messages',
    'Upgrade to Continue',
  ], reason: 'Wizard final step must show Generate or Upgrade action');
}

/// Check if any of the given texts exist
bool anyTextExists(List<String> texts) =>
    texts.any((text) => find.text(text).evaluate().isNotEmpty);

/// Wait until [text] appears, polling for up to [timeout].
Future<bool> waitForText(
  WidgetTester tester,
  String text, {
  Duration timeout = const Duration(seconds: 10),
  Duration pollInterval = const Duration(milliseconds: 250),
}) => _waitForFinder(
  tester,
  find.text(text),
  timeout: timeout,
  pollInterval: pollInterval,
);

/// Wait until any text in [texts] appears, polling for up to [timeout].
Future<bool> waitForAnyText(
  WidgetTester tester,
  List<String> texts, {
  Duration timeout = const Duration(seconds: 10),
  Duration pollInterval = const Duration(milliseconds: 250),
}) async {
  final intervalMs = pollInterval.inMilliseconds;
  final safeIntervalMs = intervalMs <= 0 ? 1 : intervalMs;
  final maxAttempts = timeout.inMilliseconds ~/ safeIntervalMs;
  for (var attempt = 0; attempt < maxAttempts; attempt++) {
    if (anyTextExists(texts)) {
      return true;
    }
    await _pumpFor(tester, pollInterval);
  }
  return anyTextExists(texts);
}

/// Scroll until text is visible, returns true if found
Future<bool> scrollToText(
  WidgetTester tester,
  String text, {
  double delta = 200,
  int maxScrolls = 10,
}) async {
  final target = find.text(text);
  if (target.evaluate().isNotEmpty) {
    return true;
  }

  final scrollables = find.byType(Scrollable);
  if (scrollables.evaluate().isEmpty) {
    return false;
  }

  final scrollable = scrollables.first;
  for (var attempt = 0; attempt < maxScrolls; attempt++) {
    await tester.drag(scrollable, Offset(0, -delta));
    await _pumpFor(tester, const Duration(milliseconds: 300));
    if (target.evaluate().isNotEmpty) {
      return true;
    }
  }

  return target.evaluate().isNotEmpty;
}

/// Tap back button if visible
Future<bool> tapBack(WidgetTester tester) async {
  final standardBack = find.byIcon(Icons.arrow_back);
  final chevronBack = find.byIcon(Icons.chevron_left_rounded);
  if (standardBack.evaluate().isNotEmpty) {
    await tester.tap(standardBack);
    await _pumpFor(tester, const Duration(seconds: 1));
    return true;
  }
  if (chevronBack.evaluate().isNotEmpty) {
    await tester.tap(chevronBack);
    await _pumpFor(tester, const Duration(seconds: 1));
    return true;
  }
  return false;
}

Future<void> _resetPersistentState({
  bool seedFreeTierUsed = false,
  bool seedOnboardingCompleted = false,
}) async {
  // Use real plugin storage for device integration runs.
  // Mock initial-values helpers are unit/widget-test oriented and can leak
  // stale state across wired runs.
  final prefs = await SharedPreferences.getInstance();
  await prefs.clear();
  await prefs.setBool(
    PreferenceKeys.hasCompletedOnboarding,
    seedOnboardingCompleted,
  );
  await prefs.setBool(PreferenceKeys.hasSeenFirstActionHint, false);
  await prefs.setBool(PreferenceKeys.analyticsEnabled, false);
  await prefs.setInt(PreferenceKeys.usageTotalCount, seedFreeTierUsed ? 1 : 0);
  await prefs.setBool(PreferenceKeys.usageDeviceUsedFreeTier, seedFreeTierUsed);

  const secureStorage = FlutterSecureStorage();
  await secureStorage.deleteAll();

  // Keep launch deterministic in smoke/journey tests.
  await BiometricService.instance.setEnabled(false);
}

Future<bool> _waitForFinder(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 10),
  Duration pollInterval = const Duration(milliseconds: 250),
}) async {
  final intervalMs = pollInterval.inMilliseconds;
  final safeIntervalMs = intervalMs <= 0 ? 1 : intervalMs;
  final maxAttempts = timeout.inMilliseconds ~/ safeIntervalMs;
  for (var attempt = 0; attempt < maxAttempts; attempt++) {
    if (finder.evaluate().isNotEmpty) return true;
    await _pumpFor(tester, pollInterval);
  }
  return finder.evaluate().isNotEmpty;
}

Future<void> _pumpFor(WidgetTester tester, Duration duration) async {
  await tester.pump(duration);
}
