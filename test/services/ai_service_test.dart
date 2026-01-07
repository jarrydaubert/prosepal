import 'package:flutter_test/flutter_test.dart';
import 'package:prosepal/core/models/models.dart';
import 'package:prosepal/core/services/ai_service.dart';

/// AiService Unit Tests
///
/// Tests REAL AiService methods, not fake helpers.
/// Each test answers: "What bug does this catch?"
///
/// Test Categories:
/// 1. JSON Parsing - Catches: Malformed AI response handling
/// 2. Prompt Building - Catches: Wrong context sent to AI
/// 3. Exception Types - Catches: Wrong error shown to user
void main() {
  late AiService service;

  setUp(() {
    service = AiService();
  });

  // ============================================================
  // JSON PARSING - Tests parseJsonResponse()
  // Bug: AI returns valid JSON but we fail to extract messages
  // ============================================================

  group('parseJsonResponse', () {
    group('valid responses', () {
      test('parses 3 messages from valid JSON', () {
        const json = '''
{
  "messages": [
    {"text": "Happy birthday! Wishing you joy and happiness."},
    {"text": "Another year wiser! Celebrate big today."},
    {"text": "On your special day, know you are loved."}
  ]
}
''';

        final messages = service.parseJsonResponse(
          json,
          occasion: Occasion.birthday,
          relationship: Relationship.closeFriend,
          tone: Tone.heartfelt,
        );

        expect(messages.length, equals(3));
        expect(messages[0].text, contains('Happy birthday'));
        expect(messages[1].text, contains('wiser'));
        expect(messages[2].text, contains('special day'));
      });

      test('sets correct occasion on all messages', () {
        const json = '{"messages": [{"text": "Test message"}]}';

        final messages = service.parseJsonResponse(
          json,
          occasion: Occasion.wedding,
          relationship: Relationship.family,
          tone: Tone.formal,
        );

        expect(messages.every((m) => m.occasion == Occasion.wedding), isTrue);
      });

      test('sets correct relationship on all messages', () {
        const json = '{"messages": [{"text": "Test message"}]}';

        final messages = service.parseJsonResponse(
          json,
          occasion: Occasion.birthday,
          relationship: Relationship.colleague,
          tone: Tone.casual,
        );

        expect(
          messages.every((m) => m.relationship == Relationship.colleague),
          isTrue,
        );
      });

      test('sets correct tone on all messages', () {
        const json = '{"messages": [{"text": "Test message"}]}';

        final messages = service.parseJsonResponse(
          json,
          occasion: Occasion.thankYou,
          relationship: Relationship.closeFriend,
          tone: Tone.funny,
        );

        expect(messages.every((m) => m.tone == Tone.funny), isTrue);
      });

      test('includes recipientName when provided', () {
        const json = '{"messages": [{"text": "Test message"}]}';

        final messages = service.parseJsonResponse(
          json,
          occasion: Occasion.birthday,
          relationship: Relationship.closeFriend,
          tone: Tone.heartfelt,
          recipientName: 'Sarah',
        );

        expect(messages[0].recipientName, equals('Sarah'));
      });

      test('includes personalDetails when provided', () {
        const json = '{"messages": [{"text": "Test message"}]}';

        final messages = service.parseJsonResponse(
          json,
          occasion: Occasion.birthday,
          relationship: Relationship.closeFriend,
          tone: Tone.heartfelt,
          personalDetails: 'Loves hiking',
        );

        expect(messages[0].personalDetails, equals('Loves hiking'));
      });

      test('generates unique IDs for each message', () {
        const json = '''
{"messages": [{"text": "Msg 1"}, {"text": "Msg 2"}, {"text": "Msg 3"}]}
''';

        final messages = service.parseJsonResponse(
          json,
          occasion: Occasion.birthday,
          relationship: Relationship.closeFriend,
          tone: Tone.heartfelt,
        );

        final ids = messages.map((m) => m.id).toSet();
        expect(ids.length, equals(3), reason: 'All IDs should be unique');
      });

      test('trims whitespace from message text', () {
        const json = '{"messages": [{"text": "  Spaced message  "}]}';

        final messages = service.parseJsonResponse(
          json,
          occasion: Occasion.birthday,
          relationship: Relationship.closeFriend,
          tone: Tone.heartfelt,
        );

        expect(messages[0].text, equals('Spaced message'));
      });

      test('filters out empty messages', () {
        const json = '''
{"messages": [{"text": "Valid"}, {"text": ""}, {"text": "   "}, {"text": "Also valid"}]}
''';

        final messages = service.parseJsonResponse(
          json,
          occasion: Occasion.birthday,
          relationship: Relationship.closeFriend,
          tone: Tone.heartfelt,
        );

        expect(messages.length, equals(2));
        expect(messages[0].text, equals('Valid'));
        expect(messages[1].text, equals('Also valid'));
      });

      test('handles single message response', () {
        const json = '{"messages": [{"text": "Only one message"}]}';

        final messages = service.parseJsonResponse(
          json,
          occasion: Occasion.sympathy,
          relationship: Relationship.acquaintance,
          tone: Tone.formal,
        );

        expect(messages.length, equals(1));
      });
    });

    group('invalid responses', () {
      test('throws AiParseException for invalid JSON', () {
        const invalidJson = 'not valid json at all';

        expect(
          () => service.parseJsonResponse(
            invalidJson,
            occasion: Occasion.birthday,
            relationship: Relationship.closeFriend,
            tone: Tone.heartfelt,
          ),
          throwsA(isA<AiParseException>()),
        );
      });

      test('throws AiParseException for wrong schema (no messages key)', () {
        const json = '{"content": [{"text": "Wrong key"}]}';

        expect(
          () => service.parseJsonResponse(
            json,
            occasion: Occasion.birthday,
            relationship: Relationship.closeFriend,
            tone: Tone.heartfelt,
          ),
          throwsA(isA<AiParseException>()),
        );
      });

      test('throws AiParseException for wrong schema (messages not array)', () {
        const json = '{"messages": "not an array"}';

        expect(
          () => service.parseJsonResponse(
            json,
            occasion: Occasion.birthday,
            relationship: Relationship.closeFriend,
            tone: Tone.heartfelt,
          ),
          throwsA(isA<AiParseException>()),
        );
      });

      test('returns empty list when all messages are empty', () {
        const json = '{"messages": [{"text": ""}, {"text": "   "}]}';

        final messages = service.parseJsonResponse(
          json,
          occasion: Occasion.birthday,
          relationship: Relationship.closeFriend,
          tone: Tone.heartfelt,
        );

        expect(messages, isEmpty);
      });

      test('handles missing text field gracefully', () {
        const json =
            '{"messages": [{"content": "wrong field"}, {"text": "valid"}]}';

        final messages = service.parseJsonResponse(
          json,
          occasion: Occasion.birthday,
          relationship: Relationship.closeFriend,
          tone: Tone.heartfelt,
        );

        // Should only include the valid message
        expect(messages.length, equals(1));
        expect(messages[0].text, equals('valid'));
      });
    });
  });

  // ============================================================
  // PROMPT BUILDING - Tests buildPrompt()
  // Bug: Wrong context sent to AI, resulting in wrong message style
  // ============================================================

  group('buildPrompt', () {
    test('includes occasion in prompt', () {
      final prompt = service.buildPrompt(
        occasion: Occasion.birthday,
        relationship: Relationship.closeFriend,
        tone: Tone.heartfelt,
        length: MessageLength.standard,
      );

      expect(prompt.toLowerCase(), contains('birthday'));
    });

    test('includes relationship in prompt', () {
      final prompt = service.buildPrompt(
        occasion: Occasion.thankYou,
        relationship: Relationship.colleague,
        tone: Tone.formal,
        length: MessageLength.standard,
      );

      expect(prompt.toLowerCase(), contains('colleague'));
    });

    test('includes tone in prompt', () {
      final prompt = service.buildPrompt(
        occasion: Occasion.congrats,
        relationship: Relationship.family,
        tone: Tone.funny,
        length: MessageLength.standard,
      );

      // Check for tone-related keywords
      expect(
        prompt.toLowerCase().contains('funny') ||
            prompt.toLowerCase().contains('humor') ||
            prompt.toLowerCase().contains('light'),
        isTrue,
      );
    });

    test('includes length in prompt', () {
      final prompt = service.buildPrompt(
        occasion: Occasion.wedding,
        relationship: Relationship.closeFriend,
        tone: Tone.heartfelt,
        length: MessageLength.brief,
      );

      // Check for brief-related keywords
      expect(
        prompt.toLowerCase().contains('brief') ||
            prompt.toLowerCase().contains('short') ||
            prompt.toLowerCase().contains('1-2'),
        isTrue,
      );
    });

    test('includes recipient name when provided', () {
      final prompt = service.buildPrompt(
        occasion: Occasion.birthday,
        relationship: Relationship.closeFriend,
        tone: Tone.heartfelt,
        length: MessageLength.standard,
        recipientName: 'Michael',
      );

      expect(prompt, contains('Michael'));
    });

    test('includes personal details when provided', () {
      final prompt = service.buildPrompt(
        occasion: Occasion.graduation,
        relationship: Relationship.family,
        tone: Tone.inspirational,
        length: MessageLength.detailed,
        personalDetails: 'First in family to graduate college',
      );

      expect(prompt, contains('First in family'));
    });

    test('excludes recipient name when not provided', () {
      final prompt = service.buildPrompt(
        occasion: Occasion.birthday,
        relationship: Relationship.closeFriend,
        tone: Tone.heartfelt,
        length: MessageLength.standard,
      );

      expect(prompt, isNot(contains("Recipient's name")));
    });

    test('excludes personal details when not provided', () {
      final prompt = service.buildPrompt(
        occasion: Occasion.birthday,
        relationship: Relationship.closeFriend,
        tone: Tone.heartfelt,
        length: MessageLength.standard,
      );

      expect(prompt, isNot(contains('Personal context')));
    });

    test('works for all occasions', () {
      for (final occasion in Occasion.values) {
        final prompt = service.buildPrompt(
          occasion: occasion,
          relationship: Relationship.closeFriend,
          tone: Tone.heartfelt,
          length: MessageLength.standard,
        );

        expect(
          prompt.isNotEmpty,
          isTrue,
          reason: '${occasion.label} prompt should not be empty',
        );
        expect(
          prompt.contains(occasion.prompt),
          isTrue,
          reason: '${occasion.label} prompt should contain occasion.prompt',
        );
      }
    });

    test('works for all relationships', () {
      for (final relationship in Relationship.values) {
        final prompt = service.buildPrompt(
          occasion: Occasion.birthday,
          relationship: relationship,
          tone: Tone.casual,
          length: MessageLength.standard,
        );

        expect(
          prompt.contains(relationship.prompt),
          isTrue,
          reason:
              '${relationship.label} prompt should contain relationship.prompt',
        );
      }
    });

    test('works for all tones', () {
      for (final tone in Tone.values) {
        final prompt = service.buildPrompt(
          occasion: Occasion.congrats,
          relationship: Relationship.colleague,
          tone: tone,
          length: MessageLength.standard,
        );

        expect(
          prompt.contains(tone.prompt),
          isTrue,
          reason: '${tone.label} prompt should contain tone.prompt',
        );
      }
    });

    test('works for all message lengths', () {
      for (final length in MessageLength.values) {
        final prompt = service.buildPrompt(
          occasion: Occasion.anniversary,
          relationship: Relationship.romantic,
          tone: Tone.heartfelt,
          length: length,
        );

        expect(
          prompt.contains(length.prompt),
          isTrue,
          reason: '${length.label} prompt should contain length.prompt',
        );
      }
    });
  });

  // ============================================================
  // ERROR CLASSIFICATION - Tests classifyFirebaseAIError() and classifyGeneralError()
  // Bug: Wrong error type shown to user, wrong retry behavior
  // ============================================================

  group('classifyFirebaseAIError', () {
    group('rate limiting errors', () {
      test('classifies "rate limit exceeded" as AiRateLimitException', () {
        final result = AiService.classifyFirebaseAIError('Rate limit exceeded');

        expect(result.exceptionType, equals(AiRateLimitException));
        expect(result.errorCode, equals('RATE_LIMIT'));
        expect(result.isRetryable, isTrue);
        expect(result.message, contains('busy'));
      });

      test('classifies "quota exceeded" as AiRateLimitException', () {
        final result = AiService.classifyFirebaseAIError(
          'API quota exceeded for today',
        );

        expect(result.exceptionType, equals(AiRateLimitException));
        expect(result.errorCode, equals('RATE_LIMIT'));
        expect(result.isRetryable, isTrue);
      });

      test('case insensitive - "RATE LIMIT" works', () {
        final result = AiService.classifyFirebaseAIError('RATE LIMIT EXCEEDED');
        expect(result.exceptionType, equals(AiRateLimitException));
      });
    });

    group('network errors', () {
      test('classifies "network error" as AiNetworkException', () {
        final result = AiService.classifyFirebaseAIError(
          'Network error occurred',
        );

        expect(result.exceptionType, equals(AiNetworkException));
        expect(result.errorCode, equals('NETWORK_ERROR'));
        expect(result.isRetryable, isFalse);
      });

      test('classifies "connection failed" as AiNetworkException', () {
        final result = AiService.classifyFirebaseAIError('Connection failed');

        expect(result.exceptionType, equals(AiNetworkException));
        expect(result.errorCode, equals('NETWORK_ERROR'));
      });
    });

    group('content blocked errors', () {
      test('classifies "content blocked" as AiContentBlockedException', () {
        final result = AiService.classifyFirebaseAIError(
          'Content was blocked by safety filters',
        );

        expect(result.exceptionType, equals(AiContentBlockedException));
        expect(result.errorCode, equals('CONTENT_BLOCKED'));
        expect(result.isRetryable, isFalse);
        expect(result.message, contains('safety filters'));
      });

      test('classifies "safety" as AiContentBlockedException', () {
        final result = AiService.classifyFirebaseAIError('Safety check failed');

        expect(result.exceptionType, equals(AiContentBlockedException));
      });
    });

    group('service unavailable errors', () {
      test('classifies "unavailable" as AiUnavailableException', () {
        final result = AiService.classifyFirebaseAIError(
          'Service temporarily unavailable',
        );

        expect(result.exceptionType, equals(AiUnavailableException));
        expect(result.errorCode, equals('SERVICE_UNAVAILABLE'));
        expect(result.isRetryable, isTrue);
      });

      test('classifies "503" as AiUnavailableException', () {
        final result = AiService.classifyFirebaseAIError(
          'Error 503: Service unavailable',
        );

        expect(result.exceptionType, equals(AiUnavailableException));
      });
    });

    group('timeout errors', () {
      test('classifies "timeout" as AiNetworkException with TIMEOUT code', () {
        final result = AiService.classifyFirebaseAIError(
          'Request timeout after 30s',
        );

        expect(result.exceptionType, equals(AiNetworkException));
        expect(result.errorCode, equals('TIMEOUT'));
        expect(result.isRetryable, isTrue);
      });
    });

    group('invalid request errors', () {
      test('classifies "invalid" as AiServiceException', () {
        final result = AiService.classifyFirebaseAIError(
          'Invalid request format',
        );

        expect(result.exceptionType, equals(AiServiceException));
        expect(result.errorCode, equals('INVALID_REQUEST'));
        expect(result.isRetryable, isFalse);
      });

      test('classifies "malformed" as AiServiceException', () {
        final result = AiService.classifyFirebaseAIError(
          'Malformed JSON in request',
        );

        expect(result.exceptionType, equals(AiServiceException));
        expect(result.errorCode, equals('INVALID_REQUEST'));
      });
    });

    group('unknown errors', () {
      test('classifies unknown error as generic AiServiceException', () {
        final result = AiService.classifyFirebaseAIError(
          'Something completely unexpected',
        );

        expect(result.exceptionType, equals(AiServiceException));
        expect(result.errorCode, equals('FIREBASE_AI_ERROR'));
        expect(result.isRetryable, isFalse);
      });

      test('empty error message returns generic error', () {
        final result = AiService.classifyFirebaseAIError('');

        expect(result.exceptionType, equals(AiServiceException));
        expect(result.errorCode, equals('FIREBASE_AI_ERROR'));
      });
    });
  });

  group('classifyGeneralError', () {
    group('network errors', () {
      test('classifies "network" as AiNetworkException', () {
        final result = AiService.classifyGeneralError(
          'SocketException: Network unreachable',
        );

        expect(result.exceptionType, equals(AiNetworkException));
        expect(result.errorCode, equals('NETWORK_ERROR'));
      });

      test('classifies "socket" as AiNetworkException', () {
        final result = AiService.classifyGeneralError(
          'SocketException: Connection refused',
        );

        expect(result.exceptionType, equals(AiNetworkException));
      });

      test('classifies "connection" as AiNetworkException', () {
        final result = AiService.classifyGeneralError(
          'Connection reset by peer',
        );

        expect(result.exceptionType, equals(AiNetworkException));
      });

      test('classifies "host" as AiNetworkException', () {
        final result = AiService.classifyGeneralError('Failed host lookup');

        expect(result.exceptionType, equals(AiNetworkException));
      });
    });

    group('timeout errors', () {
      test('classifies "timeout" as AiNetworkException with TIMEOUT code', () {
        final result = AiService.classifyGeneralError(
          'TimeoutException: Future timed out',
        );

        expect(result.exceptionType, equals(AiNetworkException));
        expect(result.errorCode, equals('TIMEOUT'));
        expect(result.isRetryable, isTrue);
      });
    });

    group('permission errors', () {
      test('classifies "permission" as AiServiceException', () {
        final result = AiService.classifyGeneralError('Permission denied');

        expect(result.exceptionType, equals(AiServiceException));
        expect(result.errorCode, equals('PERMISSION_DENIED'));
        expect(result.isRetryable, isFalse);
      });

      test('classifies "denied" as AiServiceException', () {
        final result = AiService.classifyGeneralError(
          'Access denied to resource',
        );

        expect(result.exceptionType, equals(AiServiceException));
        expect(result.errorCode, equals('PERMISSION_DENIED'));
      });
    });

    group('unknown errors', () {
      test('classifies unknown error as generic AiServiceException', () {
        final result = AiService.classifyGeneralError(
          'NullPointerException: null',
        );

        expect(result.exceptionType, equals(AiServiceException));
        expect(result.errorCode, equals('UNKNOWN_ERROR'));
        expect(result.isRetryable, isFalse);
        expect(result.message, contains('unexpected'));
      });
    });
  });

  group('AiErrorClassification', () {
    test('stores all fields correctly', () {
      const classification = AiErrorClassification(
        exceptionType: AiNetworkException,
        message: 'Test message',
        errorCode: 'TEST_CODE',
        isRetryable: true,
      );

      expect(classification.exceptionType, equals(AiNetworkException));
      expect(classification.message, equals('Test message'));
      expect(classification.errorCode, equals('TEST_CODE'));
      expect(classification.isRetryable, isTrue);
    });

    test('isRetryable defaults to false', () {
      const classification = AiErrorClassification(
        exceptionType: AiServiceException,
        message: 'Test',
        errorCode: 'TEST',
      );

      expect(classification.isRetryable, isFalse);
    });
  });

  // ============================================================
  // EXCEPTION TYPES - Tests error class behavior
  // Bug: Wrong exception type thrown, UI shows wrong error message
  // ============================================================

  group('Exception types', () {
    test('AiServiceException has message and optional fields', () {
      const exception = AiServiceException(
        'Test error',
        errorCode: 'TEST_CODE',
      );

      expect(exception.message, equals('Test error'));
      expect(exception.errorCode, equals('TEST_CODE'));
      expect(exception.originalError, isNull);
      expect(exception.toString(), contains('Test error'));
    });

    test('AiServiceException preserves original error', () {
      final original = FormatException('Parse failed');
      final exception = AiServiceException(
        'Wrapped error',
        originalError: original,
      );

      expect(exception.originalError, equals(original));
    });

    test('AiNetworkException is AiServiceException subtype', () {
      const exception = AiNetworkException('Network failed');

      expect(exception, isA<AiServiceException>());
      expect(exception.message, equals('Network failed'));
    });

    test('AiRateLimitException is AiServiceException subtype', () {
      const exception = AiRateLimitException('Too many requests');

      expect(exception, isA<AiServiceException>());
    });

    test('AiContentBlockedException is AiServiceException subtype', () {
      const exception = AiContentBlockedException('Safety filter triggered');

      expect(exception, isA<AiServiceException>());
    });

    test('AiEmptyResponseException is AiServiceException subtype', () {
      const exception = AiEmptyResponseException('No content returned');

      expect(exception, isA<AiServiceException>());
    });

    test('AiParseException is AiServiceException subtype', () {
      const exception = AiParseException('JSON parse failed');

      expect(exception, isA<AiServiceException>());
    });

    test('AiUnavailableException is AiServiceException subtype', () {
      const exception = AiUnavailableException('Service down');

      expect(exception, isA<AiServiceException>());
    });
  });
}
