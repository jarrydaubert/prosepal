import 'package:flutter_test/flutter_test.dart';
import 'package:prosepal/core/services/diagnostic_service.dart';

void main() {
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
}
