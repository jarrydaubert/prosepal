import Foundation
import ProsePalAPI
import ProsePalDomain
import ProsePalUI
import Testing

@Test
@MainActor
func unconfiguredAppleSignInDoesNotCreateSignedInState() {
    let account = MomentAccountModel(clientContext: ClientContext(appVersion: "1.0", buildNumber: "1"))

    let nonce = account.beginAppleSignInRequest(source: "settings")

    #expect(nonce == nil)
    #expect(account.isSignedIn == false)
    #expect(account.notice?.title == "Sign in is not configured for this build")
}

@Test
@MainActor
func appleSignInIgnoresDuplicateRequestsWhileInFlight() {
    let account = makeAccount(authClient: MomentAccountAuthClient())

    let firstNonce = account.beginAppleSignInRequest(source: "settings")
    let secondNonce = account.beginAppleSignInRequest(source: "settings")

    #expect(firstNonce != nil)
    #expect(secondNonce == nil)
    #expect(account.isSigningIn)
}

@Test
@MainActor
func appleSignInMissingTokenDoesNotCreateSignedInState() async {
    let account = makeAccount(authClient: MomentAccountAuthClient())
    _ = account.beginAppleSignInRequest(source: "settings")

    await account.completeAppleSignIn(
        idToken: "   ",
        authorizationCode: "authorization-code",
        appleUserID: "apple-user",
        source: "settings"
    )

    #expect(account.isSignedIn == false)
    #expect(account.isSigningIn == false)
    #expect(account.notice?.title == AuthError.missingIdentityToken.userSafeMessage)
}

@Test
@MainActor
func appleSignInSuccessStoresSessionAndRefreshesEntitlement() async throws {
    let store = MomentAccountInMemoryAuthSessionStore()
    let authClient = MomentAccountAuthClient()
    let subscriptionClient = MomentAccountSubscriptionClient(entitlement: SubscriptionEntitlement(
        isActive: true,
        productID: "com.prosepal.pro.yearly"
    ))
    let account = makeAccount(
        store: store,
        authClient: authClient,
        subscriptionClient: subscriptionClient
    )

    let nonce = account.beginAppleSignInRequest(source: "settings")
    #expect(nonce != nil)

    await account.completeAppleSignIn(
        idToken: "apple-token",
        authorizationCode: "authorization-code",
        appleUserID: "apple-user",
        source: "settings"
    )

    #expect(account.isSignedIn)
    #expect(account.signedInEmail == "user@example.com")
    #expect(account.isPremiumUnlocked)
    #expect(account.subscriptionEntitlement.productID == "com.prosepal.pro.yearly")
    #expect(try await store.loadSession()?.accessToken == "access-token")
    #expect(try await store.loadSession()?.appleCredentialUserID == "apple-user")
}

@Test
@MainActor
func appleSignInForwardsAuthorizationCodeForFirstAndRepeatSignIn() async throws {
    let store = MomentAccountInMemoryAuthSessionStore()
    let lifecycleClient = MomentAccountAppleLifecycleClient()
    let account = makeAccount(
        store: store,
        authClient: MomentAccountAuthClient(),
        appleAccountLifecycleClient: lifecycleClient
    )

    for code in ["first-code", "repeat-code"] {
        _ = account.beginAppleSignInRequest(source: "settings")
        await account.completeAppleSignIn(
            idToken: "apple-token",
            authorizationCode: code,
            appleUserID: "apple-user",
            source: "settings"
        )
    }

    #expect(await lifecycleClient.exchanges() == [
        MomentAccountAppleLifecycleExchange(
            authorizationCode: "first-code",
            appleUserID: "apple-user",
            accessToken: "access-token"
        ),
        MomentAccountAppleLifecycleExchange(
            authorizationCode: "repeat-code",
            appleUserID: "apple-user",
            accessToken: "access-token"
        )
    ])
    #expect(try await store.loadSession()?.appleCredentialUserID == "apple-user")
}

@Test
@MainActor
func appleSignInRejectsMissingAuthorizationCodeAndCredentialIdentifier() async {
    let lifecycleClient = MomentAccountAppleLifecycleClient()
    let account = makeAccount(
        authClient: MomentAccountAuthClient(),
        appleAccountLifecycleClient: lifecycleClient
    )

    _ = account.beginAppleSignInRequest(source: "settings")
    await account.completeAppleSignIn(
        idToken: "apple-token",
        authorizationCode: " ",
        appleUserID: "apple-user",
        source: "settings"
    )
    #expect(account.isSignedIn == false)
    #expect(account.notice?.title == AppleAccountLifecycleError.missingAuthorizationCode.userSafeMessage)

    _ = account.beginAppleSignInRequest(source: "settings")
    await account.completeAppleSignIn(
        idToken: "apple-token",
        authorizationCode: "authorization-code",
        appleUserID: " ",
        source: "settings"
    )
    #expect(account.isSignedIn == false)
    #expect(account.notice?.title == AppleAccountLifecycleError.missingCredentialIdentifier.userSafeMessage)
    #expect(await lifecycleClient.exchanges().isEmpty)
}

@Test
@MainActor
func appleRevocationMaterialFailureDoesNotPersistPartialSignInAndCanRetry() async throws {
    let store = MomentAccountInMemoryAuthSessionStore()
    let lifecycleClient = MomentAccountAppleLifecycleClient(
        errors: [.requestFailed(statusCode: 503, message: "Apple account setup failed safely.")]
    )
    let account = makeAccount(
        store: store,
        authClient: MomentAccountAuthClient(),
        appleAccountLifecycleClient: lifecycleClient
    )

    _ = account.beginAppleSignInRequest(source: "settings")
    await account.completeAppleSignIn(
        idToken: "apple-token",
        authorizationCode: "first-code",
        appleUserID: "apple-user",
        source: "settings"
    )
    #expect(account.isSignedIn == false)
    #expect(try await store.loadSession() == nil)
    #expect(account.notice?.title == "Apple account setup failed safely.")

    _ = account.beginAppleSignInRequest(source: "settings")
    await account.completeAppleSignIn(
        idToken: "apple-token",
        authorizationCode: "retry-code",
        appleUserID: "apple-user",
        source: "settings"
    )
    #expect(account.isSignedIn)
    #expect(try await store.loadSession()?.appleCredentialUserID == "apple-user")
}

