import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:prosepal/app/router.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../mocks/mock_subscription_service.dart';

void main() {
  group('resolveAnonymousProRestore', () {
    late MockSubscriptionService subscriptionService;

    setUp(() {
      subscriptionService = MockSubscriptionService();
    });

    test('returns false when RevenueCat is not configured', () async {
      subscriptionService.setConfigured(false);

      final result = await resolveAnonymousProRestore(
        subscriptionService: subscriptionService,
        timeout: const Duration(milliseconds: 20),
      );

      expect(result, isFalse);
      expect(subscriptionService.getCustomerInfoCallCount, 0);
    });

    test('returns false when customer info is unavailable', () async {
      final result = await resolveAnonymousProRestore(
        subscriptionService: subscriptionService,
        timeout: const Duration(milliseconds: 20),
      );

      expect(result, isFalse);
      expect(subscriptionService.getCustomerInfoCallCount, 1);
    });

    test('returns true when active Pro entitlement exists', () async {
      subscriptionService.setCustomerInfo(_customerInfoWithPro());

      final result = await resolveAnonymousProRestore(
        subscriptionService: subscriptionService,
        timeout: const Duration(milliseconds: 20),
      );

      expect(result, isTrue);
      expect(subscriptionService.getCustomerInfoCallCount, 1);
    });

    test('returns false when customer info fetch exceeds timeout', () async {
      final delayedService = _HangingCustomerInfoSubscriptionService();

      final result = await resolveAnonymousProRestore(
        subscriptionService: delayedService,
        timeout: const Duration(milliseconds: 10),
      );

      expect(result, isFalse);
      expect(delayedService.getCustomerInfoCallCount, 1);
    });

    test('returns false when customer info fetch throws', () async {
      subscriptionService.methodErrors['getCustomerInfo'] = Exception(
        'network down',
      );

      final result = await resolveAnonymousProRestore(
        subscriptionService: subscriptionService,
        timeout: const Duration(milliseconds: 20),
      );

      expect(result, isFalse);
      expect(subscriptionService.getCustomerInfoCallCount, 1);
    });
  });
}

CustomerInfo _customerInfoWithPro() {
  const proEntitlement = EntitlementInfo(
    'pro',
    true,
    true,
    '2026-03-13T00:00:00Z',
    '2026-03-13T00:00:00Z',
    'pro_monthly',
    false,
  );

  return const CustomerInfo(
    EntitlementInfos({'pro': proEntitlement}, {'pro': proEntitlement}),
    {},
    ['pro_monthly'],
    ['pro_monthly'],
    [],
    '2026-03-13T00:00:00Z',
    r'$RCAnonymousID:test',
    {},
    '2026-03-13T00:00:00Z',
  );
}

class _HangingCustomerInfoSubscriptionService extends MockSubscriptionService {
  @override
  Future<CustomerInfo?> getCustomerInfo() async {
    getCustomerInfoCallCount++;
    return Completer<CustomerInfo?>().future;
  }
}
