import 'package:local_auth/local_auth.dart';
import 'package:prosepal/core/interfaces/biometric_interface.dart';
import 'package:prosepal/core/services/biometric_service.dart';

/// Mock implementation of IBiometricService for testing
class MockBiometricService implements IBiometricService {
  // Configurable state for tests
  bool _isSupported = true;
  bool _isEnabled = false;
  bool _hasFaceId = true;
  bool _hasTouchId = false;
  List<BiometricType> _availableBiometrics = [BiometricType.face];
  BiometricResult _authenticateResult = const BiometricResult(success: true);

  // Configuration methods for tests
  void setSupported(bool value) => _isSupported = value;
  void setMockEnabled(bool value) => _isEnabled = value;
  void setHasFaceId(bool value) => _hasFaceId = value;
  void setHasTouchId(bool value) => _hasTouchId = value;
  void setAvailableBiometrics(List<BiometricType> value) =>
      _availableBiometrics = value;
  void setAuthenticateResult(BiometricResult result) =>
      _authenticateResult = result;

  // Tracking for test verification
  int authenticateCallCount = 0;
  int setEnabledCallCount = 0;
  String? lastAuthenticateReason;

  void reset() {
    _isSupported = true;
    _isEnabled = false;
    _hasFaceId = true;
    _hasTouchId = false;
    _availableBiometrics = [BiometricType.face];
    _authenticateResult = const BiometricResult(success: true);
    authenticateCallCount = 0;
    setEnabledCallCount = 0;
    lastAuthenticateReason = null;
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
  Future<BiometricResult> authenticate({String? reason}) async {
    authenticateCallCount++;
    lastAuthenticateReason = reason;
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
    return await authenticate();
  }
}
