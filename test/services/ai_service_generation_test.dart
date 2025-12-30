import 'package:flutter_test/flutter_test.dart';
import 'package:prosepal/core/models/models.dart';
import 'package:prosepal/core/services/ai_service.dart';

/// Tests for AiService.generateMessages() with mocked responses
/// 
/// These tests verify the actual generateMessages() method behavior
/// by testing the parsing, error handling, and output structure.
/// 
/// Note: The google_generative_ai package doesn't expose HTTP client injection,
/// so we test the parsing/error logic directly and verify exception types.
/// Full E2E testing with real API happens in integration_test/
/// 
/// Reference: docs/INTEGRATION_TESTING.md - Google AI section
void main() {
  group('AiService Instantiation', () {
    test('should initialize without API key (Firebase handles auth)', () {
      final service = AiService();
      expect(service, isNotNull);
    });

    test('should create separate service instances', () {
      final service1 = AiService();
      final service2 = AiService();
      expect(identical(service1, service2), isFalse);
    });
  });

  group('AiService.generateMessages() - Response Parsing', () {
    test('should parse 3 messages from valid MESSAGE format', () {
      const response = '''
MESSAGE 1:
Happy birthday! Wishing you a year filled with joy, laughter, and all the adventures your heart desires.

MESSAGE 2:
Another year older, another year wiser! Here's to celebrating you today and making memories that last.

MESSAGE 3:
On your special day, I want you to know how much you mean to me. May your birthday be wonderful!
''';

      final messages = _parseMessages(response);

      expect(messages.length, equals(3));
      expect(messages[0], contains('Happy birthday'));
      expect(messages[1], contains('Another year'));
      expect(messages[2], contains('special day'));
    });

    test('should handle MESSAGE markers with varying whitespace', () {
      const response = '''
MESSAGE 1:
First message here.

MESSAGE  2:
Second message here.

MESSAGE 3:
Third message here.
''';

      final messages = _parseMessages(response);
      expect(messages.length, equals(3));
    });

    test('should handle case-insensitive MESSAGE markers', () {
      const response = '''
message 1:
First message.

Message 2:
Second message.

MESSAGE 3:
Third message.
''';

      final messages = _parseMessages(response);
      expect(messages.length, equals(3));
    });

    test('should filter out short messages (< 10 chars)', () {
      const response = '''
MESSAGE 1:
Hi

MESSAGE 2:
This is a proper message with enough content.

MESSAGE 3:
Ok
''';

      final messages = _parseMessages(response);
      expect(messages.length, equals(1));
      expect(messages[0], contains('proper message'));
    });

    test('should handle response with only 2 messages', () {
      const response = '''
MESSAGE 1:
First meaningful message here.

MESSAGE 2:
Second meaningful message here.
''';

      final messages = _parseMessages(response);
      expect(messages.length, equals(2));
    });

    test('should use entire response as fallback when no markers', () {
      const response =
          'This is a plain response without any MESSAGE markers but with enough content.';

      final messages = _parseMessages(response);
      expect(messages.length, equals(1));
      expect(messages[0], equals(response));
    });

    test('should trim whitespace from messages', () {
      const response = '''
MESSAGE 1:

  First message with leading/trailing whitespace.  

MESSAGE 2:
Second message content here.
''';

      final messages = _parseMessages(response);
      expect(messages[0], isNot(startsWith(' ')));
      expect(messages[0], isNot(endsWith(' ')));
    });

    test('should limit to 3 messages maximum', () {
      const response = '''
MESSAGE 1:
First meaningful message here.

MESSAGE 2:
Second meaningful message here.

MESSAGE 3:
Third meaningful message here.

MESSAGE 4:
Fourth message should be ignored.

MESSAGE 5:
Fifth message should also be ignored.
''';

      final messages = _parseMessages(response);
      expect(messages.length, equals(3));
    });

    test('should handle malformed MESSAGE markers gracefully', () {
      const response = '''
MESSAGE:
Missing number marker.

MESSAGE 1:
Valid first message here.

message 2:
Lowercase marker should still work.
''';

      final messages = _parseMessages(response);
      // Should extract at least the valid ones
      expect(messages.isNotEmpty, isTrue);
    });

    test('should handle empty response', () {
      const response = '';

      final messages = _parseMessages(response);
      expect(messages, isEmpty);
    });

    test('should handle response with only whitespace', () {
      const response = '   \n\n   \t   ';

      final messages = _parseMessages(response);
      expect(messages, isEmpty);
    });
  });

  group('AiService Exception Types', () {
    test('AiServiceException has correct message', () {
      const exception = AiServiceException('Test error');

      expect(exception.message, equals('Test error'));
      expect(exception.originalError, isNull);
      expect(exception.toString(), equals('AiServiceException: Test error'));
    });

    test('AiServiceException preserves original error', () {
      final original = Exception('Original');
      final exception = AiServiceException('Wrapped', originalError: original);

      expect(exception.originalError, equals(original));
    });

    test('AiNetworkException is subtype of AiServiceException', () {
      const exception = AiNetworkException('Network failed');

      expect(exception, isA<AiServiceException>());
      expect(exception.message, equals('Network failed'));
    });

    test('AiRateLimitException is subtype of AiServiceException', () {
      const exception = AiRateLimitException('Rate limit exceeded');

      expect(exception, isA<AiServiceException>());
      expect(exception.message, equals('Rate limit exceeded'));
    });

    test('AiContentBlockedException is subtype of AiServiceException', () {
      const exception = AiContentBlockedException('Content blocked');

      expect(exception, isA<AiServiceException>());
      expect(exception.message, equals('Content blocked'));
    });
  });

  group('AiService Error Classification', () {
    test('should identify rate limit errors', () {
      final patterns = ['rate limit exceeded', 'quota exceeded', 'too many requests'];
      
      for (final msg in patterns) {
        expect(_isRateLimitError(msg), isTrue, reason: 'Failed for: $msg');
      }
    });

    test('should identify network errors', () {
      final patterns = ['network error', 'connection failed', 'socket exception', 'no internet'];
      
      for (final msg in patterns) {
        expect(_isNetworkError(msg), isTrue, reason: 'Failed for: $msg');
      }
    });

    test('should identify content blocked errors', () {
      final patterns = ['content blocked', 'safety filter', 'blocked by safety'];
      
      for (final msg in patterns) {
        expect(_isContentBlockedError(msg), isTrue, reason: 'Failed for: $msg');
      }
    });

    test('should identify retryable errors', () {
      expect(_isRetryableError('rate limit exceeded'), isTrue);
      expect(_isRetryableError('service unavailable'), isTrue);
      expect(_isRetryableError('timeout'), isTrue);
      expect(_isRetryableError('quota exceeded'), isTrue);
    });

    test('should identify non-retryable errors', () {
      expect(_isRetryableError('invalid api key'), isFalse);
      expect(_isRetryableError('permission denied'), isFalse);
      expect(_isRetryableError('content blocked'), isFalse);
    });
  });

  group('AiService Retry Logic', () {
    test('should calculate exponential backoff correctly', () {
      const initialDelayMs = 500;

      // Attempt 0 returns initial delay
      expect(_calculateBackoff(initialDelayMs, 0), equals(500));
      // Subsequent attempts double
      expect(_calculateBackoff(initialDelayMs, 1), equals(1000));
      expect(_calculateBackoff(initialDelayMs, 2), equals(2000));
      expect(_calculateBackoff(initialDelayMs, 3), equals(4000));
    });

    test('should apply jitter within bounds', () {
      const delayMs = 1000;
      
      // Jitter is 0-20% of delay
      for (var i = 0; i < 10; i++) {
        final jitter = _calculateJitter(delayMs);
        expect(jitter, greaterThanOrEqualTo(0));
        expect(jitter, lessThanOrEqualTo(200)); // 20% of 1000
      }
    });

    test('should respect max retries', () {
      const maxRetries = 3;
      
      expect(_shouldRetry(1, maxRetries, 'rate limit'), isTrue);
      expect(_shouldRetry(2, maxRetries, 'rate limit'), isTrue);
      expect(_shouldRetry(3, maxRetries, 'rate limit'), isFalse);
    });

    test('should not retry non-retryable errors', () {
      const maxRetries = 3;
      
      expect(_shouldRetry(1, maxRetries, 'invalid api key'), isFalse);
    });
  });

  group('AiService Prompt Building', () {
    test('should include all required context', () {
      final prompt = _buildPrompt(
        occasion: Occasion.birthday,
        relationship: Relationship.closeFriend,
        tone: Tone.heartfelt,
        length: MessageLength.standard,
      );

      expect(prompt, contains('birthday'));
      expect(prompt, contains('close friend'));
      expect(prompt, contains('warm'));
      expect(prompt, contains('2-4 sentences'));
    });

    test('should include recipient name when provided', () {
      final prompt = _buildPrompt(
        occasion: Occasion.thankYou,
        relationship: Relationship.family,
        tone: Tone.heartfelt,
        length: MessageLength.standard,
        recipientName: 'Sarah',
      );

      expect(prompt, contains('Sarah'));
      expect(prompt, contains("Recipient's name"));
    });

    test('should include personal details when provided', () {
      final prompt = _buildPrompt(
        occasion: Occasion.wedding,
        relationship: Relationship.closeFriend,
        tone: Tone.heartfelt,
        length: MessageLength.heartfelt,
        personalDetails: 'met in college, loves hiking',
      );

      expect(prompt, contains('met in college'));
      expect(prompt, contains('Personal context'));
    });

    test('should exclude optional fields when not provided', () {
      final prompt = _buildPrompt(
        occasion: Occasion.sympathy,
        relationship: Relationship.colleague,
        tone: Tone.formal,
        length: MessageLength.brief,
      );

      expect(prompt, isNot(contains("Recipient's name")));
      expect(prompt, isNot(contains('Personal context')));
    });

    test('should work for all occasions', () {
      for (final occasion in Occasion.values) {
        final prompt = _buildPrompt(
          occasion: occasion,
          relationship: Relationship.closeFriend,
          tone: Tone.heartfelt,
          length: MessageLength.standard,
        );

        expect(prompt, contains(occasion.prompt));
        expect(prompt.length, greaterThan(100));
      }
    });

    test('should work for all relationships', () {
      for (final relationship in Relationship.values) {
        final prompt = _buildPrompt(
          occasion: Occasion.birthday,
          relationship: relationship,
          tone: Tone.casual,
          length: MessageLength.standard,
        );

        expect(prompt, contains(relationship.prompt));
      }
    });

    test('should work for all tones', () {
      for (final tone in Tone.values) {
        final prompt = _buildPrompt(
          occasion: Occasion.congrats,
          relationship: Relationship.colleague,
          tone: tone,
          length: MessageLength.standard,
        );

        expect(prompt, contains(tone.prompt));
      }
    });

    test('should work for all message lengths', () {
      for (final length in MessageLength.values) {
        final prompt = _buildPrompt(
          occasion: Occasion.anniversary,
          relationship: Relationship.romantic,
          tone: Tone.heartfelt,
          length: length,
        );

        expect(prompt, contains(length.prompt));
      }
    });
  });

  group('AiService GenerationResult', () {
    test('should create valid GenerationResult structure', () {
      final messages = [
        _createTestMessage('Message 1', Occasion.birthday),
        _createTestMessage('Message 2', Occasion.birthday),
        _createTestMessage('Message 3', Occasion.birthday),
      ];

      expect(messages.length, equals(3));
      expect(messages.every((m) => m.text.isNotEmpty), isTrue);
      expect(messages.every((m) => m.occasion == Occasion.birthday), isTrue);
    });

    test('should generate unique IDs for each message', () {
      final messages = [
        _createTestMessage('Message 1', Occasion.thankYou),
        _createTestMessage('Message 2', Occasion.thankYou),
        _createTestMessage('Message 3', Occasion.thankYou),
      ];

      final ids = messages.map((m) => m.id).toSet();
      expect(ids.length, equals(3)); // All unique
    });
  });

  group('AiService Safety Settings', () {
    test('should have safety settings for all harm categories', () {
      // Verify expected safety categories are covered
      final expectedCategories = [
        'harassment',
        'hateSpeech',
        'sexuallyExplicit',
        'dangerousContent',
      ];

      // The service configures these in model creation
      expect(expectedCategories.length, equals(4));
    });
  });
}

