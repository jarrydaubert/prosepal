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
    public private(set) var subscriptionEntitlementState: SubscriptionEntitlementState = .unknown(.storeUnavailable)
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
    @ObservationIgnored private let appleAccountLifecycleClient: (any AppleAccountLifecycleClient)?
    @ObservationIgnored private let appleCredentialStateProvider: (any AppleCredentialStateProviding)?
    @ObservationIgnored private let subscriptionClient: (any SubscriptionClient)?
    @ObservationIgnored private let accountMaintenanceClient: (any AccountMaintenanceClient)?
    @ObservationIgnored private let localAccountDataDeletion: (@MainActor () async throws -> Void)?
    @ObservationIgnored private let diagnostics: NativeDiagnosticsLogger
    @ObservationIgnored private var pendingAppleSignInNonce: AppleSignInNonce?
    @ObservationIgnored private var didLoadInitialState = false
    @ObservationIgnored private var appleCredentialRevocationTask: Task<Void, Never>?
    @ObservationIgnored private var subscriptionTransactionUpdatesTask: Task<Void, Never>?
    @ObservationIgnored private var subscriptionEntitlementRefreshOperation: SubscriptionEntitlementRefreshOperation?
    @ObservationIgnored private var signedInUserID: String?

    public init(
        clientContext: ClientContext,
        authSessionController: AuthSessionController? = nil,
        authClient: (any AuthClient)? = nil,
        appleAccountLifecycleClient: (any AppleAccountLifecycleClient)? = nil,
        appleCredentialStateProvider: (any AppleCredentialStateProviding)? = nil,
        subscriptionClient: (any SubscriptionClient)? = nil,
        accountMaintenanceClient: (any AccountMaintenanceClient)? = nil,
        localAccountDataDeletion: (@MainActor () async throws -> Void)? = nil,
        runtimeReadiness: NativeRuntimeReadiness = .unconfigured,
        diagnostics: NativeDiagnosticsLogger = .shared
    ) {
        self.clientContext = clientContext
        self.authSessionController = authSessionController
        self.authClient = authClient
        self.appleAccountLifecycleClient = appleAccountLifecycleClient
        self.appleCredentialStateProvider = appleCredentialStateProvider
        self.subscriptionClient = subscriptionClient
        self.accountMaintenanceClient = accountMaintenanceClient
        self.localAccountDataDeletion = localAccountDataDeletion
        self.runtimeReadiness = runtimeReadiness
        self.diagnostics = diagnostics
        startAppleCredentialRevocationListener()
        startSubscriptionTransactionListener()
    }

    deinit {
        appleCredentialRevocationTask?.cancel()
        subscriptionTransactionUpdatesTask?.cancel()
    }

    public var isAppleSignInConfigured: Bool {
        authSessionController != nil && authClient != nil && appleAccountLifecycleClient != nil
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

        if isSignedIn {
            await reconcileAppleCredentialState(source: "launch")
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

    public func completeAppleSignIn(
        idToken: String?,
        authorizationCode: String?,
        appleUserID: String?,
        source: String
    ) async {
        defer {
            pendingAppleSignInNonce = nil
            isSigningIn = false
        }

        guard let authSessionController, let authClient, let appleAccountLifecycleClient else {
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

        guard let authorizationCode,
              !authorizationCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            diagnostics.authEvent(
                "auth_apple_revocation_material_failed",
                source: source,
                outcome: AppleAccountLifecycleError.missingAuthorizationCode.diagnosticsOutcome
            )
            showNotice(
                AppleAccountLifecycleError.missingAuthorizationCode.userSafeMessage,
                systemImage: "exclamationmark.triangle"
            )
            return
        }

        guard let appleUserID,
              !appleUserID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            diagnostics.authEvent(
                "auth_apple_revocation_material_failed",
                source: source,
                outcome: AppleAccountLifecycleError.missingCredentialIdentifier.diagnosticsOutcome
            )
            showNotice(
                AppleAccountLifecycleError.missingCredentialIdentifier.userSafeMessage,
                systemImage: "exclamationmark.triangle"
            )
            return
        }

        do {
            diagnostics.authEvent("auth_apple_supabase_exchange_started", source: source)
            let exchangedSession = try await authClient.signInWithIDToken(
                provider: .apple,
                idToken: idToken,
                nonce: nonce.rawValue
            )
            diagnostics.authEvent("auth_apple_revocation_material_started", source: source)
            try await appleAccountLifecycleClient.storeRevocationMaterial(
                authorizationCode: authorizationCode,
                appleUserID: appleUserID,
                accessToken: exchangedSession.accessToken
            )
            let session = AuthSession(
                accessToken: exchangedSession.accessToken,
                refreshToken: exchangedSession.refreshToken,
                expiresAt: exchangedSession.expiresAt,
                user: exchangedSession.user,
                appleCredentialUserID: appleUserID
            )
            try await authSessionController.replaceSession(session)
            applyAuthSession(session)
            diagnostics.authEvent(
                "auth_apple_revocation_material_succeeded",
                source: source,
                outcome: "success"
            )
            diagnostics.authEvent(
                "auth_apple_supabase_exchange_succeeded",
                source: source,
                outcome: "success"
            )
            diagnostics.messageAction("auth_apple_succeeded", source: source, messageCharacters: 0)
            await refreshSubscriptionEntitlement(source: "auth_apple_success")
            showNotice("Signed in with Apple", systemImage: "checkmark.circle.fill")
        } catch let error as AppleAccountLifecycleError {
            diagnostics.authEvent(
                "auth_apple_revocation_material_failed",
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

    public func reconcileAppleCredentialState(source: String) async {
        guard let authSessionController, let appleCredentialStateProvider else { return }
        guard let session = try? await authSessionController.persistedSession(),
              let appleUserID = session.appleCredentialUserID?.trimmingCharacters(in: .whitespacesAndNewlines),
              !appleUserID.isEmpty else {
            return
        }

        do {
            let state = try await appleCredentialStateProvider.credentialState(forUserID: appleUserID)
            switch state {
            case .authorized:
                diagnostics.authEvent(
                    "auth_apple_credential_state_checked",
                    source: source,
                    outcome: "authorized"
                )
            case .revoked:
                await handleAppleCredentialInvalidation(
                    session: session,
                    source: source,
                    outcome: "revoked",
                    notice: String(localized: "Apple sign-in was revoked. Sign in again to reconnect.")
                )
            case .notFound:
                await handleAppleCredentialInvalidation(
                    session: session,
                    source: source,
                    outcome: "not_found",
                    notice: String(localized: "Apple sign-in is no longer connected. Sign in again to reconnect.")
                )
            case .transferred:
                await handleAppleCredentialInvalidation(
                    session: session,
                    source: source,
                    outcome: "transferred",
                    notice: String(localized: "This Apple account connection needs to be renewed. Sign in again to continue.")
                )
            }
        } catch is CancellationError {
            return
        } catch let error as AppleCredentialStateError {
            diagnostics.authEvent(
                "auth_apple_credential_state_failed",
                source: source,
                outcome: error.diagnosticsOutcome
            )
            if source == "revocation_notification" {
                await handleAppleCredentialInvalidation(
                    session: session,
                    source: source,
                    outcome: "revocation_notified",
                    notice: String(localized: "Apple sign-in was revoked. Sign in again to reconnect.")
                )
            }
        } catch {
            diagnostics.authEvent(
                "auth_apple_credential_state_failed",
                source: source,
                outcome: "unexpected_error"
            )
            if source == "revocation_notification" {
                await handleAppleCredentialInvalidation(
                    session: session,
                    source: source,
                    outcome: "revocation_notified",
                    notice: String(localized: "Apple sign-in was revoked. Sign in again to reconnect.")
                )
            }
        }
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
            subscriptionEntitlementState = .unknown(.notConfigured)
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

        let state = await subscriptionClient.currentEntitlement()
        subscriptionEntitlementState = state
        switch state {
        case .active(let entitlement, _, let ownership):
            let expectedToken = currentSignedInAccountToken
            guard ownership.isCompatible(with: expectedToken) else {
                subscriptionEntitlementState = .unknown(.ownershipMismatch)
                subscriptionErrorMessage = SubscriptionEntitlementFailure.ownershipMismatch.userSafeMessage
                diagnostics.subscriptionEvent(
                    "subscription_entitlement_refresh_failed",
                    source: source,
                    productCount: fetchedSubscriptionProductCount,
                    configuredProductCount: configuredSubscriptionProductCount,
                    outcome: "ownership_mismatch"
                )
                return false
            }
            isPremiumUnlocked = true
            subscriptionEntitlement = entitlement
            subscriptionErrorMessage = nil
            diagnostics.subscriptionEvent(
                "subscription_entitlement_refresh_succeeded",
                source: source,
                productCount: fetchedSubscriptionProductCount,
                configuredProductCount: configuredSubscriptionProductCount,
                outcome: "active"
            )
            return true
        case .confirmedInactive:
            isPremiumUnlocked = false
            subscriptionEntitlement = .inactive
            subscriptionErrorMessage = nil
            diagnostics.subscriptionEvent(
                "subscription_entitlement_refresh_succeeded",
                source: source,
                productCount: fetchedSubscriptionProductCount,
                configuredProductCount: configuredSubscriptionProductCount,
                outcome: "inactive"
            )
            return true
        case .unknown(let failure):
            // Unknown never creates access. A previously verified active value is
            // retained only within the same account epoch until StoreKit recovers.
            subscriptionErrorMessage = failure.userSafeMessage
            diagnostics.subscriptionEvent(
                "subscription_entitlement_refresh_failed",
                source: source,
                productCount: fetchedSubscriptionProductCount,
                configuredProductCount: configuredSubscriptionProductCount,
                outcome: failure.rawValue
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
            await applySubscriptionPurchaseResult(result, source: source)
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
            await applySubscriptionPurchaseResult(result, source: source)
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
            let deletionOutcome = try await accountMaintenanceClient.deleteAccount(accessToken: accessToken)
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
            let noticeTitle = switch (deletionOutcome, didClearLocalData) {
            case (.deleted, true):
                "Account deleted"
            case (.deleted, false):
                "Account deleted. Some local data may remain."
            case (.indeterminate, true):
                "Deletion is still being finalized. ProsePal data was removed from this device. If you can still sign in, retry deletion."
            case (.indeterminate, false):
                "Deletion is still being finalized, and some local data may remain. If you can still sign in, retry deletion."
            }
            showNotice(
                noticeTitle,
                systemImage: deletionOutcome == .deleted && didClearLocalData
                    ? "checkmark.circle.fill"
                    : "exclamationmark.triangle"
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
        let nextUserID = continuableSession?.user?.id
        if signedInUserID != nextUserID {
            isPremiumUnlocked = false
            subscriptionEntitlement = .inactive
            subscriptionEntitlementState = .unknown(.storeUnavailable)
        }
        signedInUserID = nextUserID
        isSignedIn = continuableSession != nil
        signedInEmail = continuableSession?.user?.email

        if continuableSession == nil {
            isPremiumUnlocked = false
            subscriptionEntitlement = .inactive
        }
    }

    private func applySubscriptionPurchaseResult(
        _ result: SubscriptionPurchaseResult,
        source: String
    ) async {
        subscriptionEntitlementState = result.entitlementState
        var didConverge = false
        switch result.entitlementState {
        case .active(let entitlement, _, let ownership):
            guard ownership.isCompatible(with: currentSignedInAccountToken),
                  result.transactionOwnership?.isCompatible(with: currentSignedInAccountToken) != false else {
                subscriptionEntitlementState = .unknown(.ownershipMismatch)
                subscriptionErrorMessage = SubscriptionEntitlementFailure.ownershipMismatch.userSafeMessage
                break
            }
            guard result.transactionProductID == nil || result.transactionProductID == entitlement.productID else {
                subscriptionEntitlementState = .unknown(.verificationFailed)
                subscriptionErrorMessage = SubscriptionEntitlementFailure.verificationFailed.userSafeMessage
                break
            }
            isPremiumUnlocked = true
            subscriptionEntitlement = entitlement
            subscriptionErrorMessage = nil
            didConverge = true
        case .confirmedInactive:
            isPremiumUnlocked = false
            subscriptionEntitlement = .inactive
            subscriptionErrorMessage = nil
            didConverge = true
        case .unknown(let failure):
            subscriptionErrorMessage = failure.userSafeMessage
        }

        if result.status == .purchased, didConverge, isPremiumUnlocked {
            await result.finish()
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
            if didConverge, isPremiumUnlocked {
                showNotice("Premium purchase completed", systemImage: "checkmark.seal.fill")
            } else {
                subscriptionErrorMessage = SubscriptionError.verificationFailed.userSafeMessage
                showNotice("Purchase needs verification", systemImage: "exclamationmark.triangle")
            }
        case .restored:
            if case .unknown = result.entitlementState {
                showNotice("Could not verify purchases. Please try again.", systemImage: "exclamationmark.triangle")
            } else {
                showNotice(isPremiumUnlocked ? "Premium restored" : "No active subscription found", systemImage: "arrow.clockwise")
            }
        case .pending:
            showNotice("Purchase pending approval", systemImage: "clock")
        case .cancelled:
            showNotice("Purchase cancelled", systemImage: "xmark.circle")
        case .notEntitled:
            if case .unknown = result.entitlementState {
                showNotice("Could not verify purchases. Please try again.", systemImage: "exclamationmark.triangle")
            } else {
                showNotice("No active subscription found", systemImage: "arrow.clockwise")
            }
        }
    }

    private func startAppleCredentialRevocationListener() {
        guard appleCredentialRevocationTask == nil,
              let appleCredentialStateProvider else { return }

        appleCredentialRevocationTask = Task { [weak self] in
            let events = appleCredentialStateProvider.revocationEvents()
            for await _ in events {
                guard !Task.isCancelled, let self else { return }
                await self.reconcileAppleCredentialState(source: "revocation_notification")
            }
        }
    }

    private func handleAppleCredentialInvalidation(
        session: AuthSession,
        source: String,
        outcome: String,
        notice: String
    ) async {
        diagnostics.authEvent(
            "auth_apple_credential_invalidated",
            source: source,
            outcome: outcome
        )
        applyAuthSession(nil)
        showNotice(notice, systemImage: "person.crop.circle.badge.xmark")
        do {
            try await authSessionController?.clearSession()
            try? await authClient?.signOut(accessToken: session.accessToken)
        } catch {
            diagnostics.authEvent(
                "auth_apple_credential_clear_failed",
                source: source,
                outcome: "session_storage_failed"
            )
            showNotice(
                String(localized: "Apple sign-in changed, but ProsePal could not clear the saved session. Restart ProsePal and try signing out again."),
                systemImage: "exclamationmark.triangle"
            )
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

        guard update.ownership.isCompatible(with: currentSignedInAccountToken) else {
            subscriptionEntitlementState = .unknown(.ownershipMismatch)
            subscriptionErrorMessage = SubscriptionEntitlementFailure.ownershipMismatch.userSafeMessage
            diagnostics.subscriptionEvent(
                "subscription_transaction_ownership_mismatch",
                source: "transaction_updates",
                productCount: fetchedSubscriptionProductCount,
                configuredProductCount: configuredSubscriptionProductCount,
                outcome: "ownership_mismatch"
            )
            return
        }

        let didConverge = await refreshSubscriptionEntitlement(
            source: "transaction_updates"
        )
        guard didConverge,
              !Task.isCancelled,
              hasReconciled(update) else { return }
        await update.finish()
    }

    private func hasReconciled(_ update: SubscriptionTransactionUpdate) -> Bool {
        switch update.effect {
        case .grantsOrRenews:
            return subscriptionEntitlementState.entitlement?.productID == update.productID
        case .removesAccess:
            return subscriptionEntitlementState.entitlement?.productID != update.productID
        case .unknown:
            return false
        }
    }

    private var currentSignedInAccountToken: UUID? {
        guard let signedInUserID else { return nil }
        return UUID(uuidString: signedInUserID)
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

private extension AppleCredentialStateError {
    var diagnosticsOutcome: String {
        switch self {
        case .invalidUserIdentifier:
            "invalid_user_identifier"
        case .unavailable:
            "unavailable"
        case .timedOut:
            "timed_out"
        }
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
