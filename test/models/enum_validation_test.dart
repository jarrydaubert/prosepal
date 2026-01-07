import 'package:flutter_test/flutter_test.dart';
import 'package:prosepal/core/models/models.dart';

/// Enum Validation Tests
///
/// Tests that all enum values have valid properties.
/// Each test answers: "What bug does this catch?"
///
/// Bug categories:
/// - Missing/empty prompts → AI gets no context, generates garbage
/// - Missing/empty labels → UI shows blank text
/// - Invalid emojis → UI rendering issues
void main() {
  // ============================================================
  // OCCASION ENUM
  // Bug: New occasion added but prompt forgotten → AI fails
  // ============================================================

  group('Occasion enum', () {
    test('has exactly 40 occasions', () {
      // Bug: Occasion count changed but landing page/marketing not updated
      expect(Occasion.values.length, equals(40));
    });

    test('all occasions have non-empty labels', () {
      // Bug: UI shows empty string instead of occasion name
      for (final occasion in Occasion.values) {
        expect(
          occasion.label.isNotEmpty,
          isTrue,
          reason: '${occasion.name} has empty label',
        );
      }
    });

    test('all occasions have non-empty prompts', () {
      // Bug: AI receives empty context, generates irrelevant messages
      for (final occasion in Occasion.values) {
        expect(
          occasion.prompt.isNotEmpty,
          isTrue,
          reason: '${occasion.name} has empty prompt',
        );
        // Prompts should be descriptive (at least 10 chars)
        expect(
          occasion.prompt.length >= 10,
          isTrue,
          reason: '${occasion.name} prompt too short: "${occasion.prompt}"',
        );
      }
    });

    test('all occasions have valid emojis', () {
      // Bug: Empty emoji breaks UI layout
      for (final occasion in Occasion.values) {
        expect(
          occasion.emoji.isNotEmpty,
          isTrue,
          reason: '${occasion.name} has empty emoji',
        );
        // Emojis should be 1-4 characters (some emojis are multi-codepoint)
        expect(
          occasion.emoji.length <= 8,
          isTrue,
          reason: '${occasion.name} emoji too long: "${occasion.emoji}"',
        );
      }
    });

    test('all occasions have valid background colors', () {
      // Bug: Null color causes rendering crash
      for (final occasion in Occasion.values) {
        expect(occasion.backgroundColor, isNotNull);
        expect(occasion.borderColor, isNotNull);
        expect(occasion.color, isNotNull);
      }
    });

    test('no duplicate labels', () {
      // Bug: Two occasions show same name, confuses users
      final labels = Occasion.values.map((o) => o.label).toList();
      final uniqueLabels = labels.toSet();
      expect(labels.length, equals(uniqueLabels.length));
    });
  });

  // ============================================================
  // TONE ENUM
  // Bug: Tone prompt doesn't match label → confusing AI output
  // ============================================================

  group('Tone enum', () {
    test('has exactly 6 tones', () {
      // Bug: Tone count changed but not reflected in UI/tests
      expect(Tone.values.length, equals(6));
    });

    test('all tones have non-empty labels', () {
      // Bug: Tone selector shows blank option
      for (final tone in Tone.values) {
        expect(
          tone.label.isNotEmpty,
          isTrue,
          reason: '${tone.name} has empty label',
        );
      }
    });

    test('all tones have non-empty prompts', () {
      // Bug: AI gets no tone guidance
      for (final tone in Tone.values) {
        expect(
          tone.prompt.isNotEmpty,
          isTrue,
          reason: '${tone.name} has empty prompt',
        );
        expect(
          tone.prompt.length >= 10,
          isTrue,
          reason: '${tone.name} prompt too short',
        );
      }
    });

    test('all tones have non-empty descriptions', () {
      // Bug: Tone description in UI is blank
      for (final tone in Tone.values) {
        expect(
          tone.description.isNotEmpty,
          isTrue,
          reason: '${tone.name} has empty description',
        );
      }
    });

    test('all tones have valid emojis', () {
      // Bug: Empty emoji in tone selector
      for (final tone in Tone.values) {
        expect(
          tone.emoji.isNotEmpty,
          isTrue,
          reason: '${tone.name} has empty emoji',
        );
      }
    });

    test('expected tones exist', () {
      // Bug: Core tone accidentally deleted
      expect(Tone.values.map((t) => t.name), containsAll([
        'heartfelt',
        'casual',
        'funny',
        'formal',
        'inspirational',
        'playful',
      ]));
    });
  });

  // ============================================================
  // MESSAGE LENGTH ENUM
  // Bug: Length prompt doesn't give AI clear guidance
  // ============================================================

  group('MessageLength enum', () {
    test('has exactly 3 lengths', () {
      // Bug: Length option added/removed without UI update
      expect(MessageLength.values.length, equals(3));
    });

    test('all lengths have non-empty labels', () {
      // Bug: Length selector shows blank
      for (final length in MessageLength.values) {
        expect(
          length.label.isNotEmpty,
          isTrue,
          reason: '${length.name} has empty label',
        );
      }
    });

    test('all lengths have non-empty prompts with sentence guidance', () {
      // Bug: AI ignores length, always generates same size
      for (final length in MessageLength.values) {
        expect(
          length.prompt.isNotEmpty,
          isTrue,
          reason: '${length.name} has empty prompt',
        );
        // Length prompts should mention sentences
        expect(
          length.prompt.toLowerCase().contains('sentence'),
          isTrue,
          reason: '${length.name} prompt should mention sentences',
        );
      }
    });

    test('all lengths have non-empty descriptions', () {
      // Bug: Description in UI is blank
      for (final length in MessageLength.values) {
        expect(
          length.description.isNotEmpty,
          isTrue,
          reason: '${length.name} has empty description',
        );
      }
    });

    test('expected lengths exist with correct names', () {
      // Bug: Length renamed breaking saved preferences
      expect(MessageLength.values.map((l) => l.name), containsAll([
        'brief',
        'standard',
        'detailed',
      ]));
    });
  });

  // ============================================================
  // RELATIONSHIP ENUM
  // Bug: Relationship prompt too vague → AI doesn't adjust intimacy
  // ============================================================

  group('Relationship enum', () {
    test('has exactly 14 relationships', () {
      // Bug: Relationship count changed, marketing incorrect
      expect(Relationship.values.length, equals(14));
    });

    test('all relationships have non-empty labels', () {
      // Bug: Relationship selector shows blank
      for (final rel in Relationship.values) {
        expect(
          rel.label.isNotEmpty,
          isTrue,
          reason: '${rel.name} has empty label',
        );
      }
    });

    test('all relationships have non-empty prompts', () {
      // Bug: AI gets no relationship context
      for (final rel in Relationship.values) {
        expect(
          rel.prompt.isNotEmpty,
          isTrue,
          reason: '${rel.name} has empty prompt',
        );
        expect(
          rel.prompt.length >= 5,
          isTrue,
          reason: '${rel.name} prompt too short',
        );
      }
    });

    test('all relationships have valid emojis', () {
      // Bug: Empty emoji breaks layout
      for (final rel in Relationship.values) {
        expect(
          rel.emoji.isNotEmpty,
          isTrue,
          reason: '${rel.name} has empty emoji',
        );
      }
    });

    test('expected relationships exist', () {
      // Bug: Core relationship accidentally deleted
      expect(Relationship.values.map((r) => r.name), containsAll([
        'closeFriend',
        'family',
        'parent',
        'child',
        'sibling',
        'romantic',
        'colleague',
        'boss',
      ]));
    });

    test('no duplicate labels', () {
      // Bug: Two relationships show same name
      final labels = Relationship.values.map((r) => r.label).toList();
      final uniqueLabels = labels.toSet();
      expect(labels.length, equals(uniqueLabels.length));
    });
  });
}
