import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import 'log_service.dart';

/// Service for device fingerprinting and server-side free tier tracking.
///
/// Uses platform-specific identifiers for server-side free tier tracking:
/// - iOS: keychain-backed persisted ID, seeded from `identifierForVendor`
/// - Android: current device identifier implementation
///
/// ## Security Notes
/// - Device fingerprints can be spoofed on rooted/jailbroken devices
/// - This is a deterrent for casual abuse, not a bulletproof solution
/// - Combined with user account tracking and rate limiting for defense in depth
///
/// ## Usage
/// ```dart
/// final service = DeviceFingerprintService();
/// final canUseFreeTier = await service.canUseFreeTier();
/// if (canUseFreeTier) {
///   // Allow generation, then mark as used
///   await service.markFreeTierUsed();
/// }
/// ```
class DeviceFingerprintService {
  DeviceFingerprintService({
    DeviceInfoPlugin? deviceInfo,
    FlutterSecureStorage? secureStorage,
    Future<String?> Function(String key)? secureRead,
    Future<void> Function(String key, String value)? secureWrite,
    Future<String?> Function(DeviceInfoPlugin deviceInfo)? iosIdentifierReader,
    Future<String?> Function(DeviceInfoPlugin deviceInfo)?
    androidIdentifierReader,
    bool Function()? isIOS,
    bool Function()? isAndroid,
    String Function()? generateUuid,
  }) : _deviceInfo = deviceInfo ?? DeviceInfoPlugin(),
       _secureStorage = secureStorage ?? const FlutterSecureStorage(),
       _secureReadOverride = secureRead,
       _secureWriteOverride = secureWrite,
       _iosIdentifierReader = iosIdentifierReader,
       _androidIdentifierReader = androidIdentifierReader,
       _isIOS = isIOS,
       _isAndroid = isAndroid,
       _generateUuid = generateUuid;

  static const _iosPersistentFingerprintKey =
      'device_fingerprint_ios_persistent_id';

  final DeviceInfoPlugin _deviceInfo;
  final FlutterSecureStorage _secureStorage;
  final Future<String?> Function(String key)? _secureReadOverride;
  final Future<void> Function(String key, String value)? _secureWriteOverride;
  final Future<String?> Function(DeviceInfoPlugin deviceInfo)?
  _iosIdentifierReader;
  final Future<String?> Function(DeviceInfoPlugin deviceInfo)?
  _androidIdentifierReader;
  final bool Function()? _isIOS;
  final bool Function()? _isAndroid;
  final String Function()? _generateUuid;
  String? _cachedFingerprint;
  String? _cachedPlatform;

  /// Get Supabase client (may be null if not initialized)
  SupabaseClient? get _supabase {
    try {
      return Supabase.instance.client;
    } on Object catch (_) {
      return null;
    }
  }

  /// Get current user ID (null if not authenticated)
  String? get _userId => _supabase?.auth.currentUser?.id;

  /// Get the device fingerprint.
  ///
  /// Returns a unique identifier that persists across app reinstalls:
  /// - iOS: keychain-backed identifier seeded from identifierForVendor
  /// - Android: current device identifier implementation
  ///
  /// Returns null if unable to get fingerprint (should fallback to local check).
  Future<String?> getDeviceFingerprint() async {
    // Return cached value if available
    if (_cachedFingerprint != null) {
      return _cachedFingerprint;
    }

    try {
      if (_isIOSPlatform) {
        _cachedFingerprint = await _getOrCreateIosPersistentFingerprint();
        _cachedPlatform = 'ios';
      } else if (_isAndroidPlatform) {
        _cachedFingerprint = await _readAndroidIdentifier();
        _cachedPlatform = 'android';
      }

      if (_cachedFingerprint != null) {
        Log.info('Device fingerprint obtained', {
          'platform': _cachedPlatform,
          'fingerprintPrefix': _cachedFingerprint!.substring(
            0,
            _cachedFingerprint!.length.clamp(0, 8),
          ),
        });
      }

      return _cachedFingerprint;
    } on Exception catch (e) {
      Log.error('Failed to get device fingerprint', e);
      return null;
    }
  }

  /// Get the platform string for the current device.
  String getPlatform() {
    if (_cachedPlatform != null) return _cachedPlatform!;
    if (_isIOSPlatform) return 'ios';
    if (_isAndroidPlatform) return 'android';
    return 'unknown';
  }

