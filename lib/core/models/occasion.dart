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

/// Occasions ordered by predicted usage frequency (most used first)
/// This order determines display order in the occasion grid
enum Occasion {
  // ============================================================
  // TIER 1: HIGHEST USAGE (Universal, frequent occasions)
  // ============================================================
  birthday(
    label: 'Birthday',
    emoji: '🎂',
    prompt: 'birthday celebration - joyful wishes for their special day and the year ahead',
    opacity: _OccasionOpacity.low,
  ),
  thankYou(
    label: 'Thank You',
    emoji: '🙏',
    prompt: 'expressing genuine, specific gratitude - make it personal and meaningful',
    opacity: _OccasionOpacity.medium,
  ),
  sympathy(
    label: 'Sympathy',
    emoji: '💐',
    prompt: 'offering condolences and comfort - acknowledge grief with warmth, avoid clichés, be genuinely supportive',
    opacity: _OccasionOpacity.high,
  ),
  wedding(
    label: 'Wedding',
    emoji: '💒',
    prompt: 'wedding celebration - heartfelt wishes for their journey together as a married couple',
    opacity: _OccasionOpacity.low,
  ),
  christmas(
    label: 'Christmas',
    emoji: '🎄',
    prompt: 'warm Christmas wishes - capture the spirit of the season with joy and goodwill',
    opacity: _OccasionOpacity.medium,
  ),

  // ============================================================
  // TIER 2: HIGH USAGE (Common life events & occasions)
  // ============================================================
  getWell(
    label: 'Get Well',
    emoji: '🌻',
    prompt: 'get well wishes - encouraging and warm without minimizing their situation',
    opacity: _OccasionOpacity.low,
  ),
  congrats(
    label: 'Congrats',
    emoji: '🎉',
    prompt: 'congratulations on an achievement - celebrate their hard work and success enthusiastically',
    opacity: _OccasionOpacity.high,
  ),
  mothersDay(
    label: "Mother's Day",
    emoji: '👩‍👧‍👦',
    prompt: "celebrating a mother on Mother's Day - express love, appreciation, and gratitude for all she does",
    opacity: _OccasionOpacity.medium,
  ),
  fathersDay(
    label: "Father's Day",
    emoji: '👨‍👧‍👦',
    prompt: "celebrating a father on Father's Day - express love, appreciation, and gratitude for his guidance",
    opacity: _OccasionOpacity.low,
  ),
  baby(
    label: 'New Baby',
    emoji: '👶',
    prompt: 'welcoming a new baby - joyful congratulations for the new parents on this life-changing moment',
    opacity: _OccasionOpacity.high,
  ),

  // ============================================================
  // TIER 3: MODERATE USAGE (Milestones & seasonal)
  // ============================================================
  graduation(
    label: 'Graduation',
    emoji: '🎓',
    prompt: 'graduation celebration - honor their achievement and wish them well on the exciting path ahead',
    opacity: _OccasionOpacity.medium,
  ),
  anniversary(
    label: 'Anniversary',
    emoji: '💕',
    prompt: 'celebrating an anniversary milestone - honor the journey and love they share together',
    opacity: _OccasionOpacity.medium,
  ),
  valentinesDay(
    label: "Valentine's Day",
    emoji: '❤️',
    prompt: "expressing romantic love on Valentine's Day - heartfelt and genuine, not cheesy",
    opacity: _OccasionOpacity.high,
  ),
  thinkingOfYou(
    label: 'Thinking of You',
    emoji: '🤗',
    prompt: 'letting someone know you care - warm thoughts that brighten their day',
    opacity: _OccasionOpacity.medium,
  ),
  newYear(
    label: 'New Year',
    emoji: '🎆',
    prompt: 'New Year wishes - hopeful sentiments for happiness, health, and success in the year ahead',
    opacity: _OccasionOpacity.medium,
  ),
  engagement(
    label: 'Engagement',
    emoji: '💍',
    prompt: 'congratulating on an engagement - celebrate this exciting step toward marriage',
    opacity: _OccasionOpacity.high,
  ),
  kidsBirthday(
    label: "Kid's Birthday",
    emoji: '🎈',
    prompt: 'fun, child-appropriate birthday celebration - playful and age-appropriate excitement',
    opacity: _OccasionOpacity.medium,
  ),
  justBecause(
    label: 'Just Because',
    emoji: '💝',
    prompt: 'sending love or appreciation for no special reason - spontaneous warmth and connection',
    opacity: _OccasionOpacity.high,
  ),

  // ============================================================
  // TIER 4: OCCASIONAL USE (Life milestones)
  // ============================================================
  housewarming(
    label: 'New Home',
    emoji: '🏠',
    prompt: 'congratulating on a new home - warm wishes for happiness and memories in their new space',
    opacity: _OccasionOpacity.high,
  ),
  retirement(
    label: 'Retirement',
    emoji: '🏖️',
    prompt: 'celebrating retirement - honor their career and wish them well for this exciting new chapter',
    opacity: _OccasionOpacity.medium,
  ),
  newJob(
    label: 'New Job',
    emoji: '💼',
    prompt: 'congratulating on a new job - celebrate this career milestone and wish them success',
    opacity: _OccasionOpacity.medium,
  ),
  encouragement(
    label: 'Encouragement',
    emoji: '💪',
    prompt: 'offering support during a challenge - uplifting and genuine without toxic positivity',
    opacity: _OccasionOpacity.low,
  ),

