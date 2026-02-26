/// Message length options for generation
/// Ordered shortest to longest for UI progression
/// Provides clear guidance to Gemini on output length
enum MessageLength {
  brief(
    label: 'Brief',
    emoji: '⚡',
    prompt: '1-2 sentences maximum - concise, impactful, gets straight to the point',
    description: 'Short & sweet',
  ),
  standard(
    label: 'Standard',
    emoji: '✨',
    prompt: '2-4 sentences - balanced length with room to express the sentiment fully',
    description: 'Just right',
  ),
  detailed(
    label: 'Detailed',
    emoji: '💝',
    prompt: '4-6 sentences - longer format with space for personal details and deeper expression',
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