@Test(arguments: [
    AppleCredentialState.revoked,
    AppleCredentialState.notFound,
    AppleCredentialState.transferred
])
@MainActor
func nonAuthorizedAppleCredentialStatesSignOutWithoutDeletingLocalDrafts(
    state: AppleCredentialState
) async throws {
    let session = AuthSession.test(
        accessToken: "signed-in-token",
        appleCredentialUserID: "apple-user"
    )
    let store = MomentAccountInMemoryAuthSessionStore(session: session)
    let authClient = MomentAccountAuthClient()
    let credentialProvider = MomentAccountAppleCredentialStateProvider(state: state)
    var localDataDeletionCount = 0
    let account = makeAccount(
        store: store,
        authClient: authClient,
        appleCredentialStateProvider: credentialProvider,
        localAccountDataDeletion: {
            localDataDeletionCount += 1
        }
    )

    await account.loadAuthSession()

    #expect(account.isSignedIn == false)
    #expect(try await store.loadSession() == nil)
    #expect(await authClient.signOutTokens() == ["signed-in-token"])
    #expect(localDataDeletionCount == 0)
}

@Test
@MainActor
func authorizedAppleCredentialStateKeepsSession() async throws {
    let session = AuthSession.test(
        accessToken: "signed-in-token",
        appleCredentialUserID: "apple-user"
    )
    let store = MomentAccountInMemoryAuthSessionStore(session: session)
    let account = makeAccount(
        store: store,
        authClient: MomentAccountAuthClient(),
        appleCredentialStateProvider: MomentAccountAppleCredentialStateProvider(state: .authorized)
    )

    await account.loadAuthSession()

    #expect(account.isSignedIn)
    #expect(try await store.loadSession() == session)
}

@Test
@MainActor
func revokedAppleCredentialFailsClosedInMemoryWhenSessionStorageCannotClear() async throws {
    let session = AuthSession.test(
        accessToken: "signed-in-token",
        appleCredentialUserID: "apple-user"
    )
    let store = MomentAccountInMemoryAuthSessionStore(
        session: session,
        clearError: MomentAccountSessionStoreError.testFailure
    )
    let account = makeAccount(
        store: store,
        authClient: MomentAccountAuthClient(),
        appleCredentialStateProvider: MomentAccountAppleCredentialStateProvider(state: .revoked)
    )

    await account.loadAuthSession()

    #expect(account.isSignedIn == false)
    #expect(try await store.loadSession() == session)
    #expect(account.notice?.title.contains("could not clear the saved session") == true)
}

@Test
@MainActor
func AppleCredentialRevocationNotificationSignsOutWithoutDeletingLocalDrafts() async throws {
    let session = AuthSession.test(
        accessToken: "signed-in-token",
        appleCredentialUserID: "apple-user"
    )
    let store = MomentAccountInMemoryAuthSessionStore(session: session)
    let provider = MomentAccountAppleCredentialStateProvider(state: .authorized)
    var localDataDeletionCount = 0
    let account = makeAccount(
        store: store,
        authClient: MomentAccountAuthClient(),
        appleCredentialStateProvider: provider,
        localAccountDataDeletion: {
            localDataDeletionCount += 1
        }
    )
    await account.loadAuthSession()
    await provider.setState(.revoked)

    provider.sendRevocationEvent()
    for _ in 0..<200 {
        if !account.isSignedIn, try await store.loadSession() == nil { break }
        await Task.yield()
    }

    #expect(account.isSignedIn == false)
    #expect(try await store.loadSession() == nil)
    #expect(localDataDeletionCount == 0)
}

@Test
@MainActor
func launchRefreshesExpiredAuthSessionAndKeepsAccountSignedIn() async throws {
    let expiredSession = AuthSession.test(
        accessToken: "expired-token",
        refreshToken: "refresh-token-1",
        expiresAt: Date(timeIntervalSince1970: 1_700_000_000)
    )
    let rotatedSession = AuthSession.test(
        accessToken: "access-token-2",
        refreshToken: "refresh-token-2",
        expiresAt: Date(timeIntervalSince1970: 2_000_000_000)
    )
    let store = MomentAccountInMemoryAuthSessionStore(session: expiredSession)
    let authClient = MomentAccountAuthClient(session: rotatedSession)
    let account = makeAccount(store: store, authClient: authClient)

    await account.loadAuthSession()

    #expect(account.isSignedIn)
    #expect(account.signedInEmail == "user@example.com")
    #expect(try await store.loadSession() == rotatedSession)
    #expect(await authClient.refreshCallCount() == 1)
}

@Test
@MainActor
func launchPreservesSignedInIdentityWhenExpiredSessionRefreshIsOffline() async throws {
    let expiredSession = AuthSession.test(
        accessToken: "expired-token",
        refreshToken: "refresh-token-1",
        expiresAt: Date(timeIntervalSince1970: 1_700_000_000)
    )
    let store = MomentAccountInMemoryAuthSessionStore(session: expiredSession)
    let authClient = MomentAccountAuthClient(refreshError: AuthError.networkUnavailable)
    let account = makeAccount(store: store, authClient: authClient)

    await account.loadAuthSession()

    #expect(account.isSignedIn)
    #expect(account.signedInEmail == "user@example.com")
    #expect(try await store.loadSession() == expiredSession)
    #expect(await authClient.refreshCallCount() == 1)
}

@Test
@MainActor
func launchClearsSignedInStateAfterTerminalRefreshRejection() async throws {
    let expiredSession = AuthSession.test(
        accessToken: "expired-token",
        refreshToken: "refresh-token-1",
        expiresAt: Date(timeIntervalSince1970: 1_700_000_000)
    )
    let store = MomentAccountInMemoryAuthSessionStore(session: expiredSession)
    let authClient = MomentAccountAuthClient(refreshError: AuthError.requestFailed(
        statusCode: 401,
        message: "Refresh token rejected."
    ))
    let account = makeAccount(store: store, authClient: authClient)

    await account.loadAuthSession()

    #expect(account.isSignedIn == false)
    #expect(try await store.loadSession() == nil)
    #expect(await authClient.refreshCallCount() == 1)
}

@Test
@MainActor
func appleSignInFailurePreservesExistingSignedInSession() async throws {
    let existingSession = AuthSession.test(
        accessToken: "existing-token",
        userID: "existing-user",
        email: "existing@example.com"
    )
    let store = MomentAccountInMemoryAuthSessionStore(session: existingSession)
    let authClient = MomentAccountAuthClient(signInError: AuthError.requestFailed(
        statusCode: 401,
        message: "Apple sign-in was rejected."
    ))
    let account = makeAccount(store: store, authClient: authClient)

    await account.loadAuthSession()
    _ = account.beginAppleSignInRequest(source: "settings")
    await account.completeAppleSignIn(
        idToken: "apple-token",
        authorizationCode: "authorization-code",
        appleUserID: "apple-user",
        source: "settings"
    )

    #expect(account.isSignedIn)
    #expect(account.signedInEmail == "existing@example.com")
    #expect(try await store.loadSession()?.accessToken == "existing-token")
    #expect(account.notice?.title == "Apple sign-in was rejected.")
}

