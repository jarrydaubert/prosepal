/// Journey 4: Settings & Account
///
/// Keeps only the explicit destructive-action oracle:
/// Delete Account must show the destructive warning or auth gate.
library;

import 'package:flutter_test/flutter_test.dart';
import '_helpers.dart';

void main() {
  initBinding();

  group('Journey 4: Settings & Account', () {
    testWidgets(
      'J4.10: Delete Account flow shows destructive warning or auth gate',
      (tester) async {
        final atSettings = await navigateToSettings(tester);
        expect(atSettings, isTrue, reason: 'Failed to navigate to settings');

        final hasDeleteAccount = await scrollToText(tester, 'Delete Account');
        final hasSignIn =
            !hasDeleteAccount && await scrollToText(tester, 'Sign In');

        expect(
          hasDeleteAccount || hasSignIn,
          isTrue,
          reason: 'Expected Delete Account action or Sign In gating action',
        );

        if (hasDeleteAccount) {
          await tester.tap(find.text('Delete Account'));
          await tester.pumpAndSettle();

          final hasWarning =
              exists(find.text('Delete')) ||
              exists(find.text('Cancel')) ||
              exists(find.textContaining('permanent')) ||
              exists(find.textContaining('sure'));

          expect(hasWarning, isTrue, reason: 'Should show delete confirmation');
        } else {
          await tester.tap(find.text('Sign In'));
          await tester.pumpAndSettle();
          expectAnyTextVisible([
            'Sign in with Google',
            'Sign in with Apple',
          ], reason: 'Sign In action should navigate to auth screen');
        }

        await screenshot(tester, 'j4_10_delete_warning');
      },
    );
  });
}
