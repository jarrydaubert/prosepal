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
  const AiNetworkException(super.message, {super.originalError, super.errorCode});
}

/// Content blocked by safety filters
class AiContentBlockedException extends AiServiceException {
  const AiContentBlockedException(super.message, {super.originalError, super.errorCode});
}

/// Rate limiting or quota exceeded
class AiRateLimitException extends AiServiceException {
  const AiRateLimitException(super.message, {super.originalError, super.errorCode});
}

/// Model or service temporarily unavailable
class AiUnavailableException extends AiServiceException {
  const AiUnavailableException(super.message, {super.originalError, super.errorCode});
}

/// Invalid or empty response from model
class AiEmptyResponseException extends AiServiceException {
  const AiEmptyResponseException(super.message, {super.originalError, super.errorCode});
}

/// Response parsing failed
class AiParseException extends AiServiceException {
  const AiParseException(super.message, {super.originalError, super.errorCode});
}

class AiService {
  AiService();

  GenerativeModel? _model;
  final _uuid = const Uuid();

  GenerativeModel get model {
    _model ??= FirebaseAI.googleAI().generativeModel(
      model: AiConfig.model,
      generationConfig: GenerationConfig(
        temperature: AiConfig.temperature,
        topK: AiConfig.topK,
        topP: AiConfig.topP,
        maxOutputTokens: AiConfig.maxOutputTokens,
      ),
      safetySettings: [
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
      ],
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
      if (response.promptFeedback?.blockReason != null) {
        throw AiContentBlockedException(
          'Content was blocked: ${response.promptFeedback?.blockReason}',
        );
      }

      final text = response.text ?? '';

      if (text.isEmpty) {
        throw const AiEmptyResponseException(
          'The AI model returned an empty response. Please try again.',
          errorCode: 'EMPTY_RESPONSE',
        );
      }

      final messages = _parseMessages(
        text,
        occasion: occasion,
        relationship: relationship,
        tone: tone,
        recipientName: recipientName,
        personalDetails: personalDetails,
      );

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

  String _buildPrompt({
    required Occasion occasion,
    required Relationship relationship,
    required Tone tone,
    required MessageLength length,
    String? recipientName,
    String? personalDetails,
  }) {
    final recipientPart = recipientName != null && recipientName.isNotEmpty
        ? "Recipient's name: $recipientName"
        : '';

    final detailsPart = personalDetails != null && personalDetails.isNotEmpty
        ? 'Personal context to weave in naturally: $personalDetails'
        : '';

    return '''
You are an expert at crafting heartfelt, memorable greeting card messages. Your messages consistently make recipients feel truly seen and valued.

**Your Task:** Write exactly 3 unique message options for a greeting card.

**Context:**
- Occasion: ${occasion.prompt}
- Relationship: ${relationship.prompt}  
- Desired tone: ${tone.prompt}
- Message length: ${length.prompt}
${recipientPart.isNotEmpty ? '- $recipientPart' : ''}
${detailsPart.isNotEmpty ? '- $detailsPart' : ''}

**Guidelines:**
- Length: ${length.prompt} - this is important, respect the requested length
- Make each message feel personal and specific, never generic or template-like
- Each option should take a distinctly different emotional angle or approach
- If a name is provided, incorporate it naturally (not just at the start)
- If personal details are given, weave them in authentically
- Capture the essence of the relationship
- Use vivid, emotionally resonant language appropriate to the tone

**Format Rules:**
- NO greetings (no "Dear...", "Hi...", etc.)
- NO sign-offs (no "Love,", "Best wishes,", "Sincerely,", etc.)
- Just the message body itself

**Output Format (follow exactly):**
MESSAGE 1:
[First message]

MESSAGE 2:
[Second message]

MESSAGE 3:
[Third message]
''';
  }

  List<GeneratedMessage> _parseMessages(
    String response, {
    required Occasion occasion,
    required Relationship relationship,
    required Tone tone,
    String? recipientName,
    String? personalDetails,
  }) {
    final messages = <GeneratedMessage>[];
    final now = DateTime.now().toUtc();

    // Split by MESSAGE markers
    final pattern = RegExp(r'MESSAGE\s*\d+:\s*', caseSensitive: false);
    final parts = response.split(pattern);

    for (final part in parts) {
      final trimmed = part.trim();
      if (trimmed.isNotEmpty && trimmed.length > 10) {
        messages.add(
          GeneratedMessage(
            id: _uuid.v4(),
            text: trimmed,
            occasion: occasion,
            relationship: relationship,
            tone: tone,
            createdAt: now,
            recipientName: recipientName,
            personalDetails: personalDetails,
          ),
        );
      }
    }

    // Fallback: if parsing failed, treat whole response as one message
    if (messages.isEmpty && response.trim().isNotEmpty) {
      messages.add(
        GeneratedMessage(
          id: _uuid.v4(),
          text: response.trim(),
          occasion: occasion,
          relationship: relationship,
          tone: tone,
          createdAt: now,
          recipientName: recipientName,
          personalDetails: personalDetails,
        ),
      );
    }

    return messages.take(3).toList();
  }
}
