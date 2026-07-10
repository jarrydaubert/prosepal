import Foundation
import Observation
import ProsePalAPI
import ProsePalDomain

@MainActor
@Observable
public final class MomentAccountModel {
    public private(set) var isSignedIn = false
    public private(set) var signedInEmail: String?
    public private(set) var isSigningIn = false
    public private(set) var isPremiumUnlocked = false
    public private(set) var subscriptionEntitlement: SubscriptionEntitlement = .inactive
    public private(set) var subscriptionProducts: [SubscriptionProduct] = []
    public var selectedSubscriptionProductID: String?
    public private(set) var isLoadingSubscriptions = false
    public private(set) var isRefreshingSubscriptionEntitlement = false
    public private(set) var isPurchasingPremium = false
    public private(set) var isRestoringPurchases = false
    public private(set) var isConfirmingAccountDeletion = false
    public private(set) var isDeletingAccount = false
    public private(set) var notice: MomentAccountNotice?
    public private(set) var subscriptionErrorMessage: String?

    public let runtimeReadiness: NativeRuntimeReadiness

    @ObservationIgnored private let clientContext: ClientContext
    @ObservationIgnored private let authSessionController: AuthSessionController?
    @ObservationIgnored private let authClient: (any AuthClient)?
    @ObservationIgnored private let subscriptionClient: (any SubscriptionClient)?
    @ObservationIgnored private let accountMaintenanceClient: (any AccountMaintenanceClient)?
    @ObservationIgnored private let localAccountDataDeletion: (@MainActor () async throws -> Void)?
    @ObservationIgnored private let diagnostics: NativeDiagnosticsLogger
    @ObservationIgnored private var pendingAppleSignInNonce: AppleSignInNonce?
    @ObservationIgnored private var didLoadInitialState = false
    @ObservationIgnored private var subscriptionTransactionUpdatesTask: Task<Void, Never>?
    @ObservationIgnored private var subscriptionEntitlementRefreshOperation: SubscriptionEntitlementRefreshOperation?

    public init(
        clientContext: ClientContext,
        authSessionController: AuthSessionController? = nil,
        authClient: (any AuthClient)? = nil,
        subscriptionClient: (any SubscriptionClient)? = nil,
        accountMaintenanceClient: (any AccountMaintenanceClient)? = nil,
        localAccountDataDeletion: (@MainActor () async throws -> Void)? = nil,
        runtimeReadiness: NativeRuntimeReadiness = .unconfigured,
        diagnostics: NativeDiagnosticsLogger = .shared
    ) {
        self.clientContext = clientContext
        self.authSessionController = authSessionController
        self.authClient = authClient
        self.subscriptionClient = subscriptionClient
        self.accountMaintenanceClient = accountMaintenanceClient
        self.localAccountDataDeletion = localAccountDataDeletion
        self.runtimeReadiness = runtimeReadiness
        self.diagnostics = diagnostics
        startSubscriptionTransactionListener()
    }

    deinit {
        subscriptionTransactionUpdatesTask?.cancel()
    }

    public var isAppleSignInConfigured: Bool {
        authSessionController != nil && authClient != nil
    }

    public var isSubscriptionConfigured: Bool {
        subscriptionClient != nil
    }

    private var fetchedSubscriptionProductCount: Int {
        subscriptionProducts.count
    }

    private var configuredSubscriptionProductCount: Int {
        runtimeReadiness.premiumProductCount
    }

    public var isAccountDeletionConfigured: Bool {
        accountMaintenanceClient != nil
    }

    public var appVersionDisplayText: String {
        "\(clientContext.appVersion) (\(clientContext.buildNumber))"
    }

    public var selectedSubscriptionProduct: SubscriptionProduct? {
        if let selectedSubscriptionProductID,
           let selectedProduct = subscriptionProducts.first(where: { $0.id == selectedSubscriptionProductID }) {
            return selectedProduct
        }

        return subscriptionProducts.first
    }