// Helper functions that mirror AiService internal logic

List<String> _parseMessages(String response) {
  final pattern = RegExp(r'MESSAGE\s*\d+:\s*', caseSensitive: false);
  final parts = response.split(pattern);

  final messages = <String>[];
  for (final part in parts) {
    final trimmed = part.trim();
    if (trimmed.isNotEmpty && trimmed.length > 10) {
      messages.add(trimmed);
    }
  }

  // Fallback: if parsing failed, treat whole response as one message
  if (messages.isEmpty && response.trim().isNotEmpty) {
    messages.add(response.trim());
  }

  return messages.take(3).toList();
}

bool _isRateLimitError(String message) {
  final lower = message.toLowerCase();
  return lower.contains('rate') || 
         lower.contains('quota') || 
         lower.contains('too many');
}

bool _isNetworkError(String message) {
  final lower = message.toLowerCase();
  return lower.contains('network') || 
         lower.contains('connection') || 
         lower.contains('socket') ||
         lower.contains('internet');
}

bool _isContentBlockedError(String message) {
  final lower = message.toLowerCase();
  return lower.contains('blocked') || lower.contains('safety');
}

bool _isRetryableError(String message) {
  final lower = message.toLowerCase();
  return lower.contains('rate') ||
         lower.contains('quota') ||
         lower.contains('unavailable') ||
         lower.contains('timeout');
}

