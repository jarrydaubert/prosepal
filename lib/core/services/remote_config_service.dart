import 'dart:io';

import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../config/ai_config.dart';
import 'log_service.dart';

/// Centralized Firebase Remote Config service
///
/// Manages all remotely configurable values:
/// - AI model name and fallbacks
/// - Force update version requirements
/// - Feature flags
///
/// ## Firebase Remote Config Setup (CONFIGURED - Jan 2026)
/// Parameters are configured in Firebase Console > Remote Config (Client):
///    - `ai_model`: "gemini-2.5-flash" (stable model)
///    - `ai_model_fallback`: "gemini-2.5-flash-lite" (fallback if primary fails)
///    - `min_app_version_ios`: "1.0.0" (force update threshold)
///    - `min_app_version_android`: "1.0.0" (force update threshold)
///
/// To update AI model (e.g., when Gemini 3 SDK support is released):
/// 1. Go to Firebase Console > Prosepal > Run > Remote Config
/// 2. Edit `ai_model` value
/// 3. Publish changes - app will use new model on next launch
class RemoteConfigService {
  // Singleton for app-wide access
  static final RemoteConfigService _instance = RemoteConfigService._();
  static RemoteConfigService get instance => _instance;
  RemoteConfigService._();

  // Keys
  static const _aiModelKey = 'ai_model';
  static const _aiModelFallbackKey = 'ai_model_fallback';
  static const _minVersionIosKey = 'min_app_version_ios';
  static const _minVersionAndroidKey = 'min_app_version_android';
  static const _forceUpdateEnabledKey = 'force_update_enabled';

  FirebaseRemoteConfig? _remoteConfig;
  bool _initialized = false;

  /// Initialize Remote Config with defaults
  ///
  /// Call this once during app startup (after Firebase.initializeApp).
  /// Safe to call multiple times - subsequent calls are no-ops.
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      _remoteConfig = FirebaseRemoteConfig.instance;

      // Set defaults (used if fetch fails or values not set)
      await _remoteConfig!.setDefaults({
        _aiModelKey: AiConfig.defaultModel,
        _aiModelFallbackKey: AiConfig.defaultFallbackModel,
        _minVersionIosKey: '1.0.0',
        _minVersionAndroidKey: '1.0.0',
        _forceUpdateEnabledKey: true,
      });

      // Configure fetch settings
      await _remoteConfig!.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 10),
          minimumFetchInterval: const Duration(hours: 1),
        ),
      );

      // Fetch and activate
      await _remoteConfig!.fetchAndActivate();
      _initialized = true;

      Log.info('Remote Config initialized', {
        'aiModel': aiModel,
        'aiModelFallback': aiModelFallback,
        'forceUpdateEnabled': isForceUpdateEnabled,
      });
    } catch (e) {
      Log.warning('Remote Config init failed - using defaults', {
        'error': '$e',
      });
      // Don't throw - app should work with defaults
      _initialized = true; // Mark as initialized to use defaults
    }
  }

  // ===== AI Model Config =====

  /// Current AI model to use
  ///
  /// Returns remote value if available, otherwise default.
  String get aiModel {
    if (_remoteConfig == null) return AiConfig.defaultModel;
    final value = _remoteConfig!.getString(_aiModelKey);
    return value.isNotEmpty ? value : AiConfig.defaultModel;
  }

  /// Fallback AI model if primary fails
  String get aiModelFallback {
    if (_remoteConfig == null) return AiConfig.defaultFallbackModel;
    final value = _remoteConfig!.getString(_aiModelFallbackKey);
    return value.isNotEmpty ? value : AiConfig.defaultFallbackModel;
  }

  // ===== Force Update Config =====

  /// Whether force update checking is enabled
  bool get isForceUpdateEnabled {
    return _remoteConfig?.getBool(_forceUpdateEnabledKey) ?? true;
  }

  /// Minimum app version required for current platform
  String get minAppVersion {
    if (_remoteConfig == null) return '1.0.0';
    final key = Platform.isIOS ? _minVersionIosKey : _minVersionAndroidKey;
    return _remoteConfig!.getString(key);
  }

  /// Check if app version meets minimum requirement
  ///
  /// Returns true if update is required, false otherwise.
  Future<bool> isUpdateRequired() async {
    if (!isForceUpdateEnabled) return false;

    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;
      final minVersion = minAppVersion;

      final comparison = _compareVersions(currentVersion, minVersion);
      return comparison < 0; // Current version is below minimum
    } catch (e) {
      Log.warning('Version check failed', {'error': '$e'});
      return false; // Fail open
    }
  }

  /// Compare semantic versions
  /// Returns negative if v1 < v2, zero if equal, positive if v1 > v2
  int _compareVersions(String v1, String v2) {
    final parts1 = v1.split('.').map((p) => int.tryParse(p) ?? 0).toList();
    final parts2 = v2.split('.').map((p) => int.tryParse(p) ?? 0).toList();

    while (parts1.length < 3) parts1.add(0);
    while (parts2.length < 3) parts2.add(0);

    for (var i = 0; i < 3; i++) {
      if (parts1[i] < parts2[i]) return -1;
      if (parts1[i] > parts2[i]) return 1;
    }
    return 0;
  }

  /// Get the store URL for current platform
  String get storeUrl {
    if (Platform.isIOS) {
      // TODO: Update after App Store approval
      return 'https://apps.apple.com/app/prosepal/id0000000000';
    } else {
      return 'https://play.google.com/store/apps/details?id=com.prosepal.prosepal';
    }
  }

  /// Force refresh config from server
  ///
  /// Use sparingly - respects minimumFetchInterval.
  Future<void> refresh() async {
    try {
      await _remoteConfig?.fetchAndActivate();
      Log.info('Remote Config refreshed');
    } catch (e) {
      Log.warning('Remote Config refresh failed', {'error': '$e'});
    }
  }
}
