import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:prosepal/core/services/usage_service.dart';

void main() {
  group('UsageService', () {
    late UsageService usageService;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      usageService = UsageService(prefs);
    });

    test('should start with 0 total count', () {
      expect(usageService.getTotalCount(), equals(0));
    });

    test('should start with 3 remaining free generations', () {
      expect(usageService.getRemainingFree(), equals(3));
    });

    test('should decrement remaining after recording generation', () async {
      await usageService.recordGeneration();
      expect(usageService.getRemainingFree(), equals(2));
    });

    test('should increment total count after recording generation', () async {
      await usageService.recordGeneration();
      expect(usageService.getTotalCount(), equals(1));
    });

    test(
      'should return false for canGenerateFree when free limit reached',
      () async {
        await usageService.recordGeneration();
        await usageService.recordGeneration();
        await usageService.recordGeneration();
        expect(usageService.canGenerateFree(), equals(false));
      },
    );

    test(
      'should return true for canGeneratePro when under monthly limit',
      () async {
        await usageService.recordGeneration();
        await usageService.recordGeneration();
        await usageService.recordGeneration();
        expect(usageService.canGeneratePro(), equals(true));
      },
    );

    test('should not go below 0 remaining', () async {
      for (int i = 0; i < 10; i++) {
        await usageService.recordGeneration();
      }
      expect(usageService.getRemainingFree(), equals(0));
    });
  });
}
