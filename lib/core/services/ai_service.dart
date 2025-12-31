import 'dart:convert';

import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../config/ai_config.dart';
import '../models/models.dart';
import 'error_log_service.dart';

/// Exception types for AI service errors
/// Base exception for AI service errors
class AiServiceException implements Exception {
  const AiServiceException(this.message, {this.originalError, this.errorCode});
  final String message;
  final Object? originalError;
  final String? errorCode;

  @override
  String toString() => 'AiServiceException: $message';
}

/// Network connectivity issues
class AiNetworkException extends AiServiceException {
  const AiNetworkException(
    super.message, {
    super.originalError,
    super.errorCode,
  });
}

/// Content blocked by safety filters
class AiContentBlockedException extends AiServiceException {
  const AiContentBlockedException(
    super.message, {
    super.originalError,
    super.errorCode,
  });
}

/// Rate limiting or quota exceeded
class AiRateLimitException extends AiServiceException {
  const AiRateLimitException(
    super.message, {
    super.originalError,
    super.errorCode,
  });
}

/// Model or service temporarily unavailable
class AiUnavailableException extends AiServiceException {
  const AiUnavailableException(
    super.message, {
    super.originalError,
    super.errorCode,
  });
}

/// Invalid or empty response from model
class AiEmptyResponseException extends AiServiceException {
  const AiEmptyResponseException(
    super.message, {
    super.originalError,
    super.errorCode,
  });
}

/// Response parsing failed
class AiParseException extends AiServiceException {
  const AiParseException(super.message, {super.originalError, super.errorCode});
}

class AiService {
  AiService();

  GenerativeModel? _model;
  final _uuid = const Uuid();

  /// JSON schema for structured output - 3 message strings
  static final _responseSchema = Schema.object(
    properties: {
      'messages': Schema.array(
        items: Schema.object(
          properties: {
            'text': Schema.string(
              description: 'The greeting card message text',
            ),
          },
        ),
      ),
    },
  );

  /// Safety settings for content generation
  static final _safetySettings = [
    SafetySetting(
      HarmCategory.harassment,
      HarmBlockThreshold.medium,
      HarmBlockMethod.probability,
    ),
    SafetySetting(
      HarmCategory.hateSpeech,
      HarmBlockThreshold.medium,
      HarmBlockMethod.probability,
    ),
    SafetySetting(
      HarmCategory.sexuallyExplicit,
      HarmBlockThreshold.high,
      HarmBlockMethod.probability,
    ),
    SafetySetting(
      HarmCategory.dangerousContent,
      HarmBlockThreshold.medium,
      HarmBlockMethod.probability,
    ),
  ];

  GenerativeModel get model {
    _model ??= FirebaseAI.googleAI().generativeModel(
      model: AiConfig.model,
      generationConfig: GenerationConfig(
        temperature: AiConfig.temperature,
        topK: AiConfig.topK,
        topP: AiConfig.topP,
        maxOutputTokens: AiConfig.maxOutputTokens,
        responseMimeType: 'application/json',
        responseSchema: _responseSchema,
      ),
      safetySettings: _safetySettings,
    );
    return _model!;
  }

  /// Generate messages with proper error handling and retry logic
  /// Throws [AiServiceException] subtypes for different failure modes
  Future<GenerationResult> generateMessages({
    required Occasion occasion,
    required Relationship relationship,
    required Tone tone,
    MessageLength length = MessageLength.standard,
    String? recipientName,
    String? personalDetails,
  }) async {
    final prompt = _buildPrompt(
      occasion: occasion,
      relationship: relationship,
      tone: tone,
      length: length,
      recipientName: recipientName,
      personalDetails: personalDetails,
    );

    return _executeWithRetry(() async {
      final response = await model.generateContent([Content.text(prompt)]);

      // Check for blocked content
      if (response.promptFeedback?.blockReason case final reason?) {
        throw AiContentBlockedException(
          'Your message details triggered our safety filters. '
          'Try removing any sensitive words or phrases.',
          errorCode: 'CONTENT_BLOCKED',
          originalError: reason,
        );
      }

      final jsonText = response.text;
      if (jsonText == null || jsonText.isEmpty) {
        throw const AiEmptyResponseException(
          'The AI model returned an empty response. Please try again.',
          errorCode: 'EMPTY_RESPONSE',
        );
      }

      // Parse structured JSON response
      final messages = _parseJsonResponse(
        jsonText,
        occasion: occasion,
        relationship: relationship,
        tone: tone,
        recipientName: recipientName,
        personalDetails: personalDetails,
      );

      if (messages.isEmpty) {
        throw const AiEmptyResponseException(
          'No messages were generated. Please try again.',
          errorCode: 'NO_MESSAGES',
        );
      }

      return GenerationResult(
        messages: messages,
        occasion: occasion,
        relationship: relationship,
        tone: tone,
        recipientName: recipientName,
        personalDetails: personalDetails,
      );
    });
  }

