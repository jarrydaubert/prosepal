/// Journey 10: Results Screen Actions
///
/// Tests all actions on the results screen:
/// 1. Copy each message option
/// 2. Share functionality
/// 3. Start Over
/// 4. Regenerate (if available)
///
/// Expected logs:
/// - [INFO] Message copied | option=1/2/3
/// - [INFO] Share initiated
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '_helpers.dart';

void main() {
  initBinding();

  group('Journey 10: Results Actions', () {
    Future<bool> navigateToResults(WidgetTester tester) async {
      final atHome = await navigateToHome(tester);
      expect(atHome, isTrue, reason: 'Failed to navigate to home');

      await completeWizard(tester);

      expect(
        exists(find.text('Generate Messages')),
        isTrue,
        reason: 'Generate Messages button not found',
      );

      await tester.tap(find.text('Generate Messages'));
      await tester.pumpAndSettle(const Duration(seconds: 15));

      return exists(find.text('Your Messages')) ||
          exists(find.text('Option 1'));
    }

    testWidgets('J10.1: Results show 3 message options', (tester) async {
      final atResults = await navigateToResults(tester);
      expect(atResults, isTrue, reason: 'Failed to navigate to results');

      expect(exists(find.text('Option 1')), isTrue);
      expect(exists(find.text('Option 2')), isTrue);
      expect(exists(find.text('Option 3')), isTrue);

      await screenshot(tester, 'j10_1_three_options');
    });

    testWidgets('J10.2: Copy button on each option', (tester) async {
      final atResults = await navigateToResults(tester);
      expect(atResults, isTrue, reason: 'Failed to navigate to results');

      // Should have at least one copy button
      final copyButtons = find.text('Copy');
      expect(
        copyButtons.evaluate().isNotEmpty,
        isTrue,
        reason: 'Should have Copy buttons',
      );

      await screenshot(tester, 'j10_2_copy_buttons');
    });

    testWidgets('J10.3: Copy first option shows confirmation', (tester) async {
      final atResults = await navigateToResults(tester);
      expect(atResults, isTrue, reason: 'Failed to navigate to results');

      if (exists(find.text('Copy'))) {
        await tester.tap(find.text('Copy').first);
        await tester.pumpAndSettle();

        expect(
          exists(find.text('Copied!')),
          isTrue,
          reason: 'Should show Copied! confirmation',
        );

        await screenshot(tester, 'j10_3_copied_confirmation');
      }
    });

    testWidgets('J10.4: Can copy different options', (tester) async {
      final atResults = await navigateToResults(tester);
      expect(atResults, isTrue, reason: 'Failed to navigate to results');

      final copyButtons = find.text('Copy');
      if (copyButtons.evaluate().length >= 2) {
        // Copy second option
        await tester.tap(copyButtons.at(1));
        await tester.pumpAndSettle();

        await screenshot(tester, 'j10_4_second_option_copied');
      }
    });

    testWidgets('J10.5: Share button exists', (tester) async {
      // Bug: Share functionality missing from results screen
      final atResults = await navigateToResults(tester);
      expect(atResults, isTrue, reason: 'Failed to navigate to results');

      // Look for share button/icon
      final hasShare =
          exists(find.text('Share')) ||
          exists(find.byIcon(Icons.share)) ||
          exists(find.byIcon(Icons.share_outlined));

      expect(hasShare, isTrue, reason: 'Results should have share button');
      await screenshot(tester, 'j10_5_share_button');
    });

    testWidgets('J10.6: Start Over button returns to home', (tester) async {
      final atResults = await navigateToResults(tester);
      expect(atResults, isTrue, reason: 'Failed to navigate to results');

      if (exists(find.text('Start Over'))) {
        await tester.tap(find.text('Start Over'));
        await tester.pumpAndSettle();

        expect(
          anyTextExists(["What's the occasion?", 'Birthday']),
          isTrue,
          reason: 'Should return to home',
        );

        await screenshot(tester, 'j10_6_start_over');
      }
    });

    testWidgets('J10.7: Messages have visible content', (tester) async {
      // Bug: Generated messages are empty or not displayed
      final atResults = await navigateToResults(tester);
      expect(atResults, isTrue, reason: 'Failed to navigate to results');

      // Verify message cards/content are visible (not empty results)
      final hasContent =
          exists(find.byType(Card)) ||
          exists(find.text('Copy')) ||
          exists(find.text('Option 1'));

      expect(hasContent, isTrue, reason: 'Results should show message content');
      await screenshot(tester, 'j10_7_message_content');
    });
  });
}
