import XCTest
import ProsePalAPI
import ProsePalDomain
@testable import ProsePalUI

@MainActor
final class AuthPurchaseFlowTests: XCTestCase {
    func testSignedOutStandardGenerationCanReachResults() async {
        let model = makeModel(
            client: MockMessageWritingClient(
                response: CardResponse(
                    messages: [GeneratedMessage(id: "draft-1", text: "A thoughtful draft.")],
                    laneUsed: .standard,
                    fallbackStatus: .none,
                    usage: UsageSummary(remaining: 2, limit: 3)
                )
            )
        )

        await model.generate()

        XCTAssertTrue(model.isShowingResults)
        XCTAssertFalse(model.isShowingPaywall)
        XCTAssertEqual(model.generatedMessages.count, 1)
        XCTAssertEqual(model.usageStatus.standardRemaining, 2)
    }

    func testPremiumSelectionOpensPaywallWithoutChangingGenerationLane() {
        let model = makeModel()

        model.selectLane(.premium)

        XCTAssertTrue(model.isShowingPaywall)
        XCTAssertEqual(model.draft.requestedLane, .standard)
        XCTAssertFalse(model.usageStatus.isPremiumUnlocked)
    }

    func testSubscriptionProductsLoadAndSelectRecommendedPlan() async {
        let subscriptionClient = FlowSubscriptionClient(
            products: [
                SubscriptionProduct(id: "monthly", displayName: "Monthly", displayPrice: "$4.99", durationLabel: "Every 1 month"),
                SubscriptionProduct(id: "yearly", displayName: "Yearly", displayPrice: "$39.99", durationLabel: "Every 1 year", isRecommended: true)
            ]
        )
        let model = makeModel(subscriptionClient: subscriptionClient)

        await model.loadSubscriptionProducts(source: "paywall")

        XCTAssertEqual(model.subscriptionProducts.map(\.id), ["monthly", "yearly"])
        XCTAssertEqual(model.selectedSubscriptionProductID, "yearly")
        XCTAssertFalse(model.isLoadingSubscriptions)
        XCTAssertNil(model.subscriptionErrorMessage)
        let loadProductsCallCount = await subscriptionClient.loadProductsCalls()
        XCTAssertEqual(loadProductsCallCount, 1)
    }

    func testEmptySubscriptionProductsShowUnavailableState() async {
        let subscriptionClient = FlowSubscriptionClient(products: [])
        let model = makeModel(subscriptionClient: subscriptionClient)

        await model.loadSubscriptionProducts(source: "paywall")

        XCTAssertTrue(model.subscriptionProducts.isEmpty)
        XCTAssertNil(model.selectedSubscriptionProductID)
        XCTAssertEqual(model.subscriptionErrorMessage, SubscriptionError.productsUnavailable.userSafeMessage)
        XCTAssertFalse(model.isLoadingSubscriptions)
    }

    func testSubscriptionProductLoadFailureClearsStaleSelection() async {
        let subscriptionClient = FlowSubscriptionClient(
            products: [
                SubscriptionProduct(id: "yearly", displayName: "Yearly", displayPrice: "$39.99", isRecommended: true)
            ]
        )
        let model = makeModel(subscriptionClient: subscriptionClient)
        await model.loadSubscriptionProducts(source: "paywall")
        XCTAssertEqual(model.selectedSubscriptionProductID, "yearly")

        await subscriptionClient.setLoadProductsError(.storeUnavailable)
        await model.loadSubscriptionProducts(source: "paywall_retry")

        XCTAssertTrue(model.subscriptionProducts.isEmpty)
        XCTAssertNil(model.selectedSubscriptionProductID)
        XCTAssertEqual(model.subscriptionErrorMessage, SubscriptionError.storeUnavailable.userSafeMessage)
    }

    func testPurchaseAutoLoadsProductsBeforeStartingStorePurchase() async {
        let subscriptionClient = FlowSubscriptionClient(
            products: [
                SubscriptionProduct(id: "yearly", displayName: "Yearly", displayPrice: "$39.99", isRecommended: true)
            ],
            purchaseResult: SubscriptionPurchaseResult(
                status: .purchased,
                entitlement: SubscriptionEntitlement(isActive: true, productID: "yearly")
            )
        )
        let model = makeModel(subscriptionClient: subscriptionClient)
        model.isShowingPaywall = true

        await model.purchasePremium(source: "paywall")

        let loadProductsCallCount = await subscriptionClient.loadProductsCalls()
        let purchasedProductIDs = await subscriptionClient.purchasedProducts()
        XCTAssertEqual(loadProductsCallCount, 1)
        XCTAssertEqual(purchasedProductIDs, ["yearly"])
        XCTAssertTrue(model.usageStatus.isPremiumUnlocked)
        XCTAssertFalse(model.isShowingPaywall)
    }