@Test
@MainActor
func signOutClearsPersistedSessionAndPremiumState() async throws {
    let session = AuthSession.test(accessToken: "signed-in-token")
    let store = MomentAccountInMemoryAuthSessionStore(session: session)
    let authClient = MomentAccountAuthClient()
    let subscriptionClient = MomentAccountSubscriptionClient(entitlement: SubscriptionEntitlement(
        isActive: true,
        productID: "com.prosepal.pro.yearly"
    ))
    let account = makeAccount(
        store: store,
        authClient: authClient,
        subscriptionClient: subscriptionClient
    )

    await account.loadInitialState()
    #expect(account.isSignedIn)
    #expect(account.isPremiumUnlocked)
    #expect(account.subscriptionEntitlement.isActive)

    await account.signOut()

    #expect(account.isSignedIn == false)
    #expect(account.isPremiumUnlocked == false)
    #expect(account.subscriptionEntitlement == .inactive)
    #expect(try await store.loadSession() == nil)
    #expect(await authClient.signOutTokens() == ["signed-in-token"])
}

@Test
@MainActor
func subscriptionProductsSelectRecommendedPlanAndPurchaseUnlocksPremium() async {
    let yearly = SubscriptionProduct.yearly(isRecommended: true)
    let monthly = SubscriptionProduct.monthly()
    let subscriptionClient = MomentAccountSubscriptionClient(
        products: [monthly, yearly],
        purchaseResult: SubscriptionPurchaseResult(
            status: .purchased,
            entitlement: SubscriptionEntitlement(isActive: true, productID: yearly.id)
        )
    )
    let account = makeAccount(subscriptionClient: subscriptionClient)

    await account.loadSubscriptionProducts(source: "paywall")
    #expect(account.subscriptionProducts.count == 2)
    #expect(account.selectedSubscriptionProductID == yearly.id)
    #expect(account.selectedPremiumPlanDisclosureText == "$39.99 / Every 1 year")
    #expect(account.premiumRenewalDisclosureText.contains("Auto-renews"))

    await account.purchasePremium(source: "paywall")
    #expect(account.isPremiumUnlocked)
    #expect(account.subscriptionEntitlement.productID == yearly.id)
    #expect(account.notice?.title == "Premium purchase completed")
    #expect(await subscriptionClient.purchasedProductIDs() == [yearly.id])
}

@Test
@MainActor
func subscriptionLoadFailureClearsProductsAndSelection() async {
    let subscriptionClient = MomentAccountSubscriptionClient(loadProductsError: SubscriptionError.productsUnavailable)
    let account = makeAccount(subscriptionClient: subscriptionClient)
    account.selectedSubscriptionProductID = "stale-plan"

    await account.loadSubscriptionProducts(source: "paywall")

    #expect(account.subscriptionProducts.isEmpty)
    #expect(account.selectedSubscriptionProductID == nil)
    #expect(account.subscriptionErrorMessage == SubscriptionError.productsUnavailable.userSafeMessage)
}

@Test
@MainActor
func purchaseAutoLoadsProductsAndHandlesCancellationWithoutUnlockingPremium() async {
    let weekly = SubscriptionProduct.weekly()
    let subscriptionClient = MomentAccountSubscriptionClient(
        products: [weekly],
        purchaseResult: SubscriptionPurchaseResult(status: .cancelled)
    )
    let account = makeAccount(subscriptionClient: subscriptionClient)

    await account.purchasePremium(source: "paywall")

    #expect(account.subscriptionProducts == [weekly])
    #expect(account.selectedSubscriptionProductID == weekly.id)
    #expect(account.isPremiumUnlocked == false)
    #expect(account.notice?.title == "Purchase cancelled")
    #expect(await subscriptionClient.loadProductsCallCount() == 1)
    #expect(await subscriptionClient.purchasedProductIDs() == [weekly.id])
}

@Test
@MainActor
func restorePurchasesHandlesActiveAndNotEntitledStates() async {
    let subscriptionClient = MomentAccountSubscriptionClient(restoreResult: SubscriptionPurchaseResult(
        status: .restored,
        entitlement: SubscriptionEntitlement(isActive: true, productID: "com.prosepal.pro.yearly")
    ))
    let account = makeAccount(subscriptionClient: subscriptionClient)

    await account.restorePurchases(source: "paywall")
    #expect(account.isPremiumUnlocked)
    #expect(account.subscriptionEntitlement.productID == "com.prosepal.pro.yearly")
    #expect(account.notice?.title == "Premium restored")

    await subscriptionClient.setRestoreResult(SubscriptionPurchaseResult(status: .notEntitled))
    await account.restorePurchases(source: "paywall")

    #expect(account.isPremiumUnlocked == false)
    #expect(account.subscriptionEntitlement == .inactive)
    #expect(account.notice?.title == "No active subscription found")
}

@Test
@MainActor
func restorePurchasesShowsVisibleErrorWhenUnconfigured() async {
    let account = makeAccount()

    await account.restorePurchases(source: "settings")

    #expect(account.isPremiumUnlocked == false)
    #expect(account.subscriptionErrorMessage == SubscriptionError.notConfigured.userSafeMessage)
    #expect(account.notice?.title == SubscriptionError.notConfigured.userSafeMessage)
}

