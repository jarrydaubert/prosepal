import 'dart:convert';
import 'dart:math';

import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../config/ai_config.dart';
import '../models/models.dart';
import 'error_log_service.dart';
import 'log_service.dart';

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

/// Error classification result for testability
class AiErrorClassification {
  const AiErrorClassification({
    required this.exceptionType,
    required this.message,
    required this.errorCode,
    this.isRetryable = false,
  });

  final Type exceptionType;
  final String message;
  final String errorCode;
  final bool isRetryable;
}

class AiService {
  AiService();

  GenerativeModel? _model;
  final _uuid = const Uuid();
  final _random = Random();

  /// Create typed exception from classification result
  static AiServiceException _createException(
    AiErrorClassification classification,
    Object originalError,
  ) {
    return switch (classification.exceptionType) {
      const (AiNetworkException) => AiNetworkException(
        classification.message,
        originalError: originalError,
        errorCode: classification.errorCode,
      ),
      const (AiContentBlockedException) => AiContentBlockedException(
        classification.message,
        originalError: originalError,
        errorCode: classification.errorCode,
      ),
      const (AiRateLimitException) => AiRateLimitException(
        classification.message,
        originalError: originalError,
        errorCode: classification.errorCode,
      ),
      const (AiUnavailableException) => AiUnavailableException(
        classification.message,
        originalError: originalError,
        errorCode: classification.errorCode,
      ),
      _ => AiServiceException(
        classification.message,
        originalError: originalError,
        errorCode: classification.errorCode,
      ),
    };
  }

  // ============================================================
  // ERROR CLASSIFICATION - Extracted for testability
  // ============================================================

  /// Classify Firebase AI errors based on message content
  /// Returns classification with exception type, user message, and retry info
  @visibleForTesting
  static AiErrorClassification classifyFirebaseAIError(String errorMessage) {
    final message = errorMessage.toLowerCase();

    // Rate limiting
    if (message.contains('rate') || message.contains('quota')) {
      return AiErrorClassification(
        exceptionType: AiRateLimitException,
        message:
            'Our servers are busy right now. Please wait a moment and try again.',
        errorCode: 'RATE_LIMIT',
        isRetryable: true,
      );
    }

    // Network errors
    if (message.contains('network') || message.contains('connection')) {
      return AiErrorClassification(
        exceptionType: AiNetworkException,
        message: 'Unable to connect. Please check your internet connection.',
        errorCode: 'NETWORK_ERROR',
        isRetryable: false,
      );
    }

    // Content blocked
    if (message.contains('blocked') || message.contains('safety')) {
      return AiErrorClassification(
        exceptionType: AiContentBlockedException,
        message:
            'Your message details triggered our safety filters. '
            'Try removing any sensitive words or phrases.',
        errorCode: 'CONTENT_BLOCKED',
        isRetryable: false,
      );
    }

    // Service unavailable
    if (message.contains('unavailable') || message.contains('503')) {
      return AiErrorClassification(
        exceptionType: AiUnavailableException,
        message:
            'The AI service is temporarily unavailable. Please try again in a few minutes.',
        errorCode: 'SERVICE_UNAVAILABLE',
        isRetryable: true,
      );
    }

    // Timeout
    if (message.contains('timeout')) {
      return AiErrorClassification(
        exceptionType: AiNetworkException,
        message:
            'The request timed out. Please check your connection and try again.',
        errorCode: 'TIMEOUT',
        isRetryable: true,
      );
    }

    // Invalid request
    if (message.contains('invalid') || message.contains('malformed')) {
      return AiErrorClassification(
        exceptionType: AiServiceException,
        message: 'There was an issue with the request. Please try again.',
        errorCode: 'INVALID_REQUEST',
        isRetryable: false,
      );
    }

    // Generic fallback
    return const AiErrorClassification(
      exceptionType: AiServiceException,
      message: 'Unable to generate messages right now. Please try again.',
      errorCode: 'FIREBASE_AI_ERROR',
      isRetryable: false,
    );
  }

