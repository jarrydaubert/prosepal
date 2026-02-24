/// Abstract interface for remote configuration services.
///
/// Enables dependency injection and mocking for unit tests without
/// requiring the Firebase Remote Config SDK at test time.
///
/// ## Usage Flow
/// 1. Call [initialize] at app startup (after Firebase.initializeApp)
/// 2. Access config values via [aiModel], [aiModelFallback], etc.
/// 3. Check [isUpdateRequired] to enforce minimum app versions
/// 4. Call [refresh] to force-fetch new values (respects fetch interval)
///
/// ## Testing
/// Use [MockRemoteConfigService] in tests to control config values
/// and simulate force update scenarios without Firebase SDK.
abstract class IRemoteConfigService {
  /// Whether the service has been initialized.
  ///
  /// Returns true after [initialize] completes (even if fetch failed,
  /// since defaults are used as fallback).
  bool get isInitialized;

  /// Initialize Remote Config with defaults and fetch latest values.
  ///
  /// Safe to call multiple times - subsequent calls are no-ops.
  /// Throws no exceptions - uses defaults on failure.
  Future<void> initialize();

  // ===== AI Model Config =====

  /// Current AI model to use for generation.
  ///
  /// Returns remote value if available, otherwise default from [AiConfig].
  String get aiModel;

  /// Fallback AI model if primary fails (404, deprecated, etc.).
  String get aiModelFallback;

  /// Whether Firebase AI should request limited-use App Check tokens.
  ///
  /// When true, AI requests use `FirebaseAppCheck.getLimitedUseToken()`
  /// for stronger replay resistance at the cost of stricter token behavior.
  bool get useLimitedUseAppCheckTokens;

  /// Schema version for Remote Config payload compatibility checks.
  int get configSchemaVersion;

  /// Feature kill switch for AI generation.
  bool get isAiEnabled;

  /// Feature kill switch for paywall presentation.
  bool get isPaywallEnabled;

  /// Feature kill switch for premium subscription flows.
  bool get isPremiumEnabled;

  // ===== Force Update Config =====

  /// Whether force update checking is enabled.
  ///
  /// When false, [isUpdateRequired] always returns false.
  /// Use to disable force update during rollout issues.
  bool get isForceUpdateEnabled;

  /// Minimum app version required for current platform.
  ///
  /// Format: semantic version string (e.g., "1.2.0").
  String get minAppVersion;

  /// Check if app version meets minimum requirement.
  ///
  /// Returns true if update is required (current < minimum).
  /// Returns false if:
  /// - Force update is disabled
  /// - Current version meets or exceeds minimum
  /// - Version check fails (fail-open for user experience)
  Future<bool> isUpdateRequired();

  /// Get the store URL for current platform.
  ///
  /// Returns App Store URL on iOS, Play Store URL on Android.
  String get storeUrl;

  /// Force refresh config from server.
  ///
  /// Respects [minimumFetchInterval] - may not actually fetch if
  /// called too frequently.
  Future<void> refresh();

  // ===== Version Comparison (exposed for testing) =====

  /// Compare two semantic version strings.
  ///
  /// Returns:
  /// - Negative if v1 < v2
  /// - Zero if v1 == v2
  /// - Positive if v1 > v2
  ///
  /// Examples:
  /// - compareVersions("1.0.0", "1.0.1") -> -1
  /// - compareVersions("2.0.0", "1.9.9") -> 1
  /// - compareVersions("1.2.3", "1.2.3") -> 0
  int compareVersions(String v1, String v2);
}
