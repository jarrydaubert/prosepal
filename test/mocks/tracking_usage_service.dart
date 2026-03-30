import 'package:prosepal/core/services/usage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'mock_device_fingerprint_service.dart';
import 'mock_rate_limit_service.dart';

/// Test usage service with deterministic call tracking for widget flows.
class TrackingUsageService extends UsageService {
  TrackingUsageService(SharedPreferences prefs)
    : super(prefs, MockDeviceFingerprintService(), MockRateLimitService());

  int serverConsumeCalls = 0;
  int recordGenerationCalls = 0;
  UsageCheckResult serverResult = const UsageCheckResult(
    allowed: true,
    remaining: 0,
  );
  UsageCheckException? serverException;

  @override
  Future<UsageCheckResult> checkAndIncrementServerSide({
    required bool isPro,
  }) async {
    serverConsumeCalls++;
    if (serverException != null) {
      throw serverException!;
    }
    return serverResult;
  }

  @override
  Future<void> recordGeneration({bool isPro = false}) async {
    recordGenerationCalls++;
  }
}
