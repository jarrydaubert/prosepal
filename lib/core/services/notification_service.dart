import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../config/preference_keys.dart';
import '../models/models.dart';
import 'log_service.dart';

/// Callback for handling notification taps (set from main.dart)
typedef NotificationTapCallback = void Function(String? payload);

/// Service for managing local push notifications
///
/// Handles:
/// - Permission requests
/// - Scheduling reminders for saved occasions
/// - Deep linking from notification taps
class NotificationService {
  NotificationService(
    this._prefs, {
    FlutterLocalNotificationsPlugin? notifications,
  }) : _notifications = notifications ?? FlutterLocalNotificationsPlugin();

  final SharedPreferences _prefs;
  final FlutterLocalNotificationsPlugin _notifications;

  static NotificationTapCallback? onNotificationTap;

  static const _channelId = 'prosepal_reminders';
  static const _channelName = 'Occasion Reminders';
  static const _channelDesc = 'Reminders for upcoming occasions';
  static const _notificationIdMapKey = 'notification_id_map_v1';
  static const _maxNotificationId = 0x7FFFFFFF;

  bool _initialized = false;

  /// Initialize the notification service
  Future<void> initialize() async {
    if (_initialized) return;

    // Initialize timezone
    tz.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    _initialized = true;
    Log.info('Notification service initialized');
  }

  /// Check if notifications are enabled
  bool get notificationsEnabled =>
      _prefs.getBool(PreferenceKeys.notificationsEnabled) ??
      PreferenceKeys.notificationsEnabledDefault;

  /// Check if we've asked for permission before
  bool get hasAskedPermission =>
      _prefs.getBool(PreferenceKeys.notificationsAsked) ?? false;

  /// Request notification permission
  /// Returns true if permission was granted
  Future<bool> requestPermission() async {
    await _prefs.setBool(PreferenceKeys.notificationsAsked, true);

    if (Platform.isIOS) {
      final result = await _notifications
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);

      final granted = result ?? false;
      await _prefs.setBool(PreferenceKeys.notificationsEnabled, granted);
      Log.info('iOS notification permission', {'granted': granted});
      return granted;
    }

    if (Platform.isAndroid) {
      final android = _notifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();

      final granted = await android?.requestNotificationsPermission() ?? false;
      await _prefs.setBool(PreferenceKeys.notificationsEnabled, granted);
      Log.info('Android notification permission', {'granted': granted});
      return granted;
    }

