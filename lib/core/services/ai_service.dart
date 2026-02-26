import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:uuid/uuid.dart';

import '../models/models.dart';

/// Exception types for AI service errors
class AiServiceException implements Exception {
  const AiServiceException(this.message, {this.originalError});
  final String message;
  final Object? originalError;

  @override
  String toString() => 'AiServiceException: $message';
}

class AiNetworkException extends AiServiceException {
  const AiNetworkException(super.message, {super.originalError});
}

class AiContentBlockedException extends AiServiceException {
  const AiContentBlockedException(super.message, {super.originalError});
}

class AiRateLimitException extends AiServiceException {
  const AiRateLimitException(super.message, {super.originalError});
}

class AiService {
  AiService({required String apiKey}) : _apiKey = apiKey;

  final String _apiKey;
  GenerativeModel? _model;
  final _uuid = Uuid();

  GenerativeModel get model {
    _model ??= GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: _apiKey,
      generationConfig: GenerationConfig(
        temperature: 0.9,
        topK: 40,
        topP: 0.95,
        maxOutputTokens: 1024,
      ),
      safetySettings: [
        SafetySetting(HarmCategory.harassment, HarmBlockThreshold.medium),
        SafetySetting(HarmCategory.hateSpeech, HarmBlockThreshold.medium),
        SafetySetting(HarmCategory.sexuallyExplicit, HarmBlockThreshold.high),
        SafetySetting(HarmCategory.dangerousContent, HarmBlockThreshold.medium),
      ],
    );
    return _model!;
  }

  /// Generate messages with proper error handling
  /// Throws [AiServiceException] subtypes for different failure modes
  Future<GenerationResult> generateMessages({
    required Occasion occasion,
    required Relationship relationship,
    required Tone tone,
    String? recipientName,
    String? personalDetails,
  }) async {
    final prompt = _buildPrompt(
      occasion: occasion,
      relationship: relationship,
      tone: tone,
      recipientName: recipientName,
      personalDetails: personalDetails,
    );

    try {
      final response = await model.generateContent([Content.text(prompt)]);

      // Check for blocked content
      if (response.promptFeedback?.blockReason != null) {
        throw AiContentBlockedException(
          'Content was blocked: ${response.promptFeedback?.blockReason}',
        );
      }

      final text = response.text ?? '';

      if (text.isEmpty) {
        throw const AiServiceException('Empty response from AI model');
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
    } on GenerativeAIException catch (e) {
      // Log in debug mode
      if (kDebugMode) {
        debugPrint('Gemini API error: $e');
      }

      // Categorize the error
      final message = e.message.toLowerCase();
      if (message.contains('rate') || message.contains('quota')) {
        throw AiRateLimitException(
          'Too many requests. Please try again later.',
          originalError: e,
        );
      }
      if (message.contains('network') || message.contains('connection')) {
        throw AiNetworkException(
          'Network error. Please check your connection.',
          originalError: e,
        );
      }
      if (message.contains('blocked') || message.contains('safety')) {
        throw AiContentBlockedException(
          'Content was blocked by safety filters.',
          originalError: e,
        );
      }

      throw AiServiceException(
        'Failed to generate messages. Please try again.',
        originalError: e,
      );
    } catch (e) {
      if (e is AiServiceException) rethrow;

      // Log unexpected errors in debug mode
      if (kDebugMode) {
        debugPrint('Unexpected AI error: $e');
      }

      // Network-related errors
      final errorStr = e.toString().toLowerCase();
      if (errorStr.contains('network') ||
          errorStr.contains('socket') ||
          errorStr.contains('connection')) {
        throw AiNetworkException(
          'Network error. Please check your connection.',
          originalError: e,
        );
      }

      throw AiServiceException(
        'Something went wrong. Please try again.',
        originalError: e,
      );
    }
  }

  String _buildPrompt({
    required Occasion occasion,
    required Relationship relationship,
    required Tone tone,
    String? recipientName,
    String? personalDetails,
  }) {
    final recipientPart = recipientName != null && recipientName.isNotEmpty
        ? 'The recipient\'s name is $recipientName.'
        : '';

    final detailsPart = personalDetails != null && personalDetails.isNotEmpty
        ? 'Additional context: $personalDetails'
        : '';

    return '''
You are a skilled greeting card message writer. Generate exactly 3 different message options for a greeting card.

Context:
- Occasion: ${occasion.prompt}
- Recipient: ${relationship.prompt}
- Tone: ${tone.prompt}
$recipientPart
$detailsPart

Requirements:
1. Each message should be 2-4 sentences
2. Messages should feel personal and genuine, not generic
3. Each option should have a different approach/angle
4. Do NOT include greetings like "Dear [Name]" at the start
5. Do NOT include sign-offs like "Best wishes" or "Love" at the end
6. Just the message body content

Format your response EXACTLY like this:
MESSAGE 1:
[First message here]

MESSAGE 2:
[Second message here]

MESSAGE 3:
[Third message here]
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
    final now = DateTime.now()
        .toUtc(); // Use UTC for cross-timezone consistency

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
