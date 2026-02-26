import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';

import '../models/models.dart';
import 'log_service.dart';

// ignore_for_file: unused_element, unused_field

/// Model version for future migration support
const int _historyModelVersion = 1;

/// Saved generation with metadata
class SavedGeneration {
  SavedGeneration({
    required this.id,
    required this.result,
    required this.savedAt,
  });

  final String id;
  final GenerationResult result;
  final DateTime savedAt;

  Map<String, dynamic> toJson() => {
    'id': id,
    'result': result.toJson(),
    'savedAt': savedAt.toIso8601String(),
  };

  factory SavedGeneration.fromJson(Map<String, dynamic> json) {
    return SavedGeneration(
      id: json['id'] as String,
      result: GenerationResult.fromJson(json['result'] as Map<String, dynamic>),
      savedAt: DateTime.parse(json['savedAt'] as String),
    );
  }
}

/// Service for saving and retrieving generation history
///
/// Stores history locally via SharedPreferences with a 200-item cap.
/// History is cleared on sign-out for privacy (see settings_screen.dart).
///
/// ## Limitations (LOCAL-ONLY STORAGE)
/// - Data is lost on app uninstall or device change
/// - No cross-device sync
/// - Consider server sync for production (similar to UsageService)
///
/// ## Future Improvements (see BACKLOG.md)
/// - Supabase sync for cross-device persistence
/// - Migration to hive/sqflite for larger data
/// - Export/share functionality
class HistoryService {
  /// Constructor - no longer requires SharedPreferences (uses secure storage)
  HistoryService();

  /// Secure storage for history (encrypts personal details in saved messages)
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  final _uuid = const Uuid();
  static const _key = 'generation_history';
  static const _versionKey = 'generation_history_version';

  /// Maximum history items stored locally
  /// 200 items ≈ 2 weeks of heavy Pro usage (500/month)
  /// Oldest items are automatically removed when limit is reached
  static const int maxHistoryItems = 200;

  /// Get all saved generations (newest first)
  ///
  /// Returns empty list on parse failure and clears corrupted data.
  Future<List<SavedGeneration>> getHistory() async {
    final jsonString = await _secureStorage.read(key: _key);
    if (jsonString == null || jsonString.isEmpty) {
      return [];
    }

    try {
      final jsonList = jsonDecode(jsonString) as List<dynamic>;
      return jsonList
          .map((json) => SavedGeneration.fromJson(json as Map<String, dynamic>))
          .toList();
    } on Exception catch (e) {
      Log.error('Failed to load history - clearing corrupted data', e);
      // Clear corrupted data to allow recovery
      await _secureStorage.delete(key: _key);
      return [];
    }
  }

  /// Save a new generation to history
  Future<void> saveGeneration(GenerationResult result) async {
    final history = await getHistory();

    final saved = SavedGeneration(
      id: _uuid.v4(),
      result: result,
      savedAt: DateTime.now(),
    );

    history.insert(0, saved);

    if (history.length > maxHistoryItems) {
      history.removeRange(maxHistoryItems, history.length);
    }

    await _saveHistory(history);
    Log.info('Generation saved to history', {'total': history.length});
  }

  /// Delete a specific generation
  Future<void> deleteGeneration(String id) async {
    final history = await getHistory();
    history.removeWhere((item) => item.id == id);
    await _saveHistory(history);
  }

  /// Clear all history
  Future<void> clearHistory() async {
    await _secureStorage.delete(key: _key);
    Log.info('History cleared');
  }

  Future<void> _saveHistory(List<SavedGeneration> history) async {
    final jsonList = history.map((item) => item.toJson()).toList();
    await _secureStorage.write(key: _key, value: jsonEncode(jsonList));
  }
}
