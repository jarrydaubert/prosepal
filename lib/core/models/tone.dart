/// Tone options for message generation
/// Ordered by predicted user preference (most versatile first)
/// Prompts optimized for Google Gemini
enum Tone {
  heartfelt(
    label: 'Heartfelt',
    emoji: '💖',
    prompt:
        'warm, sincere, and emotionally touching - express genuine feeling without being overly sentimental',
    description: 'Warm and sincere',
  ),
  casual(
    label: 'Casual',
    emoji: '😊',
    prompt:
        'friendly, relaxed, and conversational - like talking to a friend, natural and easy',
    description: 'Friendly and relaxed',
  ),
  funny(
    label: 'Funny',
    emoji: '😂',
    prompt:
        'humorous, witty, and lighthearted - clever wordplay and gentle humor that makes them smile',
    description: 'Humorous and witty',
  ),
  formal(
    label: 'Formal',
    emoji: '📝',
    prompt:
        'professional, respectful, and polished - appropriate for colleagues, bosses, or formal occasions',
    description: 'Professional and polished',
  ),
  inspirational(
    label: 'Inspirational',
    emoji: '✨',
    prompt:
        'uplifting, motivational, and encouraging - genuinely inspiring without resorting to clichés',
    description: 'Uplifting and motivational',
  ),
  playful(
    label: 'Playful',
    emoji: '😜',
    prompt:
        'cheeky, teasing, and fun - gentle sarcasm and inside-joke energy between close friends',
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
