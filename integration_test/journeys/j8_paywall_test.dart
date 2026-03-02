/// Journey 8: Paywall & Purchase Flow
///
/// Tests the paywall screen and purchase path:
/// 1. Paywall displays correctly
/// 2. Pricing visible
/// 3. Purchase buttons work
/// 4. Terms/Privacy links
///
/// Note: Actual purchase requires StoreKit sandbox (manual test)
///
/// Expected logs:
/// - [INFO] Paywall shown
/// - [INFO] Paywall offerings loaded
/// - [INFO] Purchase initiated (manual)
library;

import 'package:flutter_test/flutter_test.dart';
import '_helpers.dart';

void main() {
  initBinding();

  group('Journey 8: Paywall', () {
    Future<void> openPaywallFromSettings(WidgetTester tester) async {
      final atSettings = await navigateToSettings(tester);
      expect(atSettings, isTrue, reason: 'Failed to navigate to settings');

      var triggerLabel = '';
      if (await scrollToText(tester, 'Upgrade')) {
        triggerLabel = 'Upgrade';
      } else if (await scrollToText(tester, 'Go Pro')) {
        triggerLabel = 'Go Pro';
      }

      expect(
        triggerLabel.isNotEmpty,
        isTrue,
        reason: 'Expected Upgrade or Go Pro trigger in settings',
      );

      await tapTextOrFail(
        tester,
        triggerLabel,
        settleDuration: const Duration(seconds: 3),
        reason: 'Failed to tap "$triggerLabel" paywall trigger',
      );
    }

    testWidgets('J8.1: Paywall accessible via upgrade button', (tester) async {
      final atHome = await navigateToHome(tester, seedFreeTierUsed: true);
      expect(atHome, isTrue, reason: 'Failed to navigate to home');

      await completeWizardOrFail(tester);
      await tapTextOrFail(
        tester,
        'Upgrade to Continue',
        settleDuration: const Duration(seconds: 3),
        reason: 'Expected Upgrade to Continue CTA on exhausted free tier',
      );

      // Should show auth or paywall
      final atAuth = anyTextExists([
        'Sign in with Apple',
        'Sign in with Google',
      ]);
      final atPaywall = anyTextExists(['Subscribe', 'Pro', 'month', 'year']);

      expect(
        atAuth || atPaywall,
        isTrue,
        reason: 'Upgrade flow should reach auth or paywall',
      );

      await screenshot(tester, 'j8_1_upgrade_destination');
    });

    testWidgets('J8.2: Paywall shows pricing options', (tester) async {
      await openPaywallFromSettings(tester);

      // Check for pricing elements
      final hasPricing =
          find.textContaining(r'$').evaluate().isNotEmpty ||
          find.textContaining('month').evaluate().isNotEmpty ||
          find.textContaining('year').evaluate().isNotEmpty;
      expect(hasPricing, isTrue, reason: 'Paywall should show visible pricing');

      await screenshot(tester, 'j8_2_paywall_pricing');
    });

    testWidgets('J8.3: Paywall has restore purchases link', (tester) async {
      await openPaywallFromSettings(tester);

      // Look for restore option on paywall
      final hasRestore =
          exists(find.text('Restore')) ||
          find.textContaining('restore').evaluate().isNotEmpty;
      expect(
        hasRestore,
        isTrue,
        reason: 'Paywall should expose restore action',
      );

      await screenshot(tester, 'j8_3_paywall_restore');
    });

    testWidgets('J8.4: Paywall shows feature benefits', (tester) async {
      await openPaywallFromSettings(tester);

      // Should show benefits/features
      final hasBenefits = anyTextExists([
        'Unlimited',
        'unlimited',
        '500',
        'messages',
        'Pro',
      ]);
      expect(
        hasBenefits,
        isTrue,
        reason: 'Paywall should show feature benefits',
      );

      await screenshot(tester, 'j8_4_paywall_benefits');
    });
  });
}
