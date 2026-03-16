import 'package:flutter_test/flutter_test.dart';
import 'package:prosepal/core/services/feedback_service.dart';

void main() {
  group('FeedbackService', () {
    test('requires authenticated access token', () async {
      final service = FeedbackService(accessTokenProvider: () => null);

      expect(
        () => service.submitFeedback(
          message: 'Need help',
          includeSensitiveLogs: false,
        ),
        throwsA(isA<FeedbackAuthRequiredException>()),
      );
    });

    test('submits trimmed payload through server-side invoker', () async {
      String? capturedToken;
      Map<String, dynamic>? capturedBody;

      final service = FeedbackService(
        accessTokenProvider: () => 'token-123',
        userIdProvider: () => 'user-12345678',
        invokeRequest: ({required accessToken, required body}) async {
          capturedToken = accessToken;
          capturedBody = body;
        },
      );

      await service.submitFeedback(
        message: '  Need a better feedback flow  ',
        diagnosticReport: '  diag report  ',
        includeSensitiveLogs: true,
      );

      expect(capturedToken, 'token-123');
      expect(capturedBody?['message'], 'Need a better feedback flow');
      expect(capturedBody?['diagnostic_report'], 'diag report');
      expect(capturedBody?['include_sensitive_logs'], true);
    });
  });
}
