import 'dart:convert';

import 'package:add_2_calendar/add_2_calendar.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';

import '../models/models.dart';
import 'log_service.dart';

/// Service for managing saved calendar occasions
///
/// Stores occasions locally via FlutterSecureStorage.
/// Provides CRUD operations and upcoming occasion queries.
class CalendarService {
  CalendarService();

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final _uuid = const Uuid();
  static const _key = 'saved_occasions';
  static const int maxOccasions = 100;

  List<SavedOccasion>? _cache;

  /// Get all saved occasions (sorted by date, upcoming first)
  Future<List<SavedOccasion>> getOccasions() async {
    if (_cache != null) return _cache!;

    final jsonString = await _secureStorage.read(key: _key);
    if (jsonString == null || jsonString.isEmpty) {
      _cache = [];
      return [];
    }

    try {
      final jsonList = jsonDecode(jsonString) as List<dynamic>;
      _cache =
          jsonList
              .map(
                (json) => SavedOccasion.fromJson(json as Map<String, dynamic>),
              )
              .toList()
            ..sort((a, b) => a.date.compareTo(b.date));
      return _cache!;
    } on Exception catch (e) {
      Log.error('Failed to load occasions - clearing corrupted data', e);
      await _secureStorage.delete(key: _key);
      _cache = [];
      return [];
    }
  }

  /// Get upcoming occasions (not past, sorted by date)
  Future<List<SavedOccasion>> getUpcomingOccasions({int? limit}) async {
    final all = await getOccasions();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final upcoming = all.where((o) => !o.date.isBefore(today)).toList();

    if (limit != null && upcoming.length > limit) {
      return upcoming.sublist(0, limit);
    }
    return upcoming;
  }

  /// Get occasions that need reminders today
  Future<List<SavedOccasion>> getOccasionsNeedingReminder() async {
    final all = await getOccasions();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return all.where((o) {
      if (!o.reminderEnabled) return false;
      final reminderDate = DateTime(
        o.reminderDate.year,
        o.reminderDate.month,
        o.reminderDate.day,
      );
      return reminderDate.isAtSameMomentAs(today);
    }).toList();
  }

  /// Save a new occasion
  Future<SavedOccasion> saveOccasion({
    required Occasion occasion,
    required DateTime date,
    String? recipientName,
    Relationship? relationship,
    String? notes,
    bool reminderEnabled = true,
    int reminderDaysBefore = 7,
  }) async {
    final occasions = await getOccasions();

    final saved = SavedOccasion(
      id: _uuid.v4(),
      occasion: occasion,
      date: date,
      recipientName: recipientName,
      relationship: relationship,
      notes: notes,
      reminderEnabled: reminderEnabled,
      reminderDaysBefore: reminderDaysBefore,
      createdAt: DateTime.now(),
    );

    occasions.add(saved);
    occasions.sort((a, b) => a.date.compareTo(b.date));

    if (occasions.length > maxOccasions) {
      // Remove oldest past occasions first
      final past = occasions.where((o) => o.isPast).toList();
      if (past.isNotEmpty) {
        occasions.remove(past.first);
      } else {
        occasions.removeLast();
      }
    }

    await _saveOccasions(occasions);
    Log.info('Occasion saved', {
      'occasion': occasion.name,
      'date': date.toIso8601String(),
    });

    return saved;
  }

  /// Update an existing occasion
  Future<void> updateOccasion(SavedOccasion updated) async {
    final occasions = await getOccasions();
    final index = occasions.indexWhere((o) => o.id == updated.id);

    if (index == -1) {
      Log.warning('Occasion not found for update', {'id': updated.id});
      return;
    }

    occasions[index] = updated;
    occasions.sort((a, b) => a.date.compareTo(b.date));
    await _saveOccasions(occasions);
    Log.info('Occasion updated', {'id': updated.id});
  }

  /// Mark an occasion as generated (updates lastGeneratedAt)
  Future<void> markAsGenerated(String id) async {
    final occasions = await getOccasions();
    final index = occasions.indexWhere((o) => o.id == id);

    if (index == -1) return;

    occasions[index] = occasions[index].copyWith(
      lastGeneratedAt: DateTime.now(),
    );
    await _saveOccasions(occasions);
  }

  /// Delete an occasion
  Future<void> deleteOccasion(String id) async {
    final occasions = await getOccasions();
    occasions.removeWhere((o) => o.id == id);
    await _saveOccasions(occasions);
    Log.info('Occasion deleted', {'id': id});
  }

  /// Clear all occasions
  Future<void> clearAll() async {
    await _secureStorage.delete(key: _key);
    _cache = null;
    Log.info('All occasions cleared');
  }

  /// Export occasion to native calendar app
  Future<bool> exportToNativeCalendar(SavedOccasion occasion) async {
    try {
      final event = Event(
        title:
            '${occasion.occasion.emoji} ${occasion.occasion.label}'
            '${occasion.recipientName != null ? ' for ${occasion.recipientName}' : ''}',
        description: occasion.notes ?? 'Created with Prosepal',
        location: '',
        startDate: occasion.date,
        endDate: occasion.date.add(const Duration(hours: 1)),
        allDay: true,
        iosParams: const IOSParams(reminder: Duration(days: 1)),
        androidParams: const AndroidParams(emailInvites: []),
      );

      final success = await Add2Calendar.addEvent2Cal(event);
      Log.info('Export to calendar', {'success': success});
      return success;
    } on Exception catch (e) {
      Log.error('Failed to export to calendar', e);
      return false;
    }
  }

  Future<void> _saveOccasions(List<SavedOccasion> occasions) async {
    _cache = occasions;
    final jsonList = occasions.map((o) => o.toJson()).toList();
    await _secureStorage.write(key: _key, value: jsonEncode(jsonList));
  }
}
