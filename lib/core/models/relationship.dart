enum Relationship {
  closeFriend(label: 'Close Friend', emoji: '👯', prompt: 'a close friend'),
  family(label: 'Family', emoji: '👨‍👩‍👧', prompt: 'a family member'),
  parent(label: 'Parent', emoji: '👨‍👩‍👦', prompt: 'a parent (mom or dad)'),
  child(label: 'Child', emoji: '👧', prompt: 'a son or daughter'),
  colleague(
    label: 'Colleague',
    emoji: '💼',
    prompt: 'a work colleague or professional contact',
  ),
  boss(label: 'Boss', emoji: '👔', prompt: 'a boss or manager'),
  mentor(label: 'Mentor', emoji: '🎓', prompt: 'a mentor or teacher'),
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