  /// Executes operation with exponential backoff retry for transient errors
  Future<T> _executeWithRetry<T>(Future<T> Function() operation) async {
    var attempt = 0;
    while (true) {
      try {
        return await operation();
      } on FirebaseAIException catch (e, stackTrace) {
        attempt++;
        final message = e.message.toLowerCase();
        final isRetryable =
            message.contains('rate') ||
            message.contains('quota') ||
            message.contains('unavailable') ||
            message.contains('timeout');

        if (isRetryable && attempt < AiConfig.maxRetries) {
          // Exponential backoff with jitter
          final delayMs = AiConfig.initialDelayMs * (1 << attempt);
          final jitter =
              (delayMs * 0.2 * (DateTime.now().millisecond % 10) / 10).toInt();
          if (kDebugMode) {
            debugPrint('Retry attempt $attempt after ${delayMs + jitter}ms');
          }
          await Future.delayed(Duration(milliseconds: delayMs + jitter));
          continue;
        }

        // Log and categorize error
        ErrorLogService.instance.log(e, stackTrace);
        if (kDebugMode) {
          debugPrint('Firebase AI error: $e');
        }

        // Categorize Firebase AI errors with specific messages
        if (message.contains('rate') || message.contains('quota')) {
          throw AiRateLimitException(
            'Our servers are busy right now. Please wait a moment and try again.',
            originalError: e,
            errorCode: 'RATE_LIMIT',
          );
        }
        if (message.contains('network') || message.contains('connection')) {
          throw AiNetworkException(
            'Unable to connect. Please check your internet connection.',
            originalError: e,
            errorCode: 'NETWORK_ERROR',
          );
        }
        if (message.contains('blocked') || message.contains('safety')) {
          throw AiContentBlockedException(
            'Your message details triggered our safety filters. '
            'Try removing any sensitive words or phrases.',
            originalError: e,
            errorCode: 'CONTENT_BLOCKED',
          );
        }
        if (message.contains('unavailable') || message.contains('503')) {
          throw AiUnavailableException(
            'The AI service is temporarily unavailable. Please try again in a few minutes.',
            originalError: e,
            errorCode: 'SERVICE_UNAVAILABLE',
          );
        }
        if (message.contains('timeout')) {
          throw AiNetworkException(
            'The request timed out. Please check your connection and try again.',
            originalError: e,
            errorCode: 'TIMEOUT',
          );
        }
        if (message.contains('invalid') || message.contains('malformed')) {
          throw AiServiceException(
            'There was an issue with the request. Please try again.',
            originalError: e,
            errorCode: 'INVALID_REQUEST',
          );
        }

        // Generic Firebase AI error - provide context
        throw AiServiceException(
          'Unable to generate messages right now. Please try again.',
          originalError: e,
          errorCode: 'FIREBASE_AI_ERROR',
        );
      } catch (e, stackTrace) {
        if (e is AiServiceException) rethrow;

        attempt++;
        final errorStr = e.toString().toLowerCase();
        final isRetryable =
            errorStr.contains('timeout') || errorStr.contains('unavailable');

        if (isRetryable && attempt < AiConfig.maxRetries) {
          final delayMs = AiConfig.initialDelayMs * (1 << attempt);
          await Future.delayed(Duration(milliseconds: delayMs));
          continue;
        }

        // Log error for feedback reports
        ErrorLogService.instance.log(e, stackTrace);
        if (kDebugMode) {
          debugPrint('Unexpected AI error: $e');
        }

        // Categorize general errors
        if (errorStr.contains('network') ||
            errorStr.contains('socket') ||
            errorStr.contains('connection') ||
            errorStr.contains('host')) {
          throw AiNetworkException(
            'Unable to connect. Please check your internet connection.',
            originalError: e,
            errorCode: 'NETWORK_ERROR',
          );
        }
        if (errorStr.contains('timeout')) {
          throw AiNetworkException(
            'The request timed out. Please try again.',
            originalError: e,
            errorCode: 'TIMEOUT',
          );
        }
        if (errorStr.contains('permission') || errorStr.contains('denied')) {
          throw AiServiceException(
            'Permission error. Please restart the app and try again.',
            originalError: e,
            errorCode: 'PERMISSION_DENIED',
          );
        }

        // Fallback with more context
        throw AiServiceException(
          'Something unexpected happened. Please try again.',
          originalError: e,
          errorCode: 'UNKNOWN_ERROR',
        );
      }
    }
  }

