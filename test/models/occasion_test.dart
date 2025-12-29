import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prosepal/core/models/occasion.dart';

void main() {
  group('Occasion enum', () {
    test('should have all 10 occasions', () {
      expect(Occasion.values.length, equals(10));
    });

    test('should have correct occasion values', () {
      expect(Occasion.values, contains(Occasion.birthday));
      expect(Occasion.values, contains(Occasion.thankYou));
      expect(Occasion.values, contains(Occasion.sympathy));
      expect(Occasion.values, contains(Occasion.wedding));
      expect(Occasion.values, contains(Occasion.graduation));
      expect(Occasion.values, contains(Occasion.baby));
      expect(Occasion.values, contains(Occasion.getWell));
      expect(Occasion.values, contains(Occasion.anniversary));
      expect(Occasion.values, contains(Occasion.congrats));
      expect(Occasion.values, contains(Occasion.apology));
    });

    group('birthday', () {
      test('should have correct properties', () {
        expect(Occasion.birthday.label, equals('Birthday'));
        expect(Occasion.birthday.emoji, equals('🎂'));
        expect(Occasion.birthday.prompt, equals('birthday celebration'));
        expect(Occasion.birthday.color, isA<Color>());
      });
    });

    group('thankYou', () {
      test('should have correct properties', () {
        expect(Occasion.thankYou.label, equals('Thank You'));
        expect(Occasion.thankYou.emoji, equals('🙏'));
        expect(
          Occasion.thankYou.prompt,
          equals('expressing gratitude and appreciation'),
        );
        expect(Occasion.thankYou.color, isA<Color>());
      });
    });

    group('sympathy', () {
      test('should have correct properties', () {
        expect(Occasion.sympathy.label, equals('Sympathy'));
        expect(Occasion.sympathy.emoji, equals('💐'));
        expect(
          Occasion.sympathy.prompt,
          contains('condolences'),
        );
        expect(Occasion.sympathy.color, isA<Color>());
      });
    });

    group('wedding', () {
      test('should have correct properties', () {
        expect(Occasion.wedding.label, equals('Wedding'));
        expect(Occasion.wedding.emoji, equals('💒'));
        expect(Occasion.wedding.prompt, contains('wedding'));
        expect(Occasion.wedding.color, isA<Color>());
      });
    });

    group('graduation', () {
      test('should have correct properties', () {
        expect(Occasion.graduation.label, equals('Graduation'));
        expect(Occasion.graduation.emoji, equals('🎓'));
        expect(Occasion.graduation.prompt, contains('graduation'));
        expect(Occasion.graduation.color, isA<Color>());
      });
    });

    group('baby', () {
      test('should have correct properties', () {
        expect(Occasion.baby.label, equals('New Baby'));
        expect(Occasion.baby.emoji, equals('👶'));
        expect(Occasion.baby.prompt, contains('baby'));
        expect(Occasion.baby.color, isA<Color>());
      });
    });

    group('getWell', () {
      test('should have correct properties', () {
        expect(Occasion.getWell.label, equals('Get Well'));
        expect(Occasion.getWell.emoji, equals('🌻'));
        expect(Occasion.getWell.prompt, contains('recovery'));
        expect(Occasion.getWell.color, isA<Color>());
      });
    });

    group('anniversary', () {
      test('should have correct properties', () {
        expect(Occasion.anniversary.label, equals('Anniversary'));
        expect(Occasion.anniversary.emoji, equals('💕'));
        expect(Occasion.anniversary.prompt, contains('anniversary'));
        expect(Occasion.anniversary.color, isA<Color>());
      });
    });

    group('congrats', () {
      test('should have correct properties', () {
        expect(Occasion.congrats.label, equals('Congrats'));
        expect(Occasion.congrats.emoji, equals('🎉'));
        expect(Occasion.congrats.prompt, contains('achievement'));
        expect(Occasion.congrats.color, isA<Color>());
      });
    });

    group('apology', () {
      test('should have correct properties', () {
        expect(Occasion.apology.label, equals('Apology'));
        expect(Occasion.apology.emoji, equals('💔'));
        expect(Occasion.apology.prompt, contains('regret'));
        expect(Occasion.apology.color, isA<Color>());
      });
    });

    test('all occasions should have non-empty labels', () {
      for (final occasion in Occasion.values) {
        expect(occasion.label.isNotEmpty, isTrue);
      }
    });

    test('all occasions should have non-empty emojis', () {
      for (final occasion in Occasion.values) {
        expect(occasion.emoji.isNotEmpty, isTrue);
      }
    });

    test('all occasions should have non-empty prompts', () {
      for (final occasion in Occasion.values) {
        expect(occasion.prompt.isNotEmpty, isTrue);
      }
    });

    test('all occasions should have valid colors', () {
      for (final occasion in Occasion.values) {
        expect(occasion.color, isA<Color>());
      }
    });

    test('all occasions should have unique labels', () {
      final labels = Occasion.values.map((o) => o.label).toSet();
      expect(labels.length, equals(Occasion.values.length));
    });

    test('all occasions should have unique emojis', () {
      final emojis = Occasion.values.map((o) => o.emoji).toSet();
      expect(emojis.length, equals(Occasion.values.length));
    });
  });
}