@Test
@MainActor
func transactionUpdatesConvergeApprovalsRenewalsFamilySharingAndRevocations() async {
    let subscriptionClient = MomentAccountSubscriptionClient()
    let finishRecorder = MomentAccountTransactionFinishRecorder()
    let account = makeAccount(subscriptionClient: subscriptionClient)

    await subscriptionClient.setEntitlement(SubscriptionEntitlement(
        isActive: true,
        productID: "com.prosepal.pro.monthly"
    ))
    await subscriptionClient.emitTransactionUpdate(SubscriptionTransactionUpdate(
        verification: .verified,
        productID: "com.prosepal.pro.monthly",
        finishAction: { await finishRecorder.recordFinish() }
    ))
    await waitForTransactionUpdates(finishRecorder: finishRecorder, expectedFinishCount: 1)

    #expect(account.isPremiumUnlocked)
    #expect(account.subscriptionEntitlement.productID == "com.prosepal.pro.monthly")

    await subscriptionClient.setEntitlement(SubscriptionEntitlement(
        isActive: true,
        productID: "com.prosepal.pro.yearly"
    ))
    await subscriptionClient.emitTransactionUpdate(SubscriptionTransactionUpdate(
        verification: .verified,
        productID: "com.prosepal.pro.yearly",
        finishAction: { await finishRecorder.recordFinish() }
    ))
    await waitForTransactionUpdates(finishRecorder: finishRecorder, expectedFinishCount: 2)

    #expect(account.isPremiumUnlocked)
    #expect(account.subscriptionEntitlement.productID == "com.prosepal.pro.yearly")

    await subscriptionClient.setEntitlement(.inactive)
    await subscriptionClient.emitTransactionUpdate(SubscriptionTransactionUpdate(
        verification: .verified,
        productID: "com.prosepal.pro.yearly",
        effect: .removesAccess,
        finishAction: { await finishRecorder.recordFinish() }
    ))
    await waitForTransactionUpdates(finishRecorder: finishRecorder, expectedFinishCount: 3)

    #expect(account.isPremiumUnlocked == false)
    #expect(account.subscriptionEntitlement == .inactive)
    #expect(await subscriptionClient.currentEntitlementCallCount() == 3)
    account.stopSubscriptionTransactionListener()
}

@Test
@MainActor
func unverifiedTransactionUpdateCannotUnlockPremiumOrFinishTransaction() async {
    let subscriptionClient = MomentAccountSubscriptionClient(entitlement: SubscriptionEntitlement(
        isActive: true,
        productID: "com.prosepal.pro.yearly"
    ))
    let unverifiedFinishRecorder = MomentAccountTransactionFinishRecorder()
    let verifiedFinishRecorder = MomentAccountTransactionFinishRecorder()
    let account = makeAccount(subscriptionClient: subscriptionClient)

    for _ in 0..<200 {
        if await subscriptionClient.transactionUpdatesCallCount() == 1 { break }
        await Task.yield()
    }
    await subscriptionClient.emitTransactionUpdate(SubscriptionTransactionUpdate(
        verification: .unverified,
        productID: "com.prosepal.pro.yearly",
        finishAction: { await unverifiedFinishRecorder.recordFinish() }
    ))

    for _ in 0..<200 {
        await Task.yield()
    }

    #expect(account.isPremiumUnlocked == false)
    #expect(await unverifiedFinishRecorder.finishCount() == 0)
    #expect(await subscriptionClient.currentEntitlementCallCount() == 0)

    await subscriptionClient.setEntitlement(.inactive)
    await subscriptionClient.emitTransactionUpdate(SubscriptionTransactionUpdate(
        verification: .verified,
        productID: "com.prosepal.pro.yearly",
        effect: .removesAccess,
        finishAction: { await verifiedFinishRecorder.recordFinish() }
    ))
    await waitForTransactionUpdates(
        finishRecorder: verifiedFinishRecorder,
        expectedFinishCount: 1
    )

    #expect(account.isPremiumUnlocked == false)
    #expect(account.subscriptionEntitlement == .inactive)
    #expect(await unverifiedFinishRecorder.finishCount() == 0)
    #expect(await subscriptionClient.currentEntitlementCallCount() == 1)
    account.stopSubscriptionTransactionListener()
}

@Test
@MainActor
func failedTransactionReconciliationRemainsUnfinishedUntilRedeliveryConverges() async {
    let subscriptionClient = MomentAccountSubscriptionClient(
        currentEntitlementError: SubscriptionError.storeUnavailable
    )
    let finishRecorder = MomentAccountTransactionFinishRecorder()
    let account = makeAccount(subscriptionClient: subscriptionClient)

    await subscriptionClient.emitTransactionUpdate(SubscriptionTransactionUpdate(
        verification: .verified,
        productID: "com.prosepal.pro.yearly",
        finishAction: { await finishRecorder.recordFinish() }
    ))

    for _ in 0..<200 {
        if await subscriptionClient.currentEntitlementCallCount() == 1 { break }
        await Task.yield()
    }

    #expect(await subscriptionClient.currentEntitlementCallCount() == 1)
    #expect(await finishRecorder.finishCount() == 0)
    #expect(account.isPremiumUnlocked == false)
    #expect(account.subscriptionErrorMessage == SubscriptionError.storeUnavailable.userSafeMessage)

    await subscriptionClient.setEntitlement(SubscriptionEntitlement(
        isActive: true,
        productID: "com.prosepal.pro.yearly"
    ))
    await subscriptionClient.emitTransactionUpdate(SubscriptionTransactionUpdate(
        verification: .verified,
        productID: "com.prosepal.pro.yearly",
        finishAction: { await finishRecorder.recordFinish() }
    ))
    await waitForTransactionUpdates(
        finishRecorder: finishRecorder,
        expectedFinishCount: 1
    )

    #expect(await subscriptionClient.currentEntitlementCallCount() == 2)
    #expect(account.isPremiumUnlocked)
    account.stopSubscriptionTransactionListener()
}

@Test
@MainActor
func transientEntitlementFailureKeepsLastVerifiedActiveAccessForSameAccount() async {
    let active = SubscriptionEntitlement(
        isActive: true,
        productID: "com.prosepal.pro.yearly"
    )
    let subscriptionClient = MomentAccountSubscriptionClient(entitlement: active)
    let account = makeAccount(subscriptionClient: subscriptionClient)

    #expect(await account.refreshSubscriptionEntitlement(source: "launch"))
    #expect(account.isPremiumUnlocked)
    #expect(account.subscriptionEntitlement == active)

    await subscriptionClient.setEntitlementError(SubscriptionError.storeUnavailable)
    #expect(await account.refreshSubscriptionEntitlement(source: "foreground") == false)

    #expect(account.isPremiumUnlocked)
    #expect(account.subscriptionEntitlement == active)
    #expect(account.subscriptionEntitlementState == .unknown(.storeUnavailable))
    #expect(account.subscriptionErrorMessage == SubscriptionError.storeUnavailable.userSafeMessage)
    account.stopSubscriptionTransactionListener()
}

