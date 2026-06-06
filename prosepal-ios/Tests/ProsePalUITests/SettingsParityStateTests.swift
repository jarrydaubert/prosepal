import XCTest
import ProsePalAPI
import ProsePalDomain
@testable import ProsePalUI

@MainActor
final class SettingsParityStateTests: XCTestCase {
    func testAppleSignInWhenUnconfiguredDoesNotFakeSignedInState() {
        let model = makeModel()

        let nonce = model.beginAppleSignInRequest(source: "settings")

        XCTAssertNil(nonce)
        XCTAssertFalse(model.isSignedIn)
        XCTAssertNotNil(model.notice)
    }

    func testLoadPersistedAuthSessionUpdatesSignedInState() async throws {
        let store = InMemoryAuthSessionStore(
            session: AuthSession(
                accessToken: "saved-token",
                user: AuthUser(id: "user-1", email: "user@example.com")
            )
        )
        let model = makeModel(
            authSessionController: AuthSessionController(store: store),
            authClient: RecordingAuthClient(session: AuthSession(accessToken: "unused"))
        )

        await model.loadAuthSession()

        XCTAssertTrue(model.isSignedIn)
        XCTAssertEqual(model.signedInEmail, "user@example.com")
    }

    func testCompletingAppleSignInStoresSessionAndMarksSignedIn() async throws {
        let store = InMemoryAuthSessionStore()
        let authClient = RecordingAuthClient(
            session: AuthSession(
                accessToken: "supabase-access-token",
                user: AuthUser(id: "user-1", email: "user@example.com")
            )
        )
        let model = makeModel(
            authSessionController: AuthSessionController(store: store),
            authClient: authClient
        )

        let nonce = model.beginAppleSignInRequest(source: "settings")
        XCTAssertNotNil(nonce)
        await model.completeAppleSignIn(idToken: "apple-id-token", source: "settings")

        let request = await authClient.signInRequests.first
        let storedSession = try await store.loadSession()
        XCTAssertEqual(request?.provider, .apple)
        XCTAssertEqual(request?.idToken, "apple-id-token")
        XCTAssertNotNil(request?.nonce)
        XCTAssertEqual(storedSession?.accessToken, "supabase-access-token")
        XCTAssertTrue(model.isSignedIn)
        XCTAssertEqual(model.signedInEmail, "user@example.com")
        XCTAssertFalse(model.isSigningIn)
    }

    func testSignOutClearsAuthSessionAndBiometricState() async throws {
        let store = InMemoryAuthSessionStore(
            session: AuthSession(accessToken: "saved-token", user: AuthUser(id: "user-1"))
        )
        let authClient = RecordingAuthClient(session: AuthSession(accessToken: "unused"))
        let model = makeModel(
            authSessionController: AuthSessionController(store: store),
            authClient: authClient
        )

        await model.loadAuthSession()
        model.setBiometricLockEnabled(true)
        XCTAssertTrue(model.isSignedIn)
        XCTAssertTrue(model.biometricLockEnabled)

        await model.signOut()

        let clearedSession = try await store.loadSession()
        let signOutTokens = await authClient.signOutTokens
        XCTAssertFalse(model.isSignedIn)
        XCTAssertFalse(model.biometricLockEnabled)
        XCTAssertNil(clearedSession)
        XCTAssertEqual(signOutTokens, ["saved-token"])
    }

    func testPremiumPurchaseWhenUnconfiguredDoesNotUnlockPremium() async {
        let model = makeModel()

        await model.purchasePremium(source: "paywall")

        XCTAssertFalse(model.usageStatus.isPremiumUnlocked)
        XCTAssertEqual(model.draft.requestedLane, .standard)
        XCTAssertNotNil(model.notice)
    }

    func testLoadingSubscriptionProductsSelectsRecommendedPlan() async {
        let subscriptionClient = RecordingSubscriptionClient(
            products: [
                SubscriptionProduct(id: "monthly", displayName: "Monthly", displayPrice: "$4.99", durationLabel: "Every 1 month"),
                SubscriptionProduct(id: "yearly", displayName: "Yearly", displayPrice: "$39.99", durationLabel: "Every 1 year", isRecommended: true)
            ]
        )
        let model = makeModel(subscriptionClient: subscriptionClient)

        await model.loadSubscriptionProducts(source: "paywall")

        XCTAssertEqual(model.subscriptionProducts.count, 2)
        XCTAssertEqual(model.selectedSubscriptionProductID, "yearly")
        XCTAssertNil(model.subscriptionErrorMessage)
    }

    func testCancelledPremiumPurchaseDoesNotUnlockPremium() async {
        let subscriptionClient = RecordingSubscriptionClient(
            products: [
                SubscriptionProduct(id: "monthly", displayName: "Monthly", displayPrice: "$4.99")
            ],
            purchaseResult: SubscriptionPurchaseResult(status: .cancelled)
        )
        let model = makeModel(subscriptionClient: subscriptionClient)

        await model.loadSubscriptionProducts(source: "paywall")
        await model.purchasePremium(source: "paywall")

        let purchasedProductIDs = await subscriptionClient.purchasedProductIDs
        XCTAssertEqual(purchasedProductIDs, ["monthly"])
        XCTAssertFalse(model.usageStatus.isPremiumUnlocked)
        XCTAssertTrue(model.isShowingPaywall == false || model.notice != nil)
    }

