import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prosepal/features/settings/legal_screen.dart';
import 'package:prosepal/shared/theme/app_colors.dart';

void main() {
  testWidgets('terms metadata uses readable secondary text', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: TermsScreen()));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Last updated: December 28, 2025'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    final lastUpdated = tester.widget<Text>(
      find.byWidgetPredicate(
        (widget) =>
            widget is Text && widget.data == 'Last updated: December 28, 2025',
      ),
    );
    expect(lastUpdated.style?.color, AppColors.textSecondary);
  });

  testWidgets('privacy metadata uses readable secondary text', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: PrivacyScreen()));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Last updated: December 28, 2025'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    final lastUpdated = tester.widget<Text>(
      find.byWidgetPredicate(
        (widget) =>
            widget is Text && widget.data == 'Last updated: December 28, 2025',
      ),
    );
    expect(lastUpdated.style?.color, AppColors.textSecondary);
  });
}
