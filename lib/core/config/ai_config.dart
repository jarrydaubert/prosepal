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
  /// Default Gemini model (used if Remote Config unavailable).
  ///
  /// Keep production defaults pinned to stable non-alias model IDs.
  static const String defaultModel = 'gemini-2.5-flash';

  /// Fallback model if primary fails (404, deprecated, etc.)
  static const String defaultFallbackModel = 'gemini-2.5-flash-lite';

  /// Allowed Remote Config model IDs for production.
  ///
  /// Invalid IDs are ignored and replaced with safe defaults.
  static const Set<String> allowedModelIds = {
    defaultModel,
    defaultFallbackModel,
  };

  /// @deprecated Use RemoteConfigService.instance.aiModel instead
  /// Kept for backward compatibility during migration
  static const String model = defaultModel;

  /// Generation parameters
  /// Temperature 0.7 for consistent, reliable outputs (0.85 was too creative/random)
  static const double temperature = 0.7;
  static const int topK = 40;
  static const double topP = 0.95;
  static const int maxOutputTokens =
      8192; // Increased from 4096 to handle Gemini thinking tokens

  /// Retry configuration
  static const int maxRetries = 3;
  static const int initialDelayMs = 500;

  /// Input validation limits (defense-in-depth)
  static const int maxNameLength = 50;
  static const int maxDetailsLength = 500;

  /// System instruction (set once per model, saves tokens per call)
  static const String systemInstruction = '''
Write exactly 3 unique greeting card message options.

CORE RULES:
- Each message takes a different emotional angle
- Relationship means "the recipient is my ___" (e.g., Family = recipient is my family member, Coworker = recipient is my coworker)
- Write FROM that perspective - a message to your family member, coworker, friend, etc.
- Sound human, not AI-generated
- If a name is given, use it naturally

AVOID (critical):
- Do NOT invent specific memories, events, or inside jokes
- Do NOT assume what the occasion is about - if no personal details given, stay completely generic (celebrate THEM, not a specific achievement/event)
- Do NOT assume work/professional context unless relationship is Coworker/Boss
- For Sympathy: do NOT assume who died or the relationship to the deceased - keep it general about loss and support
- Do NOT use generic phrases: "wishing you all the best", "hope your day is special", "thinking of you"
- Do NOT add religious references unless the occasion implies them (Christmas/Easter OK)

LENGTH:
- Brief: 1-2 sentences
- Standard: 3-4 sentences  
- Detailed: 5-7 sentences

TONE (show don't tell):
- Funny = wit and wordplay
- Formal = polished and respectful
- Casual = like texting a friend

FORMAT:
- No greetings (no "Dear", "Hi", "Hey")
- No sign-offs (no "Love", "Best wishes", "Sincerely")
- Just the message body

EXAMPLE (Birthday + Friend + Funny + Standard):
{"messages":[
{"text":"Another satisfying year of proving everyone wrong about your life choices. Here's to more chaos disguised as character development."},
{"text":"Age is just a number, and yours is finally getting interesting. May your cake have more candles than your plans have follow-through."},
{"text":"You've officially reached the age where your back goes out more than you do. Welcome to the club, we have snacks."}
]}
''';
}
