import 'package:flutter_test/flutter_test.dart';
import 'package:prosepal/core/services/log_service.dart';

/// LogService Unit Tests
///
/// Tests buffer management, formatting, and breadcrumb generation.
/// Firebase Crashlytics is not available in tests, so we test the
/// pure Dart logic (buffer, formatting, export).
void main() {
  setUp(Log.clearBuffer);

  group('Log Buffer Management', () {
    test('starts with empty buffer', () {
      final log = Log.getExportableLog();
      expect(log, contains('Entries: 0'));
    });

    test('info adds entry to buffer', () {
      Log.info('Test message');

      final breadcrumbs = Log.getRecentBreadcrumbs();
      expect(breadcrumbs.length, equals(1));
      expect(breadcrumbs[0], contains('Test message'));
    });

    test('warning adds entry to buffer', () {
      Log.warning('Warning message');

      final log = Log.getExportableLog();
      expect(log, contains('WARN'));
      expect(log, contains('Warning message'));
    });

    test('error adds entry to buffer', () {
      Log.error('Error message');

      final log = Log.getExportableLog();
      expect(log, contains('ERROR'));
      expect(log, contains('Error message'));
    });

    test('params are included in log entries', () {
      Log.info('User action', {'userId': '123', 'action': 'click'});

      final log = Log.getExportableLog();
      expect(log, contains('userId=123'));
      expect(log, contains('action=click'));
    });

    test('redacts known sensitive keys in export buffer', () {
      Log.info('Password reset requested', {
        'email': 'user@example.com',
        'idToken': 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.payload.signature',
      });

      final log = Log.getExportableLog();
      expect(log, contains('email=[REDACTED]'));
      expect(log, contains('idToken=[REDACTED]'));
      expect(log, isNot(contains('user@example.com')));
    });

    test('redacts sensitive value patterns even on non-sensitive keys', () {
      Log.warning('Unexpected response', {
        'error': 'token rejected for user@example.com',
        'details':
            'jwt=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.abcdefghijklmnop.defghijklmnopq',
      });

      final log = Log.getExportableLog();
      expect(log, contains('error=token rejected for [REDACTED_EMAIL]'));
      expect(log, contains('details=jwt=[REDACTED_TOKEN]'));
    });

    test('verbose export includes non-secret details when requested', () {
      Log.info('Debug payload', {
        'email': 'user@example.com',
        'note': 'hello world',
        'idToken': 'abc.def.ghi',
      });

      final verbose = Log.getExportableLog(includeSensitive: true);
      expect(verbose, contains('email=user@example.com'));
      expect(verbose, contains('note=hello world'));
      expect(verbose, contains('idToken=[REDACTED]'));
    });

    test('buffer respects max size (200 entries)', () {
      // Add 250 entries
      for (var i = 0; i < 250; i++) {
        Log.info('Message $i');
      }

      final log = Log.getExportableLog();
      expect(log, contains('Entries: 200'));

      // First 50 should be evicted
      expect(log, isNot(contains('Message 0')));
      expect(log, isNot(contains('Message 49')));

      // Last 200 should be present
      expect(log, contains('Message 50'));
      expect(log, contains('Message 249'));
    });

    test('clearBuffer removes all entries', () {
      Log.info('Entry 1');
      Log.info('Entry 2');
      Log.info('Entry 3');

      Log.clearBuffer();

      final log = Log.getExportableLog();
      expect(log, contains('Entries: 0'));
    });
  });

  group('getExportableLog', () {
    test('includes header with timestamp', () {
      final log = Log.getExportableLog();

      expect(log, contains('=== Prosepal Debug Log ==='));
      expect(log, contains('Exported:'));
      expect(log, contains('Timezone:'));
    });

    test('formats entries with time and level', () {
      Log.info('Test entry');

      final log = Log.getExportableLog();
      // Should have time in HH:mm:ss.SSS format
      expect(RegExp(r'\d{2}:\d{2}:\d{2}\.\d{3}').hasMatch(log), isTrue);
      expect(log, contains('[INFO]'));
    });

    test('includes params with pipe separator', () {
      Log.warning('Payment failed', {'amount': 9.99, 'currency': 'USD'});

      final log = Log.getExportableLog();
      expect(log, contains('Payment failed |'));
      expect(log, contains('amount=9.99'));
      expect(log, contains('currency=USD'));
    });
  });

  group('getRecentBreadcrumbs', () {
    test('returns empty list when no entries', () {
      final breadcrumbs = Log.getRecentBreadcrumbs();
      expect(breadcrumbs, isEmpty);
    });

    test('returns all entries when fewer than count', () {
      Log.info('Entry 1');
      Log.info('Entry 2');

      final breadcrumbs = Log.getRecentBreadcrumbs(count: 10);
      expect(breadcrumbs.length, equals(2));
    });

    test('returns only last N entries when buffer exceeds count', () {
      for (var i = 0; i < 100; i++) {
        Log.info('Entry $i');
      }

      final breadcrumbs = Log.getRecentBreadcrumbs(count: 10);
      expect(breadcrumbs.length, equals(10));

      // Should contain last 10 entries (90-99)
      expect(breadcrumbs[0], contains('Entry 90'));
      expect(breadcrumbs[9], contains('Entry 99'));
    });

    test('breadcrumbs have short time format', () {
      Log.info('Test entry');

      final breadcrumbs = Log.getRecentBreadcrumbs();
      // Should have time in HH:mm:ss format (no milliseconds)
      expect(RegExp(r'^\d{2}:\d{2}:\d{2} ').hasMatch(breadcrumbs[0]), isTrue);
    });

    test('breadcrumbs do not include params', () {
      Log.info('User signed in', {'provider': 'google', 'userId': 'abc123'});

      final breadcrumbs = Log.getRecentBreadcrumbs();
      expect(breadcrumbs[0], contains('User signed in'));
      // Params should not appear in breadcrumbs (they're in full export only)
      expect(breadcrumbs[0], isNot(contains('provider')));
    });
  });

  group('LogEntry', () {
    test('toExportString includes full timestamp and level', () {
      final entry = LogEntry(
        timestamp: DateTime(2024, 1, 15, 14, 30, 45, 123),
        level: AppLogLevel.info,
        message: 'Test message',
      );

      final exported = entry.toExportString();
      expect(exported, contains('14:30:45.123'));
      expect(exported, contains('[INFO]'));
      expect(exported, contains('Test message'));
    });

    test('toExportString includes params', () {
      final entry = LogEntry(
        timestamp: DateTime(2024, 1, 15, 14, 30, 45),
        level: AppLogLevel.warning,
        message: 'Warning',
        params: {'key': 'value', 'count': 42},
      );

      final exported = entry.toExportString();
      expect(exported, contains('key=value'));
      expect(exported, contains('count=42'));
    });

    test('toBreadcrumb uses short format without params', () {
      final entry = LogEntry(
        timestamp: DateTime(2024, 1, 15, 14, 30, 45, 999),
        level: AppLogLevel.error,
        message: 'Error occurred',
        params: {'detail': 'ignored'},
      );

      final breadcrumb = entry.toBreadcrumb();
      expect(breadcrumb, equals('14:30:45 Error occurred'));
      expect(breadcrumb, isNot(contains('detail')));
    });

    test('level prefix is correct for all levels', () {
      final infoEntry = LogEntry(
        timestamp: DateTime.now(),
        level: AppLogLevel.info,
        message: 'info',
      );
      final warnEntry = LogEntry(
        timestamp: DateTime.now(),
        level: AppLogLevel.warning,
        message: 'warn',
      );
      final errorEntry = LogEntry(
        timestamp: DateTime.now(),
        level: AppLogLevel.error,
        message: 'error',
      );

      expect(infoEntry.toExportString(), contains('[INFO]'));
      expect(warnEntry.toExportString(), contains('[WARN]'));
      expect(errorEntry.toExportString(), contains('[ERROR]'));
    });
  });

  group('Mixed Log Levels', () {
    test('buffer preserves order across different levels', () {
      Log.info('First');
      Log.warning('Second');
      Log.error('Third');
      Log.info('Fourth');

      final breadcrumbs = Log.getRecentBreadcrumbs();
      expect(breadcrumbs[0], contains('First'));
      expect(breadcrumbs[1], contains('Second'));
      expect(breadcrumbs[2], contains('Third'));
      expect(breadcrumbs[3], contains('Fourth'));
    });

    test('exportable log shows all levels with correct prefixes', () {
      Log.info('Info message');
      Log.warning('Warn message');
      Log.error('Error message');

      final log = Log.getExportableLog();
      expect(log, contains('[INFO] Info message'));
      expect(log, contains('[WARN] Warn message'));
      expect(log, contains('[ERROR] Error message'));
    });
  });
}
