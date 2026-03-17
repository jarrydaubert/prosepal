import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/app_config.dart';
import 'log_service.dart';

class FeedbackAuthRequiredException implements Exception {
  const FeedbackAuthRequiredException();

  @override
  String toString() => 'FeedbackAuthRequiredException';
}

class FeedbackSubmissionException implements Exception {
  const FeedbackSubmissionException(this.message);

  final String message;

  @override
  String toString() => 'FeedbackSubmissionException($message)';
}

typedef FeedbackAccessTokenProvider = String? Function();

typedef FeedbackSendRequest =
    Future<http.Response> Function({
      required Uri uri,
      required Map<String, String> headers,
      required String body,
    });

typedef FeedbackInvokeRequest =
    Future<http.Response> Function({
      required String accessToken,
      required Map<String, dynamic> body,
    });

/// Sends support feedback through an authenticated server-side delivery path.
class FeedbackService {
  FeedbackService({
    FeedbackAccessTokenProvider? accessTokenProvider,
    String? Function()? userIdProvider,
    FeedbackInvokeRequest? invokeRequest,
    FeedbackSendRequest? sendRequest,
  }) : _accessTokenProvider =
           accessTokenProvider ??
           (() => Supabase.instance.client.auth.currentSession?.accessToken),
       _userIdProvider =
           userIdProvider ??
           (() => Supabase.instance.client.auth.currentUser?.id),
       _invokeRequest =
           invokeRequest ??
           _buildDefaultInvokeRequest(sendRequest ?? _defaultSendRequest);

  static const requestTimeout = Duration(seconds: 20);
  static const maxMessageLength = 4000;
  static const maxDiagnosticLength = 24000;

  final FeedbackAccessTokenProvider _accessTokenProvider;
  final String? Function() _userIdProvider;
  final FeedbackInvokeRequest _invokeRequest;

  Future<void> submitFeedback({
    required String message,
    String? diagnosticReport,
    required bool includeSensitiveLogs,
  }) async {
    final trimmedMessage = message.trim();
    if (trimmedMessage.isEmpty) {
      throw const FeedbackSubmissionException('Please enter a message');
    }
    if (trimmedMessage.length > maxMessageLength) {
      throw const FeedbackSubmissionException(
        'Please keep feedback under 4000 characters.',
      );
    }

    final normalizedDiagnostics = diagnosticReport?.trim();
    if (normalizedDiagnostics != null &&
        normalizedDiagnostics.length > maxDiagnosticLength) {
      throw const FeedbackSubmissionException(
        'Diagnostics are too large to send directly. Use copy/share instead.',
      );
    }

    final body = <String, dynamic>{
      'message': trimmedMessage,
      'include_sensitive_logs': includeSensitiveLogs,
      if (normalizedDiagnostics != null && normalizedDiagnostics.isNotEmpty)
        'diagnostic_report': normalizedDiagnostics,
    };
    final accessToken = _accessTokenProvider()?.trim();
    if (accessToken == null || accessToken.isEmpty) {
      Log.warning('Feedback submission blocked: no access token', {
        'userId': _truncateId(_userIdProvider()),
      });
      throw const FeedbackAuthRequiredException();
    }

    try {
      Log.info('Feedback submission started', {
        'hasDiagnostics': normalizedDiagnostics != null,
        'includeSensitiveLogs': includeSensitiveLogs,
        'jwtShape': _jwtShape(accessToken),
        'userId': _truncateId(_userIdProvider()),
      });
      final response =
          await _invokeRequest(accessToken: accessToken, body: body).timeout(
            requestTimeout,
            onTimeout: () => throw const FeedbackSubmissionException(
              'Feedback request timed out. Please try again.',
            ),
          );
      if (response.statusCode == 401 || response.statusCode == 403) {
        final details = _decodeJsonMap(response.body);
        Log.warning('Feedback submission rejected by function auth', {
          'status': response.statusCode,
          'reasonPhrase': response.reasonPhrase ?? '(none)',
          'details': details ?? response.body,
          'jwtShape': _jwtShape(accessToken),
          'userId': _truncateId(_userIdProvider()),
        });
        throw const FeedbackAuthRequiredException();
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        final details = _decodeJsonMap(response.body);
        throw FeedbackSubmissionException(
          _messageForHttpError(response, details),
        );
      }
      Log.info('Feedback submitted successfully', {
        'hasDiagnostics': normalizedDiagnostics != null,
        'includeSensitiveLogs': includeSensitiveLogs,
        'userId': _truncateId(_userIdProvider()),
      });
    } on FeedbackAuthRequiredException {
      Log.warning('Feedback submission blocked: auth required', {
        'userId': _truncateId(_userIdProvider()),
      });
      rethrow;
    } on FeedbackSubmissionException catch (e) {
      Log.warning('Feedback submission failed', {
        'message': e.message,
        'userId': _truncateId(_userIdProvider()),
      });
      rethrow;
    } on PostgrestException {
      throw const FeedbackSubmissionException(
        'Unable to submit feedback right now. Please try again.',
      );
    } on Exception catch (e, stackTrace) {
      Log.warning('Feedback submission failed', {
        'error': '$e',
        'userId': _truncateId(_userIdProvider()),
      });
      if (kDebugMode) {
        Log.error('Unexpected feedback submission failure', e, stackTrace);
      }
      throw const FeedbackSubmissionException(
        'Unable to submit feedback right now. Please try again.',
      );
    }
  }

  static Future<http.Response> _defaultInvokeRequest({
    required String accessToken,
    required Map<String, dynamic> body,
    required FeedbackSendRequest sendRequest,
  }) {
    final uri = Uri.parse(
      '${AppConfig.supabaseUrl}/functions/v1/send-feedback',
    );
    return sendRequest(
      uri: uri,
      headers: {
        'Authorization': 'Bearer $accessToken',
        'apikey': AppConfig.supabaseAnonKey,
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );
  }

  static FeedbackInvokeRequest _buildDefaultInvokeRequest(
    FeedbackSendRequest sendRequest,
  ) =>
      ({required String accessToken, required Map<String, dynamic> body}) =>
          _defaultInvokeRequest(
            accessToken: accessToken,
            body: body,
            sendRequest: sendRequest,
          );

  static Future<http.Response> _defaultSendRequest({
    required Uri uri,
    required Map<String, String> headers,
    required String body,
  }) => http.post(uri, headers: headers, body: body);

  static String _messageForHttpError(
    http.Response response,
    Map<String, dynamic>? details,
  ) {
    final message = details?['error'];
    if (message is String && message.trim().isNotEmpty) {
      return message;
    }

    final reason = response.reasonPhrase?.trim();
    if (reason != null && reason.isNotEmpty) {
      return 'Feedback could not be sent: $reason';
    }

    return 'Unable to submit feedback right now. Please try again.';
  }

  static Map<String, dynamic>? _decodeJsonMap(String body) {
    if (body.trim().isEmpty) return null;
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
    } on FormatException {
      return null;
    }
    return null;
  }

  static String _jwtShape(String token) {
    final segments = '.'.allMatches(token).length + 1;
    return 'len=${token.length},segments=$segments';
  }

  static String _truncateId(String? userId) {
    if (userId == null || userId.isEmpty) return '(none)';
    return userId.length <= 8 ? userId : userId.substring(0, 8);
  }
}