@Test
@MainActor
func unknownEntitlementNeverCreatesPremiumAndConfirmedInactiveClearsLastKnownAccess() async {
    let subscriptionClient = MomentAccountSubscriptionClient(
        currentEntitlementError: SubscriptionError.storeUnavailable
    )
    let account = makeAccount(subscriptionClient: subscriptionClient)

    #expect(await account.refreshSubscriptionEntitlement(source: "launch") == false)
    #expect(account.isPremiumUnlocked == false)
    #expect(account.subscriptionEntitlement == .inactive)

    await subscriptionClient.setEntitlement(SubscriptionEntitlement(
        isActive: true,
        productID: "com.prosepal.pro.monthly"
    ))
    #expect(await account.refreshSubscriptionEntitlement(source: "retry"))
    #expect(account.isPremiumUnlocked)

    await subscriptionClient.setEntitlement(.inactive)
    #expect(await account.refreshSubscriptionEntitlement(source: "expiration"))
    #expect(account.isPremiumUnlocked == false)
    #expect(account.subscriptionEntitlementState == .inactive)
    account.stopSubscriptionTransactionListener()
}

@Test
@MainActor
func successfulPurchaseFinishesOnlyAfterActiveEntitlementDelivery() async {
    let product = SubscriptionProduct.yearly(isRecommended: true)
    let finishRecorder = MomentAccountTransactionFinishRecorder()
    let active = SubscriptionEntitlement(isActive: true, productID: product.id)
    let subscriptionClient = MomentAccountSubscriptionClient(
        products: [product],
        purchaseResult: SubscriptionPurchaseResult(
            status: .purchased,
            entitlementState: .active(active),
            delivery: SubscriptionTransactionDelivery(
                productID: product.id,
                ownership: .unlinked,
                finishAction: { await finishRecorder.recordFinish() }
            )
        )
    )
    let account = makeAccount(subscriptionClient: subscriptionClient)

    await account.loadSubscriptionProducts(source: "paywall")
    await account.purchasePremium(source: "paywall")

    #expect(account.isPremiumUnlocked)
    #expect(await finishRecorder.finishCount() == 1)
    account.stopSubscriptionTransactionListener()
}

@Test
@MainActor
func purchaseWithMismatchedDeliveredProductDoesNotUnlockOrFinish() async {
    let yearly = SubscriptionProduct.yearly(isRecommended: true)
    let monthlyID = "com.prosepal.pro.monthly"
    let finishRecorder = MomentAccountTransactionFinishRecorder()
    let subscriptionClient = MomentAccountSubscriptionClient(
        products: [yearly],
        purchaseResult: SubscriptionPurchaseResult(
            status: .purchased,
            entitlementState: .active(SubscriptionEntitlement(
                isActive: true,
                productID: yearly.id
            )),
            delivery: SubscriptionTransactionDelivery(
                productID: monthlyID,
                ownership: .unlinked,
                finishAction: { await finishRecorder.recordFinish() }
            )
        )
    )
    let account = makeAccount(subscriptionClient: subscriptionClient)

    await account.loadSubscriptionProducts(source: "paywall")
    await account.purchasePremium(source: "paywall")

    #expect(account.isPremiumUnlocked == false)
    #expect(account.subscriptionEntitlementState == .unknown(.verificationFailed))
    #expect(await finishRecorder.finishCount() == 0)
    #expect(account.notice?.title == "Purchase needs verification")
    account.stopSubscriptionTransactionListener()
}

@Test
@MainActor
func unknownRestoreKeepsSameAccountLastKnownGoodAndShowsVerificationFailure() async {
    let active = SubscriptionEntitlement(
        isActive: true,
        productID: "com.prosepal.pro.yearly"
    )
    let subscriptionClient = MomentAccountSubscriptionClient(
        entitlement: active,
        restoreResult: SubscriptionPurchaseResult(
            status: .notEntitled,
            entitlementState: .unknown(.storeUnavailable)
        )
    )
    let account = makeAccount(subscriptionClient: subscriptionClient)

    #expect(await account.refreshSubscriptionEntitlement(source: "launch"))
    await account.restorePurchases(source: "settings")

    #expect(account.isPremiumUnlocked)
    #expect(account.subscriptionEntitlement == active)
    #expect(account.subscriptionEntitlementState == .unknown(.storeUnavailable))
    #expect(account.notice?.title == "Could not verify purchases. Please try again.")
    account.stopSubscriptionTransactionListener()
}

@Test
@MainActor
func mismatchedAccountTransactionDoesNotUnlockOrFinish() async {
    let signedInAccount = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
    let otherAccount = UUID(uuidString: "22222222-2222-2222-2222-222222222222")!
    let store = MomentAccountInMemoryAuthSessionStore(session: .test(
        accessToken: "token",
        userID: signedInAccount.uuidString
    ))
    let subscriptionClient = MomentAccountSubscriptionClient(entitlement: SubscriptionEntitlement(
        isActive: true,
        productID: "com.prosepal.pro.yearly"
    ))
    let finishRecorder = MomentAccountTransactionFinishRecorder()
    let account = makeAccount(store: store, subscriptionClient: subscriptionClient)
    await account.loadAuthSession()

    await subscriptionClient.emitTransactionUpdate(SubscriptionTransactionUpdate(
        verification: .verified,
        productID: "com.prosepal.pro.yearly",
        ownership: .linked(otherAccount),
        finishAction: { await finishRecorder.recordFinish() }
    ))
    for _ in 0..<200 { await Task.yield() }

    #expect(account.isPremiumUnlocked == false)
    #expect(account.subscriptionEntitlementState == .unknown(.ownershipMismatch))
    #expect(await finishRecorder.finishCount() == 0)
    #expect(await subscriptionClient.currentEntitlementCallCount() == 0)
    account.stopSubscriptionTransactionListener()
}

@Test
@MainActor
func switchingAccountsClearsLastKnownPremiumAndRejectsThePreviousOwner() async throws {
    let accountA = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
    let accountB = UUID(uuidString: "22222222-2222-2222-2222-222222222222")!
    let store = MomentAccountInMemoryAuthSessionStore(session: .test(
        accessToken: "token-a",
        userID: accountA.uuidString
    ))
    let entitlement = SubscriptionEntitlement(
        isActive: true,
        productID: "com.prosepal.pro.yearly"
    )
    let subscriptionClient = MomentAccountSubscriptionClient(
        entitlementState: .active(
            entitlement,
            ownership: .linked(accountA)
        )
    )
    let authClient = MomentAccountAuthClient(session: .test(
        accessToken: "token-b",
        userID: accountB.uuidString
    ))
    let account = makeAccount(
        store: store,
        authClient: authClient,
        subscriptionClient: subscriptionClient
    )

    await account.loadAuthSession()
    #expect(await account.refreshSubscriptionEntitlement(source: "account-a"))
    #expect(account.isPremiumUnlocked)

    #expect(account.beginAppleSignInRequest(source: "settings") != nil)
    await account.completeAppleSignIn(
        idToken: "apple-token-b",
        authorizationCode: "authorization-code-b",
        appleUserID: "apple-user-b",
        source: "settings"
    )

    #expect(account.isPremiumUnlocked == false)
    #expect(account.subscriptionEntitlement == .inactive)
    #expect(account.subscriptionEntitlementState == .unknown(.ownershipMismatch))
    #expect(account.isPremiumUnlocked == false)
    account.stopSubscriptionTransactionListener()
}