  /// Classify general (non-Firebase) errors based on error string
  @visibleForTesting
  static AiErrorClassification classifyGeneralError(String errorString) {
    final errorStr = errorString.toLowerCase();

    // Network errors
    if (errorStr.contains('network') ||
        errorStr.contains('socket') ||
        errorStr.contains('connection') ||
        errorStr.contains('host')) {
      return AiErrorClassification(
        exceptionType: AiNetworkException,
        message: 'Unable to connect. Please check your internet connection.',
        errorCode: 'NETWORK_ERROR',
        isRetryable: false,
      );
    }

    // Timeout
    if (errorStr.contains('timeout')) {
      return AiErrorClassification(
        exceptionType: AiNetworkException,
        message: 'The request timed out. Please try again.',
        errorCode: 'TIMEOUT',
        isRetryable: true,
      );
    }

    // Permission errors
    if (errorStr.contains('permission') || errorStr.contains('denied')) {
      return AiErrorClassification(
        exceptionType: AiServiceException,
        message: 'Permission error. Please restart the app and try again.',
        errorCode: 'PERMISSION_DENIED',
        isRetryable: false,
      );
    }

    // Generic fallback
    return const AiErrorClassification(
      exceptionType: AiServiceException,
      message: 'Something unexpected happened. Please try again.',
      errorCode: 'UNKNOWN_ERROR',
      isRetryable: false,
    );
  }

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
  /// Note: HarmBlockMethod must be null for Google AI (only supported by Vertex AI)
  static final _safetySettings = [
    SafetySetting(HarmCategory.harassment, HarmBlockThreshold.medium, null),
    SafetySetting(HarmCategory.hateSpeech, HarmBlockThreshold.medium, null),
    SafetySetting(HarmCategory.sexuallyExplicit, HarmBlockThreshold.high, null),
    SafetySetting(
      HarmCategory.dangerousContent,
      HarmBlockThreshold.medium,
      null,
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
      systemInstruction: Content.system(AiConfig.systemInstruction),
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
    Log.info('AI generation started', {
      'occasion': occasion.label,
      'relationship': relationship.label,
      'tone': tone.label,
      'length': length.name,
    });

    final prompt = buildPrompt(
      occasion: occasion,
      relationship: relationship,
      tone: tone,
      length: length,
      recipientName: recipientName,
      personalDetails: personalDetails,
    );

    return _executeWithRetry(() async {
      Log.info('AI calling generateContent...');
      final response = await model.generateContent([Content.text(prompt)]);
      Log.info('AI response received');

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
      Log.info('AI raw response length: ${jsonText?.length ?? 0}');
      Log.info('AI raw response: $jsonText');
      if (jsonText == null || jsonText.isEmpty) {
        throw const AiEmptyResponseException(
          'The AI model returned an empty response. Please try again.',
          errorCode: 'EMPTY_RESPONSE',
        );
      }

      // Parse structured JSON response
      Log.info('AI parsing JSON response...');
      final messages = parseJsonResponse(
        jsonText,
        occasion: occasion,
        relationship: relationship,
        tone: tone,
        recipientName: recipientName,
        personalDetails: personalDetails,
      );

      Log.info('AI parsed ${messages.length} messages');
      if (messages.isEmpty) {
        Log.warning('AI returned no messages');
        throw const AiEmptyResponseException(
          'No messages were generated. Please try again.',
          errorCode: 'NO_MESSAGES',
        );
      }

      // Log token usage for cost tracking
      final usage = response.usageMetadata;
      Log.info('AI generation success', {
        'messageCount': messages.length,
        'model': AiConfig.model,
        'promptTokens': usage?.promptTokenCount,
        'responseTokens': usage?.candidatesTokenCount,
        'totalTokens': usage?.totalTokenCount,
      });

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
        final classification = classifyFirebaseAIError(e.message);

        if (classification.isRetryable && attempt < AiConfig.maxRetries) {
          // Exponential backoff with jitter (0-20% of delay)
          final delayMs = AiConfig.initialDelayMs * (1 << attempt);
          final jitter = (delayMs * 0.2 * _random.nextDouble()).toInt();
          Log.info('AI retry attempt', {
            'attempt': attempt,
            'delayMs': delayMs + jitter,
          });
          await Future.delayed(Duration(milliseconds: delayMs + jitter));
          continue;
        }

        // Log and throw classified exception
        ErrorLogService.instance.log(e, stackTrace);
        Log.error('Firebase AI error', e, stackTrace, {'attempt': attempt});
        throw _createException(classification, e);
      } catch (e, stackTrace) {
        if (e is AiServiceException) rethrow;

        attempt++;
        final classification = classifyGeneralError(e.toString());

        if (classification.isRetryable && attempt < AiConfig.maxRetries) {
          // Exponential backoff with jitter (0-20% of delay)
          final delayMs = AiConfig.initialDelayMs * (1 << attempt);
          final jitter = (delayMs * 0.2 * _random.nextDouble()).toInt();
          await Future.delayed(Duration(milliseconds: delayMs + jitter));
          continue;
        }

        // Log and throw classified exception
        ErrorLogService.instance.log(e, stackTrace);
        Log.error('Unexpected AI error', e, stackTrace, {'attempt': attempt});
        throw _createException(classification, e);
      }
    }
  }

  /// Build prompt for structured JSON output
  @visibleForTesting
  String buildPrompt({
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

    // System instruction contains static guidelines
    // Prompt only needs dynamic context (saves ~100-150 tokens per call)
    return '''
$context
''';
  }

  /// Parse structured JSON response from Gemini
  /// Uses Dart 3 pattern matching for type-safe extraction
  @visibleForTesting
  List<GeneratedMessage> parseJsonResponse(
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
