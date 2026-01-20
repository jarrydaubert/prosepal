import 'package:freezed_annotation/freezed_annotation.dart';

import 'occasion.dart';
import 'relationship.dart';

part 'saved_occasion.freezed.dart';
part 'saved_occasion.g.dart';

/// A saved occasion for the calendar feature
@freezed
abstract class SavedOccasion with _$SavedOccasion {
  const SavedOccasion._();

  const factory SavedOccasion({
    required String id,
    required Occasion occasion,
    required DateTime date,
    String? recipientName,
    Relationship? relationship,
    String? notes,
    @Default(true) bool reminderEnabled,
    @Default(7) int reminderDaysBefore,
    required DateTime createdAt,
    DateTime? lastGeneratedAt,
  }) = _SavedOccasion;

  factory SavedOccasion.fromJson(Map<String, dynamic> json) =>
      _$SavedOccasionFromJson(json);
}

/// Extension for SavedOccasion utilities
extension SavedOccasionX on SavedOccasion {
  /// Get the reminder date (date - reminderDaysBefore)
  DateTime get reminderDate =>
      date.subtract(Duration(days: reminderDaysBefore));

  /// Check if the occasion is in the past
  bool get isPast => date.isBefore(DateTime.now());

  /// Check if the occasion is today
  bool get isToday {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  /// Check if the occasion is within the next week
  bool get isThisWeek {
    final now = DateTime.now();
    final weekFromNow = now.add(const Duration(days: 7));
    return date.isAfter(now) && date.isBefore(weekFromNow);
  }

  /// Days until the occasion (negative if past)
  int get daysUntil => date.difference(DateTime.now()).inDays;

  /// Display string for days until
  String get daysUntilDisplay {
    final days = daysUntil;
    if (days < 0) return '${-days} days ago';
    if (days == 0) return 'Today';
    if (days == 1) return 'Tomorrow';
    if (days < 7) return 'In $days days';
    if (days < 14) return 'Next week';
    if (days < 30) return 'In ${(days / 7).round()} weeks';
    return 'In ${(days / 30).round()} months';
  }
}