  /// Check if this device can use the free tier.
  ///
  /// Queries the server to check if the device fingerprint has already
  /// been used for a free generation.
  ///
  /// Returns `true` if:
  /// - Device has not used free tier before
  /// - Unable to check server (graceful degradation)
  ///
  /// Returns `false` if:
  /// - Device has already used free tier
  Future<DeviceCheckResult> canUseFreeTier() async {
    final fingerprint = await getDeviceFingerprint();

    if (fingerprint == null) {
      Log.warning('No device fingerprint available, allowing free tier');
      return const DeviceCheckResult(
        allowed: true,
        reason: DeviceCheckReason.fingerprintUnavailable,
      );
    }

    final supabase = _supabase;
    if (supabase == null) {
      Log.warning('Supabase not initialized, allowing free tier');
      return const DeviceCheckResult(
        allowed: true,
        reason: DeviceCheckReason.serverUnavailable,
      );
    }

    try {
      final response = await supabase.rpc(
        'check_device_free_tier',
        params: {
          'p_device_fingerprint': fingerprint,
          'p_platform': getPlatform(),
          'p_user_id': _userId,
          'p_mark_used': false,
        },
      );

      final result = response as Map<String, dynamic>;
      final allowed = result['allowed'] as bool? ?? true;
      final isNewDevice = result['is_new_device'] as bool? ?? true;
      final reason = result['reason'] as String?;

      Log.info('Device free tier check', {
        'allowed': allowed,
        'isNewDevice': isNewDevice,
        'reason': reason,
      });

      if (!allowed &&
          (reason == 'device_limit' ||
              reason == 'user_limit' ||
              reason == 'rate_limited')) {
        return const DeviceCheckResult(
          allowed: false,
          reason: DeviceCheckReason.rateLimited,
        );
      }

      return DeviceCheckResult(
        allowed: allowed,
        reason: allowed
            ? (isNewDevice
                  ? DeviceCheckReason.newDevice
                  : DeviceCheckReason.notUsedYet)
            : DeviceCheckReason.alreadyUsed,
      );
    } on PostgrestException catch (e) {
      Log.error('Device free tier check failed', e);
      // Graceful degradation - allow on server error
      return const DeviceCheckResult(
        allowed: true,
        reason: DeviceCheckReason.serverError,
      );
    }
  }

  /// Mark this device as having used the free tier.
  ///
  /// Call this AFTER a successful free generation to prevent reuse.
  /// Uses atomic server-side operation to prevent race conditions.
  Future<bool> markFreeTierUsed() async {
    final fingerprint = await getDeviceFingerprint();

    if (fingerprint == null) {
      Log.warning('No device fingerprint available, cannot mark as used');
      return false;
    }

    final supabase = _supabase;
    if (supabase == null) {
      Log.warning('Supabase not initialized, cannot mark device as used');
      return false;
    }

    try {
      final response = await supabase.rpc(
        'check_device_free_tier',
        params: {
          'p_device_fingerprint': fingerprint,
          'p_platform': getPlatform(),
          'p_user_id': _userId,
          'p_mark_used': true,
        },
      );

      final result = response as Map<String, dynamic>;
      final allowed = result['allowed'] as bool? ?? false;

      Log.info('Device free tier mark evaluated', {'allowed': allowed});

      return allowed;
    } on PostgrestException catch (e) {
      Log.error('Failed to mark device as used', e);
      return false;
    }
  }

  /// Clear cached fingerprint (for testing)
  void clearCache() {
    _cachedFingerprint = null;
    _cachedPlatform = null;
  }

  bool get _isIOSPlatform => _isIOS?.call() ?? Platform.isIOS;

  bool get _isAndroidPlatform => _isAndroid?.call() ?? Platform.isAndroid;

  Future<String?> _readSecure(String key) async {
    final secureReadOverride = _secureReadOverride;
    if (secureReadOverride != null) {
      return secureReadOverride(key);
    }
    return _secureStorage.read(key: key);
  }

  Future<void> _writeSecure(String key, String value) async {
    if (_secureWriteOverride != null) {
      await _secureWriteOverride(key, value);
      return;
    }
    await _secureStorage.write(key: key, value: value);
  }

  Future<String?> _readIosIdentifier() async {
    final iosIdentifierReader = _iosIdentifierReader;
    if (iosIdentifierReader != null) {
      return iosIdentifierReader(_deviceInfo);
    }
    return (await _deviceInfo.iosInfo).identifierForVendor;
  }

  Future<String?> _readAndroidIdentifier() async {
    final androidIdentifierReader = _androidIdentifierReader;
    if (androidIdentifierReader != null) {
      return androidIdentifierReader(_deviceInfo);
    }
    return (await _deviceInfo.androidInfo).id;
  }

  Future<String?> _getOrCreateIosPersistentFingerprint() async {
    final persisted = await _readSecure(_iosPersistentFingerprintKey);
    if (persisted != null && persisted.isNotEmpty) {
      return persisted;
    }

    final identifierForVendor = await _readIosIdentifier();
    final fingerprint =
        (identifierForVendor != null && identifierForVendor.isNotEmpty)
        ? identifierForVendor
        : (_generateUuid?.call() ?? const Uuid().v4());

    await _writeSecure(_iosPersistentFingerprintKey, fingerprint);

    Log.info('Persisted iOS device fingerprint', {
      'seed': identifierForVendor != null && identifierForVendor.isNotEmpty
          ? 'identifier_for_vendor'
          : 'generated_uuid',
      'fingerprintPrefix': fingerprint.substring(
        0,
        fingerprint.length.clamp(0, 8),
      ),
    });

    return fingerprint;
  }
}

/// Result of a device free tier check
class DeviceCheckResult {
  const DeviceCheckResult({required this.allowed, required this.reason});

  /// Whether free tier usage is allowed
  final bool allowed;

  /// Reason for the decision
  final DeviceCheckReason reason;

  @override
  String toString() => 'DeviceCheckResult(allowed: $allowed, reason: $reason)';
}

/// Reasons for device check decisions
enum DeviceCheckReason {
  /// New device, never seen before
  newDevice,

  /// Known device but hasn't used free tier yet
  notUsedYet,

  /// Device has already used the free tier
  alreadyUsed,

  /// Too many checks in a short period
  rateLimited,

  /// Could not get device fingerprint, defaulting to allow
  fingerprintUnavailable,

  /// Supabase not initialized, defaulting to allow
  serverUnavailable,

  /// Server error during check, defaulting to allow
  serverError,
}
