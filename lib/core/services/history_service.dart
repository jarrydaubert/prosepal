import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../models/models.dart';
import 'log_service.dart';

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
class HistoryService {
  HistoryService(this._prefs);

  final SharedPreferences _prefs;
  final _uuid = const Uuid();
  static const _key = 'generation_history';
  
  /// Maximum history items stored locally
  /// 200 items ≈ 2 weeks of heavy Pro usage (500/month)
  /// Oldest items are automatically removed when limit is reached
  static const int maxHistoryItems = 200;

  /// Get all saved generations (newest first)
  List<SavedGeneration> getHistory() {
    final jsonString = _prefs.getString(_key);
    if (jsonString == null || jsonString.isEmpty) {
      return [];
    }

    try {
      final jsonList = jsonDecode(jsonString) as List<dynamic>;
      return jsonList
          .map((json) => SavedGeneration.fromJson(json as Map<String, dynamic>))
          .toList();
    } on Exception catch (e) {
      Log.error('Failed to load history', e);
      return [];
    }
  }

  /// Save a new generation to history
  Future<void> saveGeneration(GenerationResult result) async {
    final history = getHistory();

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
    final history = getHistory();
    history.removeWhere((item) => item.id == id);
    await _saveHistory(history);
  }

  /// Clear all history
  Future<void> clearHistory() async {
    await _prefs.remove(_key);
    Log.info('History cleared');
  }

  Future<void> _saveHistory(List<SavedGeneration> history) async {
    final jsonList = history.map((item) => item.toJson()).toList();
    await _prefs.setString(_key, jsonEncode(jsonList));
  }
}
