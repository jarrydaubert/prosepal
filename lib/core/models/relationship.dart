/// Relationship types for message personalization
/// Ordered by intimacy level (personal → professional → community)
/// Prompts help Gemini understand the appropriate tone and intimacy level
enum Relationship {
  // ============================================================
  // PERSONAL RELATIONSHIPS (Close, intimate)
  // ============================================================
  closeFriend(
    label: 'Close Friend',
    emoji: '👯',
    prompt:
        'a close friend - someone you share inside jokes with and can be yourself around',
  ),
  family(
    label: 'Family',
    emoji: '👨‍👩‍👧',
    prompt:
        'a general family member - warm and familiar but not specifically defined',
  ),
  parent(
    label: 'Parent',
    emoji: '👨‍👩‍👦',
    prompt:
        'a parent (mom or dad) - deep gratitude, love, and respect for all they do',
  ),
  child(
    label: 'Child',
    emoji: '👧',
    prompt:
        'a son or daughter - parental pride, unconditional love, and encouragement',
  ),
  sibling(
    label: 'Sibling',
    emoji: '👫',
    prompt:
        'a brother or sister - that unique mix of teasing, loyalty, and lifelong bond',
  ),
  grandparent(
    label: 'Grandparent',
    emoji: '👴',
    prompt:
        'a grandparent - deep respect, appreciation for their wisdom and love',
  ),
  grandchild(
    label: 'Grandchild',
    emoji: '👶',
    prompt: 'a grandchild - grandparental adoration, pride, and warm affection',
  ),
  romantic(
    label: 'Partner',
    emoji: '❤️',
    prompt:
        'a romantic partner or spouse - intimate, loving, can reference shared experiences',
  ),

  // ============================================================
  // PROFESSIONAL RELATIONSHIPS (Respectful, appropriate)
  // ============================================================
  colleague(
    label: 'Colleague',
    emoji: '💼',
    prompt:
        'a work colleague - friendly but professional, appropriate for the workplace',
  ),
  boss(
    label: 'Boss',
    emoji: '👔',
    prompt:
        'a boss or manager - respectful, professional, appreciative of their leadership',
  ),
  mentor(
    label: 'Mentor',
    emoji: '🎓',
    prompt:
        'a mentor or guide - gratitude for their guidance, wisdom, and investment in your growth',
  ),
  teacher(
    label: 'Teacher',
    emoji: '📚',
    prompt:
        'a teacher or educator - appreciation for their patience, knowledge, and impact',
  ),

  // ============================================================
  // COMMUNITY RELATIONSHIPS (Friendly, appropriate distance)
  // ============================================================
  neighbor(
    label: 'Neighbor',
    emoji: '🏡',
    prompt:
        'a neighbor - friendly and warm, community-minded, appropriate neighborly tone',
  ),
  acquaintance(
    label: 'Acquaintance',
    emoji: '👋',
    prompt:
        'an acquaintance or casual contact - polite, warm but not overly familiar',
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
