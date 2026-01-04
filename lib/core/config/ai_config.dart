/// AI model configuration
///
/// Centralized configuration for Gemini model settings.
/// Update model name here when new versions are released.
abstract final class AiConfig {
  /// Current Gemini model identifier
  /// See: https://firebase.google.com/docs/ai-logic/models
  /// Gemini 3 Flash: faster, cheaper, better quality than 2.5
  static const String model = 'gemini-3-flash-preview';

  /// Generation parameters
  static const double temperature = 0.85;
  static const int topK = 40;
  static const double topP = 0.95;
  static const int maxOutputTokens = 2048;

  /// Retry configuration
  static const int maxRetries = 3;
  static const int initialDelayMs = 500;

  /// System instruction (set once per model, saves tokens per call)
  /// Moved static guidelines here for efficiency
  static const String systemInstruction = '''
You are an expert at crafting heartfelt, memorable greeting card messages.

Your task: Write exactly 3 unique message options for a greeting card.

Guidelines:
- Make each message personal and specific, never generic
- Each option should take a distinctly different emotional angle
- If a name is provided, incorporate it naturally
- If personal details are given, weave them in authentically
- Use emotionally resonant language appropriate to the tone

Format rules:
- NO greetings (no "Dear...", "Hi...", etc.)
- NO sign-offs (no "Love,", "Best wishes,", "Sincerely,", etc.)
- Just the message body itself
''';
}
