import 'package:flutter/material.dart';

import '../../shared/theme/app_colors.dart';

/// Opacity variants for occasion card backgrounds
/// Explicit values ensure colors don't shift if enum is reordered
enum _OccasionOpacity {
  low(0.08),
  medium(0.10),
  high(0.12);

  const _OccasionOpacity(this.value);
  final double value;
}

enum Occasion {
  birthday(
    label: 'Birthday',
    emoji: '🎂',
    prompt: 'birthday celebration',
    opacity: _OccasionOpacity.low,
  ),
  thankYou(
    label: 'Thank You',
    emoji: '🙏',
    prompt: 'expressing gratitude and appreciation',
    opacity: _OccasionOpacity.medium,
  ),
  sympathy(
    label: 'Sympathy',
    emoji: '💐',
    prompt: 'offering condolences and comfort during a difficult time',
    opacity: _OccasionOpacity.high,
  ),
  wedding(
    label: 'Wedding',
    emoji: '💒',
    prompt: 'wedding celebration and marriage',
    opacity: _OccasionOpacity.low,
  ),
  graduation(
    label: 'Graduation',
    emoji: '🎓',
    prompt: 'graduation achievement and new beginnings',
    opacity: _OccasionOpacity.medium,
  ),
  baby(
    label: 'New Baby',
    emoji: '👶',
    prompt: 'welcoming a new baby and congratulating new parents',
    opacity: _OccasionOpacity.high,
  ),
  getWell(
    label: 'Get Well',
    emoji: '🌻',
    prompt: 'wishing someone a speedy recovery',
    opacity: _OccasionOpacity.low,
  ),
  anniversary(
    label: 'Anniversary',
    emoji: '💕',
    prompt: 'celebrating an anniversary milestone',
    opacity: _OccasionOpacity.medium,
  ),
  congrats(
    label: 'Congrats',
    emoji: '🎉',
    prompt: 'congratulating someone on their achievement',
    opacity: _OccasionOpacity.high,
  ),
  apology(
    label: 'Apology',
    emoji: '💔',
    prompt: 'apologizing and expressing sincere regret',
    opacity: _OccasionOpacity.low,
  );

  const Occasion({
    required this.label,
    required this.emoji,
    required this.prompt,
    required this.opacity,
  });

  final String label;
  final String emoji;
  final String prompt;
  final _OccasionOpacity opacity;

  /// Get the unified brand color for this occasion
  Color get color => AppColors.primary;

  /// Get background color - explicit per-variant opacity (reorder-safe)
  Color get backgroundColor =>
      AppColors.primary.withValues(alpha: opacity.value);

  /// Get border color
  Color get borderColor => AppColors.primary.withValues(alpha: 0.25);
}
