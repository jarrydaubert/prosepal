import 'package:flutter_test/flutter_test.dart';
import 'package:prosepal/core/services/usage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../mocks/mock_device_fingerprint_service.dart';
import '../mocks/mock_rate_limit_service.dart';

/// UsageService Unit Tests
///
/// Tests REAL UsageService with mocked SharedPreferences, DeviceFingerprintService,
/// and RateLimitService.
/// Each test answers: "What bug does this catch?"
void main() {
  group('UsageService', () {
    late UsageService usageService;
    late MockDeviceFingerprintService mockDeviceFingerprint;
    late MockRateLimitService mockRateLimit;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      mockDeviceFingerprint = MockDeviceFingerprintService();
      mockRateLimit = MockRateLimitService();
      usageService = UsageService(prefs, mockDeviceFingerprint, mockRateLimit);
    });

    test('should start with 0 total count', () {
      expect(usageService.getTotalCount(), equals(0));
    });

    test('should start with 1 remaining free generation', () {
      expect(usageService.getRemainingFree(), equals(1));
    });

    test('should decrement remaining after recording generation', () async {
      await usageService.recordGeneration();
      expect(usageService.getRemainingFree(), equals(0));
    });

    test('should increment total count after recording generation', () async {
      await usageService.recordGeneration();
      expect(usageService.getTotalCount(), equals(1));
    });

    test(
      'should return false for canGenerateFree when free limit reached',
      () async {
        await usageService.recordGeneration();
        expect(usageService.canGenerateFree(), equals(false));
      },
    );

    test(
      'should return true for canGeneratePro when under monthly limit',
      () async {
        await usageService.recordGeneration();
        expect(usageService.canGeneratePro(), equals(true));
      },
    );

    test('should not go below 0 remaining', () async {
      for (var i = 0; i < 10; i++) {
        await usageService.recordGeneration();
      }
      expect(usageService.getRemainingFree(), equals(0));
    });

    test('should track monthly count separately', () async {
      await usageService.recordGeneration();
      expect(usageService.getMonthlyCount(), equals(1));
      expect(usageService.getTotalCount(), equals(1));
    });

    test('should reset monthly usage', () async {
      await usageService.recordGeneration();
      await usageService.recordGeneration();
      expect(usageService.getMonthlyCount(), equals(2));

      await usageService.resetMonthlyUsage();
      expect(usageService.getMonthlyCount(), equals(0));
      // Total should remain
      expect(usageService.getTotalCount(), equals(2));
    });

    test('should return correct remaining pro monthly', () async {
      // Bug: Pro user sees wrong remaining count
      expect(usageService.getRemainingProMonthly(), equals(500));

      await usageService.recordGeneration();
      expect(usageService.getRemainingProMonthly(), equals(499));
    });

    test('canGenerateFree returns true when under limit', () {
      // Bug: Free user incorrectly blocked
      expect(usageService.canGenerateFree(), isTrue);
    });

    test('canGeneratePro returns true initially', () {
      // Bug: New Pro user blocked immediately
      expect(usageService.canGeneratePro(), isTrue);
    });

    test('getRemainingFree clamps to zero, not negative', () async {
      // Bug: Negative remaining count shown in UI
      for (var i = 0; i < 100; i++) {
        await usageService.recordGeneration();
      }
      expect(usageService.getRemainingFree(), equals(0));
      expect(usageService.getRemainingFree(), greaterThanOrEqualTo(0));
    });

    test('getRemainingProMonthly clamps to zero', () async {
      // Bug: Negative remaining shown after heavy usage
      for (var i = 0; i < 510; i++) {
        await usageService.recordGeneration();
      }
      expect(usageService.getRemainingProMonthly(), equals(0));
      expect(usageService.getRemainingProMonthly(), greaterThanOrEqualTo(0));
    });

    test('monthly count resets when month changes', () async {
      // Set up previous month data
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('monthly_generation_month', '2023-01');
      await prefs.setInt('monthly_generation_count', 50);

      // Create new service to read from prefs
      final newService = UsageService(
        prefs,
        MockDeviceFingerprintService(),
        MockRateLimitService(),
      );

      // Should return 0 because current month doesn't match stored month
      expect(newService.getMonthlyCount(), equals(0));
    });

    test('clearSyncMarker removes sync user id', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_sync_user_id', 'test-user-123');

      await usageService.clearSyncMarker();

      expect(prefs.getString('last_sync_user_id'), isNull);
    });

    test('multiple generations increment correctly', () async {
      // Bug: Counter skips numbers or double-counts
      for (var i = 1; i <= 5; i++) {
        await usageService.recordGeneration();
        expect(usageService.getTotalCount(), equals(i));
        expect(usageService.getMonthlyCount(), equals(i));
      }
    });
  });
}
