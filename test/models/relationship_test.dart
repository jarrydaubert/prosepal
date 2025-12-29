import 'package:flutter_test/flutter_test.dart';
import 'package:prosepal/core/models/relationship.dart';

void main() {
  group('Relationship enum', () {
    test('should have all 5 relationships', () {
      expect(Relationship.values.length, equals(5));
    });

    test('should have correct relationship values', () {
      expect(Relationship.values, contains(Relationship.closeFriend));
      expect(Relationship.values, contains(Relationship.family));
      expect(Relationship.values, contains(Relationship.colleague));
      expect(Relationship.values, contains(Relationship.acquaintance));
      expect(Relationship.values, contains(Relationship.romantic));
    });

    group('closeFriend', () {
      test('should have correct properties', () {
        expect(Relationship.closeFriend.label, equals('Close Friend'));
        expect(Relationship.closeFriend.emoji, equals('👯'));
        expect(Relationship.closeFriend.prompt, equals('a close friend'));
      });
    });

    group('family', () {
      test('should have correct properties', () {
        expect(Relationship.family.label, equals('Family'));
        expect(Relationship.family.emoji, equals('👨‍👩‍👧'));
        expect(Relationship.family.prompt, equals('a family member'));
      });
    });

    group('colleague', () {
      test('should have correct properties', () {
        expect(Relationship.colleague.label, equals('Colleague'));
        expect(Relationship.colleague.emoji, equals('💼'));
        expect(Relationship.colleague.prompt, contains('colleague'));
      });
    });

    group('acquaintance', () {
      test('should have correct properties', () {
        expect(Relationship.acquaintance.label, equals('Acquaintance'));
        expect(Relationship.acquaintance.emoji, equals('👋'));
        expect(Relationship.acquaintance.prompt, contains('acquaintance'));
      });
    });

    group('romantic', () {
      test('should have correct properties', () {
        expect(Relationship.romantic.label, equals('Partner'));
        expect(Relationship.romantic.emoji, equals('❤️'));
        expect(Relationship.romantic.prompt, contains('romantic'));
      });
    });

    test('all relationships should have non-empty labels', () {
      for (final relationship in Relationship.values) {
        expect(relationship.label.isNotEmpty, isTrue);
      }
    });

    test('all relationships should have non-empty emojis', () {
      for (final relationship in Relationship.values) {
        expect(relationship.emoji.isNotEmpty, isTrue);
      }
    });

    test('all relationships should have non-empty prompts', () {
      for (final relationship in Relationship.values) {
        expect(relationship.prompt.isNotEmpty, isTrue);
      }
    });

    test('all relationships should have unique labels', () {
      final labels = Relationship.values.map((r) => r.label).toSet();
      expect(labels.length, equals(Relationship.values.length));
    });

    test('all relationships should have unique emojis', () {
      final emojis = Relationship.values.map((r) => r.emoji).toSet();
      expect(emojis.length, equals(Relationship.values.length));
    });
  });
}
