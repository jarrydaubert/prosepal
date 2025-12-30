/// AI model configuration
///
/// Centralized configuration for Gemini model settings.
/// Update model name here when new versions are released.
abstract final class AiConfig {
  /// Current Gemini model identifier
  /// See: https://ai.google.dev/gemini-api/docs/models
  static const String model = 'gemini-2.0-flash';

  /// Generation parameters
  static const double temperature = 0.85;
  static const int topK = 40;
  static const double topP = 0.95;
  static const int maxOutputTokens = 1024;

  /// Retry configuration
  static const int maxRetries = 3;
  static const int initialDelayMs = 500;
}
