import '../core/interfaces/subscription_interface.dart';

class AuthIdentitySyncResult {
  const AuthIdentitySyncResult({
    required this.hadPreSignInPro,
    required this.hasProAfterIdentify,
    required this.claimedViaSync,
    required this.finalHasPro,
  });

  final bool hadPreSignInPro;
  final bool hasProAfterIdentify;
  final bool claimedViaSync;
  final bool finalHasPro;
}

/// Reconcile RevenueCat identity after app auth succeeds.
///
/// This preserves the common anonymous-restore-then-sign-in flow:
/// if the pre-sign-in anonymous user already had Pro but the identified user
/// does not immediately receive the entitlement, we perform a targeted silent
/// `syncPurchases()` to claim the store-backed receipt onto the account.
Future<AuthIdentitySyncResult> reconcileSubscriptionIdentityAfterSignIn({
  required ISubscriptionService subscriptionService,
  required String userId,
  bool? hadPreSignInProOverride,
}) async {
  final hadPreSignInPro =
      hadPreSignInProOverride ?? await subscriptionService.isPro();
  await subscriptionService.identifyUser(userId);
  final hasProAfterIdentify = await subscriptionService.isPro();

  if (hadPreSignInPro && !hasProAfterIdentify) {
    final claimedViaSync = await subscriptionService.syncPurchases();
    return AuthIdentitySyncResult(
      hadPreSignInPro: true,
      hasProAfterIdentify: false,
      claimedViaSync: true,
      finalHasPro: claimedViaSync,
    );
  }

  return AuthIdentitySyncResult(
    hadPreSignInPro: hadPreSignInPro,
    hasProAfterIdentify: hasProAfterIdentify,
    claimedViaSync: false,
    finalHasPro: hasProAfterIdentify,
  );
}