    func testCancelledPurchaseDoesNotUnlockOrClosePaywall() async {
        let subscriptionClient = FlowSubscriptionClient(
            products: [
                SubscriptionProduct(id: "monthly", displayName: "Monthly", displayPrice: "$4.99")
            ],
            purchaseResult: SubscriptionPurchaseResult(status: .cancelled)
        )
        let model = makeModel(subscriptionClient: subscriptionClient)
        model.isShowingPaywall = true

        await model.loadSubscriptionProducts(source: "paywall")
        await model.purchasePremium(source: "paywall")

        XCTAssertFalse(model.usageStatus.isPremiumUnlocked)
        XCTAssertTrue(model.isShowingPaywall)
        XCTAssertEqual(model.notice?.title, "Purchase cancelled")
    }

    func testPendingPurchaseDoesNotUnlockOrClosePaywall() async {
        let subscriptionClient = FlowSubscriptionClient(
            products: [
                SubscriptionProduct(id: "monthly", displayName: "Monthly", displayPrice: "$4.99")
            ],
            purchaseResult: SubscriptionPurchaseResult(status: .pending)
        )
        let model = makeModel(subscriptionClient: subscriptionClient)
        model.isShowingPaywall = true

        await model.loadSubscriptionProducts(source: "paywall")
        await model.purchasePremium(source: "paywall")

        XCTAssertFalse(model.usageStatus.isPremiumUnlocked)
        XCTAssertTrue(model.isShowingPaywall)
        XCTAssertEqual(model.notice?.title, "Purchase pending approval")
    }

    func testPurchaseFailureResetsPurchasingStateAndShowsSafeError() async {
        let subscriptionClient = FlowSubscriptionClient(
            products: [
                SubscriptionProduct(id: "monthly", displayName: "Monthly", displayPrice: "$4.99")
            ],
            purchaseError: .verificationFailed
        )
        let model = makeModel(subscriptionClient: subscriptionClient)

        await model.loadSubscriptionProducts(source: "paywall")
        await model.purchasePremium(source: "paywall")

        XCTAssertFalse(model.isPurchasingPremium)
        XCTAssertFalse(model.usageStatus.isPremiumUnlocked)
        XCTAssertEqual(model.subscriptionErrorMessage, SubscriptionError.verificationFailed.userSafeMessage)
    }

    func testPurchasedStatusWithoutActiveEntitlementDoesNotUnlockOrClosePaywall() async {
        let subscriptionClient = FlowSubscriptionClient(
            products: [
                SubscriptionProduct(id: "yearly", displayName: "Yearly", displayPrice: "$39.99", isRecommended: true)
            ],
            purchaseResult: SubscriptionPurchaseResult(status: .purchased, entitlement: .inactive)
        )
        let model = makeModel(subscriptionClient: subscriptionClient)
        model.isShowingPaywall = true

        await model.loadSubscriptionProducts(source: "paywall")
        await model.purchasePremium(source: "paywall")

        XCTAssertFalse(model.usageStatus.isPremiumUnlocked)
        XCTAssertTrue(model.isShowingPaywall)
        XCTAssertEqual(model.subscriptionErrorMessage, SubscriptionError.verificationFailed.userSafeMessage)
        XCTAssertEqual(model.notice?.title, "Purchase needs verification")
    }

    func testRestoreWithActiveEntitlementUnlocksAndClosesPaywall() async {
        let subscriptionClient = FlowSubscriptionClient(
            restoreResult: SubscriptionPurchaseResult(
                status: .restored,
                entitlement: SubscriptionEntitlement(isActive: true, productID: "yearly")
            )
        )
        let model = makeModel(subscriptionClient: subscriptionClient)
        model.isShowingPaywall = true

        await model.restorePurchases(source: "paywall")

        let restoreCallCount = await subscriptionClient.restoreCalls()
        XCTAssertEqual(restoreCallCount, 1)
        XCTAssertTrue(model.usageStatus.isPremiumUnlocked)
        XCTAssertFalse(model.isShowingPaywall)
        XCTAssertEqual(model.notice?.title, "Premium restored")
    }

