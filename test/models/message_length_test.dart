import 'package:flutter_test/flutter_test.dart';
import 'package:prosepal/core/models/message_length.dart';

void main() {
  group('MessageLength enum', () {
    test('should have all 3 lengths', () {
      expect(MessageLength.values.length, equals(3));
    });

    test('should have correct length values', () {
      expect(MessageLength.values, contains(MessageLength.brief));
      expect(MessageLength.values, contains(MessageLength.standard));
      expect(MessageLength.values, contains(MessageLength.heartfelt));
    });

    group('brief', () {
      test('should have correct properties', () {
        expect(MessageLength.brief.label, equals('Brief'));
        expect(MessageLength.brief.emoji, equals('⚡'));
        expect(MessageLength.brief.prompt, contains('1-2 sentences'));
        expect(MessageLength.brief.description, equals('Short & sweet'));
      });
    });

    group('standard', () {
      test('should have correct properties', () {
        expect(MessageLength.standard.label, equals('Standard'));
        expect(MessageLength.standard.emoji, equals('✨'));
        expect(MessageLength.standard.prompt, contains('2-4 sentences'));
        expect(MessageLength.standard.description, equals('Just right'));
      });
    });

    group('heartfelt', () {
      test('should have correct properties', () {
        expect(MessageLength.heartfelt.label, equals('Heartfelt'));
        expect(MessageLength.heartfelt.emoji, equals('💝'));
        expect(MessageLength.heartfelt.prompt, contains('4-6 sentences'));
        expect(MessageLength.heartfelt.description, equals('Longer & personal'));
      });
    });

    test('all lengths should have non-empty labels', () {
      for (final length in MessageLength.values) {
        expect(length.label.isNotEmpty, isTrue);
      }
    });

    test('all lengths should have non-empty emojis', () {
      for (final length in MessageLength.values) {
        expect(length.emoji.isNotEmpty, isTrue);
      }
    });

    test('all lengths should have non-empty prompts', () {
      for (final length in MessageLength.values) {
        expect(length.prompt.isNotEmpty, isTrue);
      }
    });

    test('all lengths should have non-empty descriptions', () {
      for (final length in MessageLength.values) {
        expect(length.description.isNotEmpty, isTrue);
      }
    });

    test('all lengths should have unique labels', () {
      final labels = MessageLength.values.map((l) => l.label).toSet();
      expect(labels.length, equals(MessageLength.values.length));
    });

    test('all lengths should have unique emojis', () {
      final emojis = MessageLength.values.map((l) => l.emoji).toSet();
      expect(emojis.length, equals(MessageLength.values.length));
    });

    test('prompts should mention sentence counts', () {
      expect(MessageLength.brief.prompt, contains('sentences'));
      expect(MessageLength.standard.prompt, contains('sentences'));
      expect(MessageLength.heartfelt.prompt, contains('sentences'));
    });
  });
}
