/// Smoke Test: quick sanity checks for app launch and core navigation.
///
/// Runs as a single journey to avoid cross-test state bleed on physical devices.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'journeys/_helpers.dart';

void main() {
  initBinding();

  group('Smoke Tests', () {
    testWidgets(
      'S1-S5: Launch, home, occasion, wizard, settings',
      (tester) async {
        // S1: app launches without crashing.
        await launchApp(tester, seedOnboardingCompleted: true);
        expect(find.byType(MaterialApp), findsOneWidget);
        await screenshot(tester, 'smoke_1_launch');

        // S2: home renders expected title/signals.
        final atHome = await waitForAnyText(tester, const [
          "What's the occasion?",
          'Birthday',
        ], timeout: const Duration(seconds: 12));
        expect(atHome, isTrue, reason: 'Failed to navigate to home');
        expect(find.text('Prosepal'), findsOneWidget);
        expect(find.text("What's the occasion?"), findsOneWidget);
        await screenshot(tester, 'smoke_2_home');

        // S3: at least one occasion is visible.
        if (find.text('Birthday').evaluate().isEmpty) {
          final foundBirthday = await scrollToText(tester, 'Birthday');
          expect(
            foundBirthday,
            isTrue,
            reason: 'Birthday occasion not visible',
          );
        }
        expect(find.text('Birthday'), findsOneWidget);
        await screenshot(tester, 'smoke_3_occasions');

        // S4: tapping occasion reaches wizard flow.
        await tester.tap(find.text('Birthday'));
        await _pumpForSmoke(tester, const Duration(seconds: 1));
        final reachedWizardStep = await waitForAnyText(tester, const [
          'Close Friend',
          'Family',
          'Heartfelt',
          'Generate Messages',
          'Upgrade to Continue',
        ], timeout: const Duration(seconds: 8));
        expect(
          reachedWizardStep,
          isTrue,
          reason: 'Wizard step did not appear after tapping occasion',
        );
        await screenshot(tester, 'smoke_4_navigation');

        // Return to home before settings assertion.
        final backedOut = await tapBack(tester);
        if (backedOut) {
          await _pumpForSmoke(tester, const Duration(seconds: 1));
        }

        // S5: settings button is accessible.
        final settingsByKey = find.byKey(
          const ValueKey('home_settings_button'),
        );
        final settingsByIcon = find.byIcon(Icons.settings_outlined);
        expect(
          settingsByKey.evaluate().isNotEmpty ||
              settingsByIcon.evaluate().isNotEmpty,
          isTrue,
          reason: 'Settings button not visible on home screen',
        );
        await tester.tap(
          settingsByKey.evaluate().isNotEmpty
              ? settingsByKey
              : settingsByIcon.first,
          warnIfMissed: false,
        );
        await _pumpForSmoke(tester, const Duration(seconds: 1));

        final atSettings = await waitForText(
          tester,
          'Settings',
          timeout: const Duration(seconds: 8),
        );
        expect(atSettings, isTrue, reason: 'Failed to navigate to settings');
        expect(find.text('Settings'), findsOneWidget);
        await screenshot(tester, 'smoke_5_settings');
      },
      timeout: const Timeout(Duration(seconds: 180)),
    );
  });
}

Future<void> _pumpForSmoke(WidgetTester tester, Duration duration) async {
  await tester.pump(duration);
}