    func testRestoreWithoutEntitlementLeavesPremiumLocked() async {
        let subscriptionClient = FlowSubscriptionClient(
            restoreResult: SubscriptionPurchaseResult(status: .notEntitled)
        )
        let model = makeModel(subscriptionClient: subscriptionClient)
        model.isShowingPaywall = true

        await model.restorePurchases(source: "settings")

        let restoreCallCount = await subscriptionClient.restoreCalls()
        XCTAssertEqual(restoreCallCount, 1)
        XCTAssertFalse(model.usageStatus.isPremiumUnlocked)
        XCTAssertTrue(model.isShowingPaywall)
        XCTAssertEqual(model.notice?.title, "No active subscription found")
    }

    func testRestoreWithoutEntitlementClearsStalePremiumUi() async {
        let subscriptionClient = FlowSubscriptionClient(
            restoreResult: SubscriptionPurchaseResult(status: .notEntitled)
        )
        let model = makeModel(
            usageStatus: UsageStatus(isPremiumUnlocked: true),
            subscriptionClient: subscriptionClient
        )

        await model.restorePurchases(source: "settings")

        XCTAssertFalse(model.usageStatus.isPremiumUnlocked)
        XCTAssertEqual(model.notice?.title, "No active subscription found")
    }

    func testRestoreFailureResetsRestoreStateAndShowsSafeError() async {
        let subscriptionClient = FlowSubscriptionClient(restoreError: .storeUnavailable)
        let model = makeModel(subscriptionClient: subscriptionClient)

        await model.restorePurchases(source: "settings")

        XCTAssertFalse(model.isRestoringPurchases)
        XCTAssertFalse(model.usageStatus.isPremiumUnlocked)
        XCTAssertEqual(model.subscriptionErrorMessage, SubscriptionError.storeUnavailable.userSafeMessage)
    }

    func testAppleSignInStartIsSingleFlightAndCancellationClearsState() {
        let model = makeModel(
            authSessionController: AuthSessionController(store: FlowAuthSessionStore()),
            authClient: FlowAuthClient(session: AuthSession(accessToken: "unused"))
        )

        let firstNonce = model.beginAppleSignInRequest(source: "settings")
        let secondNonce = model.beginAppleSignInRequest(source: "settings")
        XCTAssertNotNil(firstNonce)
        XCTAssertNil(secondNonce)
        XCTAssertTrue(model.isSigningIn)

        model.cancelAppleSignIn(source: "settings")

        XCTAssertFalse(model.isSigningIn)
        XCTAssertFalse(model.isSignedIn)
    }

    func testAppleSignInMissingTokenDoesNotCreateSession() async throws {
        let store = FlowAuthSessionStore()
        let model = makeModel(
            authSessionController: AuthSessionController(store: store),
            authClient: FlowAuthClient(session: AuthSession(accessToken: "unused"))
        )

        XCTAssertNotNil(model.beginAppleSignInRequest(source: "settings"))
        await model.completeAppleSignIn(idToken: nil, source: "settings")

        XCTAssertFalse(model.isSigningIn)
        XCTAssertFalse(model.isSignedIn)
        let storedSession = try await store.loadSession()
        XCTAssertNil(storedSession)
        XCTAssertEqual(model.notice?.title, AuthError.missingIdentityToken.userSafeMessage)
    }

    func testAppleSignInFailureDoesNotCreateFakeSignedInState() async throws {
        let store = FlowAuthSessionStore()
        let authClient = FlowAuthClient(error: .invalidResponse)
        let model = makeModel(
            authSessionController: AuthSessionController(store: store),
            authClient: authClient
        )

        XCTAssertNotNil(model.beginAppleSignInRequest(source: "settings"))
        await model.completeAppleSignIn(idToken: "apple-id-token", source: "settings")

        XCTAssertFalse(model.isSigningIn)
        XCTAssertFalse(model.isSignedIn)
        let storedSession = try await store.loadSession()
        XCTAssertNil(storedSession)
        XCTAssertEqual(model.notice?.title, AuthError.invalidResponse.userSafeMessage)
    }

