import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

import '../interfaces/biometric_interface.dart';
import 'log_service.dart';

/// Result of biometric authentication attempt
class BiometricResult {
  const BiometricResult({required this.success, this.error, this.message});
  final bool success;
  final BiometricError? error;
  final String? message;
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

/// Biometric authentication service implementation
///
/// Handles Face ID/Touch ID authentication and preference storage.
/// Use via provider for testability, or singleton for legacy code.
class BiometricService implements IBiometricService {
  /// Factory constructor for DI
  factory BiometricService() => instance;
  BiometricService._();
  static final instance = BiometricService._();

  final LocalAuthentication _auth = LocalAuthentication();

  /// Secure storage for biometric preference (prevents tampering on rooted devices)
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  static const _biometricsEnabledKey = 'biometrics_enabled';
  static const _authenticationDebounce = Duration(seconds: 2);
  static Future<BiometricResult>? _activeAuthentication;
  static DateTime? _lastAuthenticationStartedAt;
  static DateTime? _lastAuthenticationCompletedAt;

  @override
  Future<bool> get isSupported async {
    try {
      return await _auth.canCheckBiometrics || await _auth.isDeviceSupported();
    } on PlatformException {
      return false;
    }
  }

  @override
  Future<List<BiometricType>> get availableBiometrics async {
    try {
      return await _auth.getAvailableBiometrics();
    } on PlatformException {
      return [];
    }
  }

  @override
  Future<bool> get hasEnrolledBiometrics async {
    final biometrics = await availableBiometrics;
    return biometrics.isNotEmpty;
  }

  /// Check if device has strong (Class 3) biometrics available.
  /// Strong biometrics are cryptographically secure (e.g., Face ID, secure fingerprint).
  /// Weak biometrics (e.g., basic face unlock on some Android) are less secure.
  Future<bool> get hasStrongBiometrics async {
    final biometrics = await availableBiometrics;
    return biometrics.contains(BiometricType.strong);
  }

  /// Check if only weak biometrics are available (no strong option).
  /// Consider warning users if only weak biometrics protect sensitive data.
  Future<bool> get hasOnlyWeakBiometrics async {
    final biometrics = await availableBiometrics;
    return biometrics.contains(BiometricType.weak) &&
        !biometrics.contains(BiometricType.strong);
  }

  @override
  Future<bool> get hasFaceId async {
    final biometrics = await availableBiometrics;
    return biometrics.contains(BiometricType.face);
  }

  @override
  Future<bool> get hasTouchId async {
    final biometrics = await availableBiometrics;
    return biometrics.contains(BiometricType.fingerprint);
  }

  @override
  Future<String> get biometricTypeName async {
    if (await hasFaceId) return 'Face ID';
    if (await hasTouchId) return 'Touch ID';
    return 'Biometrics';
  }

  @override
  Future<bool> get isEnabled async {
    final value = await _secureStorage.read(key: _biometricsEnabledKey);
    return value == 'true';
  }

  @override
  Future<void> setEnabled(bool enabled) async {
    Log.info(enabled ? 'Biometrics enabled' : 'Biometrics disabled');
    await _secureStorage.write(
      key: _biometricsEnabledKey,
      value: enabled.toString(),
    );
  }

