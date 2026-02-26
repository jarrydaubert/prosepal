import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:prosepal/core/models/models.dart';
import 'package:prosepal/core/services/ai_service.dart';

/// Mock AI service for integration testing
///
/// Returns configurable fake messages for deterministic testing.
/// Can simulate errors for error path testing.
///
/// ## Basic Usage
/// ```dart
/// final mockAi = MockAiService();
/// final result = await mockAi.generateMessages(
///   occasion: Occasion.birthday,
///   relationship: Relationship.friend,
///   tone: Tone.warm,
/// );
/// expect(result.messages.length, 3);
/// expect(mockAi.generateCallCount, 1);
/// ```
///
/// ## Error Simulation
/// ```dart
/// mockAi.simulateNetworkError();
/// expect(() => mockAi.generateMessages(...), throwsA(isA<AiNetworkException>()));
///
/// // Or use any exception type:
/// mockAi.errorToThrow = AiRateLimitException('Too many requests');
/// ```
///
/// ## Network Delay
/// ```dart
/// mockAi.simulateDelay = Duration(seconds: 2);
/// // Test timeout handling, loading states, etc.
/// ```
class MockAiService extends AiService {
  // ---------------------------------------------------------------------------
  // Configuration
  // ---------------------------------------------------------------------------

  /// Messages to return from generateMessages()
  @visibleForTesting
  List<String> messagesToReturn = _defaultMessages;

  /// Error to throw (if set, throws instead of returning)
  ///
  /// Supports any Exception type:
  /// - [AiNetworkException]: Network connectivity issues
  /// - [AiRateLimitException]: Rate limiting or quota exceeded
  /// - [AiContentBlockedException]: Content blocked by safety filters
  /// - [AiUnavailableException]: Model or service temporarily unavailable
  /// - [AiEmptyResponseException]: Invalid or empty response from model
  /// - [AiParseException]: Response parsing failed
  /// - [AiTruncationException]: Response truncated (retryable)
  @visibleForTesting
  Exception? errorToThrow;

  /// Delay to simulate network latency
  @visibleForTesting
  Duration? simulateDelay;

  // ---------------------------------------------------------------------------
  // Call Tracking
  // ---------------------------------------------------------------------------

  /// Number of times generateMessages() was called
  @visibleForTesting
  int generateCallCount = 0;

  /// Last occasion passed to generateMessages()
  @visibleForTesting
  Occasion? lastOccasion;

  /// Last relationship passed to generateMessages()
  @visibleForTesting
  Relationship? lastRelationship;

  /// Last tone passed to generateMessages()
  @visibleForTesting
  Tone? lastTone;

  /// Last length passed to generateMessages()
  @visibleForTesting
  MessageLength? lastLength;

  /// Last recipientName passed to generateMessages()
  @visibleForTesting
  String? lastRecipientName;

  /// Last personalDetails passed to generateMessages()
  @visibleForTesting
  String? lastPersonalDetails;

  // ---------------------------------------------------------------------------
  // Error Simulation Helpers
  // ---------------------------------------------------------------------------

  /// Simulate network connectivity error
  void simulateNetworkError([String message = 'No internet connection']) {
    errorToThrow = AiNetworkException(message, errorCode: 'network');
  }

  /// Simulate rate limiting (quota exceeded)
  void simulateRateLimit([String message = 'Rate limit exceeded']) {
    errorToThrow = AiRateLimitException(message, errorCode: 'rate_limit');
  }

  /// Simulate content blocked by safety filters
  void simulateContentBlocked([String message = 'Content blocked']) {
    errorToThrow = AiContentBlockedException(message, errorCode: 'blocked');
  }

  /// Simulate model unavailable
  void simulateUnavailable([String message = 'Service unavailable']) {
    errorToThrow = AiUnavailableException(message, errorCode: 'unavailable');
  }

  /// Simulate empty/invalid response
  void simulateEmptyResponse([String message = 'Empty response']) {
    errorToThrow = AiEmptyResponseException(message, errorCode: 'empty');
  }

  /// Simulate response parsing failure
  void simulateParseError([String message = 'Failed to parse response']) {
    errorToThrow = AiParseException(message, errorCode: 'parse');
  }

  // ---------------------------------------------------------------------------
  // Reset
  // ---------------------------------------------------------------------------

  /// Reset all state to defaults
  void reset() {
    messagesToReturn = _defaultMessages;
    errorToThrow = null;
    simulateDelay = null;
    generateCallCount = 0;
    lastOccasion = null;
    lastRelationship = null;
    lastTone = null;
    lastLength = null;
    lastRecipientName = null;
    lastPersonalDetails = null;
  }

  static const _defaultMessages = [
    'Happy Birthday! Wishing you a wonderful day filled with joy and celebration.',
    'On your special day, I hope all your dreams come true. Have an amazing birthday!',
    'Cheers to another year of memories and adventures. Happy Birthday!',
  ];

  // ---------------------------------------------------------------------------
  // AiService Override
  // ---------------------------------------------------------------------------

  @override
  Future<GenerationResult> generateMessages({
    required Occasion occasion,
    required Relationship relationship,
    required Tone tone,
    MessageLength length = MessageLength.standard,
    String? recipientName,
    String? personalDetails,
  }) async {
    generateCallCount++;
    lastOccasion = occasion;
    lastRelationship = relationship;
    lastTone = tone;
    lastLength = length;
    lastRecipientName = recipientName;
    lastPersonalDetails = personalDetails;

    if (simulateDelay != null) {
      await Future.delayed(simulateDelay!);
    }

    if (errorToThrow != null) {
      throw errorToThrow!;
    }

    final messages = messagesToReturn
        .map(
          (text) => GeneratedMessage(
            id: 'mock-${DateTime.now().millisecondsSinceEpoch}',
            text: text,
            occasion: occasion,
            relationship: relationship,
            tone: tone,
            createdAt: DateTime.now(),
            recipientName: recipientName,
            personalDetails: personalDetails,
          ),
        )
        .toList();

    return GenerationResult(
      messages: messages,
      occasion: occasion,
      relationship: relationship,
      tone: tone,
      length: length,
      recipientName: recipientName,
      personalDetails: personalDetails,
    );
  }
}
