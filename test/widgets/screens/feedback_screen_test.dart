import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prosepal/core/providers/providers.dart';
import 'package:prosepal/features/settings/feedback_screen.dart';
import 'package:prosepal/shared/theme/app_colors.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../mocks/mock_subscription_service.dart';

void main() {
  late SharedPreferences prefs;
  late MockSubscriptionService mockSubscription;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    mockSubscription = MockSubscriptionService();
  });

  Widget buildTestWidget() => ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      subscriptionServiceProvider.overrideWithValue(mockSubscription),
    ],
    child: const MaterialApp(home: FeedbackScreen()),
  );

  testWidgets('shows feedback input and diagnostic toggle', (tester) async {
    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    expect(find.text('Send Feedback'), findsNWidgets(2));
    expect(find.text('Include diagnostic logs'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets('preserves typed feedback when diagnostics toggles change', (
    tester,
  ) async {
    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    const message = 'Details keep getting scrambled after toggling logs.';
    await tester.enterText(find.byType(TextField), message);
    await tester.pump();

    await tester.tap(find.byType(Switch).first);
    await tester.pumpAndSettle();

    expect(
      find.text('Include full technical details (advanced)'),
      findsOneWidget,
    );

    await tester.tap(find.byType(Switch).at(1));
    await tester.pumpAndSettle();

    expect(find.text('Include Full Technical Details?'), findsOneWidget);
    await tester.tap(find.text('Enable'));
    await tester.pumpAndSettle();

    expect(find.text(message), findsOneWidget);
  });

  testWidgets('send requires non-empty message', (tester) async {
    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ElevatedButton, 'Send Feedback'));
    await tester.pump();

    expect(find.text('Please enter a message'), findsOneWidget);
  });

  testWidgets('toggle labels use readable contrast colors', (tester) async {
    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    final diagnosticsLabel = tester.widget<Text>(
      find.text('Include diagnostic logs'),
    );
    expect(diagnosticsLabel.style?.color, AppColors.textPrimary);

    await tester.tap(find.byType(Switch).first);
    await tester.pumpAndSettle();

    final technicalLabel = tester.widget<Text>(
      find.text('Include full technical details (advanced)'),
    );
    expect(technicalLabel.style?.color, AppColors.textPrimary);
  });
}
