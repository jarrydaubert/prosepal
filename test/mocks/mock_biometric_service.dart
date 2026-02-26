import 'package:local_auth/local_auth.dart';
import 'package:prosepal/core/interfaces/biometric_interface.dart';
import 'package:prosepal/core/services/biometric_service.dart';

/// Mock implementation of IBiometricService for testing
///
/// Supports:
/// - Configurable device support, enabled state, biometric types
/// - Error simulation via [errorToThrow]
/// - Call tracking for verification
///
/// ## BiometricType support (local_auth 2.x)
/// - face: Face ID (iOS) or face unlock (Android)
/// - fingerprint: Touch ID (iOS) or fingerprint (Android)
/// - strong: Android strong biometric (face/fingerprint)
/// - weak: Android weak biometric
/// - iris: Iris scanner (rare)
class MockBiometricService implements IBiometricService {
  // Configurable state for tests
  bool _isSupported = true;
  bool _isEnabled = false;
  bool _hasFaceId = true;
  bool _hasTouchId = false;
  List<BiometricType> _availableBiometrics = [BiometricType.face];
  BiometricResult _authenticateResult = const BiometricResult(success: true);

  /// Error to throw on authenticate (simulates PlatformException, lockout, etc.)
  Exception? errorToThrow;

  // Configuration methods for tests
  void setSupported(bool value) => _isSupported = value;
  void setMockEnabled(bool value) => _isEnabled = value;
  void setHasFaceId(bool value) => _hasFaceId = value;
  void setHasTouchId(bool value) => _hasTouchId = value;
  void setAvailableBiometrics(List<BiometricType> value) =>
      _availableBiometrics = value;
  void setAuthenticateResult(BiometricResult result) =>
      _authenticateResult = result;

  /// Simulate user cancellation
  void simulateCancellation() {
    _authenticateResult = const BiometricResult(
      success: false,
      message: 'User cancelled',
    );
  }

  /// Simulate lockout (too many failed attempts)
  void simulateLockout() {
    _authenticateResult = const BiometricResult(
      success: false,
      error: BiometricError.lockedOut,
      message: 'Too many attempts. Try again later.',
    );
  }

  /// Simulate no biometrics enrolled
  void simulateNotEnrolled() {
    _availableBiometrics = [];
    _hasFaceId = false;
    _hasTouchId = false;
  }

  // Tracking for test verification
  int authenticateCallCount = 0;
  int setEnabledCallCount = 0;
  String? lastAuthenticateReason;
  bool? lastBiometricOnly;

  void reset() {
    _isSupported = true;
    _isEnabled = false;
    _hasFaceId = true;
    _hasTouchId = false;
    _availableBiometrics = [BiometricType.face];
    _authenticateResult = const BiometricResult(success: true);
    errorToThrow = null;
    authenticateCallCount = 0;
    setEnabledCallCount = 0;
    lastAuthenticateReason = null;
    lastBiometricOnly = null;
  }

  @override
  Future<bool> get isSupported async => _isSupported;

  @override
  Future<List<BiometricType>> get availableBiometrics async =>
      _availableBiometrics;

  @override
  Future<bool> get hasFaceId async => _hasFaceId;

  @override
  Future<bool> get hasTouchId async => _hasTouchId;

  @override
  Future<String> get biometricTypeName async {
    if (_hasFaceId) return 'Face ID';
    if (_hasTouchId) return 'Touch ID';
    // Handle Android biometric types
    if (_availableBiometrics.contains(BiometricType.fingerprint)) {
      return 'Fingerprint';
    }
    if (_availableBiometrics.contains(BiometricType.strong)) {
      return 'Biometrics';
    }
    return 'Biometrics';
  }

  @override
  Future<bool> get isEnabled async => _isEnabled;

  @override
  Future<void> setEnabled(bool enabled) async {
    setEnabledCallCount++;
    _isEnabled = enabled;
  }

  @override
  Future<BiometricResult> authenticate({
    String? reason,
    bool biometricOnly = false,
  }) async {
    authenticateCallCount++;
    lastAuthenticateReason = reason;
    lastBiometricOnly = biometricOnly;
    if (errorToThrow != null) {
      throw errorToThrow!;
    }
    return _authenticateResult;
  }

  @override
  Future<BiometricResult> authenticateIfEnabled() async {
    if (!_isEnabled) {
      return const BiometricResult(success: true);
    }
    if (!_isSupported) {
      return const BiometricResult(success: true);
    }
    return authenticate();
  }
}
