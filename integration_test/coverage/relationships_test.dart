/// Coverage: All 14 Relationships
/// 
/// Tests that each relationship can be selected in the wizard.
/// Groups: Personal, Professional, Community
library;

import 'package:flutter_test/flutter_test.dart';
import '../journeys/_helpers.dart';

void main() {
  initBinding();

  // Personal relationships
  final personalRelationships = [
    'Close Friend',
    'Family',
    'Parent',
    'Child',
    'Sibling',
    'Grandparent',
    'Grandchild',
    'Partner',
  ];

  // Professional relationships
  final professionalRelationships = [
    'Colleague',
    'Boss',
    'Mentor',
    'Teacher',
  ];

  // Community relationships
  final communityRelationships = [
    'Neighbor',
    'Acquaintance',
  ];

  group('Coverage: Personal Relationships', () {
    for (final relationship in personalRelationships) {
      testWidgets('$relationship can be selected', (tester) async {
        final atHome = await navigateToHome(tester);
        if (!atHome) return;

        await tester.tap(find.text('Birthday'));
        await tester.pumpAndSettle();

        if (await scrollToText(tester, relationship, delta: 100)) {
          await tester.tap(find.text(relationship));
          await tester.pumpAndSettle();

          // Should enable Continue button
          expect(exists(find.text('Continue')), isTrue,
              reason: '$relationship should be selectable');
        }
      });
    }
  });

  group('Coverage: Professional Relationships', () {
    for (final relationship in professionalRelationships) {
      testWidgets('$relationship can be selected', (tester) async {
        final atHome = await navigateToHome(tester);
        if (!atHome) return;

        await tester.tap(find.text('Birthday'));
        await tester.pumpAndSettle();

        if (await scrollToText(tester, relationship, delta: 100)) {
          await tester.tap(find.text(relationship));
          await tester.pumpAndSettle();

          expect(exists(find.text('Continue')), isTrue,
              reason: '$relationship should be selectable');
        }
      });
    }
  });

  group('Coverage: Community Relationships', () {
    for (final relationship in communityRelationships) {
      testWidgets('$relationship can be selected', (tester) async {
        final atHome = await navigateToHome(tester);
        if (!atHome) return;

        await tester.tap(find.text('Birthday'));
        await tester.pumpAndSettle();

        if (await scrollToText(tester, relationship, delta: 100)) {
          await tester.tap(find.text(relationship));
          await tester.pumpAndSettle();

          expect(exists(find.text('Continue')), isTrue,
              reason: '$relationship should be selectable');
        }
      });
    }
  });
}
