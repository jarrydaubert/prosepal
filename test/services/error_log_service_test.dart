import 'package:flutter_test/flutter_test.dart';
import 'package:prosepal/core/services/error_log_service.dart';

void main() {
  group('ErrorLogService', () {
    setUp(ErrorLogService.instance.clear);

    test('should return singleton instance', () {
      final instance1 = ErrorLogService.instance;
      final instance2 = ErrorLogService.instance;
      expect(identical(instance1, instance2), isTrue);
    });

    test('should start with no errors', () {
      final log = ErrorLogService.instance.getFormattedLog();
      expect(log, equals('No recent errors'));
    });

    test('should log error without stacktrace', () {
      ErrorLogService.instance.log('Test error');
      final log = ErrorLogService.instance.getFormattedLog();

      expect(log, contains('Recent Errors'));
      expect(log, contains('Test error'));
    });

    test('should log error with stacktrace', () {
      try {
        throw Exception('Test exception');
      } catch (e, stackTrace) {
        ErrorLogService.instance.log(e, stackTrace);
      }

      final log = ErrorLogService.instance.getFormattedLog();
      expect(log, contains('Test exception'));
      expect(log, contains('error_log_service_test.dart'));
    });

    test('should include timestamp in log', () {
      ErrorLogService.instance.log('Timed error');
      final log = ErrorLogService.instance.getFormattedLog();

      // Verify ISO 8601 format using regex (YYYY-MM-DDTHH:MM:SS)
      // More robust than checking specific year prefix
      expect(
        RegExp(r'\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}').hasMatch(log),
        isTrue,
        reason: 'Log should contain ISO 8601 timestamp',
      );
    });

    test('should limit to max 10 errors', () {
      for (var i = 0; i < 15; i++) {
        ErrorLogService.instance.log('Error $i');
      }

      final log = ErrorLogService.instance.getFormattedLog();

      // Should not contain early errors
      expect(log, isNot(contains('Error 0')));
      expect(log, isNot(contains('Error 4')));

      // Should contain recent errors
      expect(log, contains('Error 14'));
    });

    test('should show most recent 5 in formatted log', () {
      for (var i = 0; i < 10; i++) {
        ErrorLogService.instance.log('Error $i');
      }

      final log = ErrorLogService.instance.getFormattedLog();

      // Formatted log shows last 5
      expect(log, contains('Error 9'));
      expect(log, contains('Error 5'));
    });

    test('should clear all errors', () {
      ErrorLogService.instance.log('Error 1');
      ErrorLogService.instance.log('Error 2');

      ErrorLogService.instance.clear();

      final log = ErrorLogService.instance.getFormattedLog();
      expect(log, equals('No recent errors'));
    });

    test('should handle various error types', () {
      ErrorLogService.instance.log(Exception('Exception type'));
      ErrorLogService.instance.log(const FormatException('Format error'));
      ErrorLogService.instance.log('String error');
      ErrorLogService.instance.log(42); // Even numbers

      final log = ErrorLogService.instance.getFormattedLog();
      expect(log, contains('Exception type'));
      expect(log, contains('Format error'));
      expect(log, contains('String error'));
      expect(log, contains('42'));
    });

    test('should truncate long stacktraces to 5 lines', () {
      // Create a deep stack
      void level5() => throw Exception('Deep error');
      void level4() => level5();
      void level3() => level4();
      void level2() => level3();
      void level1() => level2();

      try {
        level1();
      } catch (e, stackTrace) {
        ErrorLogService.instance.log(e, stackTrace);
      }

      final log = ErrorLogService.instance.getFormattedLog();
      final lines = log.split('\n');

      // Should not have excessive stacktrace lines
      expect(lines.length, lessThan(20));
    });

    test('should handle very long error messages', () {
      final longMessage = 'A' * 1000; // 1000 character message
      ErrorLogService.instance.log(longMessage);

      final log = ErrorLogService.instance.getFormattedLog();
      expect(log, contains('A' * 100)); // At least partial message preserved
    });

    test('should handle empty error message', () {
      ErrorLogService.instance.log('');

      final log = ErrorLogService.instance.getFormattedLog();
      // Should still have a log entry with timestamp
      expect(
        RegExp(r'\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}').hasMatch(log),
        isTrue,
      );
    });

    test('should handle object with null toString gracefully', () {
      // Test with an object that has minimal string representation
      ErrorLogService.instance.log(Object());

      final log = ErrorLogService.instance.getFormattedLog();
      expect(log, contains('Instance of'));
    });

    test('should maintain order with rapid sequential logging', () {
      // Simulate rapid logging that might occur during error cascades
      for (var i = 0; i < 5; i++) {
        ErrorLogService.instance.log('Rapid error $i');
      }

      final log = ErrorLogService.instance.getFormattedLog();

      // Verify all errors are present
      expect(log, contains('Rapid error 0'));
      expect(log, contains('Rapid error 4'));

      // getFormattedLog shows newest first (reversed), so error 4 appears before error 0
      final error0Index = log.indexOf('Rapid error 0');
      final error4Index = log.indexOf('Rapid error 4');
      expect(
        error4Index,
        lessThan(error0Index),
        reason:
            'Newest error (4) should appear before oldest (0) in formatted log',
      );
    });
  });
}