  /// Build prompt for structured JSON output
  String _buildPrompt({
    required Occasion occasion,
    required Relationship relationship,
    required Tone tone,
    required MessageLength length,
    String? recipientName,
    String? personalDetails,
  }) {
    final context = StringBuffer()
      ..writeln('Occasion: ${occasion.prompt}')
      ..writeln('Relationship: ${relationship.prompt}')
      ..writeln('Tone: ${tone.prompt}')
      ..writeln('Length: ${length.prompt}');

    if (recipientName case final name? when name.isNotEmpty) {
      context.writeln("Recipient's name: $name");
    }
    if (personalDetails case final details? when details.isNotEmpty) {
      context.writeln('Personal context: $details');
    }

    return '''
You are an expert at crafting heartfelt, memorable greeting card messages.

Write exactly 3 unique message options for a greeting card.

Context:
$context

Guidelines:
- Respect the requested length: ${length.prompt}
- Make each message personal and specific, never generic
- Each option should take a distinctly different emotional angle
- If a name is provided, incorporate it naturally
- If personal details are given, weave them in authentically
- Use emotionally resonant language appropriate to the tone

Format rules:
- NO greetings (no "Dear...", "Hi...", etc.)
- NO sign-offs (no "Love,", "Best wishes,", "Sincerely,", etc.)
- Just the message body itself
''';
  }

  /// Parse structured JSON response from Gemini
  /// Uses Dart 3 pattern matching for type-safe extraction
  List<GeneratedMessage> _parseJsonResponse(
    String jsonText, {
    required Occasion occasion,
    required Relationship relationship,
    required Tone tone,
    String? recipientName,
    String? personalDetails,
  }) {
    try {
      final json = jsonDecode(jsonText);
      final now = DateTime.now().toUtc();

      // Dart 3 pattern matching for type-safe JSON extraction
      if (json case {'messages': final List<dynamic> messageList}) {
        return [
          for (final item in messageList)
            if (item case {
              'text': final String text,
            } when text.trim().isNotEmpty)
              GeneratedMessage(
                id: _uuid.v4(),
                text: text.trim(),
                occasion: occasion,
                relationship: relationship,
                tone: tone,
                createdAt: now,
                recipientName: recipientName,
                personalDetails: personalDetails,
              ),
        ];
      }

      // Schema mismatch - log and throw
      throw AiParseException(
        'Unexpected response format from AI model.',
        errorCode: 'SCHEMA_MISMATCH',
        originalError: 'Expected {messages: [{text: ...}]}, got: $jsonText',
      );
    } on FormatException catch (e) {
      throw AiParseException(
        'Failed to parse AI response. Please try again.',
        errorCode: 'JSON_PARSE_ERROR',
        originalError: e,
      );
    }
  }
}
