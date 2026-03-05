import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:prosepal/core/config/preference_keys.dart';
import 'package:prosepal/core/models/models.dart';
import 'package:prosepal/core/services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class _MockNotificationsPlugin extends Mock
    implements FlutterLocalNotificationsPlugin {}

void main() {
  late SharedPreferences prefs;

  setUpAll(() {
    tz.initializeTimeZones();
    registerFallbackValue(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
    );
    registerFallbackValue(
      const NotificationDetails(
        android: AndroidNotificationDetails('c', 'n'),
        iOS: DarwinNotificationDetails(),
      ),
    );
    registerFallbackValue(tz.TZDateTime.utc(2026));
    registerFallbackValue(AndroidScheduleMode.inexactAllowWhileIdle);
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  group('deterministic reminder ids', () {
    test('generates stable positive deterministic ids', () {
      final service = NotificationService(prefs);

      final first = service.deterministicNotificationIdForTesting(
        'occasion-alpha',
      );
      final second = service.deterministicNotificationIdForTesting(
        'occasion-alpha',
      );

      expect(first, greaterThan(0));
      expect(second, first);
    });

    test('persists mapped id across service restarts', () async {
      final serviceA = NotificationService(prefs);
      final idA = await serviceA.notificationIdForTesting('occasion-123');
      final serviceB = NotificationService(prefs);
      final idB = await serviceB.notificationIdForTesting('occasion-123');

      expect(idB, idA);
      expect(serviceB.storedNotificationIdForTesting('occasion-123'), idA);
    });

    test('resolves collisions by probing to next available id', () async {
      final service = NotificationService(prefs);
      final deterministic = service.deterministicNotificationIdForTesting(
        'collision-target',
      );
      await prefs.setString(
        'notification_id_map_v1',
        '{"existing":$deterministic}',
      );

      final assigned = await service.notificationIdForTesting(
        'collision-target',
      );

      expect(assigned, isNot(deterministic));
      expect(assigned, deterministic + 1);
    });
  });

  group('migration-safe cancellation', () {
    test(
      'cancels deterministic and legacy ids and clears stored mapping',
      () async {
        final plugin = _MockNotificationsPlugin();
        final cancelledIds = <int>[];
        when(
          () => plugin.initialize(
            settings: any(named: 'settings'),
            onDidReceiveNotificationResponse: any(
              named: 'onDidReceiveNotificationResponse',
            ),
          ),
        ).thenAnswer((_) async => true);
        when(() => plugin.cancel(id: any(named: 'id'))).thenAnswer((
          invocation,
        ) async {
          cancelledIds.add(invocation.namedArguments[#id]! as int);
        });

        final service = NotificationService(prefs, notifications: plugin);
        final mappedId = await service.notificationIdForTesting('occasion-321');
        final deterministicId = service.deterministicNotificationIdForTesting(
          'occasion-321',
        );
        final legacyId = service.legacyNotificationIdForTesting('occasion-321');

        await service.cancelReminder('occasion-321');

        expect(cancelledIds.toSet(), <int>{
          mappedId,
          deterministicId,
          legacyId,
        });
        expect(service.storedNotificationIdForTesting('occasion-321'), isNull);
      },
    );
  });

  group('reminder scheduling', () {
    test('skips scheduling when notifications are disabled', () async {
      final plugin = _MockNotificationsPlugin();
      var scheduled = 0;
      when(
        () => plugin.initialize(
          settings: any(named: 'settings'),
          onDidReceiveNotificationResponse: any(
            named: 'onDidReceiveNotificationResponse',
          ),
        ),
      ).thenAnswer((_) async => true);
      when(
        () => plugin.zonedSchedule(
          id: any(named: 'id'),
          title: any(named: 'title'),
          body: any(named: 'body'),
          scheduledDate: any(named: 'scheduledDate'),
          notificationDetails: any(named: 'notificationDetails'),
          androidScheduleMode: any(named: 'androidScheduleMode'),
          payload: any(named: 'payload'),
        ),
      ).thenAnswer((_) async {
        scheduled++;
      });

      final service = NotificationService(prefs, notifications: plugin);
      final occasion = SavedOccasion(
        id: 'occasion-disabled',
        occasion: Occasion.birthday,
        date: DateTime.now().add(const Duration(days: 10)),
        createdAt: DateTime.now().toUtc(),
      );

      await service.scheduleReminder(occasion);

      expect(scheduled, 0);
      verifyNever(
        () => plugin.zonedSchedule(
          id: any(named: 'id'),
          title: any(named: 'title'),
          body: any(named: 'body'),
          scheduledDate: any(named: 'scheduledDate'),
          notificationDetails: any(named: 'notificationDetails'),
          androidScheduleMode: any(named: 'androidScheduleMode'),
          payload: any(named: 'payload'),
        ),
      );
    });

    test('schedules reminders with stable id and payload', () async {
      await prefs.setBool(PreferenceKeys.notificationsEnabled, true);

      final plugin = _MockNotificationsPlugin();
      Map<Symbol, dynamic>? args;
      when(
        () => plugin.initialize(
          settings: any(named: 'settings'),
          onDidReceiveNotificationResponse: any(
            named: 'onDidReceiveNotificationResponse',
          ),
        ),
      ).thenAnswer((_) async => true);
      when(() => plugin.cancel(id: any(named: 'id'))).thenAnswer((_) async {});
      when(
        () => plugin.zonedSchedule(
          id: any(named: 'id'),
          title: any(named: 'title'),
          body: any(named: 'body'),
          scheduledDate: any(named: 'scheduledDate'),
          notificationDetails: any(named: 'notificationDetails'),
          androidScheduleMode: any(named: 'androidScheduleMode'),
          payload: any(named: 'payload'),
        ),
      ).thenAnswer((invocation) async {
        args = invocation.namedArguments;
      });

      final service = NotificationService(prefs, notifications: plugin);
      final occasion = SavedOccasion(
        id: 'occasion-stable',
        occasion: Occasion.newYear,
        date: DateTime.now().add(const Duration(days: 14)),
        recipientName: 'Alex',
        relationship: Relationship.closeFriend,
        createdAt: DateTime.now().toUtc(),
      );

      await service.scheduleReminder(occasion);

      final expectedId = await service.notificationIdForTesting(occasion.id);
      expect(args, isNotNull);
      expect(args![#id], expectedId);
      expect(args![#payload], 'occasion:${occasion.id}');
      expect(args![#title], '${occasion.occasion.emoji} New Year coming up!');
    });
  });
}
