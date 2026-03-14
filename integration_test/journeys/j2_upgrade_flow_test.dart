/// Journey 2: Return User → Upgrade → Purchase
///
/// Keeps the single high-signal anonymous upgrade assertion:
/// an exhausted free user must be routed into auth or paywall, not allowed to
/// continue generating.
library;

import 'package:flutter_test/flutter_test.dart';
import '_helpers.dart';

void main() {
  initBinding();

  group('Journey 2: Upgrade Flow', () {
    testWidgets('J2.2: Exhausted anonymous user is routed to auth or paywall', (
      tester,
    ) async {
      final atHome = await navigateToHome(tester, seedFreeTierUsed: true);
      expect(atHome, isTrue, reason: 'Failed to navigate to home');

      await completeWizardOrFail(tester);
      await tapTextOrFail(
        tester,
        'Upgrade to Continue',
        settleDuration: const Duration(seconds: 2),
        reason: 'Expected Upgrade gate for anonymous user with free tier used',
      );

      final destination = await waitForCheckpoint(tester, {
        'auth': ['Sign in with Apple', 'Sign in with Google'],
        'paywall': ['Continue Creating', 'Restore Purchases', 'Maybe Later'],
      });

      expect(
        destination,
        isNotNull,
        reason:
            'Upgrade flow should reach a named auth or paywall destination after the anonymous free-tier gate',
      );

      await screenshot(tester, 'j2_2_upgrade_destination');
    });
  });
}