    func testAppleSignInFailurePreservesExistingSignedInSession() async throws {
        let store = FlowAuthSessionStore(
            session: AuthSession(
                accessToken: "user-a-token",
                user: AuthUser(id: "user-a", email: "a@example.com")
            )
        )
        let authClient = FlowAuthClient(error: .invalidResponse)
        let model = makeModel(
            usageStatus: UsageStatus(isPremiumUnlocked: true),
            authSessionController: AuthSessionController(store: store),
            authClient: authClient
        )

        await model.loadAuthSession()
        XCTAssertTrue(model.isSignedIn)
        XCTAssertEqual(model.signedInUserID, "user-a")

        XCTAssertNotNil(model.beginAppleSignInRequest(source: "settings"))
        await model.completeAppleSignIn(idToken: "apple-id-token", source: "settings")

        let storedSession = try await store.loadSession()
        XCTAssertTrue(model.isSignedIn)
        XCTAssertEqual(model.signedInUserID, "user-a")
        XCTAssertEqual(storedSession?.accessToken, "user-a-token")
        XCTAssertTrue(model.usageStatus.isPremiumUnlocked)
        XCTAssertEqual(model.notice?.title, AuthError.invalidResponse.userSafeMessage)
    }

    func testAppleSignInSuccessPersistsSessionAndUserIdentity() async throws {
        let store = FlowAuthSessionStore()
        let authClient = FlowAuthClient(
            session: AuthSession(
                accessToken: "supabase-access-token",
                user: AuthUser(id: "user-1", email: "user@example.com")
            )
        )
        let model = makeModel(
            authSessionController: AuthSessionController(store: store),
            authClient: authClient
        )

        XCTAssertNotNil(model.beginAppleSignInRequest(source: "settings"))
        await model.completeAppleSignIn(idToken: "apple-id-token", source: "settings")

        let storedSession = try await store.loadSession()
        let signInRequests = await authClient.recordedSignInRequests()
        XCTAssertEqual(signInRequests.count, 1)
        XCTAssertEqual(storedSession?.accessToken, "supabase-access-token")
        XCTAssertTrue(model.isSignedIn)
        XCTAssertEqual(model.signedInUserID, "user-1")
        XCTAssertEqual(model.signedInEmail, "user@example.com")
    }

    func testSignOutClearsSignedInStateBiometricAndPremiumUi() async throws {
        let store = FlowAuthSessionStore(
            session: AuthSession(
                accessToken: "saved-token",
                user: AuthUser(id: "user-1", email: "user@example.com")
            )
        )
        let authClient = FlowAuthClient(session: AuthSession(accessToken: "unused"))
        let model = makeModel(
            usageStatus: UsageStatus(isPremiumUnlocked: true),
            authSessionController: AuthSessionController(store: store),
            authClient: authClient
        )

        await model.loadAuthSession()
        model.setBiometricLockEnabled(true)
        XCTAssertTrue(model.usageStatus.isPremiumUnlocked)

        await model.signOut()

        XCTAssertFalse(model.isSignedIn)
        XCTAssertNil(model.signedInUserID)
        XCTAssertNil(model.signedInEmail)
        XCTAssertFalse(model.biometricLockEnabled)
        XCTAssertFalse(model.usageStatus.isPremiumUnlocked)
        let clearedSession = try await store.loadSession()
        let signOutTokens = await authClient.recordedSignOutTokens()
        XCTAssertNil(clearedSession)
        XCTAssertEqual(signOutTokens, ["saved-token"])
    }

    func testAccountSwitchClearsStalePremiumUiUntilEntitlementRefresh() async throws {
        let store = FlowAuthSessionStore(
            session: AuthSession(
                accessToken: "user-a-token",
                user: AuthUser(id: "user-a", email: "a@example.com")
            )
        )
        let authClient = FlowAuthClient(
            session: AuthSession(
                accessToken: "user-b-token",
                user: AuthUser(id: "user-b", email: "b@example.com")
            )
        )
        let model = makeModel(
            usageStatus: UsageStatus(isPremiumUnlocked: true),
            authSessionController: AuthSessionController(store: store),
            authClient: authClient
        )

        await model.loadAuthSession()
        XCTAssertEqual(model.signedInUserID, "user-a")
        XCTAssertTrue(model.usageStatus.isPremiumUnlocked)

        XCTAssertNotNil(model.beginAppleSignInRequest(source: "settings"))
        await model.completeAppleSignIn(idToken: "apple-id-token", source: "settings")

        XCTAssertEqual(model.signedInUserID, "user-b")
        XCTAssertFalse(model.usageStatus.isPremiumUnlocked)
        let switchedSession = try await store.loadSession()
        XCTAssertEqual(switchedSession?.accessToken, "user-b-token")
    }

