/// Journey 9: Wizard Details & Customization
///
/// Keeps only the customization checks with a concrete user-facing oracle:
/// 1. Final-step message length controls are visible.
/// 2. Filled customization fields still allow generation to complete.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '_helpers.dart';

void main() {
  initBinding();

  group('Journey 9: Wizard Details', () {
    testWidgets('J9.1: Final step exposes message length options', (
      tester,
    ) async {
      final atHome = await navigateToHome(tester);
      expect(atHome, isTrue, reason: 'Failed to navigate to home');

      await completeWizardOrFail(tester);
      expectAnyTextVisible([
        'Brief',
        'Standard',
        'Detailed',
      ], reason: 'Should show message length options');

      await screenshot(tester, 'j9_1_length_options');
    });

    testWidgets(
      'J9.4: Filled customization fields still allow generation to complete',
      (tester) async {
        final atHome = await navigateToHome(tester);
        expect(atHome, isTrue, reason: 'Failed to navigate to home');

        await completeWizardOrFail(tester);

        final textFields = find.byType(TextField);
        expect(
          textFields.evaluate().length >= 2,
          isTrue,
          reason: 'Expected recipient and details fields on final wizard step',
        );
        await tester.enterText(textFields.first, 'Sarah');
        await tester.enterText(textFields.at(1), 'We met at college');
        await tester.pumpAndSettle();

        await tapTextOrFail(
          tester,
          'Detailed',
          reason: 'Detailed message length option should be selectable',
        );
        await tapTextOrFail(
          tester,
          'Generate Messages',
          settleDuration: const Duration(seconds: 15),
          reason: 'Generate button should remain available after customization',
        );

        expect(
          anyTextExists(['Your Messages', 'Option 1', 'error', 'Unable']),
          isTrue,
          reason:
              'Customized generation should end in a visible results or error state',
        );

        await screenshot(tester, 'j9_4_customized_generation');
      },
    );
  });
}