    public var selectedPremiumPlanDisclosureText: String? {
        guard let selectedSubscriptionProduct else { return nil }
        let price = selectedSubscriptionProduct.displayPrice.trimmingCharacters(in: .whitespacesAndNewlines)
        let duration = selectedSubscriptionProduct.durationLabel?.trimmingCharacters(in: .whitespacesAndNewlines)
        let displayPrice = price.isEmpty ? selectedSubscriptionProduct.displayName : price

        if let duration, !duration.isEmpty {
            return "\(displayPrice) / \(duration)"
        }

        return displayPrice
    }

    public var activeSubscriptionProduct: SubscriptionProduct? {
        guard let productID = subscriptionEntitlement.productID else { return nil }
        return subscriptionProducts.first { $0.id == productID }
    }

    public var premiumRenewalDisclosureText: String {
        if let selectedPremiumPlanDisclosureText {
            return "Selected plan: \(selectedPremiumPlanDisclosureText). Auto-renews. Cancel anytime in App Store settings."
        }

        return "Choose a plan to continue. Auto-renews. Cancel anytime in App Store settings."
    }

    public func loadInitialState() async {
        guard !didLoadInitialState else { return }
        didLoadInitialState = true
        await loadAuthSession()
        await refreshSubscriptionEntitlement(source: "launch")
    }

    public func loadAuthSession() async {
        guard let authSessionController else { return }

        do {
            let session = try await authSessionController.currentSession()
            let persistedSession: AuthSession?
            if let session {
                persistedSession = session
            } else {
                persistedSession = try await authSessionController.persistedSession()
            }
            applyAuthSession(persistedSession)
        } catch let error as AuthError {
            let persistedSession = try? await authSessionController.persistedSession()
            applyAuthSession(persistedSession)
            diagnostics.authEvent(
                "auth_session_refresh_failed",
                source: "launch",
                outcome: error.diagnosticsOutcome,
                statusCode: error.diagnosticsStatusCode
            )
        } catch {
            let persistedSession = try? await authSessionController.persistedSession()
            applyAuthSession(persistedSession)
            diagnostics.messageAction("auth_session_load_failed", source: "launch", messageCharacters: 0)
        }
    }

    public func beginAppleSignInRequest(source: String) -> String? {
        guard !isSigningIn else {
            diagnostics.messageAction("auth_apple_ignored_inflight", source: source, messageCharacters: 0)
            return nil
        }

        guard isAppleSignInConfigured else {
            diagnostics.messageAction("auth_apple_unconfigured", source: source, messageCharacters: 0)
            showNotice("Sign in is not configured for this build", systemImage: "exclamationmark.triangle")
            return nil
        }

        do {
            let nonce = try AppleSignInNonce.make()
            pendingAppleSignInNonce = nonce
            isSigningIn = true
            diagnostics.messageAction("auth_apple_started", source: source, messageCharacters: 0)
            return nonce.sha256Value
        } catch let error as AuthError {
            isSigningIn = false
            diagnostics.messageAction("auth_apple_nonce_failed", source: source, messageCharacters: 0)
            showNotice(error.userSafeMessage, systemImage: "exclamationmark.triangle")
            return nil
        } catch {
            isSigningIn = false
            diagnostics.messageAction("auth_apple_nonce_failed", source: source, messageCharacters: 0)
            showNotice("Apple sign-in could not start securely. Please try again.", systemImage: "exclamationmark.triangle")
            return nil
        }
    }

    public func completeAppleSignIn(idToken: String?, source: String) async {
        defer {
            pendingAppleSignInNonce = nil
            isSigningIn = false
        }

        guard let authSessionController, let authClient else {
            diagnostics.messageAction("auth_apple_unconfigured", source: source, messageCharacters: 0)
            showNotice("Sign in is not configured for this build", systemImage: "exclamationmark.triangle")
            return
        }

        guard let nonce = pendingAppleSignInNonce else {
            diagnostics.messageAction("auth_apple_missing_nonce", source: source, messageCharacters: 0)
            showNotice(AuthError.missingNonce.userSafeMessage, systemImage: "exclamationmark.triangle")
            return
        }

        guard let idToken, !idToken.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            diagnostics.messageAction("auth_apple_missing_token", source: source, messageCharacters: 0)
            showNotice(AuthError.missingIdentityToken.userSafeMessage, systemImage: "exclamationmark.triangle")
            return
        }

