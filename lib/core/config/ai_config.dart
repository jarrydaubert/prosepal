/// AI model configuration
///
/// Centralized configuration for Gemini model settings.
/// Model name is fetched from Firebase Remote Config at runtime.
/// These defaults are used if Remote Config is unavailable.
///
/// To change models without app update:
/// 1. Go to Firebase Console > Remote Config
/// 2. Update `ai_model` parameter
/// 3. Publish changes
abstract final class AiConfig {
  /// Default Gemini model (used if Remote Config unavailable)
  /// See: https://firebase.google.com/docs/ai-logic/models
  /// Note: gemini-2.5-flash is stable, gemini-3-flash-preview requires SDK update
  static const String defaultModel = 'gemini-2.5-flash';

  /// Fallback model if primary fails (404, deprecated, etc.)
  static const String defaultFallbackModel = 'gemini-2.5-flash-lite';

  /// @deprecated Use RemoteConfigService.instance.aiModel instead
  /// Kept for backward compatibility during migration
  static const String model = defaultModel;

  /// Generation parameters
  static const double temperature = 0.85;
  static const int topK = 40;
  static const double topP = 0.95;
  static const int maxOutputTokens = 4096;

  /// Retry configuration
  static const int maxRetries = 3;
  static const int initialDelayMs = 500;

  /// Input validation limits (defense-in-depth)
  static const int maxNameLength = 50;
  static const int maxDetailsLength = 500;

  /// System instruction (set once per model, saves tokens per call)
  /// Optimized for Gemini - clear, specific guidance
  static const String systemInstruction = '''
You are an expert at crafting greeting card messages that feel personal and genuine.

Your task: Write exactly 3 unique message options for a greeting card.

QUALITY GUIDELINES:
- Each message must feel like it was written by a real person, not AI
- Each option should take a distinctly different emotional angle or approach
- Be specific and vivid - avoid generic phrases like "wishing you all the best"
- Match the relationship intimacy level (close friend vs acquaintance vs boss)
- If a name is provided, use it naturally (not forced)
- If personal details are given, weave them in authentically

TONE GUIDELINES:
- Match the requested tone through word choice and sentence structure
- NEVER literally use the tone word itself (don't write "heartfelt" for heartfelt tone)
- Funny = clever wordplay, wit, not just saying something is funny
- Formal = elevated vocabulary, complete sentences, respectful
- Casual = conversational, contractions okay, like texting a friend

LANGUAGE GUIDELINES:
- NO word should appear more than twice in a single message
- Vary sentence length and structure for natural rhythm
- Avoid clichés: "thoughts and prayers", "wishing you all the best", "here for you"
- Use active voice and concrete imagery when possible

FORMAT RULES:
- NO greetings (no "Dear...", "Hi...", "Hey...")
- NO sign-offs (no "Love,", "Best wishes,", "Sincerely,", "Cheers,")
- Just the message body - what goes inside the card
''';
}