    return false;
  }

  /// Schedule a reminder for an occasion
  Future<void> scheduleReminder(SavedOccasion occasion) async {
    if (!_initialized) await initialize();
    if (!notificationsEnabled || !occasion.reminderEnabled) return;

    final reminderDate = occasion.reminderDate;
    final now = DateTime.now();

    // Don't schedule if reminder date is in the past
    if (reminderDate.isBefore(now)) {
      Log.info('Skipping past reminder', {'id': occasion.id});
      return;
    }

    // Schedule for 9 AM on reminder day
    final scheduledDate = DateTime(
      reminderDate.year,
      reminderDate.month,
      reminderDate.day,
      9, // 9 AM
    );

    final tzScheduledDate = tz.TZDateTime.from(scheduledDate, tz.local);

    final title =
        '${occasion.occasion.emoji} ${occasion.occasion.label} coming up!';
    final body = occasion.recipientName != null
        ? "${occasion.recipientName}'s ${occasion.occasion.label.toLowerCase()} is in ${occasion.reminderDaysBefore} days"
        : '${occasion.occasion.label} is in ${occasion.reminderDaysBefore} days';
    final notificationId = await _notificationIdForOccasion(occasion.id);
    final legacyNotificationId = _legacyNotificationIdForOccasion(occasion.id);
    if (legacyNotificationId != notificationId) {
      // Migration safety: clear reminders created by the legacy hashCode path.
      await _notifications.cancel(id: legacyNotificationId);
    }

    await _notifications.zonedSchedule(
      id: notificationId,
      title: title,
      body: body,
      scheduledDate: tzScheduledDate,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDesc,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: 'occasion:${occasion.id}',
    );

    Log.info('Reminder scheduled', {
      'occasion': occasion.occasion.name,
      'date': scheduledDate.toIso8601String(),
    });
  }

  /// Cancel a scheduled reminder
  Future<void> cancelReminder(String occasionId) async {
    if (!_initialized) await initialize();
    final mappedId = _storedNotificationIdForOccasion(occasionId);
    final deterministicId = _deterministicNotificationId(occasionId);
    final legacyId = _legacyNotificationIdForOccasion(occasionId);
    final idsToCancel = <int?>[
      mappedId,
      deterministicId,
      legacyId,
    ].whereType<int>().toSet();

    for (final id in idsToCancel) {
      await _notifications.cancel(id: id);
    }
    await _removeStoredNotificationId(occasionId);
    Log.info('Reminder cancelled', {'id': occasionId});
  }

  /// Cancel all reminders
  Future<void> cancelAll() async {
    if (!_initialized) await initialize();
    await _notifications.cancelAll();
    await _prefs.remove(_notificationIdMapKey);
    Log.info('All reminders cancelled');
  }

  /// Reschedule all reminders (call after app update or timezone change)
  Future<void> rescheduleAll(List<SavedOccasion> occasions) async {
    await cancelAll();
    for (final occasion in occasions) {
      if (occasion.reminderEnabled && !occasion.isPast) {
        await scheduleReminder(occasion);
      }
    }
    Log.info('All reminders rescheduled', {'count': occasions.length});
  }

  /// Set notifications enabled/disabled
  Future<void> setEnabled(bool enabled) async {
    await _prefs.setBool(PreferenceKeys.notificationsEnabled, enabled);
    if (!enabled) {
      await cancelAll();
    }
    Log.info('Notifications ${enabled ? 'enabled' : 'disabled'}');
  }

  void _onNotificationTap(NotificationResponse response) {
    Log.info('Notification tapped', {'payload': response.payload});
    onNotificationTap?.call(response.payload);
  }

  /// Show a test notification (DEBUG ONLY)
  @visibleForTesting
  Future<void> showTestNotification() async {
    if (!kDebugMode) return;
    if (!_initialized) await initialize();

    await _notifications.show(
      id: 0,
      title: '🎂 Test Notification',
      body: 'This is a test reminder from Prosepal',
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDesc,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );
  }

  Future<int> _notificationIdForOccasion(String occasionId) async {
    final existingId = _storedNotificationIdForOccasion(occasionId);
    if (existingId != null) return existingId;

    final map = _notificationIdMap;
    var candidate = _deterministicNotificationId(occasionId);
    final usedIds = map.values.toSet();

    while (usedIds.contains(candidate)) {
      candidate = candidate == _maxNotificationId ? 1 : candidate + 1;
    }

    map[occasionId] = candidate;
    await _saveNotificationIdMap(map);
    return candidate;
  }

  Map<String, int> get _notificationIdMap {
    final raw = _prefs.getString(_notificationIdMapKey);
    if (raw == null || raw.isEmpty) return <String, int>{};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return <String, int>{};
      return decoded.map((key, value) {
        final parsed = value is int ? value : int.tryParse('$value');
        return MapEntry(key, parsed ?? 0);
      })..removeWhere((_, value) => value <= 0);
    } on FormatException {
      return <String, int>{};
    }
  }

  int? _storedNotificationIdForOccasion(String occasionId) =>
      _notificationIdMap[occasionId];

  Future<void> _removeStoredNotificationId(String occasionId) async {
    final map = _notificationIdMap;
    if (!map.containsKey(occasionId)) return;
    map.remove(occasionId);
    await _saveNotificationIdMap(map);
  }

  Future<void> _saveNotificationIdMap(Map<String, int> map) async {
    await _prefs.setString(_notificationIdMapKey, jsonEncode(map));
  }

  int _legacyNotificationIdForOccasion(String occasionId) =>
      occasionId.hashCode;

  @visibleForTesting
  int deterministicNotificationIdForTesting(String occasionId) =>
      _deterministicNotificationId(occasionId);

  @visibleForTesting
  int? storedNotificationIdForTesting(String occasionId) =>
      _storedNotificationIdForOccasion(occasionId);

  @visibleForTesting
  Future<int> notificationIdForTesting(String occasionId) =>
      _notificationIdForOccasion(occasionId);

  @visibleForTesting
  int legacyNotificationIdForTesting(String occasionId) =>
      _legacyNotificationIdForOccasion(occasionId);

  int _deterministicNotificationId(String occasionId) {
    // FNV-1a 32-bit hash for stable cross-run IDs (unlike Dart hashCode).
    var hash = 0x811C9DC5;
    for (final unit in occasionId.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0xFFFFFFFF;
    }
    final positive = hash & 0x7FFFFFFF;
    return positive == 0 ? 1 : positive;
  }
}
