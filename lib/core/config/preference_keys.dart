/// Centralized SharedPreferences keys to avoid duplication and typos.
///
/// Keys are organized by feature area. Each key has:
/// - A constant for the key string
/// - A default value constant (where applicable)
///
/// ## Usage
/// ```dart
/// final enabled = prefs.getBool(PreferenceKeys.Analytics.enabled)
///     ?? PreferenceKeys.Analytics.enabledDefault;
/// ```
///
/// ## Adding New Keys
/// 1. Add to appropriate category (or create new nested class)
/// 2. Include default value if the key has one
/// 3. Document GDPR/privacy implications if applicable
abstract class PreferenceKeys {
  PreferenceKeys._(); // Prevent instantiation

  // ===========================================================================
  // Analytics & Privacy (GDPR-sensitive)
  // ===========================================================================

  /// Analytics opt-out preference (GDPR consent)
  /// Controls both Firebase Analytics and Crashlytics
  static const analyticsEnabled = 'analytics_enabled';
  static const analyticsEnabledDefault = true;

  // ===========================================================================
  // Onboarding
  // ===========================================================================

  /// Whether user has completed the onboarding flow
  static const hasCompletedOnboarding = 'hasCompletedOnboarding';
  static const hasCompletedOnboardingDefault = false;

  /// Whether user has generated their first message (for activation tracking)
  static const hasGeneratedFirstMessage = 'has_generated_first_message';
  static const hasGeneratedFirstMessageDefault = false;

  /// Whether user has seen the first-action hint on home screen
  static const hasSeenFirstActionHint = 'has_seen_first_action_hint';
  static const hasSeenFirstActionHintDefault = false;

  // ===========================================================================
  // App Review
  // ===========================================================================

  /// Timestamp of first app launch (for review timing)
  static const reviewFirstLaunch = 'review_first_launch';

  /// Whether review has been requested this install
  static const reviewHasRequested = 'review_has_requested';
  static const reviewHasRequestedDefault = false;

  // ===========================================================================
  // Usage Tracking (local cache - server is source of truth)
  // ===========================================================================

  /// Total message count (lifetime)
  static const usageTotalCount = 'usage_total_count';
  static const usageTotalCountDefault = 0;

  /// Monthly message count
  static const usageMonthlyCount = 'usage_monthly_count';
  static const usageMonthlyCountDefault = 0;

  /// Month key for monthly count (e.g., "2026-01")
  static const usageMonthlyDate = 'usage_monthly_date';

  /// Whether device has used free tier (for anonymous limits)
  static const usageDeviceUsedFreeTier = 'usage_device_used_free_tier';
  static const usageDeviceUsedFreeTierDefault = false;

  /// Last synced user ID (for merge detection)
  static const usageLastSyncUserId = 'usage_last_sync_user_id';

  // ===========================================================================
  // Rate Limiting
  // ===========================================================================

  /// Persisted rate limit timestamps (survives app restart)
  static const rateLimitTimestamps = 'rate_limit_timestamps';

  // ===========================================================================
  // Subscription
  // ===========================================================================

  /// Cached pro status (for fast UI, not for entitlement checks)
  static const proStatusCache = 'pro_status_cache';
  static const proStatusCacheDefault = false;

  /// User ID associated with cached pro status (prevents cross-account leakage)
  static const proStatusCacheUserId = 'pro_status_cache_user_id';

  /// Timestamp of last explicit paywall dismissal (ISO string)
  static const paywallLastDismissed = 'paywall_last_dismissed';

  // ===========================================================================
  // Spelling / Localization
  // ===========================================================================

  /// Spelling preference: 'us' (Mom, favorite) or 'uk' (Mum, favourite)
  /// Auto-detected from device locale, user can override in settings
  static const spellingPreference = 'spelling_preference';
  static const spellingPreferenceDefault = 'us';

  // ===========================================================================
  // Notifications
  // ===========================================================================

  /// Whether push notifications are enabled
  static const notificationsEnabled = 'notifications_enabled';
  static const notificationsEnabledDefault = false;

  /// Whether we've asked for notification permission
  static const notificationsAsked = 'notifications_asked';
}