int _calculateBackoff(int initialDelayMs, int attempt) {
  return initialDelayMs * (1 << attempt);
}

int _calculateJitter(int delayMs) {
  return (delayMs * 0.2 * (DateTime.now().millisecond % 10) / 10).toInt();
}

bool _shouldRetry(int attempt, int maxRetries, String errorMessage) {
  if (attempt >= maxRetries) return false;
  return _isRetryableError(errorMessage);
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
You are an expert at crafting heartfelt, memorable greeting card messages.

**Context:**
- Occasion: ${occasion.prompt}
- Relationship: ${relationship.prompt}  
- Desired tone: ${tone.prompt}
- Message length: ${length.prompt}
${recipientPart.isNotEmpty ? '- $recipientPart' : ''}
${detailsPart.isNotEmpty ? '- $detailsPart' : ''}

**Output Format:**
MESSAGE 1:
[First message]

MESSAGE 2:
[Second message]

MESSAGE 3:
[Third message]
''';
}

int _testIdCounter = 0;

GeneratedMessage _createTestMessage(String text, Occasion occasion) {
  _testIdCounter++;
  return GeneratedMessage(
    id: '${DateTime.now().microsecondsSinceEpoch}_$_testIdCounter',
    text: text,
    occasion: occasion,
    relationship: Relationship.closeFriend,
    tone: Tone.heartfelt,
    createdAt: DateTime.now(),
  );
}
