import 'package:flutter_test/flutter_test.dart';
import 'package:prosepal/app/auth_identity_sync.dart';

import '../mocks/mock_subscription_service.dart';

void main() {
  late MockSubscriptionService subscriptionService;

  setUp(() {
    subscriptionService = MockSubscriptionService();
  });

  test(
    'claims store-backed Pro via sync when anonymous user had Pro before identify',
    () async {
      subscriptionService
        ..setIsPro(true)
        ..syncPurchasesResult = true
        ..onIdentifyUser = (_) => subscriptionService.setIsPro(false);

      final result = await reconcileSubscriptionIdentityAfterSignIn(
        subscriptionService: subscriptionService,
        userId: 'user-123',
      );

      expect(subscriptionService.identifyUserCallCount, 1);
      expect(subscriptionService.syncPurchasesCallCount, 1);
      expect(result.hadPreSignInPro, isTrue);
      expect(result.hasProAfterIdentify, isFalse);
      expect(result.claimedViaSync, isTrue);
      expect(result.finalHasPro, isTrue);
    },
  );

  test('does not sync when identified user already has Pro', () async {
    subscriptionService.setIsPro(true);

    final result = await reconcileSubscriptionIdentityAfterSignIn(
      subscriptionService: subscriptionService,
      userId: 'user-123',
    );

    expect(subscriptionService.identifyUserCallCount, 1);
    expect(subscriptionService.syncPurchasesCallCount, 0);
    expect(result.hadPreSignInPro, isTrue);
    expect(result.hasProAfterIdentify, isTrue);
    expect(result.claimedViaSync, isFalse);
    expect(result.finalHasPro, isTrue);
  });

  test('does not sync when there was no pre-sign-in Pro entitlement', () async {
    subscriptionService.setIsPro(false);

    final result = await reconcileSubscriptionIdentityAfterSignIn(
      subscriptionService: subscriptionService,
      userId: 'user-123',
    );

    expect(subscriptionService.identifyUserCallCount, 1);
    expect(subscriptionService.syncPurchasesCallCount, 0);
    expect(result.hadPreSignInPro, isFalse);
    expect(result.hasProAfterIdentify, isFalse);
    expect(result.claimedViaSync, isFalse);
    expect(result.finalHasPro, isFalse);
  });
}
