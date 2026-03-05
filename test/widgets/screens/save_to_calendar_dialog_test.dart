import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:prosepal/core/models/models.dart';
import 'package:prosepal/core/providers/providers.dart';
import 'package:prosepal/core/services/calendar_service.dart';
import 'package:prosepal/core/services/notification_service.dart';
import 'package:prosepal/features/results/save_to_calendar_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockCalendarService extends Mock implements CalendarService {}

class _MockNotificationService extends Mock implements NotificationService {}

class _DialogHost extends StatefulWidget {
  const _DialogHost({required this.result});

  final GenerationResult result;

  @override
  State<_DialogHost> createState() => _DialogHostState();
}

class _DialogHostState extends State<_DialogHost> {
  bool? _dialogResult;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final result = await showDialog<bool>(
        context: context,
        builder: (context) => SaveToCalendarDialog(result: widget.result),
      );
      if (mounted) {
        setState(() => _dialogResult = result);
      }
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(child: Text('dialog_result:${_dialogResult ?? 'pending'}')),
  );
}

void main() {
  late SharedPreferences prefs;
  late _MockCalendarService calendarService;
  late _MockNotificationService notificationService;
  late SavedOccasion savedOccasion;
  late GenerationResult generationResult;

  setUpAll(() {
    registerFallbackValue(DateTime.utc(2026));
    registerFallbackValue(Occasion.birthday);
    registerFallbackValue(Relationship.closeFriend);
    registerFallbackValue(
      SavedOccasion(
        id: 'fallback',
        occasion: Occasion.birthday,
        date: DateTime.utc(2026, 3),
        createdAt: DateTime.utc(2026, 3),
      ),
    );
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    calendarService = _MockCalendarService();
    notificationService = _MockNotificationService();

    savedOccasion = SavedOccasion(
      id: 'saved-1',
      occasion: Occasion.birthday,
      date: DateTime.now().add(const Duration(days: 10)),
      recipientName: 'Mom',
      relationship: Relationship.closeFriend,
      createdAt: DateTime.now().toUtc(),
    );

    generationResult = GenerationResult(
      occasion: Occasion.birthday,
      relationship: Relationship.closeFriend,
      tone: Tone.heartfelt,
      length: MessageLength.standard,
      recipientName: 'Mom',
      messages: [
        GeneratedMessage(
          id: 'g1',
          text: 'Happy birthday!',
          occasion: Occasion.birthday,
          relationship: Relationship.closeFriend,
          tone: Tone.heartfelt,
          createdAt: DateTime.now().toUtc(),
          recipientName: 'Mom',
        ),
      ],
    );

    when(
      () => calendarService.saveOccasion(
        occasion: any(named: 'occasion'),
        date: any(named: 'date'),
        recipientName: any(named: 'recipientName'),
        relationship: any(named: 'relationship'),
        reminderEnabled: any(named: 'reminderEnabled'),
      ),
    ).thenAnswer((_) async => savedOccasion);

    when(() => notificationService.notificationsEnabled).thenReturn(false);
    when(() => notificationService.hasAskedPermission).thenReturn(false);
    when(
      () => notificationService.requestPermission(),
    ).thenAnswer((_) async => false);
    when(
      () => notificationService.scheduleReminder(any()),
    ).thenAnswer((_) async {});
  });

  Widget buildApp() => ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      calendarServiceProvider.overrideWithValue(calendarService),
      notificationServiceProvider.overrideWithValue(notificationService),
    ],
    child: MaterialApp(home: _DialogHost(result: generationResult)),
  );

  testWidgets('dismisses with false and increments dismissal count', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(find.text('Save to Calendar?'), findsOneWidget);

    await tester.tap(find.text('Not Now'));
    await tester.pumpAndSettle();

    expect(find.text('dialog_result:false'), findsOneWidget);
    expect(prefs.getInt('calendar_dialog_dismissed_count'), 1);
  });

  testWidgets('saves without reminder scheduling when reminder toggle is off', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    verify(
      () => calendarService.saveOccasion(
        occasion: Occasion.birthday,
        date: any(named: 'date'),
        recipientName: 'Mom',
        relationship: Relationship.closeFriend,
        reminderEnabled: false,
      ),
    ).called(1);
    verifyNever(() => notificationService.requestPermission());
    verifyNever(() => notificationService.scheduleReminder(any()));
    expect(find.text('dialog_result:true'), findsOneWidget);
  });

  testWidgets(
    'requests permission but skips scheduling when permission is denied',
    (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      verify(() => notificationService.requestPermission()).called(1);
      verifyNever(() => notificationService.scheduleReminder(any()));
      expect(find.text('dialog_result:true'), findsOneWidget);
    },
  );

  testWidgets(
    'schedules reminder when permission request enables notifications',
    (tester) async {
      var enabled = false;
      when(
        () => notificationService.notificationsEnabled,
      ).thenAnswer((_) => enabled);
      when(() => notificationService.requestPermission()).thenAnswer((_) async {
        enabled = true;
        return true;
      });

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      verify(() => notificationService.requestPermission()).called(1);
      verify(
        () => notificationService.scheduleReminder(savedOccasion),
      ).called(1);
      expect(find.text('dialog_result:true'), findsOneWidget);
    },
  );

  testWidgets('keeps dialog open after save failure for retry', (tester) async {
    when(
      () => calendarService.saveOccasion(
        occasion: any(named: 'occasion'),
        date: any(named: 'date'),
        recipientName: any(named: 'recipientName'),
        relationship: any(named: 'relationship'),
        reminderEnabled: any(named: 'reminderEnabled'),
      ),
    ).thenThrow(Exception('save failed'));

    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('Save to Calendar?'), findsOneWidget);
    expect(find.text('dialog_result:pending'), findsOneWidget);
  });
}
