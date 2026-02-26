import 'package:local_auth/local_auth.dart';

import '../services/biometric_service.dart';

/// Abstract interface for biometric authentication
/// Allows mocking in tests without local_auth dependency
abstract class IBiometricService {
  /// Check if device supports biometrics
  Future<bool> get isSupported;

  /// Get available biometric types
  Future<List<BiometricType>> get availableBiometrics;

  /// Check if Face ID is available
  Future<bool> get hasFaceId;

  /// Check if Touch ID is available
  Future<bool> get hasTouchId;

  /// Get friendly name for available biometric type
  Future<String> get biometricTypeName;

  /// Check if user has enabled biometric lock
  Future<bool> get isEnabled;

  /// Enable or disable biometric lock
  Future<void> setEnabled(bool enabled);

  /// Authenticate with biometrics
  ///
  /// [reason] - The message shown to the user explaining why authentication is needed.
  /// [biometricOnly] - If true, only biometrics are allowed (no PIN/pattern fallback).
  ///                   Use for high-security scenarios like protecting sensitive data.
  Future<BiometricResult> authenticate({
    String? reason,
    bool biometricOnly = false,
  });

  /// Authenticate only if biometrics are enabled
  Future<BiometricResult> authenticateIfEnabled();
}
