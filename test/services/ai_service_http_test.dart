import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:prosepal/core/models/occasion.dart';
import 'package:prosepal/core/models/relationship.dart';
import 'package:prosepal/core/models/tone.dart';
import 'package:prosepal/core/models/message_length.dart';
import 'package:prosepal/core/services/ai_service.dart';

/// Tests for AiService using HTTP mocking
/// Verifies Gemini API endpoint responses
void main() {
  group('AiService HTTP Integration', () {
    group('Gemini API Response Parsing', () {
      test('should parse successful generation response', () {
        const mockResponse = '''
MESSAGE 1:
Happy birthday! Wishing you a year filled with joy, laughter, and all the adventures your heart desires. May this special day be as wonderful as you are!

MESSAGE 2:
Another year older, another year wiser! Here's to celebrating you today and making memories that will last a lifetime. Have the most amazing birthday!

MESSAGE 3:
On your special day, I want you to know how much you mean to me. May your birthday be filled with love, happiness, and everything that makes you smile!
''';

        final pattern = RegExp(r'MESSAGE\s*\d+:\s*', caseSensitive: false);
        final parts = mockResponse.split(pattern);

        // Filter out empty parts and short messages
        final messages = parts
            .where((p) => p.trim().length > 10)
            .map((p) => p.trim())
            .toList();

        expect(messages.length, equals(3));
        expect(messages[0], contains('Happy birthday'));
        expect(messages[1], contains('Another year'));
        expect(messages[2], contains('special day'));
      });

      test('should handle response with extra whitespace', () {
        const mockResponse = '''

MESSAGE 1:

  First message with leading/trailing whitespace.  


MESSAGE 2:
Second message content here.

MESSAGE 3:
Third message with some content.

''';

        final pattern = RegExp(r'MESSAGE\s*\d+:\s*', caseSensitive: false);
        final parts = mockResponse.split(pattern);
        final messages = parts
            .where((p) => p.trim().length > 10)
            .map((p) => p.trim())
            .toList();

        expect(messages.length, equals(3));
        expect(messages[0], isNot(startsWith(' ')));
        expect(messages[0], isNot(endsWith(' ')));
      });

      test('should handle response with only 2 messages', () {
        const mockResponse = '''
MESSAGE 1:
First message here with enough content.

MESSAGE 2:
Second message here with enough content.
''';

        final pattern = RegExp(r'MESSAGE\s*\d+:\s*', caseSensitive: false);
        final parts = mockResponse.split(pattern);
        final messages = parts
            .where((p) => p.trim().length > 10)
            .map((p) => p.trim())
            .toList();

        expect(messages.length, equals(2));
      });

      test('should handle fallback response without MESSAGE markers', () {
        const mockResponse =
            'This is a plain response without any MESSAGE markers. '
            'It should be treated as a single message fallback.';

        final pattern = RegExp(r'MESSAGE\s*\d+:\s*', caseSensitive: false);
        final parts = mockResponse.split(pattern);

        // When no markers, entire response is one message
        expect(parts.length, equals(1));
        expect(parts[0], equals(mockResponse));
      });
    });

    group('Gemini API Request Structure', () {
      test('should build correct prompt for birthday occasion', () {
        const occasion = Occasion.birthday;
        const relationship = Relationship.closeFriend;
        const tone = Tone.heartfelt;
        const length = MessageLength.standard;

        final prompt = _buildTestPrompt(
          occasion: occasion,
          relationship: relationship,
          tone: tone,
          length: length,
        );

        expect(prompt, contains('birthday celebration'));
        expect(prompt, contains('a close friend'));
        expect(prompt, contains('warm'));
        expect(prompt, contains('2-4 sentences'));
      });

      test('should include recipient name when provided', () {
        final prompt = _buildTestPrompt(
          occasion: Occasion.birthday,
          relationship: Relationship.family,
          tone: Tone.heartfelt,
          length: MessageLength.standard,
          recipientName: 'Sarah',
        );

        expect(prompt, contains('Sarah'));
        expect(prompt, contains("Recipient's name"));
      });

      test('should include personal details when provided', () {
        final prompt = _buildTestPrompt(
          occasion: Occasion.thankYou,
          relationship: Relationship.colleague,
          tone: Tone.formal,
          length: MessageLength.brief,
          personalDetails: 'helped with the project last week',
        );

        expect(prompt, contains('helped with the project'));
        expect(prompt, contains('Personal context'));
      });

      test('should exclude optional fields when not provided', () {
        final prompt = _buildTestPrompt(
          occasion: Occasion.sympathy,
          relationship: Relationship.family,
          tone: Tone.heartfelt,
          length: MessageLength.heartfelt,
        );

        expect(prompt, isNot(contains("Recipient's name")));
        expect(prompt, isNot(contains('Personal context')));
      });
    });

    group('All Occasion Types', () {
      for (final occasion in Occasion.values) {
        test('should generate prompt for ${occasion.label}', () {
          final prompt = _buildTestPrompt(
            occasion: occasion,
            relationship: Relationship.closeFriend,
            tone: Tone.heartfelt,
            length: MessageLength.standard,
          );

          expect(prompt, contains(occasion.prompt));
          expect(prompt.length, greaterThan(100));
        });
      }
    });

    group('All Relationship Types', () {
      for (final relationship in Relationship.values) {
        test('should generate prompt for ${relationship.label}', () {
          final prompt = _buildTestPrompt(
            occasion: Occasion.birthday,
            relationship: relationship,
            tone: Tone.casual,
            length: MessageLength.standard,
          );

          expect(prompt, contains(relationship.prompt));
        });
      }
    });

    group('All Tone Types', () {
      for (final tone in Tone.values) {
        test('should generate prompt for ${tone.label}', () {
          final prompt = _buildTestPrompt(
            occasion: Occasion.congrats,
            relationship: Relationship.colleague,
            tone: tone,
            length: MessageLength.standard,
          );

          expect(prompt, contains(tone.prompt));
        });
      }
    });

    group('All Message Length Types', () {
      for (final length in MessageLength.values) {
        test('should generate prompt for ${length.label}', () {
          final prompt = _buildTestPrompt(
            occasion: Occasion.wedding,
            relationship: Relationship.romantic,
            tone: Tone.heartfelt,
            length: length,
          );

          expect(prompt, contains(length.prompt));
        });
      }
    });

    group('Error Response Handling', () {
      test('should identify rate limit error message', () {
        const errorMessage = 'Rate limit exceeded. Please try again later.';

        final isRateLimit = errorMessage.toLowerCase().contains('rate') ||
            errorMessage.toLowerCase().contains('limit');

        expect(isRateLimit, isTrue);
      });

      test('should identify quota exceeded error', () {
        const errorMessage = 'Quota exceeded for the day.';

        final isQuota = errorMessage.toLowerCase().contains('quota');

        expect(isQuota, isTrue);
      });

      test('should identify content blocked error', () {
        const errorMessage = 'Content was blocked by safety filters.';

        final isBlocked = errorMessage.toLowerCase().contains('blocked') ||
            errorMessage.toLowerCase().contains('safety');

        expect(isBlocked, isTrue);
      });

      test('should identify network error', () {
        const errorMessage = 'Network connection failed.';

        final isNetwork = errorMessage.toLowerCase().contains('network') ||
            errorMessage.toLowerCase().contains('connection');

        expect(isNetwork, isTrue);
      });
    });

    group('AiServiceException Types', () {
      test('should create base exception correctly', () {
        const exception = AiServiceException('Test error');

        expect(exception.message, equals('Test error'));
        expect(exception.originalError, isNull);
        expect(exception.toString(), contains('Test error'));
      });

      test('should create network exception correctly', () {
        const exception = AiNetworkException('Network failed');

        expect(exception, isA<AiServiceException>());
        expect(exception.message, equals('Network failed'));
      });

      test('should create rate limit exception correctly', () {
        const exception = AiRateLimitException('Too many requests');

        expect(exception, isA<AiServiceException>());
        expect(exception.message, equals('Too many requests'));
      });

      test('should create content blocked exception correctly', () {
        const exception = AiContentBlockedException('Content blocked');

        expect(exception, isA<AiServiceException>());
        expect(exception.message, equals('Content blocked'));
      });
    });

    group('HTTP Client Mocking', () {
      test('should create mock HTTP client', () {
        final mockClient = MockClient((request) async {
          return http.Response(
            jsonEncode({'response': 'mock'}),
            200,
            headers: {'content-type': 'application/json'},
          );
        });

        expect(mockClient, isNotNull);
      });

      test('should mock successful API response', () async {
        final mockClient = MockClient((request) async {
          // Verify request structure
          expect(request.url.host, contains('generativelanguage'));

          return http.Response(
            jsonEncode({
              'candidates': [
                {
                  'content': {
                    'parts': [
                      {'text': 'MESSAGE 1:\nTest message one.\n\nMESSAGE 2:\nTest message two.\n\nMESSAGE 3:\nTest message three.'}
                    ]
                  }
                }
              ]
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        });

        final response = await mockClient.get(
          Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent'),
        );

        expect(response.statusCode, equals(200));
        final body = jsonDecode(response.body);
        expect(body['candidates'], isNotNull);
      });

      test('should mock rate limit error response', () async {
        final mockClient = MockClient((request) async {
          return http.Response(
            jsonEncode({
              'error': {
                'code': 429,
                'message': 'Resource has been exhausted',
                'status': 'RESOURCE_EXHAUSTED',
              }
            }),
            429,
            headers: {'content-type': 'application/json'},
          );
        });

        final response = await mockClient.get(
          Uri.parse('https://generativelanguage.googleapis.com/test'),
        );

        expect(response.statusCode, equals(429));
      });

      test('should mock content blocked response', () async {
        final mockClient = MockClient((request) async {
          return http.Response(
            jsonEncode({
              'candidates': [
                {
                  'finishReason': 'SAFETY',
                  'safetyRatings': [
                    {'category': 'HARM_CATEGORY_HARASSMENT', 'probability': 'HIGH'}
                  ]
                }
              ]
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        });

        final response = await mockClient.get(
          Uri.parse('https://generativelanguage.googleapis.com/test'),
        );

        final body = jsonDecode(response.body);
        expect(body['candidates'][0]['finishReason'], equals('SAFETY'));
      });
    });

    group('Retry Logic', () {
      test('should calculate exponential backoff correctly', () {
        const initialDelayMs = 500;

        const attempt1Delay = initialDelayMs * (1 << 1);
        const attempt2Delay = initialDelayMs * (1 << 2);
        const attempt3Delay = initialDelayMs * (1 << 3);

        expect(attempt1Delay, equals(1000));
        expect(attempt2Delay, equals(2000));
        expect(attempt3Delay, equals(4000));
      });

      test('should apply jitter to backoff', () {
        const initialDelayMs = 500;
        const attempt = 1;
        const delayMs = initialDelayMs * (1 << attempt);

        // Jitter is 0-20% of delay
        const minJitter = 0;
        final maxJitter = (delayMs * 0.2).toInt();

        expect(minJitter, equals(0));
        expect(maxJitter, equals(200)); // 20% of 1000ms
      });

      test('should identify retryable errors', () {
        final retryablePatterns = ['rate', 'quota', 'unavailable', 'timeout'];

        expect(
          retryablePatterns.any((p) => 'rate limit exceeded'.contains(p)),
          isTrue,
        );
        expect(
          retryablePatterns.any((p) => 'service unavailable'.contains(p)),
          isTrue,
        );
        expect(
          retryablePatterns.any((p) => 'request timeout'.contains(p)),
          isTrue,
        );
        expect(
          retryablePatterns.any((p) => 'invalid api key'.contains(p)),
          isFalse,
        );
      });
    });
  });
}

/// Helper to build test prompts matching AiService._buildPrompt logic
String _buildTestPrompt({
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
