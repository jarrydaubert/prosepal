import 'dart:io';

import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../config/ai_config.dart';
import '../interfaces/remote_config_interface.dart';
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
///    - `ai_model`: "gemini-3-flash-preview" (current model)
///    - `ai_model_fallback`: "gemini-2.5-flash" (fallback if primary fails)
/// When gemini-3-flash goes stable, update `ai_model` via Remote Config.
///    - `min_app_version_ios`: "1.0.0" (force update threshold)
///    - `min_app_version_android`: "1.0.0" (force update threshold)
///
/// To update AI model (e.g., when Gemini 3 SDK support is released):
/// 1. Go to Firebase Console > Prosepal > Run > Remote Config
/// 2. Edit `ai_model` value
/// 3. Publish changes - app will use new model on next launch
class RemoteConfigService implements IRemoteConfigService {
  RemoteConfigService._();
  // Singleton for app-wide access
  static final RemoteConfigService _instance = RemoteConfigService._();
  static RemoteConfigService get instance => _instance;

  // Keys
  static const _aiModelKey = 'ai_model';
  static const _aiModelFallbackKey = 'ai_model_fallback';
  static const _minVersionIosKey = 'min_app_version_ios';
  static const _minVersionAndroidKey = 'min_app_version_android';
  static const _forceUpdateEnabledKey = 'force_update_enabled';

  FirebaseRemoteConfig? _remoteConfig;
  bool _initialized = false;

  @override
  bool get isInitialized => _initialized;

  @override
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

      // Configure fetch settings (short timeout to not block launch)
      await _remoteConfig!.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 3),
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
    } on Exception catch (e) {
      Log.warning('Remote Config init failed - using defaults', {
        'error': '$e',
      });
      // Don't throw - app should work with defaults
      _initialized = true; // Mark as initialized to use defaults
    }
  }

  // ===== AI Model Config =====

  @override
  String get aiModel {
    if (_remoteConfig == null) return AiConfig.defaultModel;
    final value = _remoteConfig!.getString(_aiModelKey);
    return value.isNotEmpty ? value : AiConfig.defaultModel;
  }

  @override
  String get aiModelFallback {
    if (_remoteConfig == null) return AiConfig.defaultFallbackModel;
    final value = _remoteConfig!.getString(_aiModelFallbackKey);
    return value.isNotEmpty ? value : AiConfig.defaultFallbackModel;
  }

  // ===== Force Update Config =====

  @override
  bool get isForceUpdateEnabled =>
      _remoteConfig?.getBool(_forceUpdateEnabledKey) ?? true;

  @override
  String get minAppVersion {
    if (_remoteConfig == null) return '1.0.0';
    final key = Platform.isIOS ? _minVersionIosKey : _minVersionAndroidKey;
    return _remoteConfig!.getString(key);
  }

  @override
  Future<bool> isUpdateRequired() async {
    if (!isForceUpdateEnabled) return false;

    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;
      final minVersion = minAppVersion;

      final comparison = compareVersions(currentVersion, minVersion);
      return comparison < 0; // Current version is below minimum
    } on Exception catch (e) {
      Log.warning('Version check failed', {'error': '$e'});
      return false; // Fail open
    }
  }

  @override
  int compareVersions(String v1, String v2) {
    final parts1 = v1.split('.').map((p) => int.tryParse(p) ?? 0).toList();
    final parts2 = v2.split('.').map((p) => int.tryParse(p) ?? 0).toList();

    while (parts1.length < 3) {
      parts1.add(0);
    }
    while (parts2.length < 3) {
      parts2.add(0);
    }

    for (var i = 0; i < 3; i++) {
      if (parts1[i] < parts2[i]) return -1;
      if (parts1[i] > parts2[i]) return 1;
    }
    return 0;
  }

  @override
  String get storeUrl {
    if (Platform.isIOS) {
      return 'https://apps.apple.com/app/id6757088726';
    } else {
      return 'https://play.google.com/store/apps/details?id=com.prosepal.prosepal';
    }
  }

  @override
  Future<void> refresh() async {
    try {
      await _remoteConfig?.fetchAndActivate();
      Log.info('Remote Config refreshed');
    } on Exception catch (e) {
      Log.warning('Remote Config refresh failed', {'error': '$e'});
    }
  }
}
