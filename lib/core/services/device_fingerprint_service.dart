import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'log_service.dart';

/// Service for device fingerprinting and server-side free tier tracking.
///
/// Uses platform-specific identifiers that persist across app reinstalls:
/// - iOS: `identifierForVendor` - UUID consistent for apps from same vendor
/// - Android: `androidId` - 64-bit hex string consistent per signing key/user/device
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
  DeviceFingerprintService();

  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  String? _cachedFingerprint;
  String? _cachedPlatform;

  /// Get Supabase client (may be null if not initialized)
  SupabaseClient? get _supabase {
    try {
      return Supabase.instance.client;
    } on Exception catch (_) {
      return null;
    }
  }

  /// Get current user ID (null if not authenticated)
  String? get _userId => _supabase?.auth.currentUser?.id;

  /// Get the device fingerprint.
  ///
  /// Returns a unique identifier that persists across app reinstalls:
  /// - iOS: identifierForVendor (resets only when all vendor apps uninstalled)
  /// - Android: androidId (consistent per signing key and user)
  ///
  /// Returns null if unable to get fingerprint (should fallback to local check).
  Future<String?> getDeviceFingerprint() async {
    // Return cached value if available
    if (_cachedFingerprint != null) {
      return _cachedFingerprint;
    }

    try {
      if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        _cachedFingerprint = iosInfo.identifierForVendor;
        _cachedPlatform = 'ios';
      } else if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        _cachedFingerprint = androidInfo.id;
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
    if (Platform.isIOS) return 'ios';
    if (Platform.isAndroid) return 'android';
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

      Log.info('Device free tier check', {
        'allowed': allowed,
        'isNewDevice': isNewDevice,
      });

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

      Log.info('Device marked as used free tier', {'success': allowed});

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

  /// Could not get device fingerprint, defaulting to allow
  fingerprintUnavailable,

  /// Supabase not initialized, defaulting to allow
  serverUnavailable,

  /// Server error during check, defaulting to allow
  serverError,
}
