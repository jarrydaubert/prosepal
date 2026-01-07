import 'package:prosepal/core/services/rate_limit_service.dart';
import 'package:prosepal/core/services/device_fingerprint_service.dart';

import 'mock_device_fingerprint_service.dart';

/// Mock implementation of RateLimitService for testing.
///
/// By default, allows all requests. Configure behavior via constructor
/// parameters or by modifying properties after construction.
class MockRateLimitService extends RateLimitService {
  MockRateLimitService({
    DeviceFingerprintService? deviceFingerprint,
    this.allowRequests = true,
    this.mockRetryAfter = 0,
    this.mockReason,
  }) : super(deviceFingerprint ?? MockDeviceFingerprintService());

  /// Whether to allow requests
  bool allowRequests;

  /// Retry after seconds to return when blocked
  int mockRetryAfter;

  /// Reason to return when blocked
  RateLimitReason? mockReason;

  /// Track the number of times checkRateLimit was called
  int checkRateLimitCallCount = 0;

  /// Last endpoint that was checked
  String? lastEndpoint;

  @override
  Future<RateLimitResult> checkRateLimit({
    String endpoint = 'generation',
  }) async {
    checkRateLimitCallCount++;
    lastEndpoint = endpoint;

    return RateLimitResult(
      allowed: allowRequests,
      retryAfter: allowRequests ? 0 : mockRetryAfter,
      reason: allowRequests ? null : mockReason,
    );
  }

  /// Reset mock state for reuse between tests
  void reset() {
    allowRequests = true;
    mockRetryAfter = 0;
    mockReason = null;
    checkRateLimitCallCount = 0;
    lastEndpoint = null;
  }

  /// Simulate rate limit exceeded
  void simulateRateLimited({
    int retryAfter = 30,
    RateLimitReason reason = RateLimitReason.userLimit,
  }) {
    allowRequests = false;
    mockRetryAfter = retryAfter;
    mockReason = reason;
  }
}
