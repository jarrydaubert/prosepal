import 'package:flutter_test/flutter_test.dart';
import 'package:prosepal/core/models/models.dart';

void main() {
  group('GeneratedMessage', () {
    late DateTime testTime;
    late GeneratedMessage testMessage;

    setUp(() {
      testTime = DateTime.utc(2025, 1, 1, 12);
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

    test('fromJson handles missing optional fields', () {
      final json = {
        'id': 'minimal',
        'text': 'Minimal message',
        'occasion': 'birthday',
        'relationship': 'family',
        'tone': 'heartfelt',
        'createdAt': '2025-01-01T12:00:00.000Z',
        // recipientName and personalDetails omitted
      };

      final message = GeneratedMessage.fromJson(json);

      expect(message.id, equals('minimal'));
      expect(message.recipientName, isNull);
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
      testTime = DateTime.utc(2025, 1, 1, 12);
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
