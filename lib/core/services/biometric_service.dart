import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Result of biometric authentication attempt
class BiometricResult {
  final bool success;
  final BiometricError? error;
  final String? message;

  const BiometricResult({required this.success, this.error, this.message});
}

/// Types of biometric errors
enum BiometricError {
  notAvailable,
  notEnrolled,
  lockedOut,
  permanentlyLockedOut,
  passcodeNotSet,
  cancelled,
  unknown,
}

class BiometricService {
  BiometricService._();
  static final instance = BiometricService._();

  final LocalAuthentication _auth = LocalAuthentication();

  static const _biometricsEnabledKey = 'biometrics_enabled';

  /// Check if device supports biometrics
  Future<bool> get isSupported async {
    try {
      return await _auth.canCheckBiometrics || await _auth.isDeviceSupported();
    } on PlatformException {
      return false;
    }
  }

  /// Get available biometric types (Face ID, Touch ID, etc.)
  Future<List<BiometricType>> get availableBiometrics async {
    try {
      return await _auth.getAvailableBiometrics();
    } on PlatformException {
      return [];
    }
  }

  /// Check if Face ID is available
  Future<bool> get hasFaceId async {
    final biometrics = await availableBiometrics;
    return biometrics.contains(BiometricType.face);
  }

  /// Check if Touch ID is available
  Future<bool> get hasTouchId async {
    final biometrics = await availableBiometrics;
    return biometrics.contains(BiometricType.fingerprint);
  }

  /// Get a friendly name for the available biometric type
  Future<String> get biometricTypeName async {
    if (await hasFaceId) return 'Face ID';
    if (await hasTouchId) return 'Touch ID';
    return 'Biometrics';
  }

  /// Check if user has enabled biometric lock
  Future<bool> get isEnabled async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_biometricsEnabledKey) ?? false;
  }

  /// Enable or disable biometric lock
  Future<void> setEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_biometricsEnabledKey, enabled);
  }

  /// Authenticate with biometrics
  /// Returns [BiometricResult] with success status and optional error
  Future<BiometricResult> authenticate({String? reason}) async {
    try {
      final success = await _auth.authenticate(
        localizedReason: reason ?? 'Authenticate to access Prosepal',
        biometricOnly: false, // Allow PIN/passcode fallback for accessibility
        persistAcrossBackgrounding: true, // Resume prompt if app backgrounds
      );
      return BiometricResult(success: success);
    } on LocalAuthException catch (e) {
      // Handle specific errors with user-friendly messages
      switch (e.code) {
        case LocalAuthExceptionCode.noBiometricHardware:
        case LocalAuthExceptionCode.biometricHardwareTemporarilyUnavailable:
          return BiometricResult(
            success: false,
            error: BiometricError.notAvailable,
            message: 'Biometrics not available on this device.',
          );
        case LocalAuthExceptionCode.noBiometricsEnrolled:
          return BiometricResult(
            success: false,
            error: BiometricError.notEnrolled,
            message: 'No biometrics enrolled. Set up in device settings.',
          );
        case LocalAuthExceptionCode.temporaryLockout:
          return BiometricResult(
            success: false,
            error: BiometricError.lockedOut,
            message: 'Too many attempts. Try again later.',
          );
        case LocalAuthExceptionCode.biometricLockout:
          return BiometricResult(
            success: false,
            error: BiometricError.permanentlyLockedOut,
            message: 'Biometrics locked. Use device passcode to unlock.',
          );
        case LocalAuthExceptionCode.noCredentialsSet:
          return BiometricResult(
            success: false,
            error: BiometricError.passcodeNotSet,
            message: 'Set up a device passcode first.',
          );
        case LocalAuthExceptionCode.userCanceled:
          return BiometricResult(
            success: false,
            error: BiometricError.cancelled,
          );
        default:
          return BiometricResult(
            success: false,
            error: BiometricError.unknown,
            message:
                e.description ?? 'Authentication failed. Please try again.',
          );
      }
    } on PlatformException {
      return BiometricResult(
        success: false,
        error: BiometricError.unknown,
        message: 'Authentication failed. Please try again.',
      );
    }
  }

  /// Authenticate if biometrics are enabled
  /// Returns [BiometricResult] - success is true if auth passed OR biometrics not enabled
  Future<BiometricResult> authenticateIfEnabled() async {
    if (!await isEnabled) {
      return BiometricResult(success: true); // Not enabled, allow access
    }
    if (!await isSupported) {
      return BiometricResult(success: true); // Not supported, allow access
    }
    return await authenticate();
  }
}
