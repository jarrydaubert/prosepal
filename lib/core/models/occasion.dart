import 'package:flutter/material.dart';

import '../../shared/theme/app_colors.dart';

enum Occasion {
  birthday(label: 'Birthday', emoji: '🎂', prompt: 'birthday celebration'),
  thankYou(
    label: 'Thank You',
    emoji: '🙏',
    prompt: 'expressing gratitude and appreciation',
  ),
  sympathy(
    label: 'Sympathy',
    emoji: '💐',
    prompt: 'offering condolences and comfort during a difficult time',
  ),
  wedding(
    label: 'Wedding',
    emoji: '💒',
    prompt: 'wedding celebration and marriage',
  ),
  graduation(
    label: 'Graduation',
    emoji: '🎓',
    prompt: 'graduation achievement and new beginnings',
  ),
  baby(
    label: 'New Baby',
    emoji: '👶',
    prompt: 'welcoming a new baby and congratulating new parents',
  ),
  getWell(
    label: 'Get Well',
    emoji: '🌻',
    prompt: 'wishing someone a speedy recovery',
  ),
  anniversary(
    label: 'Anniversary',
    emoji: '💕',
    prompt: 'celebrating an anniversary milestone',
  ),
  congrats(
    label: 'Congrats',
    emoji: '🎉',
    prompt: 'congratulating someone on their achievement',
  ),
  apology(
    label: 'Apology',
    emoji: '💔',
    prompt: 'apologizing and expressing sincere regret',
  );

  const Occasion({
    required this.label,
    required this.emoji,
    required this.prompt,
  });

  final String label;
  final String emoji;
  final String prompt;

  /// Get the unified brand color for this occasion
  /// All occasions use the primary coral color for brand consistency
  Color get color => AppColors.primary;

  /// Get background color with slight opacity variation based on index
  Color get backgroundColor => AppColors.occasionBackground(index);

  /// Get border color
  Color get borderColor => AppColors.occasionBorder(index);
}
