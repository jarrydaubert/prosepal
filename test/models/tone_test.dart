import 'package:flutter_test/flutter_test.dart';
import 'package:prosepal/core/models/tone.dart';

void main() {
  group('Tone enum', () {
    test('should have all 4 tones', () {
      expect(Tone.values.length, equals(4));
    });

    test('should have correct tone values', () {
      expect(Tone.values, contains(Tone.heartfelt));
      expect(Tone.values, contains(Tone.casual));
      expect(Tone.values, contains(Tone.funny));
      expect(Tone.values, contains(Tone.formal));
    });

    group('heartfelt', () {
      test('should have correct properties', () {
        expect(Tone.heartfelt.label, equals('Heartfelt'));
        expect(Tone.heartfelt.emoji, equals('💖'));
        expect(Tone.heartfelt.prompt, contains('warm'));
        expect(Tone.heartfelt.prompt, contains('sincere'));
        expect(Tone.heartfelt.description, equals('Warm and sincere'));
      });
    });

    group('casual', () {
      test('should have correct properties', () {
        expect(Tone.casual.label, equals('Casual'));
        expect(Tone.casual.emoji, equals('😊'));
        expect(Tone.casual.prompt, contains('friendly'));
        expect(Tone.casual.prompt, contains('relaxed'));
        expect(Tone.casual.description, equals('Friendly and relaxed'));
      });
    });

    group('funny', () {
      test('should have correct properties', () {
        expect(Tone.funny.label, equals('Funny'));
        expect(Tone.funny.emoji, equals('😂'));
        expect(Tone.funny.prompt, contains('humorous'));
        expect(Tone.funny.prompt, contains('witty'));
        expect(Tone.funny.description, equals('Humorous and witty'));
      });
    });

    group('formal', () {
      test('should have correct properties', () {
        expect(Tone.formal.label, equals('Formal'));
        expect(Tone.formal.emoji, equals('📝'));
        expect(Tone.formal.prompt, contains('professional'));
        expect(Tone.formal.prompt, contains('polished'));
        expect(Tone.formal.description, equals('Professional and polished'));
      });
    });

    test('all tones should have non-empty labels', () {
      for (final tone in Tone.values) {
        expect(tone.label.isNotEmpty, isTrue);
      }
    });

    test('all tones should have non-empty emojis', () {
      for (final tone in Tone.values) {
        expect(tone.emoji.isNotEmpty, isTrue);
      }
    });

    test('all tones should have non-empty prompts', () {
      for (final tone in Tone.values) {
        expect(tone.prompt.isNotEmpty, isTrue);
      }
    });

    test('all tones should have non-empty descriptions', () {
      for (final tone in Tone.values) {
        expect(tone.description.isNotEmpty, isTrue);
      }
    });

    test('all tones should have unique labels', () {
      final labels = Tone.values.map((t) => t.label).toSet();
      expect(labels.length, equals(Tone.values.length));
    });

    test('all tones should have unique emojis', () {
      final emojis = Tone.values.map((t) => t.emoji).toSet();
      expect(emojis.length, equals(Tone.values.length));
    });
  });
}
