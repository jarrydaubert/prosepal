enum Relationship {
  // ============================================================
  // PERSONAL RELATIONSHIPS
  // ============================================================
  closeFriend(label: 'Close Friend', emoji: '👯', prompt: 'a close friend'),
  family(label: 'Family', emoji: '👨‍👩‍👧', prompt: 'a family member'),
  parent(label: 'Parent', emoji: '👨‍👩‍👦', prompt: 'a parent (mom or dad)'),
  child(label: 'Child', emoji: '👧', prompt: 'a son or daughter'),
  sibling(label: 'Sibling', emoji: '👫', prompt: 'a brother or sister'),
  grandparent(label: 'Grandparent', emoji: '👴', prompt: 'a grandparent'),
  grandchild(label: 'Grandchild', emoji: '👶', prompt: 'a grandchild'),
  romantic(
    label: 'Partner',
    emoji: '❤️',
    prompt: 'a romantic partner or spouse',
  ),

  // ============================================================
  // PROFESSIONAL RELATIONSHIPS
  // ============================================================
  colleague(
    label: 'Colleague',
    emoji: '💼',
    prompt: 'a work colleague or professional contact',
  ),
  boss(label: 'Boss', emoji: '👔', prompt: 'a boss or manager'),
  mentor(label: 'Mentor', emoji: '🎓', prompt: 'a mentor or guide'),
  teacher(label: 'Teacher', emoji: '📚', prompt: 'a teacher or educator'),

  // ============================================================
  // COMMUNITY RELATIONSHIPS
  // ============================================================
  neighbor(label: 'Neighbor', emoji: '🏡', prompt: 'a neighbor'),
  acquaintance(
    label: 'Acquaintance',
    emoji: '👋',
    prompt: 'an acquaintance or casual contact',
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
