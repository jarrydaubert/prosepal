import 'package:prosepal/core/models/models.dart';
import 'package:prosepal/core/services/ai_service.dart';

/// Mock AI service for integration testing
///
/// Returns configurable fake messages for deterministic testing.
/// Can simulate errors for error path testing.
class MockAiService extends AiService {
  /// Messages to return from generateMessages()
  List<String> messagesToReturn = [
    'Happy Birthday! Wishing you a wonderful day filled with joy and celebration.',
    'On your special day, I hope all your dreams come true. Have an amazing birthday!',
    'Cheers to another year of memories and adventures. Happy Birthday!',
  ];

  /// Error to throw (if set)
  AiServiceException? errorToThrow;

  /// Delay to simulate network latency
  Duration? simulateDelay;

  /// Call tracking
  int generateCallCount = 0;
  Occasion? lastOccasion;
  Relationship? lastRelationship;
  Tone? lastTone;
  String? lastRecipientName;
  String? lastPersonalDetails;

  void reset() {
    messagesToReturn = [
      'Happy Birthday! Wishing you a wonderful day filled with joy and celebration.',
      'On your special day, I hope all your dreams come true. Have an amazing birthday!',
      'Cheers to another year of memories and adventures. Happy Birthday!',
    ];
    errorToThrow = null;
    simulateDelay = null;
    generateCallCount = 0;
    lastOccasion = null;
    lastRelationship = null;
    lastTone = null;
    lastRecipientName = null;
    lastPersonalDetails = null;
  }

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
    lastRecipientName = recipientName;
    lastPersonalDetails = personalDetails;

    if (simulateDelay != null) {
      await Future.delayed(simulateDelay!);
    }

    if (errorToThrow != null) {
      throw errorToThrow!;
    }

    final messages = messagesToReturn.map((text) => GeneratedMessage(
      id: 'mock-${DateTime.now().millisecondsSinceEpoch}',
      content: text,
    )).toList();

    return GenerationResult(
      messages: messages,
      occasion: occasion,
      relationship: relationship,
      tone: tone,
      recipientName: recipientName,
      personalDetails: personalDetails,
    );
  }
}
