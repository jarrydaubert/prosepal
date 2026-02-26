import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'history_service.dart';
import 'log_service.dart';
import 'usage_service.dart';

/// Service for exporting user data (GDPR/CCPA right to portability)
class DataExportService {
  final UsageService _usageService;
  final HistoryService _historyService;

  DataExportService({
    required UsageService usageService,
    required HistoryService historyService,
  })  : _usageService = usageService,
        _historyService = historyService;

  /// Export all user data as JSON string
  ///
  /// Includes:
  /// - Account info (email, created date, provider)
  /// - Usage statistics
  /// - Message history
  ///
  /// Returns formatted JSON string ready for file export.
  Future<String> exportUserData() async {
    Log.info('Data export started');

    final export = <String, dynamic>{
      'exportDate': DateTime.now().toIso8601String(),
      'exportVersion': '1.0',
    };

    // Account info
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        export['account'] = {
          'email': user.email,
          'createdAt': user.createdAt,
          'provider': user.appMetadata['provider'],
          'lastSignInAt': user.lastSignInAt,
        };
      }
    } catch (e) {
      Log.warning('Data export: Failed to get account info', {'error': '$e'});
    }

    // Usage statistics
    try {
      export['usage'] = {
        'totalMessagesGenerated': _usageService.getTotalCount(),
        'monthlyMessagesGenerated': _usageService.getMonthlyCount(),
      };
    } catch (e) {
      Log.warning('Data export: Failed to get usage stats', {'error': '$e'});
    }

    // Message history
    try {
      final history = await _historyService.getHistory();
      export['messageHistory'] = history
          .map(
            (item) => {
              'id': item.id,
              'savedAt': item.savedAt.toIso8601String(),
              'occasion': item.result.occasion.name,
              'tone': item.result.tone.name,
              'relationship': item.result.relationship.name,
              'recipientName': item.result.recipientName,
              'personalDetails': item.result.personalDetails,
              'messages': item.result.messages
                  .map((m) => {'text': m.text, 'createdAt': m.createdAt.toIso8601String()})
                  .toList(),
            },
          )
          .toList();
    } catch (e) {
      Log.warning('Data export: Failed to get history', {'error': '$e'});
      export['messageHistory'] = [];
    }

    Log.info('Data export completed', {
      'accountIncluded': export.containsKey('account'),
      'historyCount': (export['messageHistory'] as List?)?.length ?? 0,
    });

    // Pretty print JSON for readability
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(export);
  }

  /// Get export filename with timestamp
  String getExportFilename() {
    final now = DateTime.now();
    final timestamp =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    return 'prosepal_data_export_$timestamp.json';
  }
}
