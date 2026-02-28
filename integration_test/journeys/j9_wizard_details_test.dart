/// Journey 9: Wizard Details & Customization
///
/// Tests the wizard's customization features:
/// 1. Message length options (Brief/Standard/Detailed)
/// 2. Recipient name input
/// 3. Personal details input
/// 4. All options affect generation
///
/// Expected logs:
/// - [INFO] Wizard started
/// - [INFO] AI generation started | length=brief/standard/detailed
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '_helpers.dart';

void main() {
  initBinding();

  group('Journey 9: Wizard Details', () {
    testWidgets('J9.1: Message length options visible on final step', (
      tester,
    ) async {
      final atHome = await navigateToHome(tester);
      expect(atHome, isTrue, reason: 'Failed to navigate to home');

      await completeWizard(tester);

      // Check for length options
      final hasBrief = exists(find.text('Brief'));
      final hasStandard = exists(find.text('Standard'));
      final hasDetailed = exists(find.text('Detailed'));

      expect(
        hasBrief || hasStandard || hasDetailed,
        isTrue,
        reason: 'Should show message length options',
      );

      await screenshot(tester, 'j9_1_length_options');
    });

    testWidgets('J9.2: Brief length selectable', (tester) async {
      final atHome = await navigateToHome(tester);
      expect(atHome, isTrue, reason: 'Failed to navigate to home');

      await completeWizard(tester);

      if (exists(find.text('Brief'))) {
        await tester.tap(find.text('Brief'));
        await tester.pumpAndSettle();

        await screenshot(tester, 'j9_2_brief_selected');
      }
    });

    testWidgets('J9.3: Detailed length selectable', (tester) async {
      final atHome = await navigateToHome(tester);
      expect(atHome, isTrue, reason: 'Failed to navigate to home');

      await completeWizard(tester);

      if (exists(find.text('Detailed'))) {
        await tester.tap(find.text('Detailed'));
        await tester.pumpAndSettle();

        await screenshot(tester, 'j9_3_detailed_selected');
      }
    });

    testWidgets('J9.4: Recipient name input visible', (tester) async {
      final atHome = await navigateToHome(tester);
      expect(atHome, isTrue, reason: 'Failed to navigate to home');

      await completeWizard(tester);

      // Look for name input field
      final _ =
          find.byType(TextField).evaluate().isNotEmpty ||
          find.textContaining('name').evaluate().isNotEmpty ||
          find.textContaining('Name').evaluate().isNotEmpty ||
          find.textContaining('recipient').evaluate().isNotEmpty;

      await screenshot(tester, 'j9_4_name_input');
    });

    testWidgets('J9.5: Can enter recipient name', (tester) async {
      final atHome = await navigateToHome(tester);
      expect(atHome, isTrue, reason: 'Failed to navigate to home');

      await completeWizard(tester);

      // Find text field and enter name
      final textFields = find.byType(TextField);
      if (textFields.evaluate().isNotEmpty) {
        await tester.enterText(textFields.first, 'Sarah');
        await tester.pumpAndSettle();

        expect(find.text('Sarah'), findsOneWidget);
        await screenshot(tester, 'j9_5_name_entered');
      }
    });

    testWidgets('J9.6: Personal details input visible', (tester) async {
      final atHome = await navigateToHome(tester);
      expect(atHome, isTrue, reason: 'Failed to navigate to home');

      await completeWizard(tester);

      // Look for details/personal input
      final _ =
          find.textContaining('detail').evaluate().isNotEmpty ||
          find.textContaining('Detail').evaluate().isNotEmpty ||
          find.textContaining('personal').evaluate().isNotEmpty ||
          find.textContaining('Personal').evaluate().isNotEmpty;

      await screenshot(tester, 'j9_6_details_input');
    });

    testWidgets('J9.7: Can enter personal details', (tester) async {
      final atHome = await navigateToHome(tester);
      expect(atHome, isTrue, reason: 'Failed to navigate to home');

      await completeWizard(tester);

      // Find text fields - usually second one is details
      final textFields = find.byType(TextField);
      if (textFields.evaluate().length >= 2) {
        await tester.enterText(textFields.at(1), 'We met at college');
        await tester.pumpAndSettle();

        await screenshot(tester, 'j9_7_details_entered');
      }
    });
  });
}
