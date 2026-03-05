import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:prosepal/core/services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockNotificationsPlugin extends Mock
    implements FlutterLocalNotificationsPlugin {}

void main() {
  late SharedPreferences prefs;

  setUpAll(() {
    registerFallbackValue(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
    );
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
            onDidReceiveBackgroundNotificationResponse: any(
              named: 'onDidReceiveBackgroundNotificationResponse',
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
}
