import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prosepal/features/settings/legal_screen.dart';
import 'package:prosepal/shared/theme/app_colors.dart';

void main() {
  testWidgets('terms sections use light-surface text tokens', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: TermsScreen()));
    await tester.pumpAndSettle();

    final sectionTitle = tester.widget<Text>(find.text('Agreement to Terms'));
    final sectionBody = tester.widget<Text>(
      find.text(
        'By downloading or using Prosepal, you agree to be bound by these Terms of Use. If you do not agree to these terms, please do not use the app.',
      ),
    );

    expect(sectionTitle.style?.color, AppColors.textOnLight);
    expect(sectionBody.style?.color, AppColors.textOnLightSecondary);
  });

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

  testWidgets('privacy sections use light-surface text tokens', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: PrivacyScreen()));
    await tester.pumpAndSettle();

    final sectionTitle = tester.widget<Text>(find.text('Overview'));
    final sectionBody = tester.widget<Text>(
      find.text(
        'Prosepal is committed to protecting your privacy. This policy explains how we collect, use, and safeguard your information.',
      ),
    );

    expect(sectionTitle.style?.color, AppColors.textOnLight);
    expect(sectionBody.style?.color, AppColors.textOnLightSecondary);
  });
}
