/// Message length options for generation
/// Ordered shortest to longest for UI progression
/// Provides clear guidance to Gemini on output length
enum MessageLength {
  brief(
    label: 'Brief',
    emoji: '⚡',
    prompt: '1-2 sentences',
    description: 'Short & sweet',
  ),
  standard(
    label: 'Standard',
    emoji: '✨',
    prompt: '3-4 sentences',
    description: 'Just right',
  ),
  detailed(
    label: 'Detailed',
    emoji: '💝',
    prompt: '5-7 sentences',
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