@Test
@MainActor
func overlappingEntitlementRefreshesAreSerialized() async {
    let subscriptionClient = MomentAccountSubscriptionClient(
        entitlement: SubscriptionEntitlement(
            isActive: true,
            productID: "com.prosepal.pro.yearly"
        ),
        currentEntitlementDelay: .milliseconds(20)
    )
    let account = makeAccount(subscriptionClient: subscriptionClient)

    async let launchRefresh = account.refreshSubscriptionEntitlement(source: "launch")
    async let transactionRefresh = account.refreshSubscriptionEntitlement(source: "transaction_updates")
    let results = await (launchRefresh, transactionRefresh)

    #expect(results.0)
    #expect(results.1)
    #expect(await subscriptionClient.currentEntitlementCallCount() == 2)
    #expect(await subscriptionClient.maximumConcurrentEntitlementCallCount() == 1)
    #expect(account.isPremiumUnlocked)
    account.stopSubscriptionTransactionListener()
}

@Test
@MainActor
func stoppingTransactionListenerPreventsFurtherEntitlementChanges() async {
    let subscriptionClient = MomentAccountSubscriptionClient()
    let finishRecorder = MomentAccountTransactionFinishRecorder()
    let account = makeAccount(subscriptionClient: subscriptionClient)

    for _ in 0..<200 {
        if await subscriptionClient.transactionUpdatesCallCount() == 1 { break }
        await Task.yield()
    }
    account.stopSubscriptionTransactionListener()
    await subscriptionClient.setEntitlement(SubscriptionEntitlement(
        isActive: true,
        productID: "com.prosepal.pro.yearly"
    ))
    await subscriptionClient.emitTransactionUpdate(SubscriptionTransactionUpdate(
        verification: .verified,
        productID: "com.prosepal.pro.yearly",
        finishAction: { await finishRecorder.recordFinish() }
    ))

    for _ in 0..<200 {
        await Task.yield()
    }

    #expect(account.isPremiumUnlocked == false)
    #expect(await subscriptionClient.currentEntitlementCallCount() == 0)
    #expect(await finishRecorder.finishCount() == 0)
}

@MainActor
private func waitForTransactionUpdates(
    finishRecorder: MomentAccountTransactionFinishRecorder,
    expectedFinishCount: Int
) async {
    for _ in 0..<200 {
        if await finishRecorder.finishCount() == expectedFinishCount { return }
        await Task.yield()
    }
}

@Test
@MainActor
func accountDeletionClearsSessionAndPremiumWhenConfigured() async throws {
    let session = AuthSession.test(accessToken: "delete-token")
    let store = MomentAccountInMemoryAuthSessionStore(session: session)
    let subscriptionClient = MomentAccountSubscriptionClient(entitlement: SubscriptionEntitlement(
        isActive: true,
        productID: "com.prosepal.pro.yearly"
    ))
    let maintenanceClient = MomentAccountMaintenanceClient()
    var didDeleteLocalData = false
    let account = makeAccount(
        store: store,
        authClient: MomentAccountAuthClient(),
        subscriptionClient: subscriptionClient,
        accountMaintenanceClient: maintenanceClient,
        localAccountDataDeletion: {
            didDeleteLocalData = true
        }
    )

    await account.loadInitialState()
    account.requestAccountDeletion()
    #expect(account.isConfirmingAccountDeletion)

    await account.confirmAccountDeletion()

    #expect(account.isSignedIn == false)
    #expect(account.isPremiumUnlocked == false)
    #expect(account.isConfirmingAccountDeletion == false)
    #expect(try await store.loadSession() == nil)
    #expect(await maintenanceClient.deletedTokens() == ["delete-token"])
    #expect(didDeleteLocalData)
    #expect(account.notice?.title == "Account deleted")
}

@Test
@MainActor
func accountDeletionWarnsWhenLocalDataCleanupFails() async throws {
    let session = AuthSession.test(accessToken: "delete-token")
    let store = MomentAccountInMemoryAuthSessionStore(session: session)
    let maintenanceClient = MomentAccountMaintenanceClient()
    let account = makeAccount(
        store: store,
        authClient: MomentAccountAuthClient(),
        accountMaintenanceClient: maintenanceClient,
        localAccountDataDeletion: {
            throw MomentAccountLocalDataDeletionError.testFailure
        }
    )

    await account.loadAuthSession()
    account.requestAccountDeletion()
    await account.confirmAccountDeletion()

    #expect(account.isSignedIn == false)
    #expect(try await store.loadSession() == nil)
    #expect(await maintenanceClient.deletedTokens() == ["delete-token"])
    #expect(account.notice?.title == "Account deleted. Some local data may remain.")
}

@Test
@MainActor
func indeterminateAccountDeletionClearsLocalStateWithTruthfulRetryCopy() async throws {
    let session = AuthSession.test(accessToken: "delete-token")
    let store = MomentAccountInMemoryAuthSessionStore(session: session)
    let maintenanceClient = MomentAccountMaintenanceClient(outcome: .indeterminate)
    var didDeleteLocalData = false
    let account = makeAccount(
        store: store,
        authClient: MomentAccountAuthClient(),
        accountMaintenanceClient: maintenanceClient,
        localAccountDataDeletion: {
            didDeleteLocalData = true
        }
    )

    await account.loadAuthSession()
    account.requestAccountDeletion()
    await account.confirmAccountDeletion()

    #expect(account.isSignedIn == false)
    #expect(try await store.loadSession() == nil)
    #expect(didDeleteLocalData)
    #expect(account.notice?.title == "Deletion is still being finalized. ProsePal data was removed from this device. If you can still sign in, retry deletion.")
}

@Test
@MainActor
func accountDeletionFailurePreservesSignedInState() async {
    let session = AuthSession.test(accessToken: "delete-token")
    let maintenanceClient = MomentAccountMaintenanceClient(error: AccountMaintenanceError.requestFailed(
        statusCode: 500,
        message: "Account deletion failed safely."
    ))
    let account = makeAccount(
        store: MomentAccountInMemoryAuthSessionStore(session: session),
        authClient: MomentAccountAuthClient(),
        accountMaintenanceClient: maintenanceClient
    )

    await account.loadAuthSession()
    account.requestAccountDeletion()
    await account.confirmAccountDeletion()

    #expect(account.isSignedIn)
    #expect(account.notice?.title == "Account deletion failed safely.")
}

