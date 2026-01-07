import 'package:prosepal/core/services/device_fingerprint_service.dart';

/// Mock implementation of DeviceFingerprintService for testing.
///
/// By default, allows free tier usage. Configure behavior via constructor
/// parameters or by modifying properties after construction.
class MockDeviceFingerprintService extends DeviceFingerprintService {
  MockDeviceFingerprintService({
    this.mockFingerprint = 'mock-device-fingerprint-12345',
    this.mockPlatform = 'ios',
    this.allowFreeTier = true,
    this.deviceCheckReason = DeviceCheckReason.newDevice,
  });

  /// The fingerprint to return from getDeviceFingerprint()
  String? mockFingerprint;

  /// The platform to return from getPlatform()
  String mockPlatform;

  /// Whether to allow free tier usage
  bool allowFreeTier;

  /// The reason to return in DeviceCheckResult
  DeviceCheckReason deviceCheckReason;

  /// Track if markFreeTierUsed was called
  bool markFreeTierUsedCalled = false;

  /// Track the number of times canUseFreeTier was called
  int canUseFreeTierCallCount = 0;

  @override
  Future<String?> getDeviceFingerprint() async {
    return mockFingerprint;
  }

  @override
  String getPlatform() {
    return mockPlatform;
  }

  @override
  Future<DeviceCheckResult> canUseFreeTier() async {
    canUseFreeTierCallCount++;
    return DeviceCheckResult(allowed: allowFreeTier, reason: deviceCheckReason);
  }

  @override
  Future<bool> markFreeTierUsed() async {
    markFreeTierUsedCalled = true;
    allowFreeTier = false;
    deviceCheckReason = DeviceCheckReason.alreadyUsed;
    return true;
  }

  /// Reset mock state for reuse between tests
  void reset() {
    mockFingerprint = 'mock-device-fingerprint-12345';
    mockPlatform = 'ios';
    allowFreeTier = true;
    deviceCheckReason = DeviceCheckReason.newDevice;
    markFreeTierUsedCalled = false;
    canUseFreeTierCallCount = 0;
  }

  /// Simulate a device that has already used free tier
  void simulateFreeTierUsed() {
    allowFreeTier = false;
    deviceCheckReason = DeviceCheckReason.alreadyUsed;
  }

  /// Simulate a server error during device check
  void simulateServerError() {
    allowFreeTier = true;
    deviceCheckReason = DeviceCheckReason.serverError;
  }

  /// Simulate no fingerprint available
  void simulateNoFingerprint() {
    mockFingerprint = null;
    allowFreeTier = true;
    deviceCheckReason = DeviceCheckReason.fingerprintUnavailable;
  }
}
