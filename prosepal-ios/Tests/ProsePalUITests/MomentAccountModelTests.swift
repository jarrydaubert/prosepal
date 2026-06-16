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
func appleSignInSuccessStoresSessionAndRefreshesEntitlement() async throws {
    let store = MomentAccountInMemoryAuthSessionStore()
    let authClient = MomentAccountSuccessfulAuthClient()
    let subscriptionClient = MomentAccountSubscriptionClient(entitlement: SubscriptionEntitlement(
        isActive: true,
        productID: "com.prosepal.pro.yearly"
    ))
    let account = MomentAccountModel(
        clientContext: ClientContext(appVersion: "1.0", buildNumber: "1"),
        authSessionController: AuthSessionController(store: store),
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
func subscriptionProductsSelectRecommendedPlanAndPurchaseUnlocksPremium() async {
    let yearly = SubscriptionProduct(
        id: "com.prosepal.pro.yearly",
        displayName: "Yearly",
        displayPrice: "$39.99",
        durationLabel: "Every 1 year",
        isRecommended: true
    )
    let monthly = SubscriptionProduct(
        id: "com.prosepal.pro.monthly",
        displayName: "Monthly",
        displayPrice: "$4.99",
        durationLabel: "Every 1 month"
    )
    let subscriptionClient = MomentAccountSubscriptionClient(
        products: [monthly, yearly],
        purchaseResult: SubscriptionPurchaseResult(
            status: .purchased,
            entitlement: SubscriptionEntitlement(isActive: true, productID: yearly.id)
        )
    )
    let account = MomentAccountModel(
        clientContext: ClientContext(appVersion: "1.0", buildNumber: "1"),
        subscriptionClient: subscriptionClient
    )

    await account.loadSubscriptionProducts(source: "paywall")
    #expect(account.subscriptionProducts.count == 2)
    #expect(account.selectedSubscriptionProductID == yearly.id)
    #expect(account.selectedPremiumPlanDisclosureText == "$39.99 / Every 1 year")

    await account.purchasePremium(source: "paywall")
    #expect(account.isPremiumUnlocked)
    #expect(account.notice?.title == "Premium purchase completed")
}

private actor MomentAccountInMemoryAuthSessionStore: AuthSessionStore {
    private var session: AuthSession?

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

private struct MomentAccountSuccessfulAuthClient: AuthClient {
    func signInWithIDToken(
        provider: AuthProvider,
        idToken: String,
        nonce: String?
    ) async throws -> AuthSession {
        AuthSession(
            accessToken: "access-token",
            refreshToken: "refresh-token",
            expiresAt: Date(timeIntervalSince1970: 2_000_000_000),
            user: AuthUser(id: "user-1", email: "user@example.com")
        )
    }

    func signOut(accessToken: String) async throws {}
}

private struct MomentAccountSubscriptionClient: SubscriptionClient {
    var products: [SubscriptionProduct] = []
    var entitlement: SubscriptionEntitlement = .inactive
    var purchaseResult: SubscriptionPurchaseResult = SubscriptionPurchaseResult(status: .notEntitled)
    var restoreResult: SubscriptionPurchaseResult = SubscriptionPurchaseResult(status: .notEntitled)

    func loadProducts() async throws -> [SubscriptionProduct] {
        products
    }

    func currentEntitlement() async throws -> SubscriptionEntitlement {
        entitlement
    }

    func purchase(productID: String) async throws -> SubscriptionPurchaseResult {
        purchaseResult
    }

    func restorePurchases() async throws -> SubscriptionPurchaseResult {
        restoreResult
    }
}