  // ============================================================
  // TIER 5: SEASONAL (Holiday-specific)
  // ============================================================
  easter(
    label: 'Easter',
    emoji: '🥚',
    prompt: 'warm Easter wishes - celebrate spring, renewal, and joy of the season',
    opacity: _OccasionOpacity.high,
  ),
  thanksgiving(
    label: 'Thanksgiving',
    emoji: '🦃',
    prompt: 'Thanksgiving wishes - express gratitude and warm thoughts for the holiday',
    opacity: _OccasionOpacity.medium,
  ),
  halloween(
    label: 'Halloween',
    emoji: '🎃',
    prompt: 'fun Halloween greetings - playful spooky wishes appropriate for the occasion',
    opacity: _OccasionOpacity.low,
  ),

  // ============================================================
  // TIER 6: SPECIFIC SITUATIONS
  // ============================================================
  apology(
    label: 'Apology',
    emoji: '💔',
    prompt: 'sincere apology - acknowledge what went wrong, express genuine remorse without making excuses',
    opacity: _OccasionOpacity.low,
  ),
  farewell(
    label: 'Farewell',
    emoji: '👋',
    prompt: 'saying goodbye - heartfelt farewell that honors the relationship and wishes them well',
    opacity: _OccasionOpacity.low,
  ),
  goodLuck(
    label: 'Good Luck',
    emoji: '🤞',
    prompt: 'wishing good luck - encouraging words for an upcoming challenge, interview, or big moment',
    opacity: _OccasionOpacity.medium,
  ),
  promotion(
    label: 'Promotion',
    emoji: '📈',
    prompt: 'congratulating on a promotion - celebrate their hard work and well-deserved recognition',
    opacity: _OccasionOpacity.high,
  ),

  // ============================================================
  // TIER 7: APPRECIATION (Role-specific thanks)
  // ============================================================
  thankYouTeacher(
    label: 'Thank You Teacher',
    emoji: '🍎',
    prompt: 'thanking a teacher - express gratitude for their dedication, patience, and impact on learning',
    opacity: _OccasionOpacity.low,
  ),
  thankYouHealthcare(
    label: 'Thank You Healthcare',
    emoji: '🩺',
    prompt: 'thanking a healthcare worker - express gratitude for their care, compassion, and expertise',
    opacity: _OccasionOpacity.medium,
  ),
  thankYouService(
    label: 'Thank You for Service',
    emoji: '🎖️',
    prompt: 'thanking a veteran or service member - honor their sacrifice and service to the country',
    opacity: _OccasionOpacity.high,
  ),

  // ============================================================
  // TIER 8: CULTURAL/RELIGIOUS HOLIDAYS
  // ============================================================
  hanukkah(
    label: 'Hanukkah',
    emoji: '🕎',
    prompt: 'warm Hanukkah wishes - celebrate the Festival of Lights with joy and tradition',
    opacity: _OccasionOpacity.high,
  ),
  diwali(
    label: 'Diwali',
    emoji: '🪔',
    prompt: 'Diwali wishes - celebrate the festival of lights with joy, prosperity, and new beginnings',
    opacity: _OccasionOpacity.low,
  ),
  eid(
    label: 'Eid',
    emoji: '🌙',
    prompt: 'warm Eid wishes - celebrate with joy, peace, blessings, and togetherness',
    opacity: _OccasionOpacity.medium,
  ),
  lunarNewYear(
    label: 'Lunar New Year',
    emoji: '🧧',
    prompt: 'Lunar New Year wishes - celebrate with prosperity, good fortune, and family blessings',
    opacity: _OccasionOpacity.high,
  ),
  kwanzaa(
    label: 'Kwanzaa',
    emoji: '🕯️',
    prompt: 'Kwanzaa wishes - honor the principles of unity, creativity, faith, and community',
    opacity: _OccasionOpacity.low,
  ),

  // ============================================================
  // TIER 9: PET OCCASIONS
  // ============================================================
  petBirthday(
    label: 'Pet Birthday',
    emoji: '🐶',
    prompt: 'fun pet birthday celebration - playful wishes for a beloved furry family member',
    opacity: _OccasionOpacity.high,
  ),
  newPet(
    label: 'New Pet',
    emoji: '🐕',
    prompt: 'welcoming a new pet - congratulate them on their new furry, feathered, or scaly family member',
    opacity: _OccasionOpacity.low,
  ),
  petSympathy(
    label: 'Pet Loss',
    emoji: '🌈',
    prompt: 'condolences for pet loss - acknowledge their grief with warmth and understanding for a beloved companion',
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