@MainActor
private func makeAccount(
    store: MomentAccountInMemoryAuthSessionStore = MomentAccountInMemoryAuthSessionStore(),
    authClient: (any AuthClient)? = nil,
    appleAccountLifecycleClient: (any AppleAccountLifecycleClient)? = nil,
    appleCredentialStateProvider: (any AppleCredentialStateProviding)? = nil,
    subscriptionClient: (any SubscriptionClient)? = nil,
    accountMaintenanceClient: (any AccountMaintenanceClient)? = nil,
    localAccountDataDeletion: (@MainActor () async throws -> Void)? = nil
) -> MomentAccountModel {
    let authSessionController = AuthSessionController(
        store: store,
        authClient: authClient
    )
    return MomentAccountModel(
        clientContext: ClientContext(appVersion: "1.0", buildNumber: "1"),
        authSessionController: authSessionController,
        authClient: authClient,
        appleAccountLifecycleClient: appleAccountLifecycleClient ??
            (authClient == nil ? nil : MomentAccountAppleLifecycleClient()),
        appleCredentialStateProvider: appleCredentialStateProvider,
        subscriptionClient: subscriptionClient,
        accountMaintenanceClient: accountMaintenanceClient,
        localAccountDataDeletion: localAccountDataDeletion
    )
}

private enum MomentAccountLocalDataDeletionError: Error {
    case testFailure
}

private enum MomentAccountSessionStoreError: Error {
    case testFailure
}

private actor MomentAccountInMemoryAuthSessionStore: AuthSessionStore {
    private var session: AuthSession?
    private let clearError: (any Error)?

    init(session: AuthSession? = nil, clearError: (any Error)? = nil) {
        self.session = session
        self.clearError = clearError
    }

    func loadSession() async throws -> AuthSession? {
        session
    }

    func saveSession(_ session: AuthSession) async throws {
        self.session = session
    }

    func clearSession() async throws {
        if let clearError {
            throw clearError
        }
        session = nil
    }
}

private actor MomentAccountAuthClient: AuthClient {
    private let session: AuthSession
    private let signInError: (any Error)?
    private let refreshError: (any Error)?
    private var recordedSignOutTokens: [String] = []
    private var recordedRefreshCallCount = 0

    init(
        session: AuthSession = .test(
            accessToken: "access-token",
            userID: "user-1",
            email: "user@example.com"
        ),
        signInError: (any Error)? = nil,
        refreshError: (any Error)? = nil
    ) {
        self.session = session
        self.signInError = signInError
        self.refreshError = refreshError
    }

    func signInWithIDToken(
        provider: AuthProvider,
        idToken: String,
        nonce: String?
    ) async throws -> AuthSession {
        if let signInError {
            throw signInError
        }

        return session
    }

    func refreshSession(_ session: AuthSession) async throws -> AuthSession {
        recordedRefreshCallCount += 1
        if let refreshError {
            throw refreshError
        }

        return self.session
    }

    func signOut(accessToken: String) async throws {
        recordedSignOutTokens.append(accessToken)
    }

    func signOutTokens() -> [String] {
        recordedSignOutTokens
    }

    func refreshCallCount() -> Int {
        recordedRefreshCallCount
    }
}

private struct MomentAccountAppleLifecycleExchange: Equatable, Sendable {
    var authorizationCode: String
    var appleUserID: String
    var accessToken: String
}

private actor MomentAccountAppleLifecycleClient: AppleAccountLifecycleClient {
    private var errors: [AppleAccountLifecycleError]
    private var recordedExchanges: [MomentAccountAppleLifecycleExchange] = []

    init(errors: [AppleAccountLifecycleError] = []) {
        self.errors = errors
    }

    func storeRevocationMaterial(
        authorizationCode: String,
        appleUserID: String,
        accessToken: String
    ) async throws {
        recordedExchanges.append(MomentAccountAppleLifecycleExchange(
            authorizationCode: authorizationCode,
            appleUserID: appleUserID,
            accessToken: accessToken
        ))
        if !errors.isEmpty {
            throw errors.removeFirst()
        }
    }

    func exchanges() -> [MomentAccountAppleLifecycleExchange] {
        recordedExchanges
    }
}

private final class MomentAccountAppleCredentialStateProvider: AppleCredentialStateProviding, @unchecked Sendable {
    private let stateStore: MomentAccountAppleCredentialStateStore
    private let stream: AsyncStream<Void>
    private let continuation: AsyncStream<Void>.Continuation

    init(state: AppleCredentialState) {
        self.stateStore = MomentAccountAppleCredentialStateStore(state: state)
        (stream, continuation) = AsyncStream.makeStream()
    }

    func credentialState(forUserID userID: String) async throws -> AppleCredentialState {
        await stateStore.value()
    }

    func revocationEvents() -> AsyncStream<Void> {
        stream
    }

    func setState(_ state: AppleCredentialState) async {
        await stateStore.set(state)
    }

    func sendRevocationEvent() {
        continuation.yield(())
    }
}

private actor MomentAccountAppleCredentialStateStore {
    private var state: AppleCredentialState

    init(state: AppleCredentialState) {
        self.state = state
    }

    func value() -> AppleCredentialState {
        state
    }

    func set(_ state: AppleCredentialState) {
        self.state = state
    }
}

