enum MessageLength {
  brief(
    label: 'Brief',
    emoji: '⚡',
    prompt: '1-2 sentences, concise and impactful',
    description: 'Short & sweet',
  ),
  standard(
    label: 'Standard',
    emoji: '✨',
    prompt: '2-4 sentences, balanced and complete',
    description: 'Just right',
  ),
  heartfelt(
    label: 'Heartfelt',
    emoji: '💝',
    prompt: '4-6 sentences, detailed and deeply personal',
    description: 'Longer & personal',
  );

  const MessageLength({
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
