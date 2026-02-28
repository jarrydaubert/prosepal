/// Coverage: All 9 Tones
///
/// Tests that each tone can be selected in the wizard.
library;

import 'package:flutter_test/flutter_test.dart';
import '../journeys/_helpers.dart';

void main() {
  initBinding();

  final allTones = [
    'Heartfelt',
    'Funny',
    'Formal',
    'Casual',
    'Playful',
    'Inspirational',
    'Sarcastic',
    'Nostalgic',
    'Poetic',
  ];

  group('Coverage: All Tones', () {
    for (final tone in allTones) {
      testWidgets('$tone can be selected', (tester) async {
        final atHome = await navigateToHome(tester);
        expect(atHome, isTrue, reason: 'Failed to navigate to home');

        // Navigate to tone step
        await tester.tap(find.text('Birthday'));
        await tester.pumpAndSettle();

        if (exists(find.text('Close Friend'))) {
          await tester.tap(find.text('Close Friend'));
          await tester.pumpAndSettle();
        }
        if (exists(find.text('Continue'))) {
          await tester.tap(find.text('Continue'));
          await tester.pumpAndSettle();
        }

        // Now on tone step
        if (await scrollToText(tester, tone, delta: 100)) {
          await tester.tap(find.text(tone));
          await tester.pumpAndSettle();

          expect(
            exists(find.text('Continue')),
            isTrue,
            reason: '$tone should be selectable',
          );
        }
      });
    }
  });

  group('Coverage: Tone with Different Occasions', () {
    final occasionTonePairs = [
      ('Wedding', 'Formal'),
      ('Birthday', 'Funny'),
      ('Sympathy', 'Heartfelt'),
      ('Graduation', 'Inspirational'),
      ('Thank You', 'Casual'),
    ];

    for (final (occasion, tone) in occasionTonePairs) {
      testWidgets('$occasion with $tone tone', (tester) async {
        final atHome = await navigateToHome(tester);
        expect(atHome, isTrue, reason: 'Failed to navigate to home');

        final completed = await completeWizard(
          tester,
          occasion: occasion,
          tone: tone,
        );

        expect(
          completed,
          isTrue,
          reason: '$occasion with $tone should complete wizard',
        );
      });
    }
  });
}
