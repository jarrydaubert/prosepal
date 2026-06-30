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

    await account.completeAppleSignIn(idToken: "   ", source: "settings")

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

    await account.completeAppleSignIn(idToken: "apple-token", source: "settings")

    #expect(account.isSignedIn)
    #expect(account.signedInEmail == "user@example.com")
    #expect(account.isPremiumUnlocked)
    #expect(try await store.loadSession()?.accessToken == "access-token")
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
    await account.completeAppleSignIn(idToken: "apple-token", source: "settings")

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

    await account.signOut()

    #expect(account.isSignedIn == false)
    #expect(account.isPremiumUnlocked == false)
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
    #expect(account.notice?.title == "Premium restored")

    await subscriptionClient.setRestoreResult(SubscriptionPurchaseResult(status: .notEntitled))
    await account.restorePurchases(source: "paywall")

    #expect(account.isPremiumUnlocked == false)
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
    subscriptionClient: (any SubscriptionClient)? = nil,
    accountMaintenanceClient: (any AccountMaintenanceClient)? = nil,
    localAccountDataDeletion: (@MainActor () async throws -> Void)? = nil
) -> MomentAccountModel {
    MomentAccountModel(
        clientContext: ClientContext(appVersion: "1.0", buildNumber: "1"),
        authSessionController: AuthSessionController(store: store),
        authClient: authClient,
        subscriptionClient: subscriptionClient,
        accountMaintenanceClient: accountMaintenanceClient,
        localAccountDataDeletion: localAccountDataDeletion
    )
}

private enum MomentAccountLocalDataDeletionError: Error {
    case testFailure
}

private actor MomentAccountInMemoryAuthSessionStore: AuthSessionStore {
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

private actor MomentAccountAuthClient: AuthClient {
    private let session: AuthSession
    private let signInError: (any Error)?
    private var recordedSignOutTokens: [String] = []

    init(
        session: AuthSession = .test(
            accessToken: "access-token",
            userID: "user-1",
            email: "user@example.com"
        ),
        signInError: (any Error)? = nil
    ) {
        self.session = session
        self.signInError = signInError
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

    func signOut(accessToken: String) async throws {
        recordedSignOutTokens.append(accessToken)
    }

    func signOutTokens() -> [String] {
        recordedSignOutTokens
    }
}

private actor MomentAccountSubscriptionClient: SubscriptionClient {
    private var products: [SubscriptionProduct]
    private var entitlement: SubscriptionEntitlement
    private var purchaseResult: SubscriptionPurchaseResult
    private var restoreResult: SubscriptionPurchaseResult
    private var loadProductsError: (any Error)?
    private var currentEntitlementError: (any Error)?
    private var purchaseError: (any Error)?
    private var restoreError: (any Error)?
    private var recordedLoadProductsCallCount = 0
    private var recordedPurchasedProductIDs: [String] = []

    init(
        products: [SubscriptionProduct] = [],
        entitlement: SubscriptionEntitlement = .inactive,
        purchaseResult: SubscriptionPurchaseResult = SubscriptionPurchaseResult(status: .notEntitled),
        restoreResult: SubscriptionPurchaseResult = SubscriptionPurchaseResult(status: .notEntitled),
        loadProductsError: (any Error)? = nil,
        currentEntitlementError: (any Error)? = nil,
        purchaseError: (any Error)? = nil,
        restoreError: (any Error)? = nil
    ) {
        self.products = products
        self.entitlement = entitlement
        self.purchaseResult = purchaseResult
        self.restoreResult = restoreResult
        self.loadProductsError = loadProductsError
        self.currentEntitlementError = currentEntitlementError
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

    func currentEntitlement() async throws -> SubscriptionEntitlement {
        if let currentEntitlementError {
            throw currentEntitlementError
        }

        return entitlement
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

    func setRestoreResult(_ result: SubscriptionPurchaseResult) {
        restoreResult = result
    }

    func loadProductsCallCount() -> Int {
        recordedLoadProductsCallCount
    }

    func purchasedProductIDs() -> [String] {
        recordedPurchasedProductIDs
    }
}

private actor MomentAccountMaintenanceClient: AccountMaintenanceClient {
    private let error: (any Error)?
    private var tokens: [String] = []

    init(error: (any Error)? = nil) {
        self.error = error
    }

    func deleteAccount(accessToken: String) async throws {
        if let error {
            throw error
        }

        tokens.append(accessToken)
    }

    func deletedTokens() -> [String] {
        tokens
    }
}

private extension AuthSession {
    static func test(
        accessToken: String,
        userID: String = "user-1",
        email: String? = "user@example.com"
    ) -> AuthSession {
        AuthSession(
            accessToken: accessToken,
            refreshToken: "refresh-token",
            expiresAt: Date(timeIntervalSince1970: 2_000_000_000),
            user: AuthUser(id: userID, email: email)
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
