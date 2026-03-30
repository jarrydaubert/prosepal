import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:prosepal/core/services/feedback_service.dart';

void main() {
  group('FeedbackService', () {
    test('maps 401 function response to auth required', () async {
      final service = FeedbackService(
        accessTokenProvider: () => 'token-123',
        userIdProvider: () => null,
        invokeRequest: ({required accessToken, required body}) async =>
            http.Response(
              '{"error":"Authentication required"}',
              401,
              request: http.Request('POST', Uri.parse('https://example.com')),
              reasonPhrase: 'Unauthorized',
            ),
      );

      expect(
        () => service.submitFeedback(
          message: 'Need help',
          includeSensitiveLogs: false,
        ),
        throwsA(isA<FeedbackAuthRequiredException>()),
      );
    });

    test('submits trimmed payload through server-side invoker', () async {
      String? capturedAccessToken;
      Map<String, dynamic>? capturedBody;

      final service = FeedbackService(
        accessTokenProvider: () => 'token-123',
        userIdProvider: () => 'user-12345678',
        invokeRequest: ({required accessToken, required body}) async {
          capturedAccessToken = accessToken;
          capturedBody = body;
          return http.Response(
            '{"success":true}',
            200,
            request: http.Request('POST', Uri.parse('https://example.com')),
          );
        },
      );

      await service.submitFeedback(
        message: '  Need a better feedback flow  ',
        diagnosticReport: '  diag report  ',
        includeSensitiveLogs: true,
      );

      expect(capturedAccessToken, 'token-123');
      expect(capturedBody?['message'], 'Need a better feedback flow');
      expect(capturedBody?['diagnostic_report'], 'diag report');
      expect(capturedBody?['include_sensitive_logs'], true);
    });

    test('does not fail local auth precheck when invoker can submit', () async {
      var submitCount = 0;

      final service = FeedbackService(
        accessTokenProvider: () => 'token-123',
        userIdProvider: () => 'user-12345678',
        invokeRequest: ({required accessToken, required body}) async {
          submitCount++;
          return http.Response(
            '{"success":true}',
            200,
            request: http.Request('POST', Uri.parse('https://example.com')),
          );
        },
      );

      await service.submitFeedback(
        message: 'Ship the fix',
        includeSensitiveLogs: false,
      );

      expect(submitCount, 1);
    });

    test('requires authenticated token before invoking function', () async {
      var invoked = false;

      final service = FeedbackService(
        accessTokenProvider: () => null,
        userIdProvider: () => 'user-12345678',
        invokeRequest: ({required accessToken, required body}) async {
          invoked = true;
          return http.Response(
            '{"success":true}',
            200,
            request: http.Request('POST', Uri.parse('https://example.com')),
          );
        },
      );

      expect(
        () => service.submitFeedback(
          message: 'Need help',
          includeSensitiveLogs: false,
        ),
        throwsA(isA<FeedbackAuthRequiredException>()),
      );
      expect(invoked, isFalse);
    });

    test(
      'maps non-auth HTTP errors to a user-facing submission message',
      () async {
        final service = FeedbackService(
          accessTokenProvider: () => 'token-123',
          userIdProvider: () => 'user-12345678',
          invokeRequest: ({required accessToken, required body}) async =>
              http.Response(
                '{"error":"Feedback delivery timed out. Please try again."}',
                504,
                request: http.Request('POST', Uri.parse('https://example.com')),
                reasonPhrase: 'Gateway Timeout',
              ),
        );

        expect(
          () => service.submitFeedback(
            message: 'Need help',
            includeSensitiveLogs: false,
          ),
          throwsA(
            isA<FeedbackSubmissionException>().having(
              (e) => e.message,
              'message',
              'Feedback delivery timed out. Please try again.',
            ),
          ),
        );
      },
    );
  });
}
