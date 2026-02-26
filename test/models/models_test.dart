import 'package:flutter_test/flutter_test.dart';
import 'package:prosepal/core/models/models.dart';

void main() {
  group('Occasion', () {
    test('should have correct number of occasions', () {
      expect(Occasion.values.length, equals(10));
    });

    test('should have labels', () {
      for (final occasion in Occasion.values) {
        expect(occasion.label, isNotEmpty);
      }
    });

    test('should have prompts', () {
      for (final occasion in Occasion.values) {
        expect(occasion.prompt, isNotEmpty);
      }
    });

    test('should have emojis', () {
      for (final occasion in Occasion.values) {
        expect(occasion.emoji, isNotEmpty);
      }
    });

    test('birthday should have correct properties', () {
      expect(Occasion.birthday.label, equals('Birthday'));
      expect(Occasion.birthday.emoji, equals('🎂'));
    });
  });

  group('Relationship', () {
    test('should have labels', () {
      for (final relationship in Relationship.values) {
        expect(relationship.label, isNotEmpty);
      }
    });

    test('should have prompts', () {
      for (final relationship in Relationship.values) {
        expect(relationship.prompt, isNotEmpty);
      }
    });
  });

  group('Tone', () {
    test('should have labels', () {
      for (final tone in Tone.values) {
        expect(tone.label, isNotEmpty);
      }
    });

    test('should have prompts', () {
      for (final tone in Tone.values) {
        expect(tone.prompt, isNotEmpty);
      }
    });
  });

  group('GeneratedMessage', () {
    test('should create with required fields', () {
      final message = GeneratedMessage(
        id: 'test-id',
        text: 'Happy birthday!',
        occasion: Occasion.birthday,
        relationship: Relationship.family,
        tone: Tone.heartfelt,
        createdAt: DateTime.now(),
      );

      expect(message.id, equals('test-id'));
      expect(message.text, equals('Happy birthday!'));
      expect(message.occasion, equals(Occasion.birthday));
    });

    test('should allow optional fields', () {
      final message = GeneratedMessage(
        id: 'test-id',
        text: 'Happy birthday!',
        occasion: Occasion.birthday,
        relationship: Relationship.family,
        tone: Tone.heartfelt,
        createdAt: DateTime.now(),
        recipientName: 'John',
        personalDetails: 'Loves hiking',
      );

      expect(message.recipientName, equals('John'));
      expect(message.personalDetails, equals('Loves hiking'));
    });
  });

  group('GenerationResult', () {
    test('should contain list of messages', () {
      final messages = [
        GeneratedMessage(
          id: '1',
          text: 'Message 1',
          occasion: Occasion.birthday,
          relationship: Relationship.family,
          tone: Tone.heartfelt,
          createdAt: DateTime.now(),
        ),
        GeneratedMessage(
          id: '2',
          text: 'Message 2',
          occasion: Occasion.birthday,
          relationship: Relationship.family,
          tone: Tone.heartfelt,
          createdAt: DateTime.now(),
        ),
      ];

      final result = GenerationResult(
        messages: messages,
        occasion: Occasion.birthday,
        relationship: Relationship.family,
        tone: Tone.heartfelt,
      );

      expect(result.messages.length, equals(2));
      expect(result.occasion, equals(Occasion.birthday));
    });
  });
}
