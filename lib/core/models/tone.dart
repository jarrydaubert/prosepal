enum Tone {
  heartfelt(
    label: 'Heartfelt',
    emoji: '💖',
    prompt: 'warm, sincere, and emotionally touching',
    description: 'Warm and sincere',
  ),
  casual(
    label: 'Casual',
    emoji: '😊',
    prompt: 'friendly, relaxed, and conversational',
    description: 'Friendly and relaxed',
  ),
  funny(
    label: 'Funny',
    emoji: '😂',
    prompt: 'humorous, witty, and lighthearted',
    description: 'Humorous and witty',
  ),
  formal(
    label: 'Formal',
    emoji: '📝',
    prompt: 'professional, respectful, and polished',
    description: 'Professional and polished',
  ),
  inspirational(
    label: 'Inspirational',
    emoji: '✨',
    prompt: 'uplifting, motivational, and encouraging',
    description: 'Uplifting and motivational',
  ),
  playful(
    label: 'Playful',
    emoji: '😜',
    prompt: 'cheeky, teasing, and fun with gentle sarcasm',
    description: 'Cheeky and teasing',
  );

  const Tone({
    required this.label,
    required this.emoji,
    required this.prompt,
    required this.description,
  });

  final String label;
  final String emoji;
  final String prompt;
  final String description;
}
