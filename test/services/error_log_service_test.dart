import 'package:flutter_test/flutter_test.dart';
import 'package:prosepal/core/services/error_log_service.dart';

/// ErrorLogService Unit Tests
///
/// Tests REAL ErrorLogService for error tracking used in feedback reports.
/// Each test answers: "What bug does this catch?"
void main() {
  group('ErrorLogService', () {
    setUp(ErrorLogService.instance.clear);

    test('returns singleton instance', () {
      // Bug: Multiple instances lose error history
      final instance1 = ErrorLogService.instance;
      final instance2 = ErrorLogService.instance;
      expect(identical(instance1, instance2), isTrue);
    });

    test('starts with no errors', () {
      // Bug: Shows stale errors from previous session
      final log = ErrorLogService.instance.getFormattedLog();
      expect(log, equals('No recent errors'));
    });

    test('logs error without stacktrace', () {
      // Bug: Simple string errors not captured
      ErrorLogService.instance.log('Test error');
      final log = ErrorLogService.instance.getFormattedLog();

      expect(log, contains('Recent Errors'));
      expect(log, contains('Test error'));
    });

    test('logs error with stacktrace', () {
      // Bug: Stack traces not captured, debugging impossible
      try {
        throw Exception('Test exception');
      } catch (e, stackTrace) {
        ErrorLogService.instance.log(e, stackTrace);
      }

      final log = ErrorLogService.instance.getFormattedLog();
      expect(log, contains('Test exception'));
      expect(log, contains('error_log_service_test.dart'));
    });

    test('includes timestamp in log', () {
      // Bug: No timestamps, can't correlate errors with user actions
      ErrorLogService.instance.log('Timed error');
      final log = ErrorLogService.instance.getFormattedLog();

      expect(
        RegExp(r'\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}').hasMatch(log),
        isTrue,
        reason: 'Log should contain ISO 8601 timestamp',
      );
    });

    test('limits to max 10 errors (prevents memory leak)', () {
      // Bug: Unlimited errors causes memory leak in long sessions
      for (var i = 0; i < 15; i++) {
        ErrorLogService.instance.log('Error $i');
      }

      final log = ErrorLogService.instance.getFormattedLog();

      // Should not contain early errors (evicted)
      expect(log, isNot(contains('Error 0')));
      expect(log, isNot(contains('Error 4')));

      // Should contain recent errors
      expect(log, contains('Error 14'));
    });

    test('shows most recent 5 in formatted log', () {
      // Bug: Old errors shown instead of recent ones
      for (var i = 0; i < 10; i++) {
        ErrorLogService.instance.log('Error $i');
      }

      final log = ErrorLogService.instance.getFormattedLog();

      expect(log, contains('Error 9'));
      expect(log, contains('Error 5'));
    });

    test('clears all errors', () {
      // Bug: Clear doesn't work, stale errors in feedback
      ErrorLogService.instance.log('Error 1');
      ErrorLogService.instance.log('Error 2');

      ErrorLogService.instance.clear();

      final log = ErrorLogService.instance.getFormattedLog();
      expect(log, equals('No recent errors'));
    });

    test('handles various error types', () {
      // Bug: Certain error types crash the logger
      ErrorLogService.instance.log(Exception('Exception type'));
      ErrorLogService.instance.log(const FormatException('Format error'));
      ErrorLogService.instance.log('String error');
      ErrorLogService.instance.log(42);

      final log = ErrorLogService.instance.getFormattedLog();
      expect(log, contains('Exception type'));
      expect(log, contains('Format error'));
      expect(log, contains('String error'));
      expect(log, contains('42'));
    });
  });
}
