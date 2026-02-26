import 'package:flutter/material.dart';
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

    test('should have colors', () {
      for (final occasion in Occasion.values) {
        expect(occasion.color, isA<Color>());
      }
    });

    test('birthday should have correct properties', () {
      expect(Occasion.birthday.label, equals('Birthday'));
      expect(Occasion.birthday.emoji, equals('🎂'));
      expect(Occasion.birthday.prompt, contains('birthday'));
    });

    test('thankYou should have correct properties', () {
      expect(Occasion.thankYou.label, equals('Thank You'));
      expect(Occasion.thankYou.emoji, equals('🙏'));
      expect(Occasion.thankYou.prompt, contains('gratitude'));
    });

    test('sympathy should have correct properties', () {
      expect(Occasion.sympathy.label, equals('Sympathy'));
      expect(Occasion.sympathy.emoji, equals('💐'));
      expect(Occasion.sympathy.prompt, contains('condolences'));
    });

    test('wedding should have correct properties', () {
      expect(Occasion.wedding.label, equals('Wedding'));
      expect(Occasion.wedding.emoji, equals('💒'));
    });

    test('graduation should have correct properties', () {
      expect(Occasion.graduation.label, equals('Graduation'));
      expect(Occasion.graduation.emoji, equals('🎓'));
    });

    test('baby should have correct properties', () {
      expect(Occasion.baby.label, equals('New Baby'));
      expect(Occasion.baby.emoji, equals('👶'));
    });

    test('getWell should have correct properties', () {
      expect(Occasion.getWell.label, equals('Get Well'));
      expect(Occasion.getWell.emoji, equals('🌻'));
    });

    test('anniversary should have correct properties', () {
      expect(Occasion.anniversary.label, equals('Anniversary'));
      expect(Occasion.anniversary.emoji, equals('💕'));
    });

    test('congrats should have correct properties', () {
      expect(Occasion.congrats.label, equals('Congrats'));
      expect(Occasion.congrats.emoji, equals('🎉'));
    });

    test('apology should have correct properties', () {
      expect(Occasion.apology.label, equals('Apology'));
      expect(Occasion.apology.emoji, equals('💔'));
    });
  });

  group('Relationship', () {
    test('should have correct number of relationships', () {
      expect(Relationship.values.length, equals(5));
    });

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

    test('should have emojis', () {
      for (final relationship in Relationship.values) {
        expect(relationship.emoji, isNotEmpty);
      }
    });

    test('closeFriend should have correct properties', () {
      expect(Relationship.closeFriend.label, equals('Close Friend'));
      expect(Relationship.closeFriend.emoji, equals('👯'));
      expect(Relationship.closeFriend.prompt, contains('close friend'));
    });

    test('family should have correct properties', () {
      expect(Relationship.family.label, equals('Family'));
      expect(Relationship.family.emoji, equals('👨‍👩‍👧'));
      expect(Relationship.family.prompt, contains('family'));
    });

    test('colleague should have correct properties', () {
      expect(Relationship.colleague.label, equals('Colleague'));
      expect(Relationship.colleague.emoji, equals('💼'));
      expect(Relationship.colleague.prompt, contains('colleague'));
    });

    test('acquaintance should have correct properties', () {
      expect(Relationship.acquaintance.label, equals('Acquaintance'));
      expect(Relationship.acquaintance.emoji, equals('👋'));
    });

    test('romantic should have correct properties', () {
      expect(Relationship.romantic.label, equals('Partner'));
      expect(Relationship.romantic.emoji, equals('❤️'));
      expect(Relationship.romantic.prompt, contains('romantic'));
    });
  });

  group('Tone', () {
    test('should have correct number of tones', () {
      expect(Tone.values.length, equals(4));
    });

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

    test('should have emojis', () {
      for (final tone in Tone.values) {
        expect(tone.emoji, isNotEmpty);
      }
    });

    test('should have descriptions', () {
      for (final tone in Tone.values) {
        expect(tone.description, isNotEmpty);
      }
    });

    test('heartfelt should have correct properties', () {
      expect(Tone.heartfelt.label, equals('Heartfelt'));
      expect(Tone.heartfelt.emoji, equals('💖'));
      expect(Tone.heartfelt.prompt, contains('sincere'));
      expect(Tone.heartfelt.description, contains('Warm'));
    });

    test('casual should have correct properties', () {
      expect(Tone.casual.label, equals('Casual'));
      expect(Tone.casual.emoji, equals('😊'));
      expect(Tone.casual.prompt, contains('friendly'));
    });

    test('funny should have correct properties', () {
      expect(Tone.funny.label, equals('Funny'));
      expect(Tone.funny.emoji, equals('😂'));
      expect(Tone.funny.prompt, contains('humorous'));
    });

    test('formal should have correct properties', () {
      expect(Tone.formal.label, equals('Formal'));
      expect(Tone.formal.emoji, equals('📝'));
      expect(Tone.formal.prompt, contains('professional'));
    });
  });

  group('GeneratedMessage', () {
    late DateTime testTime;
    late GeneratedMessage testMessage;

    setUp(() {
      testTime = DateTime.utc(2025, 1, 1, 12, 0, 0);
      testMessage = GeneratedMessage(
        id: 'test-id',
        text: 'Happy birthday!',
        occasion: Occasion.birthday,
        relationship: Relationship.family,
        tone: Tone.heartfelt,
        createdAt: testTime,
      );
    });

    test('should create with required fields', () {
      expect(testMessage.id, equals('test-id'));
      expect(testMessage.text, equals('Happy birthday!'));
      expect(testMessage.occasion, equals(Occasion.birthday));
      expect(testMessage.relationship, equals(Relationship.family));
      expect(testMessage.tone, equals(Tone.heartfelt));
      expect(testMessage.createdAt, equals(testTime));
    });

    test('should allow optional fields', () {
      final message = GeneratedMessage(
        id: 'test-id',
        text: 'Happy birthday!',
        occasion: Occasion.birthday,
        relationship: Relationship.family,
        tone: Tone.heartfelt,
        createdAt: testTime,
        recipientName: 'John',
        personalDetails: 'Loves hiking',
      );

      expect(message.recipientName, equals('John'));
      expect(message.personalDetails, equals('Loves hiking'));
    });

    test('copyWith should create new instance with updated fields', () {
      final updated = testMessage.copyWith(text: 'New text');

      expect(updated.text, equals('New text'));
      expect(updated.id, equals(testMessage.id));
      expect(updated.occasion, equals(testMessage.occasion));
      expect(identical(updated, testMessage), isFalse);
    });

    test('copyWith should preserve all fields when none provided', () {
      final copy = testMessage.copyWith();

      expect(copy, equals(testMessage));
    });

    test('toJson should serialize all fields', () {
      final message = GeneratedMessage(
        id: 'json-test',
        text: 'Test message',
        occasion: Occasion.wedding,
        relationship: Relationship.closeFriend,
        tone: Tone.formal,
        createdAt: testTime,
        recipientName: 'Jane',
        personalDetails: 'Met in college',
      );

      final json = message.toJson();

      expect(json['id'], equals('json-test'));
      expect(json['text'], equals('Test message'));
      expect(json['occasion'], equals('wedding'));
      expect(json['relationship'], equals('closeFriend'));
      expect(json['tone'], equals('formal'));
      expect(json['createdAt'], equals('2025-01-01T12:00:00.000Z'));
      expect(json['recipientName'], equals('Jane'));
      expect(json['personalDetails'], equals('Met in college'));
    });

    test('fromJson should deserialize correctly', () {
      final json = {
        'id': 'from-json',
        'text': 'Deserialized message',
        'occasion': 'graduation',
        'relationship': 'colleague',
        'tone': 'casual',
        'createdAt': '2025-06-15T10:30:00.000Z',
        'recipientName': 'Bob',
        'personalDetails': null,
      };

      final message = GeneratedMessage.fromJson(json);

      expect(message.id, equals('from-json'));
      expect(message.text, equals('Deserialized message'));
      expect(message.occasion, equals(Occasion.graduation));
      expect(message.relationship, equals(Relationship.colleague));
      expect(message.tone, equals(Tone.casual));
      expect(message.recipientName, equals('Bob'));
      expect(message.personalDetails, isNull);
    });

    test('toJson and fromJson should be reversible', () {
      final original = GeneratedMessage(
        id: 'round-trip',
        text: 'Round trip test',
        occasion: Occasion.baby,
        relationship: Relationship.romantic,
        tone: Tone.funny,
        createdAt: testTime,
        recipientName: 'Partner',
        personalDetails: 'Expecting first child',
      );

      final json = original.toJson();
      final restored = GeneratedMessage.fromJson(json);

      expect(restored, equals(original));
    });

    test('equality should compare all fields', () {
      final message1 = GeneratedMessage(
        id: 'same-id',
        text: 'Same text',
        occasion: Occasion.birthday,
        relationship: Relationship.family,
        tone: Tone.heartfelt,
        createdAt: testTime,
      );

      final message2 = GeneratedMessage(
        id: 'same-id',
        text: 'Same text',
        occasion: Occasion.birthday,
        relationship: Relationship.family,
        tone: Tone.heartfelt,
        createdAt: testTime,
      );

      expect(message1, equals(message2));
      expect(message1.hashCode, equals(message2.hashCode));
    });

    test('inequality when fields differ', () {
      final message1 = testMessage;
      final message2 = testMessage.copyWith(id: 'different-id');

      expect(message1, isNot(equals(message2)));
    });

    test('toString should return readable representation', () {
      final str = testMessage.toString();

      expect(str, contains('GeneratedMessage'));
      expect(str, contains('test-id'));
      expect(str, contains('birthday'));
    });
  });

  group('GenerationResult', () {
    late DateTime testTime;
    late List<GeneratedMessage> testMessages;

    setUp(() {
      testTime = DateTime.utc(2025, 1, 1, 12, 0, 0);
      testMessages = [
        GeneratedMessage(
          id: '1',
          text: 'Message 1',
          occasion: Occasion.birthday,
          relationship: Relationship.family,
          tone: Tone.heartfelt,
          createdAt: testTime,
        ),
        GeneratedMessage(
          id: '2',
          text: 'Message 2',
          occasion: Occasion.birthday,
          relationship: Relationship.family,
          tone: Tone.heartfelt,
          createdAt: testTime,
        ),
      ];
    });

    test('should contain list of messages', () {
      final result = GenerationResult(
        messages: testMessages,
        occasion: Occasion.birthday,
        relationship: Relationship.family,
        tone: Tone.heartfelt,
      );

      expect(result.messages.length, equals(2));
      expect(result.occasion, equals(Occasion.birthday));
    });

    test('should allow optional fields', () {
      final result = GenerationResult(
        messages: testMessages,
        occasion: Occasion.birthday,
        relationship: Relationship.family,
        tone: Tone.heartfelt,
        recipientName: 'Mom',
        personalDetails: 'Turning 50',
      );

      expect(result.recipientName, equals('Mom'));
      expect(result.personalDetails, equals('Turning 50'));
    });

    test('toJson should serialize all fields including messages', () {
      final result = GenerationResult(
        messages: testMessages,
        occasion: Occasion.birthday,
        relationship: Relationship.family,
        tone: Tone.heartfelt,
        recipientName: 'Test',
      );

      final json = result.toJson();

      expect(json['messages'], isA<List>());
      expect((json['messages'] as List).length, equals(2));
      expect(json['occasion'], equals('birthday'));
      expect(json['recipientName'], equals('Test'));
    });

    test('fromJson should deserialize correctly', () {
      final json = {
        'messages': [
          {
            'id': 'json-1',
            'text': 'First',
            'occasion': 'thankYou',
            'relationship': 'acquaintance',
            'tone': 'formal',
            'createdAt': '2025-01-01T12:00:00.000Z',
            'recipientName': null,
            'personalDetails': null,
          },
        ],
        'occasion': 'thankYou',
        'relationship': 'acquaintance',
        'tone': 'formal',
        'recipientName': null,
        'personalDetails': null,
      };

      final result = GenerationResult.fromJson(json);

      expect(result.messages.length, equals(1));
      expect(result.messages[0].id, equals('json-1'));
      expect(result.occasion, equals(Occasion.thankYou));
    });

    test('toJson and fromJson should be reversible', () {
      final original = GenerationResult(
        messages: testMessages,
        occasion: Occasion.birthday,
        relationship: Relationship.family,
        tone: Tone.heartfelt,
        recipientName: 'Test',
        personalDetails: 'Details',
      );

      final json = original.toJson();
      final restored = GenerationResult.fromJson(json);

      expect(restored, equals(original));
    });

    test('equality should compare all fields including messages', () {
      final result1 = GenerationResult(
        messages: testMessages,
        occasion: Occasion.birthday,
        relationship: Relationship.family,
        tone: Tone.heartfelt,
      );

      final result2 = GenerationResult(
        messages: List.from(testMessages),
        occasion: Occasion.birthday,
        relationship: Relationship.family,
        tone: Tone.heartfelt,
      );

      expect(result1, equals(result2));
    });

    test('inequality when message count differs', () {
      final result1 = GenerationResult(
        messages: testMessages,
        occasion: Occasion.birthday,
        relationship: Relationship.family,
        tone: Tone.heartfelt,
      );

      final result2 = GenerationResult(
        messages: [testMessages[0]],
        occasion: Occasion.birthday,
        relationship: Relationship.family,
        tone: Tone.heartfelt,
      );

      expect(result1, isNot(equals(result2)));
    });

    test('toString should return readable representation', () {
      final result = GenerationResult(
        messages: testMessages,
        occasion: Occasion.birthday,
        relationship: Relationship.family,
        tone: Tone.heartfelt,
      );

      final str = result.toString();

      expect(str, contains('GenerationResult'));
      expect(str, contains('2 messages'));
      expect(str, contains('birthday'));
    });
  });
}
