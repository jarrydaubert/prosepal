import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prosepal/core/providers/providers.dart';
import 'package:prosepal/core/services/feedback_service.dart';
import 'package:prosepal/features/settings/feedback_screen.dart';
import 'package:prosepal/shared/theme/app_colors.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../mocks/mock_subscription_service.dart';

void main() {
  late SharedPreferences prefs;
  late MockSubscriptionService mockSubscription;
  late _FakeFeedbackService fakeFeedbackService;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    mockSubscription = MockSubscriptionService();
    fakeFeedbackService = _FakeFeedbackService();
  });

  Widget buildTestWidget() => ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      subscriptionServiceProvider.overrideWithValue(mockSubscription),
      feedbackServiceProvider.overrideWithValue(fakeFeedbackService),
    ],
    child: const MaterialApp(home: FeedbackScreen()),
  );

  Widget buildRoutedTestWidget(_TestNavigatorObserver observer) =>
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          subscriptionServiceProvider.overrideWithValue(mockSubscription),
          feedbackServiceProvider.overrideWithValue(fakeFeedbackService),
        ],
        child: MaterialApp(
          navigatorObservers: [observer],
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const FeedbackScreen(),
                      ),
                    );
                  },
                  child: const Text('Open Feedback'),
                ),
              ),
            ),
          ),
        ),
      );

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

    expect(find.text('Include full technical details'), findsOneWidget);

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

  testWidgets('successful submit uses in-app delivery path', (tester) async {
    final observer = _TestNavigatorObserver();

    await tester.pumpWidget(buildRoutedTestWidget(observer));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Open Feedback'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Feature idea');
    await tester.pump();

    await tester.tap(find.widgetWithText(ElevatedButton, 'Send Feedback'));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(fakeFeedbackService.submitCallCount, 1);
    expect(fakeFeedbackService.lastMessage, 'Feature idea');
    expect(observer.popCount, 1);
    expect(find.text('Send manually'), findsNothing);
  });

  testWidgets('failed submit offers manual fallback actions', (tester) async {
    fakeFeedbackService.errorToThrow = const FeedbackSubmissionException(
      'Feedback delivery failed',
    );

    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Bug report');
    await tester.pump();

    await tester.tap(find.widgetWithText(ElevatedButton, 'Send Feedback'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Send manually'), findsOneWidget);
    expect(find.text('Feedback delivery failed'), findsOneWidget);
    expect(find.text('Copy feedback'), findsOneWidget);
    expect(find.text('Share feedback'), findsOneWidget);
  });

  testWidgets('manual fallback actions use readable contrast on dark sheet', (
    tester,
  ) async {
    fakeFeedbackService.errorToThrow = const FeedbackSubmissionException(
      'Feedback delivery failed',
    );

    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Bug report');
    await tester.pump();

    await tester.tap(find.widgetWithText(ElevatedButton, 'Send Feedback'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    final copyButton = tester.widget<OutlinedButton>(
      find.widgetWithText(OutlinedButton, 'Copy feedback'),
    );
    final shareButton = tester.widget<OutlinedButton>(
      find.widgetWithText(OutlinedButton, 'Share feedback'),
    );
    final cancelButton = tester.widget<TextButton>(
      find.widgetWithText(TextButton, 'Cancel'),
    );

    expect(
      copyButton.style?.foregroundColor?.resolve(<WidgetState>{}),
      AppColors.textPrimary,
    );
    expect(
      shareButton.style?.foregroundColor?.resolve(<WidgetState>{}),
      AppColors.textPrimary,
    );
    expect(
      cancelButton.style?.foregroundColor?.resolve(<WidgetState>{}),
      AppColors.primary,
    );
  });

  testWidgets('toggle labels use readable contrast colors', (tester) async {
    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    final diagnosticsLabel = tester.widget<Text>(
      find.text('Attach diagnostic summary'),
    );
    expect(diagnosticsLabel.style?.color, AppColors.textPrimary);

    await tester.tap(find.byType(Switch).first);
    await tester.pumpAndSettle();

    final technicalLabel = tester.widget<Text>(
      find.text('Include full technical details'),
    );
    expect(technicalLabel.style?.color, AppColors.textPrimary);
  });
}

class _FakeFeedbackService extends FeedbackService {
  _FakeFeedbackService() : super();

  int submitCallCount = 0;
  String? lastMessage;
  String? lastDiagnosticReport;
  bool? lastIncludeSensitiveLogs;
  Exception? errorToThrow;

  @override
  Future<void> submitFeedback({
    required String message,
    String? diagnosticReport,
    required bool includeSensitiveLogs,
  }) async {
    submitCallCount++;
    lastMessage = message;
    lastDiagnosticReport = diagnosticReport;
    lastIncludeSensitiveLogs = includeSensitiveLogs;

    final error = errorToThrow;
    if (error != null) throw error;
  }
}

class _TestNavigatorObserver extends NavigatorObserver {
  int popCount = 0;

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    popCount++;
    super.didPop(route, previousRoute);
  }
}
