enum Relationship {
  closeFriend(
    label: 'Close Friend',
    emoji: '👯',
    prompt: 'a close friend',
  ),
  family(
    label: 'Family',
    emoji: '👨‍👩‍👧',
    prompt: 'a family member',
  ),
  colleague(
    label: 'Colleague',
    emoji: '💼',
    prompt: 'a work colleague or professional contact',
  ),
  acquaintance(
    label: 'Acquaintance',
    emoji: '👋',
    prompt: 'an acquaintance or casual contact',
  ),
  romantic(
    label: 'Partner',
    emoji: '❤️',
    prompt: 'a romantic partner or spouse',
  );

  const Relationship({
    required this.label,
    required this.emoji,
    required this.prompt,
  });

  final String label;
  final String emoji;
  final String prompt;
}
