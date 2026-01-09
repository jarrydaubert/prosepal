import 'package:local_auth/local_auth.dart';

import '../services/biometric_service.dart';

/// Abstract interface for biometric authentication.
///
/// Allows mocking in tests without local_auth dependency. All methods
/// handle platform exceptions internally and return safe defaults.
///
/// ## Preconditions
/// - On iOS: NSFaceIDUsageDescription must be set in Info.plist
/// - On Android: USE_BIOMETRIC permission must be declared
///
/// ## Error Handling
/// Authentication methods return [BiometricResult] with typed [BiometricError]
/// instead of throwing. Common errors include:
/// - [BiometricError.notAvailable] - Device doesn't support biometrics
/// - [BiometricError.notEnrolled] - No biometrics registered on device
/// - [BiometricError.lockedOut] - Too many failed attempts (temporary)
/// - [BiometricError.permanentlyLockedOut] - Too many failed attempts (permanent)
/// - [BiometricError.cancelled] - User dismissed the prompt
///
/// ## Platform Biometric Types
/// - iOS: [BiometricType.face] (Face ID), [BiometricType.fingerprint] (Touch ID)
/// - Android: [BiometricType.fingerprint], [BiometricType.face], [BiometricType.iris]
/// - Windows: [BiometricType.face], [BiometricType.fingerprint]
abstract class IBiometricService {
  /// Check if device supports biometrics (has hardware).
  ///
  /// Returns false on unsupported platforms or if hardware unavailable.
  /// Note: This returns true even if no biometrics are enrolled.
  /// Use [hasEnrolledBiometrics] to check enrollment status.
  Future<bool> get isSupported;

  /// Check if user has enrolled biometrics on the device.
  ///
  /// Returns true if at least one biometric is registered.
  /// Use this before prompting for biometric setup in your app.
  Future<bool> get hasEnrolledBiometrics;

  /// Get list of enrolled biometric types.
  ///
  /// Returns empty list if no biometrics enrolled or on error.
  /// Check [isSupported] first to distinguish "not supported" from "not enrolled".
  Future<List<BiometricType>> get availableBiometrics;

  /// Check if Face ID is available and enrolled (iOS/Android).
  Future<bool> get hasFaceId;

  /// Check if Touch ID / fingerprint is available and enrolled.
  Future<bool> get hasTouchId;

  /// Get user-friendly name for the primary available biometric.
  ///
  /// Returns "Face ID", "Touch ID", "Fingerprint", or "Biometrics" as fallback.
  Future<String> get biometricTypeName;

  /// Check if user has enabled biometric lock in app settings.
  ///
  /// This is the app-level preference, not device enrollment status.
  Future<bool> get isEnabled;

  /// Enable or disable biometric lock for the app.
  ///
  /// Stores preference securely. Does not affect device biometric enrollment.
  Future<void> setEnabled(bool enabled);

  /// Authenticate user with biometrics.
  ///
  /// [reason] - Message shown to user explaining why authentication is needed.
  ///            Should be localized. Defaults to generic message if null.
  /// [biometricOnly] - If true, only biometrics allowed (no PIN/pattern fallback).
  ///                   Use for high-security scenarios. Default false allows fallback.
  ///
  /// Returns [BiometricResult] with [success] = true if authenticated,
  /// or [error] indicating why authentication failed.
  Future<BiometricResult> authenticate({
    String? reason,
    bool biometricOnly = false,
  });

  /// Authenticate only if biometrics are enabled in app settings.
  ///
  /// Returns success immediately if biometrics not enabled (no prompt shown).
  /// Use for optional biometric gates like app unlock.
  Future<BiometricResult> authenticateIfEnabled();
}
