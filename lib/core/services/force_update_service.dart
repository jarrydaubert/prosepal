import 'dart:io';

import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'log_service.dart';

/// Result of force update check
enum UpdateStatus {
  /// App is up to date
  upToDate,

  /// Optional update available
  updateAvailable,

  /// Mandatory update required - app should be blocked
  forceUpdateRequired,

  /// Unable to check - allow app to continue
  checkFailed,
}

/// Service to check if app needs to be updated
///
/// Uses Firebase Remote Config to fetch:
/// - `min_app_version`: Minimum version allowed (force update if below)
/// - `latest_app_version`: Latest version available (optional update)
/// - `force_update_enabled`: Kill switch to disable force update
///
/// ## Firebase Remote Config Setup
/// 1. Go to Firebase Console > Remote Config
/// 2. Add parameters:
///    - `min_app_version_ios`: "1.0.0" (string)
///    - `min_app_version_android`: "1.0.0" (string)
///    - `force_update_enabled`: true (boolean)
/// 3. Publish changes
class ForceUpdateService {
  static const _minVersionIosKey = 'min_app_version_ios';
  static const _minVersionAndroidKey = 'min_app_version_android';
  static const _forceUpdateEnabledKey = 'force_update_enabled';

  FirebaseRemoteConfig? _remoteConfig;
  bool _initialized = false;

  /// Initialize Remote Config with defaults
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      _remoteConfig = FirebaseRemoteConfig.instance;

      // Set defaults (used if fetch fails)
      await _remoteConfig!.setDefaults({
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

      Log.info('Force update service initialized', {
        'minVersionIos': _remoteConfig!.getString(_minVersionIosKey),
        'minVersionAndroid': _remoteConfig!.getString(_minVersionAndroidKey),
        'enabled': _remoteConfig!.getBool(_forceUpdateEnabledKey),
      });
    } catch (e) {
      Log.warning('Force update service init failed', {'error': '$e'});
      // Don't throw - app should work without this
    }
  }

  /// Check if app needs to be updated
  ///
  /// Returns [UpdateStatus] indicating what action to take.
  /// Always returns [UpdateStatus.checkFailed] on error (fail-open).
  Future<UpdateStatus> checkForUpdate() async {
    try {
      if (_remoteConfig == null) {
        await initialize();
      }

      if (_remoteConfig == null) {
        return UpdateStatus.checkFailed;
      }

      // Check if force update is enabled
      final enabled = _remoteConfig!.getBool(_forceUpdateEnabledKey);
      if (!enabled) {
        Log.info('Force update disabled via Remote Config');
        return UpdateStatus.upToDate;
      }

      // Get minimum version for platform
      final minVersionKey =
          Platform.isIOS ? _minVersionIosKey : _minVersionAndroidKey;
      final minVersionStr = _remoteConfig!.getString(minVersionKey);

      // Get current app version
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      Log.info('Version check', {
        'current': currentVersion,
        'minimum': minVersionStr,
      });

      // Compare versions
      final comparison = _compareVersions(currentVersion, minVersionStr);

      if (comparison < 0) {
        // Current version is below minimum
        Log.warning('Force update required', {
          'current': currentVersion,
          'minimum': minVersionStr,
        });
        return UpdateStatus.forceUpdateRequired;
      }

      return UpdateStatus.upToDate;
    } catch (e) {
      Log.warning('Force update check failed', {'error': '$e'});
      return UpdateStatus.checkFailed;
    }
  }

  /// Compare semantic versions
  ///
  /// Returns:
  /// - negative if v1 < v2
  /// - zero if v1 == v2
  /// - positive if v1 > v2
  int _compareVersions(String v1, String v2) {
    final parts1 = v1.split('.').map((p) => int.tryParse(p) ?? 0).toList();
    final parts2 = v2.split('.').map((p) => int.tryParse(p) ?? 0).toList();

    // Pad to same length
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

  /// Get the store URL for the current platform
  String get storeUrl {
    if (Platform.isIOS) {
      // TODO: Update after App Store approval
      return 'https://apps.apple.com/app/prosepal/id0000000000';
    } else {
      return 'https://play.google.com/store/apps/details?id=com.prosepal.prosepal';
    }
  }
}
