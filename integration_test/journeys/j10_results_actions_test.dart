/// Journey 10: Results Screen Actions
///
/// Keeps the two results actions with a concrete bug target:
/// 1. Copy must show explicit confirmation.
/// 2. Start Over must return to home.
library;

import 'package:flutter_test/flutter_test.dart';
import '_helpers.dart';

void main() {
  initBinding();

  group('Journey 10: Results Actions', () {
    Future<void> navigateToResults(WidgetTester tester) async {
      final atHome = await navigateToHome(tester);
      expect(atHome, isTrue, reason: 'Failed to navigate to home');

      await completeWizardOrFail(tester);
      await tapTextOrFail(
        tester,
        'Generate Messages',
        settleDuration: const Duration(seconds: 15),
        reason: 'Generate Messages button not found on final wizard step',
      );

      final terminalState = await waitForCheckpoint(tester, {
        'results': ['Your Messages', 'Option 1'],
        'error': ['error', 'Unable'],
      });

      expect(
        terminalState,
        equals('results'),
        reason:
            'Results-actions journey requires generated messages, but generation ended without a results surface',
      );
    }

    testWidgets('J10.3: Copy first option shows confirmation', (tester) async {
      await navigateToResults(tester);

      expect(
        exists(find.text('Copy')),
        isTrue,
        reason: 'Copy action not found',
      );
      await tester.tap(find.text('Copy').first);
      await tester.pumpAndSettle();

      expect(
        exists(find.text('Copied!')),
        isTrue,
        reason: 'Should show Copied! confirmation',
      );

      await screenshot(tester, 'j10_3_copied_confirmation');
    });

    testWidgets('J10.6: Start Over returns to the home picker', (tester) async {
      await navigateToResults(tester);

      expect(
        exists(find.text('Start Over')),
        isTrue,
        reason: 'Start Over action should be present on results screen',
      );
      await tester.tap(find.text('Start Over'));
      await tester.pumpAndSettle();

      expect(
        anyTextExists(["What's the occasion?", 'Birthday']),
        isTrue,
        reason: 'Should return to home',
      );

      await screenshot(tester, 'j10_6_start_over');
    });
  });
}
