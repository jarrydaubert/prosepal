/// Journey 1: Fresh Install → Free Generation
///
/// Keeps only the highest-signal checks from the first-time user path:
/// 1. Onboarding reaches a valid post-onboarding surface.
/// 2. A fresh user can complete generation and reach a concrete result/error state.
library;

import 'package:flutter_test/flutter_test.dart';
import '_helpers.dart';

void main() {
  initBinding();

  group('Journey 1: Fresh Install → Free Generation', () {
    testWidgets('J1.2: Onboarding completes to a valid post-onboarding route', (
      tester,
    ) async {
      await launchApp(tester);
      await skipOnboarding(tester);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      expect(
        anyTextExists([
          'Sign in with Google',
          'Sign in with Apple',
          'Birthday',
          "What's the occasion?",
        ]),
        isTrue,
        reason: 'Should reach auth or home after onboarding',
      );

      await screenshot(tester, 'j1_2_after_onboarding');
    });

    testWidgets(
      'J1.8: Fresh user can generate and reach a concrete end state',
      (tester) async {
        final atHome = await navigateToHome(tester);
        expect(atHome, isTrue, reason: 'Failed to navigate to home');

        await completeWizardOrFail(tester);
        expect(find.text('Generate Messages'), findsOneWidget);
        await tester.tap(find.text('Generate Messages'));
        await tester.pumpAndSettle(const Duration(seconds: 15));

        expect(
          anyTextExists(['Your Messages', 'Option 1', 'error', 'Unable']),
          isTrue,
          reason: 'Generation should end in a visible results or error state',
        );

        await screenshot(tester, 'j1_8_generation_result');
      },
    );
  });
}