    func testConfirmedPremiumPurchaseUpdatesPremiumState() async {
        let subscriptionClient = RecordingSubscriptionClient(
            products: [
                SubscriptionProduct(id: "yearly", displayName: "Yearly", displayPrice: "$39.99", isRecommended: true)
            ],
            purchaseResult: SubscriptionPurchaseResult(
                status: .purchased,
                entitlement: SubscriptionEntitlement(isActive: true, productID: "yearly")
            )
        )
        let model = makeModel(subscriptionClient: subscriptionClient)

        await model.loadSubscriptionProducts(source: "paywall")
        await model.purchasePremium(source: "paywall")

        XCTAssertTrue(model.usageStatus.isPremiumUnlocked)
        XCTAssertFalse(model.isShowingPaywall)
    }

    func testRestoreWithoutActiveSubscriptionDoesNotUnlockPremium() async {
        let subscriptionClient = RecordingSubscriptionClient(
            restoreResult: SubscriptionPurchaseResult(status: .notEntitled)
        )
        let model = makeModel(subscriptionClient: subscriptionClient)

        await model.restorePurchases(source: "settings")

        XCTAssertFalse(model.usageStatus.isPremiumUnlocked)
        XCTAssertNotNil(model.notice)
    }

    func testSettingsExternalActionsDoNotChangeAccountOrPremiumState() {
        let model = makeModel()

        model.openSettingsLink("support")
        model.openSettingsLink("privacy")
        model.requestAppReview()

        XCTAssertFalse(model.isSignedIn)
        XCTAssertFalse(model.usageStatus.isPremiumUnlocked)
        XCTAssertNil(model.signedInEmail)
    }

    func testBiometricLockRequiresSignedInAccount() {
        let model = makeModel()

        model.setBiometricLockEnabled(true)

        XCTAssertFalse(model.biometricLockEnabled)

        model.isSignedIn = true
        model.setBiometricLockEnabled(true)

        XCTAssertTrue(model.biometricLockEnabled)
    }

    func testSuccessfulGenerationUpdatesDisplayedStats() async {
        let model = makeModel(
            client: MockMessageWritingClient(
                response: CardResponse(
                    messages: [
                        GeneratedMessage(id: "draft-1", text: "A thoughtful draft."),
                        GeneratedMessage(id: "draft-2", text: "Another thoughtful draft.")
                    ],
                    laneUsed: .standard,
                    fallbackStatus: .none
                )
            )
        )

        await model.generate()

        XCTAssertEqual(model.totalGeneratedCount, 2)
    }

    private func makeModel(
        client: MessageWritingClient? = nil,
        authSessionController: AuthSessionController? = nil,
        authClient: (any AuthClient)? = nil,
        subscriptionClient: (any SubscriptionClient)? = nil
    ) -> ProsePalAppModel {
        ProsePalAppModel(
            client: client ?? MockMessageWritingClient(
                response: CardResponse(messages: [], laneUsed: .standard)
            ),
            clientContext: ClientContext(appVersion: "0.0.0", buildNumber: "1"),
            authSessionController: authSessionController,
            authClient: authClient,
            subscriptionClient: subscriptionClient
        )
    }
}

private actor InMemoryAuthSessionStore: AuthSessionStore {
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

private actor RecordingAuthClient: AuthClient {
    struct SignInRequest: Equatable {
        var provider: AuthProvider
        var idToken: String
        var nonce: String?
    }

    private let session: AuthSession
    private(set) var signInRequests: [SignInRequest] = []
    private(set) var signOutTokens: [String] = []

    init(session: AuthSession) {
        self.session = session
    }

    func signInWithIDToken(
        provider: AuthProvider,
        idToken: String,
        nonce: String?
    ) async throws -> AuthSession {
        signInRequests.append(SignInRequest(provider: provider, idToken: idToken, nonce: nonce))
        return session
    }

    func signOut(accessToken: String) async throws {
        signOutTokens.append(accessToken)
    }
}

private actor RecordingSubscriptionClient: SubscriptionClient {
    private let products: [SubscriptionProduct]
    private let entitlement: SubscriptionEntitlement
    private let purchaseResult: SubscriptionPurchaseResult
    private let restoreResult: SubscriptionPurchaseResult
    private(set) var purchasedProductIDs: [String] = []
    private(set) var restoreCallCount = 0

    init(
        products: [SubscriptionProduct] = [],
        entitlement: SubscriptionEntitlement = .inactive,
        purchaseResult: SubscriptionPurchaseResult = SubscriptionPurchaseResult(status: .cancelled),
        restoreResult: SubscriptionPurchaseResult = SubscriptionPurchaseResult(status: .notEntitled)
    ) {
        self.products = products
        self.entitlement = entitlement
        self.purchaseResult = purchaseResult
        self.restoreResult = restoreResult
    }

    func loadProducts() async throws -> [SubscriptionProduct] {
        products
    }

    func currentEntitlement() async throws -> SubscriptionEntitlement {
        entitlement
    }

    func purchase(productID: String) async throws -> SubscriptionPurchaseResult {
        purchasedProductIDs.append(productID)
        return purchaseResult
    }

    func restorePurchases() async throws -> SubscriptionPurchaseResult {
        restoreCallCount += 1
        return restoreResult
    }
}
