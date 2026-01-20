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
  NotificationService(this._prefs);

  final SharedPreferences _prefs;
  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static NotificationTapCallback? onNotificationTap;

  static const _channelId = 'prosepal_reminders';
  static const _channelName = 'Occasion Reminders';
  static const _channelDesc = 'Reminders for upcoming occasions';

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
      settings,
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

    await _notifications.zonedSchedule(
      occasion.id.hashCode,
      title,
      body,
      tzScheduledDate,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDesc,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: 'occasion:${occasion.id}',
      matchDateTimeComponents: null,
    );

    Log.info('Reminder scheduled', {
      'occasion': occasion.occasion.name,
      'date': scheduledDate.toIso8601String(),
    });
  }

  /// Cancel a scheduled reminder
  Future<void> cancelReminder(String occasionId) async {
    if (!_initialized) await initialize();
    await _notifications.cancel(occasionId.hashCode);
    Log.info('Reminder cancelled', {'id': occasionId});
  }

  /// Cancel all reminders
  Future<void> cancelAll() async {
    if (!_initialized) await initialize();
    await _notifications.cancelAll();
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
      0,
      '🎂 Test Notification',
      'This is a test reminder from Prosepal',
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDesc,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );
  }
}