  @override
  Future<BiometricResult> authenticate({
    String? reason,
    bool biometricOnly = false,
  }) async {
    if (_activeAuthentication case final inFlight?) {
      Log.info('Skip biometric auth - request already in flight');
      return inFlight;
    }

    final startedAt = _lastAuthenticationStartedAt;
    if (startedAt != null) {
      final elapsed = DateTime.now().toUtc().difference(startedAt);
      if (elapsed < _authenticationDebounce) {
        Log.info('Skip biometric auth - start debounced', {
          'elapsedMs': elapsed.inMilliseconds,
        });
        return const BiometricResult(
          success: false,
          error: BiometricError.cancelled,
        );
      }
    }

    final completedAt = _lastAuthenticationCompletedAt;
    if (completedAt != null) {
      final elapsed = DateTime.now().toUtc().difference(completedAt);
      if (elapsed < _authenticationDebounce) {
        Log.info('Skip biometric auth - debounced', {
          'elapsedMs': elapsed.inMilliseconds,
        });
        return const BiometricResult(
          success: false,
          error: BiometricError.cancelled,
        );
      }
    }

    final completer = Completer<BiometricResult>();
    _activeAuthentication = completer.future;
    _lastAuthenticationStartedAt = DateTime.now().toUtc();

    Log.info('Biometric auth started', {'biometricOnly': biometricOnly});
    try {
      final success = await _auth.authenticate(
        localizedReason: reason ?? 'Authenticate to access Prosepal',
        biometricOnly: biometricOnly,
        persistAcrossBackgrounding: true, // Resume prompt if app backgrounds
      );
      if (success) {
        Log.info('Biometric auth success');
      } else {
        Log.warning('Biometric auth failed');
      }
      final result = BiometricResult(success: success);
      completer.complete(result);
      return result;
    } on LocalAuthException catch (e) {
      Log.warning('Biometric auth error', {
        'code': e.code.name,
        'message': e.description ?? 'unknown',
      });
      // Handle specific errors with user-friendly messages
      switch (e.code) {
        case LocalAuthExceptionCode.noBiometricHardware:
        case LocalAuthExceptionCode.biometricHardwareTemporarilyUnavailable:
          const result = BiometricResult(
            success: false,
            error: BiometricError.notAvailable,
            message: 'Biometrics not available on this device.',
          );
          completer.complete(result);
          return result;
        case LocalAuthExceptionCode.noBiometricsEnrolled:
          const result = BiometricResult(
            success: false,
            error: BiometricError.notEnrolled,
            message: 'No biometrics enrolled. Set up in device settings.',
          );
          completer.complete(result);
          return result;
        case LocalAuthExceptionCode.temporaryLockout:
          const result = BiometricResult(
            success: false,
            error: BiometricError.lockedOut,
            message: 'Too many attempts. Try again later.',
          );
          completer.complete(result);
          return result;
        case LocalAuthExceptionCode.biometricLockout:
          const result = BiometricResult(
            success: false,
            error: BiometricError.permanentlyLockedOut,
            message: 'Biometrics locked. Use device passcode to unlock.',
          );
          completer.complete(result);
          return result;
        case LocalAuthExceptionCode.noCredentialsSet:
          const result = BiometricResult(
            success: false,
            error: BiometricError.passcodeNotSet,
            message: 'Set up a device passcode first.',
          );
          completer.complete(result);
          return result;
        case LocalAuthExceptionCode.userCanceled:
          const result = BiometricResult(
            success: false,
            error: BiometricError.cancelled,
          );
          completer.complete(result);
          return result;
        default:
          final result = BiometricResult(
            success: false,
            error: BiometricError.unknown,
            message:
                e.description ?? 'Authentication failed. Please try again.',
          );
          completer.complete(result);
          return result;
      }
    } on PlatformException catch (e) {
      Log.warning('Biometric platform error', {
        'code': e.code,
        'message': e.message ?? 'unknown',
      });
      const result = BiometricResult(
        success: false,
        error: BiometricError.unknown,
        message: 'Authentication failed. Please try again.',
      );
      completer.complete(result);
      return result;
    } on Object catch (e, stackTrace) {
      Log.error('Unexpected biometric auth error', e, stackTrace);
      const result = BiometricResult(
        success: false,
        error: BiometricError.unknown,
        message: 'Authentication failed. Please try again.',
      );
      completer.complete(result);
      return result;
    } finally {
      _lastAuthenticationCompletedAt = DateTime.now().toUtc();
      _activeAuthentication = null;
    }
  }

  @override
  Future<BiometricResult> authenticateIfEnabled() async {
    if (!await isEnabled) {
      return const BiometricResult(success: true); // Not enabled, allow access
    }
    if (!await isSupported) {
      return const BiometricResult(
        success: true,
      ); // Not supported, allow access
    }
    return authenticate();
  }

  @visibleForTesting
  void resetAuthStateForTests() {
    _activeAuthentication = null;
    _lastAuthenticationStartedAt = null;
    _lastAuthenticationCompletedAt = null;
  }
}
