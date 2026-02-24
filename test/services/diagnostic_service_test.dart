import 'package:flutter_test/flutter_test.dart';
import 'package:prosepal/core/services/diagnostic_service.dart';
import 'package:prosepal/core/services/log_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await Log.clearUserId();
    Log.clearBuffer();
  });

  group('DiagnosticService identity helpers', () {
    test('formats optional IDs for diagnostics', () {
      expect(DiagnosticService.formatOptionalIdForTesting(null), '(none)');
      expect(DiagnosticService.formatOptionalIdForTesting(''), '(none)');
      expect(
        DiagnosticService.formatOptionalIdForTesting('1234567890'),
        '12345678...',
      );
    });

    test('identity status is aligned for authenticated user', () {
      final status = DiagnosticService.identityStatusForTesting(
        'user-123',
        'user-123',
        'user-123',
      );
      expect(status, 'Aligned');
    });

    test('identity status is aligned for signed-out anonymous user', () {
      final status = DiagnosticService.identityStatusForTesting(
        null,
        'anon_abc',
        null,
      );
      expect(status, 'Aligned');
    });

    test('identity status flags mismatched telemetry', () {
      final status = DiagnosticService.identityStatusForTesting(
        'user-123',
        'user-123',
        null,
      );
      expect(status, 'Needs review');
    });
  });

  group('DiagnosticService report redaction', () {
    test('standard report redacts privacy-sensitive fields', () async {
      Log.info('Support context', {
        'email': 'user@example.com',
        'prompt': 'Need a birthday message',
        'token': 'secret-token',
      });

      final report = await DiagnosticService.generateReport();

      expect(report, contains('email=[REDACTED]'));
      expect(report, contains('prompt=[REDACTED]'));
      expect(report, contains('token=[REDACTED]'));
      expect(report, isNot(contains('user@example.com')));
      expect(report, isNot(contains('Need a birthday message')));
    });

    test(
      'advanced report keeps non-secret fields but still redacts secrets',
      () async {
        Log.info('Support context', {
          'email': 'user@example.com',
          'prompt': 'Need a birthday message',
          'token': 'secret-token',
        });

        final report = await DiagnosticService.generateReport(
          includeSensitiveLogs: true,
        );

        expect(report, contains('email=user@example.com'));
        expect(report, contains('prompt=Need a birthday message'));
        expect(report, contains('token=[REDACTED]'));
      },
    );
  });
}
