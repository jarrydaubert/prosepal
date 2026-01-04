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
  // ============================================================
  // CORE OCCASIONS (Most common, evergreen)
  // ============================================================
  birthday(
    label: 'Birthday',
    emoji: '🎂',
    prompt: 'birthday celebration',
    opacity: _OccasionOpacity.low,
  ),
  kidsBirthday(
    label: "Kid's Birthday",
    emoji: '🎈',
    prompt: 'fun, child-appropriate birthday celebration for a young child',
    opacity: _OccasionOpacity.medium,
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
  engagement(
    label: 'Engagement',
    emoji: '💍',
    prompt: 'congratulating on an engagement',
    opacity: _OccasionOpacity.high,
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
  ),
  retirement(
    label: 'Retirement',
    emoji: '🏖️',
    prompt: 'celebrating retirement and wishing well for the next chapter',
    opacity: _OccasionOpacity.medium,
  ),
  housewarming(
    label: 'New Home',
    emoji: '🏠',
    prompt: 'congratulating on a new home and wishing happiness there',
    opacity: _OccasionOpacity.high,
  ),
  encouragement(
    label: 'Encouragement',
    emoji: '💪',
    prompt: 'offering encouragement and support during a challenge',
    opacity: _OccasionOpacity.low,
  ),
  thinkingOfYou(
    label: 'Thinking of You',
    emoji: '🤗',
    prompt: 'sending warm thoughts and letting someone know you care',
    opacity: _OccasionOpacity.medium,
  ),
  justBecause(
    label: 'Just Because',
    emoji: '💝',
    prompt: 'sending love, appreciation, or a smile just because',
    opacity: _OccasionOpacity.high,
  ),

  // ============================================================
  // HOLIDAYS (Major seasonal occasions)
  // ============================================================
  mothersDay(
    label: "Mother's Day",
    emoji: '👩‍👧‍👦',
    prompt: "celebrating and appreciating a mother on Mother's Day",
    opacity: _OccasionOpacity.medium,
  ),
  fathersDay(
    label: "Father's Day",
    emoji: '👨‍👧‍👦',
    prompt: "celebrating and appreciating a father on Father's Day",
    opacity: _OccasionOpacity.low,
  ),
  valentinesDay(
    label: "Valentine's Day",
    emoji: '❤️',
    prompt: "expressing romantic love on Valentine's Day",
    opacity: _OccasionOpacity.high,
  ),
  christmas(
    label: 'Christmas',
    emoji: '🎄',
    prompt: 'warm holiday wishes for Christmas',
    opacity: _OccasionOpacity.low,
  ),
  thanksgiving(
    label: 'Thanksgiving',
    emoji: '🦃',
    prompt: 'giving thanks and warm wishes for Thanksgiving',
    opacity: _OccasionOpacity.medium,
  ),
  easter(
    label: 'Easter',
    emoji: '🥚',
    prompt: 'warm Easter wishes and spring celebration',
    opacity: _OccasionOpacity.high,
  ),
  halloween(
    label: 'Halloween',
    emoji: '🎃',
    prompt: 'fun Halloween greetings and spooky wishes',
    opacity: _OccasionOpacity.low,
  ),
  newYear(
    label: 'New Year',
    emoji: '🎆',
    prompt: 'New Year wishes for happiness and success',
    opacity: _OccasionOpacity.medium,
  ),

  // ============================================================
  // CULTURAL/RELIGIOUS HOLIDAYS (Inclusive)
  // ============================================================
  hanukkah(
    label: 'Hanukkah',
    emoji: '🕎',
    prompt: 'warm wishes for Hanukkah and the Festival of Lights',
    opacity: _OccasionOpacity.high,
  ),
  diwali(
    label: 'Diwali',
    emoji: '🪔',
    prompt: 'celebrating Diwali, the festival of lights and new beginnings',
    opacity: _OccasionOpacity.low,
  ),
  eid(
    label: 'Eid',
    emoji: '🌙',
    prompt: 'warm Eid wishes for joy, peace, and celebration',
    opacity: _OccasionOpacity.medium,
  ),
  lunarNewYear(
    label: 'Lunar New Year',
    emoji: '🧧',
    prompt: 'celebrating Lunar New Year with prosperity and good fortune',
    opacity: _OccasionOpacity.high,
  ),
  kwanzaa(
    label: 'Kwanzaa',
    emoji: '🕯️',
    prompt: 'honoring Kwanzaa principles of unity, creativity, and faith',
    opacity: _OccasionOpacity.low,
  ),

  // ============================================================
  // CAREER & MILESTONES
  // ============================================================
  newJob(
    label: 'New Job',
    emoji: '💼',
    prompt: 'congratulating on a new job or career move',
    opacity: _OccasionOpacity.medium,
  ),
  promotion(
    label: 'Promotion',
    emoji: '📈',
    prompt: 'congratulating on a job promotion',
    opacity: _OccasionOpacity.high,
  ),
  farewell(
    label: 'Farewell',
    emoji: '👋',
    prompt: 'saying goodbye or bon voyage',
    opacity: _OccasionOpacity.low,
  ),
  goodLuck(
    label: 'Good Luck',
    emoji: '🤞',
    prompt: 'wishing good luck for an upcoming event or challenge',
    opacity: _OccasionOpacity.medium,
  ),

  // ============================================================
  // APPRECIATION (Role-specific thanks)
  // ============================================================
  thankYouService(
    label: 'Thank You for Service',
    emoji: '🎖️',
    prompt: 'thanking a veteran or service member for their sacrifice and service',
    opacity: _OccasionOpacity.high,
  ),
  thankYouTeacher(
    label: 'Thank You Teacher',
    emoji: '🍎',
    prompt: 'thanking a teacher for their dedication and impact on learning',
    opacity: _OccasionOpacity.low,
  ),
  thankYouHealthcare(
    label: 'Thank You Healthcare',
    emoji: '🩺',
    prompt: 'expressing gratitude to a nurse, doctor, or healthcare professional',
    opacity: _OccasionOpacity.medium,
  ),

  // ============================================================
  // PET OCCASIONS
  // ============================================================
  petBirthday(
    label: 'Pet Birthday',
    emoji: '🐶',
    prompt: 'fun birthday celebration for a beloved pet',
    opacity: _OccasionOpacity.high,
  ),
  newPet(
    label: 'New Pet',
    emoji: '🐕',
    prompt: 'welcoming a new pet into the family',
    opacity: _OccasionOpacity.low,
  ),
  petSympathy(
    label: 'Pet Loss',
    emoji: '🌈',
    prompt: 'offering condolences for the loss of a beloved pet',
    opacity: _OccasionOpacity.medium,
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
