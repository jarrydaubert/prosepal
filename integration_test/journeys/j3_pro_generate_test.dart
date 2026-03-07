/// Journey 3: Pro User → Generate
///
/// Keeps the single highest-signal Pro assertion:
/// a Pro user reaches Generate (not Upgrade) and can complete a full
/// generation flow.
library;

import 'package:flutter_test/flutter_test.dart';
import '_helpers.dart';

void main() {
  initBinding();

  group('Journey 3: Pro User Flow', () {
    testWidgets('J3.6: Pro user reaches Generate and completes generation', (
      tester,
    ) async {
      final atHome = await navigateToHome(tester);
      expect(atHome, isTrue, reason: 'Failed to navigate to home');

      expect(exists(find.text('PRO')), isTrue, reason: 'PRO badge not found');

      await completeWizardOrFail(tester, occasion: 'Thank You', tone: 'Formal');
      expect(find.text('Generate Messages'), findsOneWidget);
      expect(find.text('Upgrade to Continue'), findsNothing);
      await tester.tap(find.text('Generate Messages'));
      await tester.pumpAndSettle(const Duration(seconds: 15));

      expect(
        anyTextExists(['Your Messages', 'Option 1']),
        isTrue,
        reason: 'Pro user should get generation results',
      );

      await screenshot(tester, 'j3_6_pro_generation');
    });
  });
}