    private func makeModel(
        client: MessageWritingClient? = nil,
        usageStatus: UsageStatus = UsageStatus(),
        authSessionController: AuthSessionController? = nil,
        authClient: (any AuthClient)? = nil,
        subscriptionClient: (any SubscriptionClient)? = nil
    ) -> ProsePalAppModel {
        ProsePalAppModel(
            client: client ?? MockMessageWritingClient(
                response: CardResponse(
                    messages: [GeneratedMessage(id: "draft-1", text: "A draft.")],
                    laneUsed: .standard
                )
            ),
            clientContext: ClientContext(appVersion: "0.0.0", buildNumber: "1"),
            usageStatus: usageStatus,
            authSessionController: authSessionController,
            authClient: authClient,
            subscriptionClient: subscriptionClient
        )
    }
}

private actor FlowAuthSessionStore: AuthSessionStore {
    private var session: AuthSession?

    init(session: AuthSession? = nil) {
        self.session = session
    }

    func loadSession() async throws -> AuthSession? {
        session
    }

    func saveSession(_ session: AuthSession) async throws {
        self.session = session
    }

    func clearSession() async throws {
        session = nil
    }
}

private actor FlowAuthClient: AuthClient {
    struct SignInRequest: Equatable {
        var provider: AuthProvider
        var idToken: String
        var nonce: String?
    }

    private let session: AuthSession?
    private let error: AuthError?
    private(set) var signInRequests: [SignInRequest] = []
    private(set) var signOutTokens: [String] = []

    init(session: AuthSession? = nil, error: AuthError? = nil) {
        self.session = session
        self.error = error
    }

    func signInWithIDToken(
        provider: AuthProvider,
        idToken: String,
        nonce: String?
    ) async throws -> AuthSession {
        signInRequests.append(SignInRequest(provider: provider, idToken: idToken, nonce: nonce))
        if let error {
            throw error
        }
        guard let session else {
            throw AuthError.invalidResponse
        }
        return session
    }

    func signOut(accessToken: String) async throws {
        signOutTokens.append(accessToken)
    }

    func recordedSignInRequests() -> [SignInRequest] {
        signInRequests
    }

    func recordedSignOutTokens() -> [String] {
        signOutTokens
    }
}

private actor FlowSubscriptionClient: SubscriptionClient {
    private var products: [SubscriptionProduct]
    private var loadProductsError: SubscriptionError?
    private let purchaseResult: SubscriptionPurchaseResult
    private let purchaseError: SubscriptionError?
    private let restoreResult: SubscriptionPurchaseResult
    private let restoreError: SubscriptionError?
    private(set) var loadProductsCallCount = 0
    private(set) var purchasedProductIDs: [String] = []
    private(set) var restoreCallCount = 0

    init(
        products: [SubscriptionProduct] = [],
        loadProductsError: SubscriptionError? = nil,
        purchaseResult: SubscriptionPurchaseResult = SubscriptionPurchaseResult(status: .cancelled),
        purchaseError: SubscriptionError? = nil,
        restoreResult: SubscriptionPurchaseResult = SubscriptionPurchaseResult(status: .notEntitled),
        restoreError: SubscriptionError? = nil
    ) {
        self.products = products
        self.loadProductsError = loadProductsError
        self.purchaseResult = purchaseResult
        self.purchaseError = purchaseError
        self.restoreResult = restoreResult
        self.restoreError = restoreError
    }

    func setLoadProductsError(_ error: SubscriptionError?) {
        loadProductsError = error
    }

    func loadProductsCalls() -> Int {
        loadProductsCallCount
    }

    func purchasedProducts() -> [String] {
        purchasedProductIDs
    }

    func restoreCalls() -> Int {
        restoreCallCount
    }

    func loadProducts() async throws -> [SubscriptionProduct] {
        loadProductsCallCount += 1
        if let loadProductsError {
            throw loadProductsError
        }
        return products
    }

    func currentEntitlement() async throws -> SubscriptionEntitlement {
        purchaseResult.entitlement.isActive ? purchaseResult.entitlement : restoreResult.entitlement
    }

    func purchase(productID: String) async throws -> SubscriptionPurchaseResult {
        purchasedProductIDs.append(productID)
        if let purchaseError {
            throw purchaseError
        }
        return purchaseResult
    }

    func restorePurchases() async throws -> SubscriptionPurchaseResult {
        restoreCallCount += 1
        if let restoreError {
            throw restoreError
        }
        return restoreResult
    }
}
