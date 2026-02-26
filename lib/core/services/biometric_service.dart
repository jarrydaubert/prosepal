import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  /// Set [biometricOnly] to true to prevent PIN/passcode fallback
  Future<bool> authenticate({
    String? reason,
    bool biometricOnly = false,
  }) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason ?? 'Authenticate to access Prosepal',
        biometricOnly: biometricOnly,
        // Keep auth valid if app goes to background briefly
        persistAcrossBackgrounding: true,
      );
    } on PlatformException catch (e) {
      // Handle specific errors
      if (e.code == 'NotAvailable') {
        return false;
      }
      if (e.code == 'NotEnrolled') {
        return false;
      }
      if (e.code == 'LockedOut' || e.code == 'PermanentlyLockedOut') {
        return false;
      }
      return false;
    }
  }

  /// Authenticate if biometrics are enabled
  Future<bool> authenticateIfEnabled() async {
    if (!await isEnabled) return true; // Not enabled, allow access
    if (!await isSupported) return true; // Not supported, allow access
    return await authenticate();
  }
}
