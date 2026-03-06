library;

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:prosepal/core/config/preference_keys.dart';
import 'package:prosepal/core/services/biometric_service.dart';
import 'package:prosepal/main.dart' as app;
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  patrolTest('saving first occasion can grant native notification permission', (
    $,
  ) async {
    await _resetPersistentState();

    app.main();
    await $.tester.pump();

    final reachedReadySurface = await _waitForAnyText($.tester, const [
      'Continue',
      'Get Started',
      'Birthday',
      "What's the occasion?",
    ]);
    expect(
      reachedReadySurface,
      isTrue,
      reason: 'App did not reach onboarding or home after launch',
    );

    await _skipOnboardingIfNeeded($);

    expect(
      find.text('Birthday').evaluate().isNotEmpty ||
          find.text("What's the occasion?").evaluate().isNotEmpty,
      isTrue,
      reason: 'Expected to reach home before opening calendar',
    );

    await $(Icons.calendar_month_outlined).tap();
    await $.tester.pumpAndSettle();

    await $('Add Your First Occasion').tap();
    await $.tester.pumpAndSettle();

    expect(
      find.text('Add Occasion').evaluate().isNotEmpty,
      isTrue,
      reason: 'Expected add occasion sheet to be visible',
    );

    await $('Add to Calendar').tap();
    await $.tester.pump(const Duration(seconds: 1));

    final permissionDialogVisible = await $.platform.mobile
        .isPermissionDialogVisible(timeout: const Duration(seconds: 5));
    if (permissionDialogVisible) {
      await $.platform.mobile.grantPermissionWhenInUse();
    }

    await $.tester.pumpAndSettle(const Duration(seconds: 5));

    expect(
      find.text('No upcoming occasions').evaluate().isEmpty,
      isTrue,
      reason: 'Expected saved occasion to replace empty calendar state',
    );
    expect(
      find.text('Birthday').evaluate().isNotEmpty,
      isTrue,
      reason: 'Expected saved Birthday occasion to be visible in calendar',
    );
  });
}

Future<void> _resetPersistentState() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.clear();
  await prefs.setBool(PreferenceKeys.hasCompletedOnboarding, false);
  await prefs.setBool(PreferenceKeys.hasSeenFirstActionHint, false);
  await prefs.setBool(PreferenceKeys.analyticsEnabled, false);
  await prefs.setInt(PreferenceKeys.usageTotalCount, 0);
  await prefs.setBool(PreferenceKeys.usageDeviceUsedFreeTier, false);

  const secureStorage = FlutterSecureStorage();
  await secureStorage.deleteAll();

  await BiometricService.instance.setEnabled(false);
}

Future<void> _skipOnboardingIfNeeded(PatrolIntegrationTester $) async {
  for (var page = 0; page < 10; page++) {
    await $.tester.pump(const Duration(milliseconds: 400));

    if (find.text('Birthday').evaluate().isNotEmpty ||
        find.text("What's the occasion?").evaluate().isNotEmpty) {
      return;
    }

    if (find.text('Get Started').evaluate().isNotEmpty) {
      await $('Get Started').tap();
      await $.tester.pumpAndSettle(const Duration(seconds: 2));
      return;
    }

    if (find.text('Continue').evaluate().isNotEmpty) {
      await $('Continue').tap();
      await $.tester.pumpAndSettle(const Duration(seconds: 1));
    }
  }

  fail('Expected onboarding to reach home within 10 steps');
}

Future<bool> _waitForAnyText(
  WidgetTester tester,
  List<String> texts, {
  Duration timeout = const Duration(seconds: 20),
  Duration pollInterval = const Duration(milliseconds: 250),
}) async {
  final maxAttempts =
      timeout.inMilliseconds ~/
      (pollInterval.inMilliseconds <= 0 ? 1 : pollInterval.inMilliseconds);

  for (var attempt = 0; attempt < maxAttempts; attempt++) {
    if (texts.any((text) => find.text(text).evaluate().isNotEmpty)) {
      return true;
    }
    await tester.pump(pollInterval);
  }

  return texts.any((text) => find.text(text).evaluate().isNotEmpty);
}
