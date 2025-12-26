import 'package:flutter/material.dart';

import '../../shared/theme/app_colors.dart';

enum Occasion {
  birthday(
    label: 'Birthday',
    emoji: '🎂',
    color: AppColors.birthday,
    prompt: 'birthday celebration',
  ),
  thankYou(
    label: 'Thank You',
    emoji: '🙏',
    color: AppColors.thankYou,
    prompt: 'expressing gratitude and appreciation',
  ),
  sympathy(
    label: 'Sympathy',
    emoji: '💐',
    color: AppColors.sympathy,
    prompt: 'offering condolences and comfort during a difficult time',
  ),
  wedding(
    label: 'Wedding',
    emoji: '💒',
    color: AppColors.wedding,
    prompt: 'wedding celebration and marriage',
  ),
  graduation(
    label: 'Graduation',
    emoji: '🎓',
    color: AppColors.graduation,
    prompt: 'graduation achievement and new beginnings',
  ),
  baby(
    label: 'New Baby',
    emoji: '👶',
    color: AppColors.baby,
    prompt: 'welcoming a new baby and congratulating new parents',
  ),
  getWell(
    label: 'Get Well',
    emoji: '🌻',
    color: AppColors.getWell,
    prompt: 'wishing someone a speedy recovery',
  ),
  anniversary(
    label: 'Anniversary',
    emoji: '💕',
    color: AppColors.anniversary,
    prompt: 'celebrating an anniversary milestone',
  ),
  congrats(
    label: 'Congrats',
    emoji: '🎉',
    color: AppColors.congrats,
    prompt: 'congratulating someone on their achievement',
  ),
  apology(
    label: 'Apology',
    emoji: '💔',
    color: AppColors.apology,
    prompt: 'apologizing and expressing sincere regret',
  );

  const Occasion({
    required this.label,
    required this.emoji,
    required this.color,
    required this.prompt,
  });

  final String label;
  final String emoji;
  final Color color;
  final String prompt;
}