private actor MomentAccountSubscriptionClient: SubscriptionClient {
    private var products: [SubscriptionProduct]
    private var entitlement: SubscriptionEntitlement
    private var entitlementState: SubscriptionEntitlementState?
    private var purchaseResult: SubscriptionPurchaseResult
    private var restoreResult: SubscriptionPurchaseResult
    private var loadProductsError: (any Error)?
    private var currentEntitlementError: (any Error)?
    private let currentEntitlementDelay: Duration?
    private var purchaseError: (any Error)?
    private var restoreError: (any Error)?
    private var recordedLoadProductsCallCount = 0
    private var recordedPurchasedProductIDs: [String] = []
    private var recordedCurrentEntitlementCallCount = 0
    private var activeCurrentEntitlementCallCount = 0
    private var recordedMaximumConcurrentEntitlementCallCount = 0
    private var transactionUpdatesStream: AsyncStream<SubscriptionTransactionUpdate>?
    private var transactionUpdatesContinuation: AsyncStream<SubscriptionTransactionUpdate>.Continuation?
    private var pendingTransactionUpdates: [SubscriptionTransactionUpdate] = []
    private var recordedTransactionUpdatesCallCount = 0

    init(
        products: [SubscriptionProduct] = [],
        entitlement: SubscriptionEntitlement = .inactive,
        entitlementState: SubscriptionEntitlementState? = nil,
        purchaseResult: SubscriptionPurchaseResult = SubscriptionPurchaseResult(status: .notEntitled),
        restoreResult: SubscriptionPurchaseResult = SubscriptionPurchaseResult(status: .notEntitled),
        loadProductsError: (any Error)? = nil,
        currentEntitlementError: (any Error)? = nil,
        currentEntitlementDelay: Duration? = nil,
        purchaseError: (any Error)? = nil,
        restoreError: (any Error)? = nil
    ) {
        self.products = products
        self.entitlement = entitlement
        self.entitlementState = entitlementState
        self.purchaseResult = purchaseResult
        self.restoreResult = restoreResult
        self.loadProductsError = loadProductsError
        self.currentEntitlementError = currentEntitlementError
        self.currentEntitlementDelay = currentEntitlementDelay
        self.purchaseError = purchaseError
        self.restoreError = restoreError
    }

    func loadProducts() async throws -> [SubscriptionProduct] {
        recordedLoadProductsCallCount += 1
        if let loadProductsError {
            throw loadProductsError
        }

        return products
    }

    func currentEntitlement() async -> SubscriptionEntitlementState {
        recordedCurrentEntitlementCallCount += 1
        activeCurrentEntitlementCallCount += 1
        recordedMaximumConcurrentEntitlementCallCount = max(
            recordedMaximumConcurrentEntitlementCallCount,
            activeCurrentEntitlementCallCount
        )
        defer { activeCurrentEntitlementCallCount -= 1 }
        if let currentEntitlementDelay {
            try? await Task.sleep(for: currentEntitlementDelay)
        }
        if let error = currentEntitlementError as? SubscriptionError {
            return .unknown(error.entitlementFailure)
        }
        if currentEntitlementError != nil {
            return .unknown(.unexpectedResponse)
        }

        return entitlementState ?? (entitlement.isActive ? .active(entitlement) : .inactive)
    }

    func purchase(productID: String) async throws -> SubscriptionPurchaseResult {
        recordedPurchasedProductIDs.append(productID)
        if let purchaseError {
            throw purchaseError
        }

        return purchaseResult
    }

    func restorePurchases() async throws -> SubscriptionPurchaseResult {
        if let restoreError {
            throw restoreError
        }

        return restoreResult
    }

    func transactionUpdates() async -> AsyncStream<SubscriptionTransactionUpdate> {
        recordedTransactionUpdatesCallCount += 1
        if let transactionUpdatesStream {
            return transactionUpdatesStream
        }

        let (stream, continuation) = AsyncStream<SubscriptionTransactionUpdate>.makeStream()
        transactionUpdatesStream = stream
        transactionUpdatesContinuation = continuation
        for update in pendingTransactionUpdates {
            continuation.yield(update)
        }
        pendingTransactionUpdates.removeAll()
        return stream
    }

    func setRestoreResult(_ result: SubscriptionPurchaseResult) {
        restoreResult = result
    }

    func setEntitlement(_ entitlement: SubscriptionEntitlement) {
        self.entitlement = entitlement
        entitlementState = nil
        currentEntitlementError = nil
    }

    func setEntitlementState(_ state: SubscriptionEntitlementState) {
        entitlementState = state
        currentEntitlementError = nil
    }

    func setEntitlementError(_ error: any Error) {
        currentEntitlementError = error
    }

    func emitTransactionUpdate(_ update: SubscriptionTransactionUpdate) {
        if let transactionUpdatesContinuation {
            transactionUpdatesContinuation.yield(update)
        } else {
            pendingTransactionUpdates.append(update)
        }
    }

    func loadProductsCallCount() -> Int {
        recordedLoadProductsCallCount
    }

    func purchasedProductIDs() -> [String] {
        recordedPurchasedProductIDs
    }

    func currentEntitlementCallCount() -> Int {
        recordedCurrentEntitlementCallCount
    }

    func maximumConcurrentEntitlementCallCount() -> Int {
        recordedMaximumConcurrentEntitlementCallCount
    }

    func transactionUpdatesCallCount() -> Int {
        recordedTransactionUpdatesCallCount
    }
}

private actor MomentAccountTransactionFinishRecorder {
    private var count = 0

    func recordFinish() {
        count += 1
    }

    func finishCount() -> Int {
        count
    }
}

private actor MomentAccountMaintenanceClient: AccountMaintenanceClient {
    private let error: (any Error)?
    private let outcome: AccountDeletionOutcome
    private var tokens: [String] = []

    init(
        outcome: AccountDeletionOutcome = .deleted,
        error: (any Error)? = nil
    ) {
        self.outcome = outcome
        self.error = error
    }

    func deleteAccount(accessToken: String) async throws -> AccountDeletionOutcome {
        if let error {
            throw error
        }

        tokens.append(accessToken)
        return outcome
    }

    func deletedTokens() -> [String] {
        tokens
    }
}

private extension AuthSession {
    static func test(
        accessToken: String,
        refreshToken: String = "refresh-token",
        expiresAt: Date = Date(timeIntervalSince1970: 2_000_000_000),
        userID: String = "user-1",
        email: String? = "user@example.com",
        appleCredentialUserID: String? = nil
    ) -> AuthSession {
        AuthSession(
            accessToken: accessToken,
            refreshToken: refreshToken,
            expiresAt: expiresAt,
            user: AuthUser(id: userID, email: email),
            appleCredentialUserID: appleCredentialUserID
        )
    }
}

private extension SubscriptionProduct {
    static func weekly(isRecommended: Bool = false) -> SubscriptionProduct {
        SubscriptionProduct(
            id: "com.prosepal.pro.weekly",
            displayName: "Weekly",
            displayPrice: "$1.99",
            durationLabel: "Every 1 week",
            isRecommended: isRecommended
        )
    }

    static func monthly(isRecommended: Bool = false) -> SubscriptionProduct {
        SubscriptionProduct(
            id: "com.prosepal.pro.monthly",
            displayName: "Monthly",
            displayPrice: "$4.99",
            durationLabel: "Every 1 month",
            isRecommended: isRecommended
        )
    }

    static func yearly(isRecommended: Bool = false) -> SubscriptionProduct {
        SubscriptionProduct(
            id: "com.prosepal.pro.yearly",
            displayName: "Yearly",
            displayPrice: "$39.99",
            durationLabel: "Every 1 year",
            isRecommended: isRecommended
        )
    }
}