        do {
            diagnostics.authEvent("auth_apple_supabase_exchange_started", source: source)
            let session = try await authClient.signInWithIDToken(
                provider: .apple,
                idToken: idToken,
                nonce: nonce.rawValue
            )
            try await authSessionController.replaceSession(session)
            applyAuthSession(session)
            diagnostics.authEvent(
                "auth_apple_supabase_exchange_succeeded",
                source: source,
                outcome: "success"
            )
            diagnostics.messageAction("auth_apple_succeeded", source: source, messageCharacters: 0)
            await refreshSubscriptionEntitlement(source: "auth_apple_success")
            showNotice("Signed in with Apple", systemImage: "checkmark.circle.fill")
        } catch let error as AuthError {
            diagnostics.authEvent(
                "auth_apple_supabase_exchange_failed",
                source: source,
                outcome: error.diagnosticsOutcome,
                statusCode: error.diagnosticsStatusCode
            )
            diagnostics.messageAction(
                "auth_apple_failed_\(error.diagnosticsOutcome)",
                source: source,
                messageCharacters: 0
            )
            showNotice(error.userSafeMessage, systemImage: "exclamationmark.triangle")
        } catch {
            diagnostics.messageAction("auth_apple_failed_unexpected_error", source: source, messageCharacters: 0)
            showNotice("Apple sign-in failed. Please try again.", systemImage: "exclamationmark.triangle")
        }
    }

    public func cancelAppleSignIn(source: String) {
        pendingAppleSignInNonce = nil
        isSigningIn = false
        diagnostics.messageAction("auth_apple_cancelled", source: source, messageCharacters: 0)
    }

    public func failAppleSignIn(source: String, category: String = "authorization_error") {
        pendingAppleSignInNonce = nil
        isSigningIn = false
        diagnostics.messageAction("auth_apple_failed_\(category)", source: source, messageCharacters: 0)
        showNotice("Apple sign-in failed. Please try again.", systemImage: "exclamationmark.triangle")
    }

    public func signOut() async {
        guard isSignedIn else {
            diagnostics.messageAction("sign_out_requested", source: "settings", messageCharacters: 0)
            showNotice("No signed-in account", systemImage: "rectangle.portrait.and.arrow.right")
            return
        }

        diagnostics.messageAction("sign_out_requested", source: "settings", messageCharacters: 0)

        if let accessToken = try? await authSessionController?.currentAccessToken() {
            try? await authClient?.signOut(accessToken: accessToken)
        }

        do {
            try await authSessionController?.clearSession()
            applyAuthSession(nil)
            showNotice("Signed out", systemImage: "rectangle.portrait.and.arrow.right")
        } catch {
            showNotice("Could not finish signing out. Please try again.", systemImage: "exclamationmark.triangle")
        }
    }

    public func loadSubscriptionProducts(source: String) async {
        guard !isLoadingSubscriptions else { return }
        guard let subscriptionClient else {
            subscriptionProducts = []
            selectedSubscriptionProductID = nil
            subscriptionErrorMessage = SubscriptionError.notConfigured.userSafeMessage
            diagnostics.subscriptionEvent(
                "subscription_products_unconfigured",
                source: source,
                productCount: 0,
                configuredProductCount: configuredSubscriptionProductCount,
                outcome: "not_configured"
            )
            return
        }

        isLoadingSubscriptions = true
        subscriptionErrorMessage = nil
        diagnostics.subscriptionEvent(
            "subscription_products_loading",
            source: source,
            productCount: fetchedSubscriptionProductCount,
            configuredProductCount: configuredSubscriptionProductCount
        )
        defer { isLoadingSubscriptions = false }

        do {
            let products = try await subscriptionClient.loadProducts()
            guard !products.isEmpty else {
                throw SubscriptionError.productsUnavailable
            }
            subscriptionProducts = products
            if selectedSubscriptionProductID == nil || !products.contains(where: { $0.id == selectedSubscriptionProductID }) {
                selectedSubscriptionProductID = products.first(where: \.isRecommended)?.id ?? products.first?.id
            }
            diagnostics.subscriptionEvent(
                "subscription_products_loaded",
                source: source,
                productCount: products.count,
                configuredProductCount: configuredSubscriptionProductCount,
                outcome: "success"
            )
        } catch let error as SubscriptionError {
            subscriptionProducts = []
            selectedSubscriptionProductID = nil
            subscriptionErrorMessage = error.userSafeMessage
            diagnostics.subscriptionEvent(
                "subscription_products_failed",
                source: source,
                productCount: 0,
                configuredProductCount: configuredSubscriptionProductCount,
                outcome: error.diagnosticsOutcome
            )
        } catch {
            subscriptionProducts = []
            selectedSubscriptionProductID = nil
            subscriptionErrorMessage = SubscriptionError.unexpectedResponse.userSafeMessage
            diagnostics.subscriptionEvent(
                "subscription_products_failed",
                source: source,
                productCount: 0,
                configuredProductCount: configuredSubscriptionProductCount,
                outcome: "unexpected_error"
            )
        }
    }

    @discardableResult
    public func refreshSubscriptionEntitlement(source: String) async -> Bool {
        guard let subscriptionClient else {
            isPremiumUnlocked = false
            subscriptionEntitlement = .inactive
            diagnostics.subscriptionEvent(
                "subscription_entitlement_unconfigured",
                source: source,
                configuredProductCount: configuredSubscriptionProductCount,
                outcome: "not_configured"
            )
            return false
        }

        while let existingOperation = subscriptionEntitlementRefreshOperation {
            _ = await existingOperation.task.value
            clearSubscriptionEntitlementRefreshOperation(ifMatching: existingOperation.id)
        }

        let operation = SubscriptionEntitlementRefreshOperation(
            id: UUID(),
            task: Task { [weak self] in
                guard let self else { return false }
                return await self.performSubscriptionEntitlementRefresh(
                    using: subscriptionClient,
                    source: source
                )
            }
        )
        subscriptionEntitlementRefreshOperation = operation
        let didRefresh = await operation.task.value
        clearSubscriptionEntitlementRefreshOperation(ifMatching: operation.id)
        return didRefresh
    }

    private func performSubscriptionEntitlementRefresh(
        using subscriptionClient: any SubscriptionClient,
        source: String
    ) async -> Bool {
        isRefreshingSubscriptionEntitlement = true
        defer { isRefreshingSubscriptionEntitlement = false }
        diagnostics.subscriptionEvent(
            "subscription_entitlement_refresh_started",
            source: source,
            productCount: fetchedSubscriptionProductCount,
            configuredProductCount: configuredSubscriptionProductCount
        )

        do {
            let entitlement = try await subscriptionClient.currentEntitlement()
            isPremiumUnlocked = entitlement.isActive
            subscriptionEntitlement = entitlement
            subscriptionErrorMessage = nil
            diagnostics.subscriptionEvent(
                "subscription_entitlement_refresh_succeeded",
                source: source,
                productCount: fetchedSubscriptionProductCount,
                configuredProductCount: configuredSubscriptionProductCount,
                outcome: entitlement.isActive ? "active" : "inactive"
            )
            return true
        } catch let error as SubscriptionError {
            isPremiumUnlocked = false
            subscriptionEntitlement = .inactive
            subscriptionErrorMessage = error.userSafeMessage
            diagnostics.subscriptionEvent(
                "subscription_entitlement_refresh_failed",
                source: source,
                productCount: fetchedSubscriptionProductCount,
                configuredProductCount: configuredSubscriptionProductCount,
                outcome: error.diagnosticsOutcome
            )
            return false
        } catch {
            isPremiumUnlocked = false
            subscriptionEntitlement = .inactive
            subscriptionErrorMessage = SubscriptionError.unexpectedResponse.userSafeMessage
            diagnostics.subscriptionEvent(
                "subscription_entitlement_refresh_failed",
                source: source,
                productCount: fetchedSubscriptionProductCount,
                configuredProductCount: configuredSubscriptionProductCount,
                outcome: "unexpected_error"
            )
            return false
        }
    }

    private func clearSubscriptionEntitlementRefreshOperation(ifMatching id: UUID) {
        guard subscriptionEntitlementRefreshOperation?.id == id else { return }
        subscriptionEntitlementRefreshOperation = nil
    }

    public func stopSubscriptionTransactionListener() {
        subscriptionTransactionUpdatesTask?.cancel()
        subscriptionTransactionUpdatesTask = nil
    }

    public func selectSubscriptionProduct(_ product: SubscriptionProduct) {
        selectedSubscriptionProductID = product.id
        diagnostics.selectionChanged(kind: "subscription_plan", value: product.durationLabel?.diagnosticsSelectionValue ?? "configured")
    }

    public func purchasePremium(source: String) async {
        guard !isPurchasingPremium else { return }
        guard let subscriptionClient else {
            subscriptionErrorMessage = SubscriptionError.notConfigured.userSafeMessage
            showNotice(SubscriptionError.notConfigured.userSafeMessage, systemImage: "exclamationmark.triangle")
            diagnostics.subscriptionEvent(
                "subscription_purchase_unconfigured",
                source: source,
                productCount: 0,
                configuredProductCount: configuredSubscriptionProductCount,
                outcome: "not_configured"
            )
            return
        }

        if subscriptionProducts.isEmpty {
            await loadSubscriptionProducts(source: source)
        }

        guard let productID = selectedSubscriptionProductID ?? subscriptionProducts.first?.id else {
            subscriptionErrorMessage = SubscriptionError.productsUnavailable.userSafeMessage
            showNotice(SubscriptionError.productsUnavailable.userSafeMessage, systemImage: "exclamationmark.triangle")
            diagnostics.subscriptionEvent(
                "subscription_purchase_failed",
                source: source,
                productCount: fetchedSubscriptionProductCount,
                configuredProductCount: configuredSubscriptionProductCount,
                outcome: "no_product"
            )
            return
        }

        isPurchasingPremium = true
        subscriptionErrorMessage = nil
        diagnostics.subscriptionEvent(
            "subscription_purchase_started",
            source: source,
            productCount: fetchedSubscriptionProductCount,
            configuredProductCount: configuredSubscriptionProductCount
        )
        defer { isPurchasingPremium = false }

        do {
            let result = try await subscriptionClient.purchase(productID: productID)
            applySubscriptionPurchaseResult(result, source: source)
        } catch let error as SubscriptionError {
            subscriptionErrorMessage = error.userSafeMessage
            showNotice(error.userSafeMessage, systemImage: "exclamationmark.triangle")
            diagnostics.subscriptionEvent(
                "subscription_purchase_failed",
                source: source,
                productCount: fetchedSubscriptionProductCount,
                configuredProductCount: configuredSubscriptionProductCount,
                outcome: error.diagnosticsOutcome
            )
        } catch {
            subscriptionErrorMessage = SubscriptionError.unexpectedResponse.userSafeMessage
            showNotice(SubscriptionError.unexpectedResponse.userSafeMessage, systemImage: "exclamationmark.triangle")
            diagnostics.subscriptionEvent(
                "subscription_purchase_failed",
                source: source,
                productCount: fetchedSubscriptionProductCount,
                configuredProductCount: configuredSubscriptionProductCount,
                outcome: "unexpected_error"
            )
        }
    }

    public func restorePurchases(source: String) async {
        guard !isRestoringPurchases else { return }
        guard let subscriptionClient else {
            subscriptionErrorMessage = SubscriptionError.notConfigured.userSafeMessage
            showNotice(SubscriptionError.notConfigured.userSafeMessage, systemImage: "exclamationmark.triangle")
            diagnostics.subscriptionEvent(
                "subscription_restore_unconfigured",
                source: source,
                productCount: 0,
                configuredProductCount: configuredSubscriptionProductCount,
                outcome: "not_configured"
            )
            return
        }

        isRestoringPurchases = true
        subscriptionErrorMessage = nil
        diagnostics.subscriptionEvent(
            "subscription_restore_started",
            source: source,
            productCount: fetchedSubscriptionProductCount,
            configuredProductCount: configuredSubscriptionProductCount
        )
        defer { isRestoringPurchases = false }

        do {
            let result = try await subscriptionClient.restorePurchases()
            applySubscriptionPurchaseResult(result, source: source)
        } catch let error as SubscriptionError {
            subscriptionErrorMessage = error.userSafeMessage
            showNotice(error.userSafeMessage, systemImage: "exclamationmark.triangle")
            diagnostics.subscriptionEvent(
                "subscription_restore_failed",
                source: source,
                productCount: fetchedSubscriptionProductCount,
                configuredProductCount: configuredSubscriptionProductCount,
                outcome: error.diagnosticsOutcome
            )
        } catch {
            subscriptionErrorMessage = SubscriptionError.unexpectedResponse.userSafeMessage
            showNotice(SubscriptionError.unexpectedResponse.userSafeMessage, systemImage: "exclamationmark.triangle")
            diagnostics.subscriptionEvent(
                "subscription_restore_failed",
                source: source,
                productCount: fetchedSubscriptionProductCount,
                configuredProductCount: configuredSubscriptionProductCount,
                outcome: "unexpected_error"
            )
        }
    }

    public func requestAccountDeletion() {
        diagnostics.messageAction("delete_account_requested", source: "settings", messageCharacters: 0)
        guard isSignedIn else {
            showNotice("Sign in before deleting your account", systemImage: "trash")
            return
        }

        guard accountMaintenanceClient != nil else {
            showNotice("Account deletion is unavailable right now", systemImage: "trash")
            return
        }

        isConfirmingAccountDeletion = true
    }

    public func cancelAccountDeletion() {
        isConfirmingAccountDeletion = false
    }

    public func confirmAccountDeletion() async {
        guard !isDeletingAccount else { return }

        guard isSignedIn else {
            showNotice("Sign in before deleting your account", systemImage: "trash")
            return
        }

        guard let accountMaintenanceClient else {
            showNotice("Account deletion is unavailable right now", systemImage: "trash")
            return
        }

        guard let accessToken = try? await authSessionController?.currentAccessToken() else {
            showNotice(AccountMaintenanceError.authenticationRequired.userSafeMessage, systemImage: "exclamationmark.triangle")
            return
        }

        isDeletingAccount = true
        defer { isDeletingAccount = false }

        do {
            try await accountMaintenanceClient.deleteAccount(accessToken: accessToken)
            var didClearLocalData = true
            do {
                try await localAccountDataDeletion?()
            } catch {
                didClearLocalData = false
                diagnostics.messageAction("local_account_data_delete_failed", source: "settings", messageCharacters: 0)
            }
            try? await authSessionController?.clearSession()
            isConfirmingAccountDeletion = false
            applyAuthSession(nil)
            isPremiumUnlocked = false
            showNotice(
                didClearLocalData ? "Account deleted" : "Account deleted. Some local data may remain.",
                systemImage: didClearLocalData ? "checkmark.circle.fill" : "exclamationmark.triangle"
            )
        } catch let error as AccountMaintenanceError {
            showNotice(error.userSafeMessage, systemImage: "exclamationmark.triangle")
        } catch {
            showNotice("Account deletion failed. Please try again.", systemImage: "exclamationmark.triangle")
        }
    }

    public func clearNotice() {
        notice = nil
    }

    private func applyAuthSession(_ session: AuthSession?) {
        let continuableSession = session?.canContinueSignIn == true ? session : nil
        isSignedIn = continuableSession != nil
        signedInEmail = continuableSession?.user?.email

        if continuableSession == nil {
            isPremiumUnlocked = false
            subscriptionEntitlement = .inactive
        }
    }

    private func applySubscriptionPurchaseResult(_ result: SubscriptionPurchaseResult, source: String) {
        if result.entitlement.isActive {
            isPremiumUnlocked = true
            subscriptionEntitlement = result.entitlement
        } else if result.status == .restored || result.status == .notEntitled {
            isPremiumUnlocked = false
            subscriptionEntitlement = .inactive
        }

        diagnostics.subscriptionEvent(
            "subscription_result",
            source: source,
            productCount: fetchedSubscriptionProductCount,
            configuredProductCount: configuredSubscriptionProductCount,
            outcome: result.status.rawValue
        )

        switch result.status {
        case .purchased:
            if result.entitlement.isActive {
                showNotice("Premium purchase completed", systemImage: "checkmark.seal.fill")
            } else {
                subscriptionErrorMessage = SubscriptionError.verificationFailed.userSafeMessage
                showNotice("Purchase needs verification", systemImage: "exclamationmark.triangle")
            }
        case .restored:
            showNotice(result.entitlement.isActive ? "Premium restored" : "No active subscription found", systemImage: "arrow.clockwise")
        case .pending:
            showNotice("Purchase pending approval", systemImage: "clock")
        case .cancelled:
            showNotice("Purchase cancelled", systemImage: "xmark.circle")
        case .notEntitled:
            showNotice("No active subscription found", systemImage: "arrow.clockwise")
        }
    }

    private func startSubscriptionTransactionListener() {
        guard subscriptionTransactionUpdatesTask == nil,
              let subscriptionClient else { return }

        subscriptionTransactionUpdatesTask = Task { [weak self] in
            let updates = await subscriptionClient.transactionUpdates()
            for await update in updates {
                guard !Task.isCancelled, let self else { return }
                await self.handleSubscriptionTransactionUpdate(update)
            }
        }
    }

    private func handleSubscriptionTransactionUpdate(
        _ update: SubscriptionTransactionUpdate
    ) async {
        guard update.verification == .verified else {
            diagnostics.subscriptionEvent(
                "subscription_transaction_unverified",
                source: "transaction_updates",
                productCount: fetchedSubscriptionProductCount,
                configuredProductCount: configuredSubscriptionProductCount,
                outcome: "verification_failed"
            )
            return
        }

        let didConverge = await refreshSubscriptionEntitlement(
            source: "transaction_updates"
        )
        guard didConverge, !Task.isCancelled else { return }
        await update.finish()
    }

    private func showNotice(_ title: String, systemImage: String) {
        let notice = MomentAccountNotice(title: title, systemImage: systemImage)
        self.notice = notice

        Task { @MainActor in
            try? await Task.sleep(for: .seconds(1.7))
            if self.notice?.id == notice.id {
                self.notice = nil
            }
        }
    }
}

private extension AuthSession {
    var canContinueSignIn: Bool {
        if isUsable() {
            return true
        }

        let refreshToken = refreshToken?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return refreshToken?.isEmpty == false
    }
}

public struct MomentAccountNotice: Identifiable, Equatable, Sendable {
    public var id = UUID()
    public var title: String
    public var systemImage: String

    public init(id: UUID = UUID(), title: String, systemImage: String) {
        self.id = id
        self.title = title
        self.systemImage = systemImage
    }
}

private struct SubscriptionEntitlementRefreshOperation: Sendable {
    let id: UUID
    let task: Task<Bool, Never>
}

private extension SubscriptionError {
    var diagnosticsOutcome: String {
        switch self {
        case .notConfigured:
            "not_configured"
        case .productsUnavailable:
            "products_unavailable"
        case .productUnavailable:
            "product_unavailable"
        case .purchaseCancelled:
            "cancelled"
        case .purchasePending:
            "pending"
        case .verificationFailed:
            "verification_failed"
        case .storeUnavailable:
            "store_unavailable"
        case .unexpectedResponse:
            "unexpected_response"
        }
    }
}

private extension String {
    var diagnosticsSelectionValue: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .replacingOccurrences(of: " ", with: "_")
    }
}
