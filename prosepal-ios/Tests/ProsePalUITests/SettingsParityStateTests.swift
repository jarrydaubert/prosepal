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

    func testPremiumRenewalDisclosureIncludesSelectedPlanPriceAndPeriod() async {
        let subscriptionClient = RecordingSubscriptionClient(
            products: [
                SubscriptionProduct(id: "monthly", displayName: "Monthly", displayPrice: "$4.99", durationLabel: "Every 1 month"),
                SubscriptionProduct(id: "yearly", displayName: "Yearly", displayPrice: "$39.99", durationLabel: "Every 1 year", isRecommended: true)
            ]
        )
        let model = makeModel(subscriptionClient: subscriptionClient)

        XCTAssertEqual(
            model.premiumRenewalDisclosureText,
            "Choose a plan to continue. Auto-renews. Cancel anytime in App Store settings."
        )

        await model.loadSubscriptionProducts(source: "paywall")

        XCTAssertEqual(model.selectedPremiumPlanDisclosureText, "$39.99 / Every 1 year")
        XCTAssertEqual(
            model.premiumRenewalDisclosureText,
            "Selected plan: $39.99 / Every 1 year. Auto-renews. Cancel anytime in App Store settings."
        )

        model.selectSubscriptionProduct(model.subscriptionProducts[0])

        XCTAssertEqual(model.selectedPremiumPlanDisclosureText, "$4.99 / Every 1 month")
        XCTAssertEqual(
            model.premiumRenewalDisclosureText,
            "Selected plan: $4.99 / Every 1 month. Auto-renews. Cancel anytime in App Store settings."
        )
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

    func testAccountActionsGuideSignedOutUsersWithoutChangingState() {
        let model = makeModel()

        XCTAssertEqual(model.dataExportStatusText, "Sign in before exporting data")
        XCTAssertEqual(model.accountDeletionStatusText, "Sign in before deleting your account")

        model.requestDataExport()
        XCTAssertEqual(model.notice?.title, "Sign in before exporting data")

        model.requestAccountDeletion()
        XCTAssertEqual(model.notice?.title, "Sign in before deleting your account")
        XCTAssertFalse(model.isSignedIn)
    }

    func testAccountActionsDoNotPretendUnavailableSignedInActionsCompleted() {
        let model = makeModel()
        model.isSignedIn = true

        XCTAssertEqual(model.dataExportStatusText, "Export is unavailable right now")
        XCTAssertEqual(model.accountDeletionStatusText, "Deletion is unavailable right now")

        model.requestDataExport()
        XCTAssertEqual(model.notice?.title, "Data export is unavailable right now")

        model.requestAccountDeletion()
        XCTAssertEqual(model.notice?.title, "Account deletion is unavailable right now")
        XCTAssertTrue(model.isSignedIn)
    }

    func testConfiguredAccountDeletionConfirmsThenClearsSignedInState() async throws {
        let store = InMemoryAuthSessionStore(
            session: AuthSession(accessToken: "saved-token", user: AuthUser(id: "user-1", email: "user@example.com"))
        )
        let deletionClient = RecordingAccountMaintenanceClient()
        let model = makeModel(
            authSessionController: AuthSessionController(store: store),
            authClient: RecordingAuthClient(session: AuthSession(accessToken: "unused")),
            accountMaintenanceClient: deletionClient
        )

        await model.loadAuthSession()
        model.usageStatus.isPremiumUnlocked = true
        model.setBiometricLockEnabled(true)

        XCTAssertEqual(model.accountDeletionStatusText, "Delete your account and ProsePal app data")

        model.requestAccountDeletion()

        XCTAssertTrue(model.isConfirmingAccountDeletion)
        XCTAssertTrue(model.isSignedIn)

        await model.confirmAccountDeletion()

        let deletedTokens = await deletionClient.deletedTokens
        let storedSession = try await store.loadSession()
        XCTAssertEqual(deletedTokens, ["saved-token"])
        XCTAssertNil(storedSession)
        XCTAssertFalse(model.isSignedIn)
        XCTAssertFalse(model.usageStatus.isPremiumUnlocked)
        XCTAssertFalse(model.biometricLockEnabled)
        XCTAssertFalse(model.isConfirmingAccountDeletion)
        XCTAssertEqual(model.notice?.title, "Account deleted")
    }

    func testAccountDeletionFailurePreservesSignedInState() async throws {
        let store = InMemoryAuthSessionStore(
            session: AuthSession(accessToken: "saved-token", user: AuthUser(id: "user-1"))
        )
        let deletionClient = RecordingAccountMaintenanceClient(
            error: .requestFailed(statusCode: 500, message: "Connection error. Please try again.")
        )
        let model = makeModel(
            authSessionController: AuthSessionController(store: store),
            authClient: RecordingAuthClient(session: AuthSession(accessToken: "unused")),
            accountMaintenanceClient: deletionClient
        )

        await model.loadAuthSession()
        model.requestAccountDeletion()
        await model.confirmAccountDeletion()

        let deletedTokens = await deletionClient.deletedTokens
        let storedSession = try await store.loadSession()
        XCTAssertEqual(deletedTokens, ["saved-token"])
        XCTAssertNotNil(storedSession)
        XCTAssertTrue(model.isSignedIn)
        XCTAssertTrue(model.isConfirmingAccountDeletion)
        XCTAssertEqual(model.notice?.title, "Connection error. Please try again.")
    }

    func testAboutUsesClientContextVersionAndGatewayRuntime() {
        let model = makeModel(
            clientContext: ClientContext(appVersion: "1.2.3", buildNumber: "45")
        )

        XCTAssertEqual(model.appVersionDisplayText, "1.2.3 (45)")
        XCTAssertEqual(model.writingRuntimeDisplayText, "ProsePal Gateway")
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
        clientContext: ClientContext = ClientContext(appVersion: "0.0.0", buildNumber: "1"),
        authSessionController: AuthSessionController? = nil,
        authClient: (any AuthClient)? = nil,
        subscriptionClient: (any SubscriptionClient)? = nil,
        accountMaintenanceClient: (any AccountMaintenanceClient)? = nil
    ) -> ProsePalAppModel {
        ProsePalAppModel(
            client: client ?? MockMessageWritingClient(
                response: CardResponse(messages: [], laneUsed: .standard)
            ),
            clientContext: clientContext,
            authSessionController: authSessionController,
            authClient: authClient,
            subscriptionClient: subscriptionClient,
            accountMaintenanceClient: accountMaintenanceClient
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

private actor RecordingAccountMaintenanceClient: AccountMaintenanceClient {
    private let error: AccountMaintenanceError?
    private(set) var deletedTokens: [String] = []

    init(error: AccountMaintenanceError? = nil) {
        self.error = error
    }

    func deleteAccount(accessToken: String) async throws {
        deletedTokens.append(accessToken)
        if let error {
            throw error
        }
    }
}
