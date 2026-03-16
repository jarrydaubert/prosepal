import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

typedef FeedbackInvokeRequest =
    Future<void> Function({
      required String accessToken,
      required Map<String, dynamic> body,
    });

/// Sends support feedback through an authenticated server-side delivery path.
class FeedbackService {
  FeedbackService({
    String? Function()? accessTokenProvider,
    String? Function()? userIdProvider,
    FeedbackInvokeRequest? invokeRequest,
  }) : _accessTokenProvider =
           accessTokenProvider ??
           (() => Supabase.instance.client.auth.currentSession?.accessToken),
       _userIdProvider =
           userIdProvider ??
           (() => Supabase.instance.client.auth.currentUser?.id),
       _invokeRequest = invokeRequest ?? _defaultInvokeRequest;

  static const requestTimeout = Duration(seconds: 20);
  static const maxMessageLength = 4000;
  static const maxDiagnosticLength = 24000;

  final String? Function() _accessTokenProvider;
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

    final accessToken = _accessTokenProvider();
    if (accessToken == null || accessToken.isEmpty) {
      throw const FeedbackAuthRequiredException();
    }

    final body = <String, dynamic>{
      'message': trimmedMessage,
      'include_sensitive_logs': includeSensitiveLogs,
      if (normalizedDiagnostics != null && normalizedDiagnostics.isNotEmpty)
        'diagnostic_report': normalizedDiagnostics,
    };

    try {
      await _invokeRequest(accessToken: accessToken, body: body).timeout(
        requestTimeout,
        onTimeout: () => throw const FeedbackSubmissionException(
          'Feedback request timed out. Please try again.',
        ),
      );
      Log.info('Feedback submitted successfully', {
        'hasDiagnostics': normalizedDiagnostics != null,
        'includeSensitiveLogs': includeSensitiveLogs,
        'userId': _truncateId(_userIdProvider()),
      });
    } on FeedbackAuthRequiredException {
      rethrow;
    } on FeedbackSubmissionException {
      rethrow;
    } on FunctionException catch (e) {
      if (e.status == 401 || e.status == 403) {
        throw const FeedbackAuthRequiredException();
      }
      throw FeedbackSubmissionException(_messageForFunctionError(e));
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

  static Future<void> _defaultInvokeRequest({
    required String accessToken,
    required Map<String, dynamic> body,
  }) async {
    await Supabase.instance.client.functions.invoke(
      'send-feedback',
      headers: {'Authorization': 'Bearer $accessToken'},
      body: body,
    );
  }

  static String _messageForFunctionError(FunctionException error) {
    final responseDetails = error.details;
    if (responseDetails is Map<String, dynamic>) {
      final message = responseDetails['error'];
      if (message is String && message.trim().isNotEmpty) {
        return message;
      }
    }

    final reason = error.reasonPhrase?.trim();
    if (reason != null && reason.isNotEmpty) {
      return 'Feedback could not be sent: $reason';
    }

    return 'Unable to submit feedback right now. Please try again.';
  }

  static String _truncateId(String? userId) {
    if (userId == null || userId.isEmpty) return '(none)';
    return userId.length <= 8 ? userId : userId.substring(0, 8);
  }
}
