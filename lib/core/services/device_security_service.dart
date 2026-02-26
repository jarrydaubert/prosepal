import 'package:flutter/foundation.dart';
import 'package:flutter_jailbreak_detection/flutter_jailbreak_detection.dart';

import 'log_service.dart';

/// Security check results
enum DeviceSecurityStatus {
  /// Device passed all security checks
  secure,

  /// Device is rooted/jailbroken
  compromised,

  /// Unable to determine (fail-open)
  unknown,
}

/// Service for detecting compromised devices (root/jailbreak)
///
/// Helps prevent:
/// - API abuse from modified apps
/// - Subscription bypass
/// - Data extraction
///
/// Behavior:
/// - Debug mode: Always returns [DeviceSecurityStatus.secure] (for development)
/// - Release mode: Performs actual checks
/// - On error: Returns [DeviceSecurityStatus.unknown] (fail-open)
class DeviceSecurityService {
  bool _checked = false;
  DeviceSecurityStatus _status = DeviceSecurityStatus.unknown;

  /// Check if device is compromised (rooted/jailbroken)
  ///
  /// Results are cached after first check.
  /// Returns [DeviceSecurityStatus.secure] in debug mode.
  Future<DeviceSecurityStatus> checkDeviceSecurity() async {
    // Skip in debug mode for development
    if (kDebugMode) {
      return DeviceSecurityStatus.secure;
    }

    // Return cached result
    if (_checked) {
      return _status;
    }

    try {
      final isJailbroken = await FlutterJailbreakDetection.jailbroken;
      final developerMode = await FlutterJailbreakDetection.developerMode;

      _checked = true;

      if (isJailbroken) {
        Log.warning('Device security: Jailbreak/root detected');
        _status = DeviceSecurityStatus.compromised;
        return _status;
      }

      if (developerMode) {
        // Developer mode is less severe - just log it
        Log.info('Device security: Developer mode enabled');
      }

      _status = DeviceSecurityStatus.secure;
      Log.info('Device security check passed');
      return _status;
    } catch (e) {
      Log.warning('Device security check failed', {'error': '$e'});
      _checked = true;
      _status = DeviceSecurityStatus.unknown;
      return _status;
    }
  }

  /// Whether device is known to be compromised
  bool get isCompromised => _status == DeviceSecurityStatus.compromised;

  /// Reset cached status (for testing)
  @visibleForTesting
  void reset() {
    _checked = false;
    _status = DeviceSecurityStatus.unknown;
  }
}
