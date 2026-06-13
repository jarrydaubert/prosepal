import ProsePalAPI
import ProsePalDomain
import Foundation
import SwiftUI

#if canImport(AuthenticationServices)
import AuthenticationServices
#endif

#if canImport(StoreKit)
import StoreKit
#endif

#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

@MainActor
public final class ProsePalAppModel: ObservableObject {
    @Published var draft = MessageDraft()
    @Published var generatedMessages: [GeneratedMessage] = []
    @Published var savedMessages: [SavedMessage] = []
    @Published var notice: AppNotice?
    @Published var isShowingResults = false
    @Published var isShowingPaywall = false
    @Published var isGenerating = false
    @Published var errorMessage: String?
    @Published var fallbackStatus: FallbackStatus = .none
    @Published var laneUsed: GenerationLane?
    @Published var usageStatus: UsageStatus
    @Published var hasCompletedOnboarding: Bool
    @Published var selectedTab: AppTab = .compose
    @Published var isSignedIn = false
    @Published var signedInUserID: String?
    @Published var signedInEmail: String?
    @Published var isSigningIn = false
    @Published var subscriptionProducts: [SubscriptionProduct] = []
    @Published var selectedSubscriptionProductID: String?
    @Published var isLoadingSubscriptions = false
    @Published var isRefreshingSubscriptionEntitlement = false
    @Published var isPurchasingPremium = false
    @Published var isRestoringPurchases = false
    @Published var subscriptionErrorMessage: String?
    @Published var biometricLockEnabled = false
    @Published var totalGeneratedCount = 0

    public nonisolated static let defaultSavedMessagesKey = "prosepal.native.savedMessages.v1"
    public nonisolated static let defaultOnboardingCompletionKey = "prosepal.native.onboardingCompleted.v1"
    public let runtimeReadiness: NativeRuntimeReadiness
    private let client: MessageWritingClient
    private let clientContext: ClientContext
    private let savedMessagesStore: UserDefaults
    private let savedMessagesKey: String
    private var savedMessagesScopeID = "anonymous"
    private let onboardingStore: UserDefaults
    private let onboardingCompletionKey: String
    private let diagnostics: NativeDiagnosticsLogger
    private let authSessionController: AuthSessionController?
    private let authClient: (any AuthClient)?
    private let subscriptionClient: (any SubscriptionClient)?
    private var pendingAppleSignInNonce: AppleSignInNonce?
    private var generationTask: Task<Void, Never>?
    private var generationTaskID: UUID?
    private var activeGenerationRequestID: String?
    private var activeGenerationStartedAt: Date?
    private var cancelledGenerationRequestIDs: Set<String> = []

    public init(
        client: MessageWritingClient,
        clientContext: ClientContext,
        usageStatus: UsageStatus = UsageStatus(),
        savedMessagesStore: UserDefaults = .standard,
        savedMessagesKey: String = ProsePalAppModel.defaultSavedMessagesKey,
        onboardingStore: UserDefaults = .standard,
        onboardingCompletionKey: String = ProsePalAppModel.defaultOnboardingCompletionKey,
        authSessionController: AuthSessionController? = nil,
        authClient: (any AuthClient)? = nil,
        subscriptionClient: (any SubscriptionClient)? = nil,
        runtimeReadiness: NativeRuntimeReadiness = .unconfigured,
        diagnostics: NativeDiagnosticsLogger = .shared
    ) {
        self.client = client
        self.clientContext = clientContext
        self.runtimeReadiness = runtimeReadiness
        self.usageStatus = usageStatus
        self.savedMessagesStore = savedMessagesStore
        self.savedMessagesKey = savedMessagesKey
        self.onboardingStore = onboardingStore
        self.onboardingCompletionKey = onboardingCompletionKey
        self.authSessionController = authSessionController
        self.authClient = authClient
        self.subscriptionClient = subscriptionClient
        self.diagnostics = diagnostics
        self.savedMessages = Self.loadSavedMessages(from: savedMessagesStore, key: savedMessagesKey)
        self.hasCompletedOnboarding = onboardingStore.bool(forKey: onboardingCompletionKey)
        diagnostics.appStarted(
            hasCompletedOnboarding: self.hasCompletedOnboarding,
            savedMessageCount: self.savedMessages.count
        )
        diagnostics.runtimeReadiness(runtimeReadiness)
    }

    var isAppleSignInConfigured: Bool {
        authSessionController != nil && authClient != nil
    }

    var isSubscriptionConfigured: Bool {
        subscriptionClient != nil
    }

    var appVersionDisplayText: String {
        "\(clientContext.appVersion) (\(clientContext.buildNumber))"
    }

    var writingRuntimeDisplayText: String {
        "ProsePal Gateway"
    }

    var dataExportStatusText: String {
        isSignedIn ? "Export is unavailable right now" : "Sign in before exporting data"
    }

    var accountDeletionStatusText: String {
        isSignedIn ? "Deletion is unavailable right now" : "Sign in before deleting your account"
    }

    var selectedSubscriptionProduct: SubscriptionProduct? {
        if let selectedSubscriptionProductID,
           let selectedProduct = subscriptionProducts.first(where: { $0.id == selectedSubscriptionProductID }) {
            return selectedProduct
        }

        return subscriptionProducts.first
    }

    var selectedPremiumPlanDisclosureText: String? {
        guard let selectedSubscriptionProduct else { return nil }
        let price = selectedSubscriptionProduct.displayPrice.trimmingCharacters(in: .whitespacesAndNewlines)
        let duration = selectedSubscriptionProduct.durationLabel?.trimmingCharacters(in: .whitespacesAndNewlines)
        let displayPrice = price.isEmpty ? selectedSubscriptionProduct.displayName : price

        if let duration, !duration.isEmpty {
            return "\(displayPrice) / \(duration)"
        }

        return displayPrice
    }

    var premiumRenewalDisclosureText: String {
        if let selectedPremiumPlanDisclosureText {
            return "Selected plan: \(selectedPremiumPlanDisclosureText). Auto-renews. Cancel anytime in App Store settings."
        }

        return "Choose a plan to continue. Auto-renews. Cancel anytime in App Store settings."
    }

    func loadAuthSession() async {
        guard let authSessionController else { return }

        do {
            let session = try await authSessionController.loadPersistedSession()
            if session?.isUsable() == true {
                applyAuthSession(session)
            } else {
                try? await authSessionController.clearSession()
                applyAuthSession(nil)
            }
        } catch {
            applyAuthSession(nil)
            diagnostics.messageAction("auth_session_load_failed", source: "launch", messageCharacters: 0)
        }
    }

    func generate() async {
        if isGenerating { return }
        guard prepareForGeneration() else { return }

        isGenerating = true
        errorMessage = nil
        let requestedLane = draft.requestedLane
        let startedAt = Date()

        let request = CardRequest(
            intent: draft.intent,
            requestedLane: requestedLane,
            clientContext: clientContext
        )
        diagnostics.generationStarted(requestID: request.idempotencyKey, draft: draft)
        activeGenerationRequestID = request.idempotencyKey
        activeGenerationStartedAt = startedAt

        do {
            let response = try await client.generateCard(request: request)
            try Task.checkCancellation()
            generatedMessages = response.messages
            fallbackStatus = response.fallbackStatus
            laneUsed = response.laneUsed
            let usageSource: String
            if let usageSummary = response.usage {
                usageStatus.applyGatewayUsageSummary(usageSummary)
                usageSource = "gateway"
            } else {
                usageStatus.recordSuccessfulGeneration(requestedLane: requestedLane, laneUsed: response.laneUsed)
                usageSource = "gateway_omitted"
            }
            totalGeneratedCount += response.messages.count
            diagnostics.generationSucceeded(
                requestID: request.idempotencyKey,
                laneUsed: response.laneUsed,
                fallbackStatus: response.fallbackStatus,
                messageCount: response.messages.count,
                totalMessageCharacters: response.messages.reduce(0) { $0 + $1.text.count },
                usageSource: usageSource,
                standardRemaining: usageStatus.standardRemaining,
                durationMs: startedAt.elapsedMilliseconds
            )
            isShowingResults = true
        } catch is CancellationError {
            handleGenerationCancellation(requestID: request.idempotencyKey, startedAt: startedAt)
        } catch let error as GenerationError {
            if Task.isCancelled {
                handleGenerationCancellation(requestID: request.idempotencyKey, startedAt: startedAt)
            } else {
                diagnostics.generationFailed(
                    requestID: request.idempotencyKey,
                    category: error.diagnosticsCategory,
                    durationMs: startedAt.elapsedMilliseconds
                )
                errorMessage = error.userSafeMessage
            }
        } catch {
            if Task.isCancelled {
                handleGenerationCancellation(requestID: request.idempotencyKey, startedAt: startedAt)
            } else {
                diagnostics.generationFailed(
                    requestID: request.idempotencyKey,
                    category: "unexpected_error",
                    durationMs: startedAt.elapsedMilliseconds
                )
                errorMessage = "Message generation failed. Please try again."
            }
        }

        finishGeneration(requestID: request.idempotencyKey)
    }

    func startGeneration() {
        guard generationTask == nil, !isGenerating else { return }

        let taskID = UUID()
        generationTaskID = taskID
        generationTask = Task { @MainActor [weak self] in
            guard let self else { return }
            await self.generate()
            if self.generationTaskID == taskID {
                self.generationTask = nil
                self.generationTaskID = nil
            }
        }
    }

    func cancelGeneration() {
        guard isGenerating || generationTask != nil else { return }

        let requestID = activeGenerationRequestID
        let durationMs = activeGenerationStartedAt?.elapsedMilliseconds ?? 0
        if let requestID {
            cancelledGenerationRequestIDs.insert(requestID)
        }

        generationTask?.cancel()
        generationTask = nil
        generationTaskID = nil
        isGenerating = false
        errorMessage = nil
        diagnostics.generationFailed(
            requestID: requestID,
            category: "cancelled",
            durationMs: durationMs
        )
        clearActiveGeneration(requestID: requestID)
        showNotice("Writing cancelled", systemImage: "xmark.circle")
    }

    private func handleGenerationCancellation(requestID: String, startedAt: Date) {
        let wasAlreadyReported = cancelledGenerationRequestIDs.remove(requestID) != nil
        if !wasAlreadyReported {
            diagnostics.generationFailed(
                requestID: requestID,
                category: "cancelled",
                durationMs: startedAt.elapsedMilliseconds
            )
            showNotice("Writing cancelled", systemImage: "xmark.circle")
        }
    }

    private func clearActiveGeneration(requestID: String?) {
        guard activeGenerationRequestID == requestID else { return }
        activeGenerationRequestID = nil
        activeGenerationStartedAt = nil
    }

    private func finishGeneration(requestID: String) {
        guard activeGenerationRequestID == requestID else { return }
        activeGenerationRequestID = nil
        activeGenerationStartedAt = nil
        isGenerating = false
    }

    func selectLane(_ lane: GenerationLane) {
        if usageStatus.isPremiumLocked(lane) {
            diagnostics.paywallShown(
                trigger: "premium_lane_selected",
                requestedLane: lane,
                standardRemaining: usageStatus.standardRemaining
            )
            isShowingPaywall = true
            showNotice("Premium is locked", systemImage: "lock")
            return
        }

        draft.requestedLane = lane
        diagnostics.selectionChanged(kind: "generation_lane", value: lane.rawValue)
    }

    func useStandardLaneFromPaywall() {
        draft.requestedLane = .standard
        isShowingPaywall = false
        diagnostics.selectionChanged(kind: "generation_lane", value: GenerationLane.standard.rawValue)
        showNotice("Standard selected", systemImage: "checkmark.circle.fill")
    }

    func loadSubscriptionProducts(source: String) async {
        guard !isLoadingSubscriptions else { return }
        guard let subscriptionClient else {
            subscriptionProducts = []
            selectedSubscriptionProductID = nil
            subscriptionErrorMessage = SubscriptionError.notConfigured.userSafeMessage
            diagnostics.subscriptionEvent(
                "subscription_products_unconfigured",
                source: source,
                productCount: 0,
                outcome: "not_configured"
            )
            return
        }

        isLoadingSubscriptions = true
        subscriptionErrorMessage = nil
        diagnostics.subscriptionEvent("subscription_products_loading", source: source)

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
                outcome: "unexpected_error"
            )
        }

        isLoadingSubscriptions = false
    }

    func refreshSubscriptionEntitlement(source: String) async {
        guard !isRefreshingSubscriptionEntitlement else { return }
        guard let subscriptionClient else {
            usageStatus.isPremiumUnlocked = false
            diagnostics.subscriptionEvent(
                "subscription_entitlement_unconfigured",
                source: source,
                outcome: "not_configured"
            )
            return
        }

        isRefreshingSubscriptionEntitlement = true
        defer { isRefreshingSubscriptionEntitlement = false }
        diagnostics.subscriptionEvent("subscription_entitlement_refresh_started", source: source)

        do {
            let entitlement = try await subscriptionClient.currentEntitlement()
            usageStatus.isPremiumUnlocked = entitlement.isActive
            subscriptionErrorMessage = nil
            diagnostics.subscriptionEvent(
                "subscription_entitlement_refresh_succeeded",
                source: source,
                outcome: entitlement.isActive ? "active" : "inactive"
            )
        } catch let error as SubscriptionError {
            usageStatus.isPremiumUnlocked = false
            subscriptionErrorMessage = error.userSafeMessage
            diagnostics.subscriptionEvent(
                "subscription_entitlement_refresh_failed",
                source: source,
                outcome: error.diagnosticsOutcome
            )
        } catch {
            usageStatus.isPremiumUnlocked = false
            subscriptionErrorMessage = SubscriptionError.unexpectedResponse.userSafeMessage
            diagnostics.subscriptionEvent(
                "subscription_entitlement_refresh_failed",
                source: source,
                outcome: "unexpected_error"
            )
        }
    }

    func selectSubscriptionProduct(_ product: SubscriptionProduct) {
        selectedSubscriptionProductID = product.id
        diagnostics.selectionChanged(kind: "subscription_plan", value: product.durationLabel?.diagnosticsSelectionValue ?? "configured")
    }

    func purchasePremium(source: String) async {
        guard !isPurchasingPremium else { return }
        guard let subscriptionClient else {
            subscriptionErrorMessage = SubscriptionError.notConfigured.userSafeMessage
            showNotice(SubscriptionError.notConfigured.userSafeMessage, systemImage: "exclamationmark.triangle")
            diagnostics.subscriptionEvent(
                "subscription_purchase_unconfigured",
                source: source,
                productCount: 0,
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
                productCount: subscriptionProducts.count,
                outcome: "no_product"
            )
            return
        }

        isPurchasingPremium = true
        subscriptionErrorMessage = nil
        diagnostics.subscriptionEvent(
            "subscription_purchase_started",
            source: source,
            productCount: subscriptionProducts.count
        )

        do {
            let result = try await subscriptionClient.purchase(productID: productID)
            applySubscriptionPurchaseResult(result, source: source)
        } catch let error as SubscriptionError {
            subscriptionErrorMessage = error.userSafeMessage
            showNotice(error.userSafeMessage, systemImage: "exclamationmark.triangle")
            diagnostics.subscriptionEvent(
                "subscription_purchase_failed",
                source: source,
                productCount: subscriptionProducts.count,
                outcome: error.diagnosticsOutcome
            )
        } catch {
            subscriptionErrorMessage = SubscriptionError.unexpectedResponse.userSafeMessage
            showNotice(SubscriptionError.unexpectedResponse.userSafeMessage, systemImage: "exclamationmark.triangle")
            diagnostics.subscriptionEvent(
                "subscription_purchase_failed",
                source: source,
                productCount: subscriptionProducts.count,
                outcome: "unexpected_error"
            )
        }

        isPurchasingPremium = false
    }

    func restorePurchases(source: String) async {
        guard !isRestoringPurchases else { return }
        guard let subscriptionClient else {
            subscriptionErrorMessage = SubscriptionError.notConfigured.userSafeMessage
            showNotice(SubscriptionError.notConfigured.userSafeMessage, systemImage: "exclamationmark.triangle")
            diagnostics.subscriptionEvent(
                "subscription_restore_unconfigured",
                source: source,
                productCount: 0,
                outcome: "not_configured"
            )
            return
        }

        isRestoringPurchases = true
        subscriptionErrorMessage = nil
        diagnostics.subscriptionEvent("subscription_restore_started", source: source)

        do {
            let result = try await subscriptionClient.restorePurchases()
            applySubscriptionPurchaseResult(result, source: source)
        } catch let error as SubscriptionError {
            subscriptionErrorMessage = error.userSafeMessage
            showNotice(error.userSafeMessage, systemImage: "exclamationmark.triangle")
            diagnostics.subscriptionEvent(
                "subscription_restore_failed",
                source: source,
                outcome: error.diagnosticsOutcome
            )
        } catch {
            subscriptionErrorMessage = SubscriptionError.unexpectedResponse.userSafeMessage
            showNotice(SubscriptionError.unexpectedResponse.userSafeMessage, systemImage: "exclamationmark.triangle")
            diagnostics.subscriptionEvent(
                "subscription_restore_failed",
                source: source,
                outcome: "unexpected_error"
            )
        }

        isRestoringPurchases = false
    }

    func beginAppleSignInRequest(source: String) -> String? {
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

    func completeAppleSignIn(idToken: String?, source: String) async {
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
            let session = try await authClient.signInWithIDToken(
                provider: .apple,
                idToken: idToken,
                nonce: nonce.rawValue
            )
            try await authSessionController.replaceSession(session)
            applyAuthSession(session)
            diagnostics.messageAction("auth_apple_succeeded", source: source, messageCharacters: 0)
            await refreshSubscriptionEntitlement(source: "auth_apple_success")
            showNotice("Signed in with Apple", systemImage: "checkmark.circle.fill")
        } catch let error as AuthError {
            diagnostics.messageAction("auth_apple_failed", source: source, messageCharacters: 0)
            showNotice(error.userSafeMessage, systemImage: "exclamationmark.triangle")
        } catch {
            diagnostics.messageAction("auth_apple_failed", source: source, messageCharacters: 0)
            showNotice("Apple sign-in failed. Please try again.", systemImage: "exclamationmark.triangle")
        }
    }

    func cancelAppleSignIn(source: String) {
        pendingAppleSignInNonce = nil
        isSigningIn = false
        diagnostics.messageAction("auth_apple_cancelled", source: source, messageCharacters: 0)
    }

    func failAppleSignIn(source: String) {
        pendingAppleSignInNonce = nil
        isSigningIn = false
        diagnostics.messageAction("auth_apple_failed", source: source, messageCharacters: 0)
        showNotice("Apple sign-in failed. Please try again.", systemImage: "exclamationmark.triangle")
    }

    func openSettingsLink(_ link: String) {
        diagnostics.messageAction("settings_link_opened", source: link, messageCharacters: 0)
    }

    func requestAppReview() {
        diagnostics.messageAction("rate_app_requested", source: "settings", messageCharacters: 0)
    }

    func requestDataExport() {
        diagnostics.messageAction("export_data_requested", source: "settings", messageCharacters: 0)
        guard isSignedIn else {
            showNotice("Sign in before exporting data", systemImage: "square.and.arrow.up")
            return
        }

        showNotice("Data export is unavailable right now", systemImage: "square.and.arrow.up")
    }

    func requestAccountDeletion() {
        diagnostics.messageAction("delete_account_requested", source: "settings", messageCharacters: 0)
        guard isSignedIn else {
            showNotice("Sign in before deleting your account", systemImage: "trash")
            return
        }

        showNotice("Account deletion is unavailable right now", systemImage: "trash")
    }

    func signOut() async {
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

    func setBiometricLockEnabled(_ enabled: Bool) {
        guard isSignedIn || !enabled else {
            biometricLockEnabled = false
            diagnostics.selectionChanged(kind: "biometric_lock", value: "blocked_requires_sign_in")
            showNotice("Sign in before enabling Face ID", systemImage: "faceid")
            return
        }

        biometricLockEnabled = enabled
        diagnostics.selectionChanged(kind: "biometric_lock", value: enabled ? "enabled" : "disabled")
    }

    func completeOnboarding() {
        hasCompletedOnboarding = true
        onboardingStore.set(true, forKey: onboardingCompletionKey)
        diagnostics.onboardingCompleted()
    }

    func logOnboardingShown() {
        diagnostics.onboardingShown()
    }

    func adjustCurrentMessage() {
        diagnostics.messageAction(
            "adjust_message",
            source: "results",
            messageCharacters: generatedMessages.reduce(0) { $0 + $1.text.count }
        )
        isShowingResults = false
    }

    func startNewMessage() {
        diagnostics.messageAction(
            "start_new_message",
            source: "results",
            messageCharacters: generatedMessages.reduce(0) { $0 + $1.text.count }
        )
        draft = MessageDraft()
        generatedMessages = []
        errorMessage = nil
        fallbackStatus = .none
        laneUsed = nil
        isShowingResults = false
        selectedTab = .compose
        showNotice("Ready for a new message", systemImage: "square.and.pencil")
    }

    private func prepareForGeneration() -> Bool {
        if usageStatus.isPremiumLocked(draft.requestedLane) {
            diagnostics.paywallShown(
                trigger: "premium_lane_generate",
                requestedLane: draft.requestedLane,
                standardRemaining: usageStatus.standardRemaining
            )
            isShowingPaywall = true
            return false
        }

        if usageStatus.isStandardLimitReached(for: draft.requestedLane) {
            errorMessage = "You've used your Standard drafts for today."
            diagnostics.paywallShown(
                trigger: "standard_limit_reached",
                requestedLane: draft.requestedLane,
                standardRemaining: usageStatus.standardRemaining
            )
            isShowingPaywall = true
            return false
        }

        return true
    }

    @discardableResult
    func save(_ message: GeneratedMessage) -> Bool {
        saveText(message.text)
    }

    @discardableResult
    func saveText(_ text: String) -> Bool {
        let trimmedText = text.trimmedForSaving
        guard !trimmedText.isEmpty else {
            showNotice("Nothing to save", systemImage: "exclamationmark.circle")
            return false
        }

        guard !savedMessages.contains(where: { $0.text == trimmedText }) else {
            showNotice("Already saved", systemImage: "bookmark.fill")
            return false
        }

        savedMessages.insert(
            SavedMessage(
                text: trimmedText,
                occasion: draft.occasion,
                relationship: draft.relationship,
                tone: draft.tone,
                length: draft.length,
                recipientName: draft.recipientName.nilIfBlank,
                savedAt: .now
            ),
            at: 0
        )
        persistSavedMessages()
        diagnostics.messageAction("save", source: "generated_or_editor", messageCharacters: trimmedText.count)
        showNotice("Saved", systemImage: "bookmark.fill")
        playSuccessFeedback()
        return true
    }

    @discardableResult
    func updateSaved(_ message: SavedMessage, text: String) -> Bool {
        let trimmedText = text.trimmedForSaving
        guard !trimmedText.isEmpty else {
            showNotice("Nothing to save", systemImage: "exclamationmark.circle")
            return false
        }

        guard let index = savedMessages.firstIndex(where: { $0.id == message.id }) else {
            showNotice("Message not found", systemImage: "exclamationmark.circle")
            return false
        }

        guard !savedMessages.contains(where: { $0.id != message.id && $0.text == trimmedText }) else {
            showNotice("Already saved", systemImage: "bookmark.fill")
            return false
        }

        savedMessages[index].text = trimmedText
        persistSavedMessages()
        diagnostics.messageAction("update_saved", source: "saved_editor", messageCharacters: trimmedText.count)
        showNotice("Updated", systemImage: "checkmark.circle.fill")
        playSuccessFeedback()
        return true
    }

    func deleteSaved(_ message: SavedMessage) {
        savedMessages.removeAll { $0.id == message.id }
        persistSavedMessages()
        diagnostics.messageAction("delete_saved", source: "saved_detail", messageCharacters: message.text.count)
        showNotice("Deleted", systemImage: "trash")
    }

    func deleteSaved(at offsets: IndexSet) {
        let deletedCharacterCount = offsets.reduce(0) { total, offset in
            total + savedMessages[offset].text.count
        }
        let ids = Set(offsets.map { savedMessages[$0].id })
        savedMessages.removeAll { ids.contains($0.id) }
        persistSavedMessages()
        diagnostics.messageAction("delete_saved", source: "saved_list", messageCharacters: deletedCharacterCount)
        showNotice("Deleted", systemImage: "trash")
    }

    func isSaved(_ message: GeneratedMessage) -> Bool {
        savedMessages.contains { $0.text == message.text.trimmedForSaving }
    }

    func copyText(_ text: String) {
        diagnostics.messageAction("copy", source: "message", messageCharacters: text.count)
        copyToPasteboard(text)
        showNotice("Copied", systemImage: "doc.on.doc")
        playSelectionFeedback()
    }

    func logTabSelected(_ tab: AppTab) {
        diagnostics.tabSelected(tab.rawValue)
    }

    func logComposeFieldFocused(_ field: ComposeField?) {
        diagnostics.composeFieldFocused(field?.rawValue)
    }

    func logOccasionPickerOpened() {
        diagnostics.pickerOpened("occasion")
    }

    func logSelectionChanged(kind: String, value: String) {
        diagnostics.selectionChanged(kind: kind, value: value)
    }

    func logPaywallOpened(trigger: String) {
        diagnostics.paywallShown(
            trigger: trigger,
            requestedLane: draft.requestedLane,
            standardRemaining: usageStatus.standardRemaining
        )
    }

    func logEditStarted(_ text: String, source: String) {
        diagnostics.messageAction("edit_started", source: source, messageCharacters: text.count)
    }

    func logShareText(_ text: String, source: String) {
        diagnostics.messageAction("share", source: source, messageCharacters: text.count)
    }

    func showNotice(_ title: String, systemImage: String) {
        let notice = AppNotice(title: title, systemImage: systemImage)
        self.notice = notice
        announceAccessibilityNotice(title)

        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 1_700_000_000)
            if self.notice?.id == notice.id {
                self.notice = nil
            }
        }
    }

    private func applyAuthSession(_ session: AuthSession?) {
        let usableSession = session?.isUsable() == true ? session : nil
        let previousUserID = signedInUserID
        let nextUserID = usableSession?.user?.id
        let nextSavedScopeID = Self.savedMessagesScopeID(for: nextUserID)
        isSignedIn = usableSession != nil
        signedInUserID = nextUserID
        signedInEmail = usableSession?.user?.email
        switchSavedMessagesScope(to: nextSavedScopeID)

        if usableSession == nil {
            biometricLockEnabled = false
            if previousUserID != nil {
                usageStatus.isPremiumUnlocked = false
            }
        } else if let previousUserID, previousUserID != nextUserID {
            usageStatus.isPremiumUnlocked = false
        }
    }

    private static let anonymousSavedMessagesScopeID = "anonymous"

    private var activeSavedMessagesKey: String {
        Self.savedMessagesKey(baseKey: savedMessagesKey, scopeID: savedMessagesScopeID)
    }

    private static func savedMessagesScopeID(for userID: String?) -> String {
        guard let userID = userID?.trimmedForSaving, !userID.isEmpty else {
            return anonymousSavedMessagesScopeID
        }

        let encodedUserID = Data(userID.utf8)
            .base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
        return "user.\(encodedUserID)"
    }

    private static func savedMessagesKey(baseKey: String, scopeID: String) -> String {
        scopeID == anonymousSavedMessagesScopeID ? baseKey : "\(baseKey).\(scopeID)"
    }

    private func switchSavedMessagesScope(to nextScopeID: String) {
        guard savedMessagesScopeID != nextScopeID else { return }

        persistSavedMessages()
        savedMessagesScopeID = nextScopeID
        savedMessages = Self.loadSavedMessages(from: savedMessagesStore, key: activeSavedMessagesKey)
    }

    private func applySubscriptionPurchaseResult(_ result: SubscriptionPurchaseResult, source: String) {
        if result.entitlement.isActive {
            usageStatus.isPremiumUnlocked = true
        } else if result.status == .restored || result.status == .notEntitled {
            usageStatus.isPremiumUnlocked = false
        }

        diagnostics.subscriptionEvent(
            "subscription_result",
            source: source,
            productCount: subscriptionProducts.count,
            outcome: result.status.rawValue
        )

        switch result.status {
        case .purchased:
            if result.entitlement.isActive {
                showNotice("Premium purchase completed", systemImage: "checkmark.seal.fill")
                isShowingPaywall = false
            } else {
                subscriptionErrorMessage = SubscriptionError.verificationFailed.userSafeMessage
                showNotice("Purchase needs verification", systemImage: "exclamationmark.triangle")
            }
        case .restored:
            showNotice(result.entitlement.isActive ? "Premium restored" : "No active subscription found", systemImage: "arrow.clockwise")
            if result.entitlement.isActive {
                isShowingPaywall = false
            }
        case .pending:
            showNotice("Purchase pending approval", systemImage: "clock")
        case .cancelled:
            showNotice("Purchase cancelled", systemImage: "xmark.circle")
        case .notEntitled:
            showNotice("No active subscription found", systemImage: "arrow.clockwise")
        }
    }

    private static func loadSavedMessages(from store: UserDefaults, key: String) -> [SavedMessage] {
        guard let data = store.data(forKey: key) else {
            return []
        }

        do {
            return try JSONDecoder().decode([SavedMessage].self, from: data)
        } catch {
            return []
        }
    }

    private func persistSavedMessages() {
        guard let data = try? JSONEncoder().encode(savedMessages) else { return }
        savedMessagesStore.set(data, forKey: activeSavedMessagesKey)
    }
}

public struct MessageDraft: Equatable, Sendable {
    public var occasion: Occasion = .birthday
    public var relationship: Relationship = .parent
    public var tone: Tone = .heartfelt
    public var length: MessageLength = .standard
    public var spellingPreference: SpellingPreference = .automatic
    public var requestedLane: GenerationLane = .standard
    public var recipientName = ""
    public var thingsToInclude = ""
    public var thingsToAvoid = ""
    public var personalContext = ""

    var intent: CardIntent {
        CardIntent(
            occasion: occasion,
            relationship: relationship,
            tone: tone,
            length: length,
            spellingPreference: spellingPreference,
            localeIdentifier: spellingPreference.localeIdentifier,
            recipientName: recipientName.nilIfBlank,
            thingsToInclude: thingsToInclude.commaSeparatedValues,
            thingsToAvoid: thingsToAvoid.commaSeparatedValues,
            userContext: personalContext.nilIfBlank
        )
    }
}

public struct SavedMessage: Codable, Identifiable, Equatable, Hashable, Sendable {
    public var id: UUID
    public var text: String
    public var occasion: Occasion
    public var relationship: Relationship
    public var tone: Tone
    public var length: MessageLength
    public var recipientName: String?
    public var savedAt: Date

    public init(
        id: UUID = UUID(),
        text: String,
        occasion: Occasion,
        relationship: Relationship,
        tone: Tone,
        length: MessageLength,
        recipientName: String? = nil,
        savedAt: Date = .now
    ) {
        self.id = id
        self.text = text
        self.occasion = occasion
        self.relationship = relationship
        self.tone = tone
        self.length = length
        self.recipientName = recipientName
        self.savedAt = savedAt
    }

    public var title: String {
        guard let recipientName = recipientName?.trimmedForSaving, !recipientName.isEmpty else {
            return occasion.displayName
        }
        return recipientName
    }

    public var subtitle: String {
        "\(occasion.displayName) / \(relationship.displayName) / \(tone.displayName)"
    }
}

public struct AppNotice: Identifiable, Equatable, Sendable {
    public var id: UUID
    public var title: String
    public var systemImage: String

    public init(id: UUID = UUID(), title: String, systemImage: String) {
        self.id = id
        self.title = title
        self.systemImage = systemImage
    }
}

public struct UsageStatus: Equatable, Sendable {
    public var standardLimit: Int
    public var standardRemaining: Int
    public var isPremiumUnlocked: Bool
    public var resetDescription: String
    public var hasAuthoritativeUsage: Bool

    public init(
        standardLimit: Int = 3,
        standardRemaining: Int = 2,
        isPremiumUnlocked: Bool = false,
        resetDescription: String = "today",
        hasAuthoritativeUsage: Bool = false
    ) {
        self.standardLimit = max(0, standardLimit)
        self.standardRemaining = max(0, min(standardRemaining, standardLimit))
        self.isPremiumUnlocked = isPremiumUnlocked
        self.resetDescription = resetDescription
        self.hasAuthoritativeUsage = hasAuthoritativeUsage
    }

    public var usageText: String {
        if isPremiumUnlocked {
            return "Premium generation active"
        }

        if !hasAuthoritativeUsage {
            return "Standard generation available"
        }

        return "\(standardRemaining) of \(standardLimit) Standard drafts left \(resetDescription)"
    }

    public var detailText: String {
        if isPremiumUnlocked {
            return "Extra help for harder moments and higher limits are available."
        }

        if !hasAuthoritativeUsage {
            return "Limits are checked by ProsePal when you generate."
        }

        if standardRemaining == 0 {
            return "Premium adds help for harder moments, higher limits, and more rewrites."
        }

        return "Premium adds help for harder moments, higher limits, and more rewrites."
    }

    public func isPremiumLocked(_ lane: GenerationLane) -> Bool {
        lane == .premium && !isPremiumUnlocked
    }

    public func isStandardLimitReached(for lane: GenerationLane) -> Bool {
        hasAuthoritativeUsage && !isPremiumUnlocked && isStandardLike(lane) && standardRemaining <= 0
    }

    public mutating func recordSuccessfulGeneration(requestedLane: GenerationLane, laneUsed: GenerationLane) {
        // The gateway is the source of truth for usage. Anonymous staging
        // responses may omit usage while still being valid; do not invent a
        // client-side limit in that path.
    }

    public mutating func applyGatewayUsageSummary(_ summary: UsageSummary, now: Date = .now) {
        hasAuthoritativeUsage = true

        if let limit = summary.limit {
            standardLimit = max(0, limit)
        }

        if let remaining = summary.remaining {
            standardRemaining = max(0, min(remaining, standardLimit))
        } else {
            standardRemaining = min(standardRemaining, standardLimit)
        }

        if let resetsAt = summary.resetsAt {
            resetDescription = Self.resetDescription(for: resetsAt, now: now)
        }
    }

    private func isStandardLike(_ lane: GenerationLane) -> Bool {
        switch lane {
        case .automatic, .standard:
            true
        case .premium, .local:
            false
        }
    }

    private static func resetDescription(for resetsAt: Date, now: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDate(resetsAt, inSameDayAs: now) {
            return "until \(resetsAt.formatted(date: .omitted, time: .shortened))"
        }

        return "until \(resetsAt.formatted(date: .abbreviated, time: .shortened))"
    }
}

enum AppTab: String, Hashable {
    case compose
    case saved
    case settings
}

public struct ProsePalRootView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @StateObject private var model: ProsePalAppModel

    public init(model: @autoclosure @escaping () -> ProsePalAppModel) {
        _model = StateObject(wrappedValue: model())
    }

    public var body: some View {
        Group {
            if model.hasCompletedOnboarding {
                AppTabsView()
                    .transition(.opacity)
            } else {
                OnboardingView(
                    onStart: model.completeOnboarding,
                    onShown: model.logOnboardingShown
                )
                .transition(.opacity)
            }
        }
        .tint(Color.prosePalCoral)
        .environmentObject(model)
        .task {
            await model.loadAuthSession()
            await model.refreshSubscriptionEntitlement(source: "launch")
        }
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.22), value: model.hasCompletedOnboarding)
        .sheet(isPresented: $model.isShowingPaywall) {
            PaywallSheet(
                usageStatus: model.usageStatus,
                onUseStandard: model.useStandardLaneFromPaywall
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .overlay(alignment: .top) {
            if let notice = model.notice {
                NoticeBanner(notice: notice)
                    .padding(.top, 8)
                    .padding(.horizontal, 18)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .overlay {
            if model.isGenerating {
                WritingProgressOverlay(draft: model.draft, onCancel: model.cancelGeneration)
                    .transition(.opacity)
            }
        }
        .animation(.spring(response: 0.34, dampingFraction: 0.86), value: model.notice?.id)
        .animation(.easeInOut(duration: 0.18), value: model.isGenerating)
    }
}

struct AppTabsView: View {
    @EnvironmentObject private var model: ProsePalAppModel

    var body: some View {
        TabView(selection: $model.selectedTab) {
            ComposeView()
                .tabItem { Label("Create", systemImage: "square.and.pencil") }
                .tag(AppTab.compose)

            SavedMessagesView()
                .tabItem { Label("Saved", systemImage: "bookmark") }
                .tag(AppTab.saved)

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape") }
                .tag(AppTab.settings)
        }
        .onChange(of: model.selectedTab) { _, tab in
            model.logTabSelected(tab)
        }
    }
}

struct OnboardingView: View {
    var onStart: () -> Void
    var onShown: () -> Void = {}
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ScaledMetric(relativeTo: .largeTitle) private var welcomeTitleSize: CGFloat = 45
    @ScaledMetric(relativeTo: .largeTitle) private var brandTitleSize: CGFloat = 48

    private let benefits = OnboardingBenefit.all

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                onboardingBackground

                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        welcomeTitle
                            .frame(maxWidth: .infinity)
                            .padding(.top, max(82, proxy.size.height * 0.20))

                        VStack(spacing: 26) {
                            ForEach(benefits) { benefit in
                                OnboardingBenefitRow(benefit: benefit)
                            }
                        }
                        .padding(.top, 54)

                        Spacer(minLength: 132)
                    }
                    .padding(.horizontal, 30)
                    .frame(minHeight: proxy.size.height, alignment: .top)
                }
                .scrollIndicators(.hidden)
            }
            .safeAreaInset(edge: .bottom) {
                Button(action: onStart) {
                    Text("Continue")
                        .font(.headline.weight(.bold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                }
                .buttonStyle(OnboardingPrimaryButtonStyle(reduceMotion: reduceMotion))
                .padding(.horizontal, 30)
                .padding(.top, 12)
                .padding(.bottom, 16)
                .background(
                    LinearGradient(
                        colors: [
                            Color.prosePalNavy.opacity(0),
                            Color.prosePalNavy,
                            Color.prosePalNavy
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .ignoresSafeArea()
                )
            }
        }
        .preferredColorScheme(.dark)
        .onAppear(perform: onShown)
    }

    private var welcomeTitle: some View {
        VStack(spacing: 8) {
            Text("Welcome to")
                .font(.system(size: welcomeTitleSize, weight: .bold, design: .rounded).leading(.tight))
                .foregroundStyle(.white)
                .minimumScaleFactor(0.78)
                .lineLimit(1)

            Text("ProsePal")
                .font(.system(size: brandTitleSize, weight: .bold, design: .rounded).leading(.tight))
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            Color.prosePalCoralLight,
                            Color(red: 1.0, green: 0.67, blue: 0.60),
                            Color.prosePalCoral
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .shadow(color: Color.prosePalCoral.opacity(0.24), radius: 18, x: 0, y: 8)
                .minimumScaleFactor(0.78)
                .lineLimit(1)
        }
        .multilineTextAlignment(.center)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Welcome to ProsePal")
        .accessibilityAddTraits(.isHeader)
    }

    private var onboardingBackground: some View {
        Color.prosePalNavy
            .overlay {
                LinearGradient(
                    colors: [
                        Color.prosePalNavy,
                        Color.prosePalDeepNavy.opacity(0.96),
                        Color.prosePalNavy
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
            .ignoresSafeArea()
    }
}

private struct OnboardingBenefitRow: View {
    let benefit: OnboardingBenefit
    @ScaledMetric(relativeTo: .title2) private var iconSize: CGFloat = 29
    @ScaledMetric(relativeTo: .title2) private var iconFrameSize: CGFloat = 42

    var body: some View {
        HStack(alignment: .top, spacing: 24) {
            Image(systemName: benefit.systemImage)
                .font(.system(size: iconSize, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: max(42, iconFrameSize), height: max(42, iconFrameSize))

            VStack(alignment: .leading, spacing: 6) {
                Text(benefit.title)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.white)
                    .fixedSize(horizontal: false, vertical: true)

                Text(benefit.detail)
                    .font(.callout)
                    .lineSpacing(3)
                    .foregroundStyle(.white.opacity(0.88))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

private struct OnboardingPrimaryButtonStyle: ButtonStyle {
    var reduceMotion: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(.black)
            .background(Color.white.opacity(configuration.isPressed ? 0.86 : 1), in: Capsule())
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.985 : 1)
            .animation(reduceMotion ? nil : .easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

private struct OnboardingBenefit: Identifiable {
    let id: String
    let title: String
    let detail: String
    let systemImage: String

    static let all: [OnboardingBenefit] = [
        OnboardingBenefit(
            id: "real-messages",
            title: "For cards, texts, and notes",
            detail: "Write something that sounds like you, even when the blank space feels awkward.",
            systemImage: "sparkles"
        ),
        OnboardingBenefit(
            id: "human-context",
            title: "Built around the person",
            detail: "Add who it is for, what the occasion is, and the details that should make it feel personal.",
            systemImage: "person.crop.circle"
        ),
        OnboardingBenefit(
            id: "standard-premium",
            title: "Standard and Premium",
            detail: "Start with Standard drafts. Premium adds help for harder messages, higher limits, and more rewrites.",
            systemImage: "star"
        )
    ]
}

struct ComposeView: View {
    @EnvironmentObject private var model: ProsePalAppModel
    @FocusState private var focusedField: ComposeField?
    @State private var isShowingOccasionPicker = false
    @State private var isShowingRelationshipPicker = false
    @State private var isShowingTonePicker = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        intentHeader
                        basicsSection
                        detailFields
                        styleControls
                        generationControls
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 18)
                    .padding(.bottom, focusedField == nil ? 24 : 180)
                }
                .scrollDismissesKeyboard(.interactively)

                if focusedField == nil {
                    generateButton
                }
            }
            .background(Color.prosePalGroupedBackground)
            .navigationTitle("Create")
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()

                    Button("Done") { focusedField = nil }

                    Button {
                        focusedField = nil
                        model.startGeneration()
                    } label: {
                        Text(model.isGenerating ? "Writing..." : "Write")
                    }
                    .fontWeight(.semibold)
                    .disabled(model.isGenerating)
                }
            }
            .sheet(isPresented: $isShowingOccasionPicker) {
                OccasionPickerSheet(selection: $model.draft.occasion)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $isShowingRelationshipPicker) {
                RelationshipPickerSheet(selection: $model.draft.relationship)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $isShowingTonePicker) {
                TonePickerSheet(selection: $model.draft.tone)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
            .navigationDestination(isPresented: $model.isShowingResults) {
                ResultsView()
            }
            .onChange(of: focusedField) { _, field in
                model.logComposeFieldFocused(field)
            }
            .onChange(of: model.draft.occasion) { _, occasion in
                model.logSelectionChanged(kind: "occasion", value: occasion.rawValue)
            }
            .onChange(of: model.draft.relationship) { _, relationship in
                model.logSelectionChanged(kind: "relationship", value: relationship.rawValue)
            }
            .onChange(of: model.draft.tone) { _, tone in
                model.logSelectionChanged(kind: "tone", value: tone.rawValue)
            }
            .onChange(of: model.draft.length) { _, length in
                model.logSelectionChanged(kind: "length", value: length.rawValue)
            }
        }
    }

    private var intentHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Find the right words")
                .font(.system(.title, design: .rounded, weight: .bold))
                .foregroundStyle(.primary)
            Text("Tell ProsePal who it is for, what is happening, and how it should feel.")
                .font(.callout)
                .foregroundStyle(.secondary)
            Text(summaryText)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Color.prosePalCoralDark)
                .padding(.top, 2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.linearGradient(
                    colors: [Color.prosePalCoral.opacity(0.18), Color.prosePalNavy.opacity(0.10), Color.prosePalSecondaryGroupedBackground],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(.white.opacity(0.72), lineWidth: 1)
        )
    }

    private var summaryText: String {
        let length = model.draft.length == .standard ? "" : "\(model.draft.length.displayName.lowercased()) "
        let tone = model.draft.tone.displayName.lowercased()
        let occasion = model.draft.occasion.displayName.lowercased()
        let base = "\(tone) \(length)\(occasion) message"
        guard let recipient = model.draft.recipientName.nilIfBlank else {
            return "\(base) for \(model.draft.relationship.summaryObjectText)"
        }
        return "\(base) for \(recipient)"
    }

    private var basicsSection: some View {
        ModernPanel {
            VStack(alignment: .leading, spacing: 14) {
                recipientFields

                fieldDivider

                relationshipSection

                fieldDivider

                occasionSelector

                fieldDivider

                toneSection
            }
        }
    }

    private var recipientFields: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Who is this for?")
                .font(.headline)
            Text("Optional, but it helps the draft feel more personal.")
                .font(.caption)
                .foregroundStyle(.secondary)
            TextField("Name or person", text: $model.draft.recipientName, prompt: Text("Alex, Mum, my manager, a group"))
                .focused($focusedField, equals: ComposeField.recipient)
                .submitLabel(.done)
                .onSubmit { focusedField = nil }
        }
    }

    private var relationshipSection: some View {
        SelectionSummaryButton(
            title: "Who are they to you?",
            value: model.draft.relationship.displayName,
            detail: model.draft.relationship.pickerDescription,
            systemImage: model.draft.relationship.symbolName
        ) {
            isShowingRelationshipPicker = true
        }
    }

    private var occasionSelector: some View {
        SelectionSummaryButton(
            title: "What is the moment?",
            value: model.draft.occasion.displayName,
            detail: "\(model.draft.occasion.group.displayName) - \(model.draft.occasion.pickerDescription)",
            systemImage: model.draft.occasion.symbolName
        ) {
            model.logOccasionPickerOpened()
            isShowingOccasionPicker = true
        }
    }

    private var toneSection: some View {
        SelectionSummaryButton(
            title: "How should it feel?",
            value: model.draft.tone.displayName,
            detail: model.draft.tone.description,
            systemImage: model.draft.tone.symbolName
        ) {
            isShowingTonePicker = true
        }
    }

    private var fieldDivider: some View {
        Divider()
            .padding(.leading, 40)
    }

    private var styleControls: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Length")
                .font(.headline)

            Picker("Length", selection: $model.draft.length) {
                ForEach(MessageLength.allCases) { length in
                    Text(length.displayName).tag(length)
                }
            }
            .pickerStyle(.segmented)

            GenerationModeSelector(
                selectedLane: model.draft.requestedLane,
                usageStatus: model.usageStatus,
                onSelect: model.selectLane
            )

            UsageStatusRow(usageStatus: model.usageStatus)
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private var detailFields: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Personal touches")
                .font(.headline)

            TextField("Anything to include?", text: $model.draft.thingsToInclude, prompt: Text("quiet cup of tea, old photos"))
                .focused($focusedField, equals: .include)
                .submitLabel(.done)
                .onSubmit { focusedField = nil }

            Divider()

            TextField("Anything to avoid?", text: $model.draft.thingsToAvoid, prompt: Text("age jokes, formal wording"))
                .focused($focusedField, equals: .avoid)
                .submitLabel(.done)
                .onSubmit { focusedField = nil }

            Divider()

            contextNotesField
        }
        .padding(16)
        .background(Color.prosePalSecondaryGroupedBackground, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private var contextNotesField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("What should this message know?")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)

            ZStack(alignment: .topLeading) {
                TextEditor(text: $model.draft.personalContext)
                    .focused($focusedField, equals: .context)
                    .font(.body)
                    .lineSpacing(3)
                    .frame(minHeight: 92, maxHeight: 148)
                    .scrollContentBackground(.hidden)

                if model.draft.personalContext.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text("A few lines of context, memory, or wording they would recognise")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .padding(.top, 8)
                        .padding(.leading, 5)
                        .allowsHitTesting(false)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(Color.prosePalGroupedBackground, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .accessibilityLabel("What should this message know?")
        }
    }

    private var generationControls: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let errorMessage = model.errorMessage {
                VStack(alignment: .leading, spacing: 10) {
                    Label(errorMessage, systemImage: "exclamationmark.triangle")
                        .font(.footnote)
                        .foregroundStyle(.red)

                    HStack {
                        Button {
                            model.startGeneration()
                        } label: {
                            Label("Try again", systemImage: "arrow.clockwise")
                        }
                        .disabled(model.isGenerating)

                        if model.usageStatus.isStandardLimitReached(for: model.draft.requestedLane) {
                            Button {
                                model.logPaywallOpened(trigger: "create_error_view_premium")
                                model.isShowingPaywall = true
                            } label: {
                                Label("View Premium", systemImage: "star")
                            }
                        }
                    }
                    .font(.footnote.weight(.semibold))
                }
                .padding(12)
                .background(Color.red.opacity(0.08), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
        }
    }

    private var generateButton: some View {
        Button {
            focusedField = nil
            model.startGeneration()
        } label: {
            HStack {
                if model.isGenerating {
                    ProgressView()
                        .tint(.white)
                }
                Text(model.isGenerating ? "Writing" : "Write message")
                    .font(.headline)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .disabled(model.isGenerating)
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 8)
        .background(.bar)
        .overlay(alignment: .top) {
            Divider()
        }
    }
}

private struct SelectionSummaryButton: View {
    let title: String
    let value: String
    let detail: String
    let systemImage: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: systemImage)
                    .font(.headline)
                    .foregroundStyle(Color.prosePalCoralDark)
                    .frame(width: 28, height: 28)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                    Text(value)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(2)
                        .minimumScaleFactor(0.88)
                    Text(detail)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                Spacer(minLength: 8)

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(title), \(value)")
    }
}

struct OccasionPickerSheet: View {
    @Binding var selection: Occasion
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""

    var body: some View {
        NavigationStack {
            List {
                if searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Section("Most Used") {
                        ForEach(Occasion.featuredCases) { occasion in
                            occasionButton(for: occasion)
                        }
                    }
                } else if !hasSearchResults {
                    ContentUnavailableView.search(text: searchText)
                }

                ForEach(displayedGroups) { group in
                    let occasions = filteredOccasions(in: group)
                    if !occasions.isEmpty {
                        Section(group.displayName) {
                            ForEach(occasions) { occasion in
                                occasionButton(for: occasion)
                            }
                        }
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search moments")
            .navigationTitle("Moment")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }

    private var displayedGroups: [OccasionGroup] {
        if searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return OccasionGroup.allCases.filter { $0 != .mostUsed }
        }

        return OccasionGroup.allCases
    }

    private var hasSearchResults: Bool {
        OccasionGroup.allCases.contains { !filteredOccasions(in: $0).isEmpty }
    }

    private func filteredOccasions(in group: OccasionGroup) -> [Occasion] {
        let groupOccasions = Occasion.allCases.filter { $0.group == group }
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return groupOccasions }

        return groupOccasions.filter {
            $0.searchText.localizedCaseInsensitiveContains(query)
        }
    }

    private func occasionButton(for occasion: Occasion) -> some View {
        Button {
            selection = occasion
            playSelectionFeedback()
            dismiss()
        } label: {
            OccasionPickerRow(
                occasion: occasion,
                isSelected: occasion == selection
            )
        }
        .buttonStyle(.plain)
    }
}

struct OccasionPickerRow: View {
    let occasion: Occasion
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: occasion.symbolName)
                .font(.headline)
                .frame(width: 28, height: 28)
                .foregroundStyle(Color.prosePalCoralDark)

            VStack(alignment: .leading, spacing: 3) {
                Text(occasion.displayName)
                    .font(.body.weight(.medium))
                    .foregroundStyle(.primary)
                Text(occasion.pickerDescription)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer()

            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(Color.prosePalCoralDark)
            }
        }
        .contentShape(Rectangle())
        .padding(.vertical, 4)
    }
}

private extension Occasion {
    var pickerDescription: String {
        switch self {
        case .birthday: "Birthday wishes for their day."
        case .thankYou: "A thoughtful note of thanks."
        case .sympathy: "Warm support and condolences."
        case .wedding: "Wishes for a couple's big day."
        case .christmas: "Warm festive wishes."
        case .getWell: "Encouragement while they recover."
        case .congrats: "Celebrate a win or achievement."
        case .mothersDay: "Appreciation for Mother's Day."
        case .fathersDay: "Appreciation for Father's Day."
        case .baby: "Welcome a new baby."
        case .graduation: "Celebrate graduation."
        case .anniversary: "Mark a special anniversary."
        case .valentinesDay: "A romantic or affectionate note."
        case .thinkingOfYou: "Let someone know you care."
        case .newYear: "Good wishes for the year ahead."
        case .engagement: "Celebrate an engagement."
        case .kidsBirthday: "A fun birthday note for a child."
        case .justBecause: "A warm note for no special reason."
        case .housewarming: "Congratulate someone on a new home."
        case .retirement: "Celebrate a new chapter."
        case .newJob: "Wish them well in a new role."
        case .encouragement: "Support them through a challenge."
        case .easter: "Spring and Easter wishes."
        case .thanksgiving: "Gratitude and holiday warmth."
        case .halloween: "A playful Halloween greeting."
        case .apology: "Say sorry with care."
        case .farewell: "A goodbye or leaving message."
        case .goodLuck: "Wish them luck for what's next."
        case .promotion: "Celebrate a promotion."
        case .thankYouTeacher: "Thank a teacher."
        case .thankYouHealthcare: "Thank someone for care."
        case .thankYouService: "Thank someone for service."
        case .hanukkah: "Warm Hanukkah wishes."
        case .diwali: "Bright Diwali wishes."
        case .eid: "Warm Eid wishes."
        case .lunarNewYear: "Lunar New Year wishes."
        case .kwanzaa: "Warm Kwanzaa wishes."
        case .petBirthday: "Celebrate a beloved pet."
        case .newPet: "Welcome a new pet."
        case .petSympathy: "Comfort after pet loss."
        }
    }
}

struct RelationshipPickerSheet: View {
    @Binding var selection: Relationship
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""

    var body: some View {
        NavigationStack {
            List {
                if !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                   !hasSearchResults {
                    ContentUnavailableView.search(text: searchText)
                }

                ForEach(RelationshipGroup.allCases) { group in
                    let relationships = filteredRelationships(in: group)
                    if !relationships.isEmpty {
                        Section(group.displayName) {
                            ForEach(relationships) { relationship in
                                Button {
                                    selection = relationship
                                    playSelectionFeedback()
                                    dismiss()
                                } label: {
                                    RelationshipPickerRow(
                                        relationship: relationship,
                                        isSelected: relationship == selection
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search relationships")
            .navigationTitle("Relationship")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }

    private var hasSearchResults: Bool {
        RelationshipGroup.allCases.contains { !filteredRelationships(in: $0).isEmpty }
    }

    private func filteredRelationships(in group: RelationshipGroup) -> [Relationship] {
        let groupRelationships = Relationship.allCases.filter { $0.group == group }
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return groupRelationships }

        return groupRelationships.filter {
            $0.searchText.localizedCaseInsensitiveContains(query)
        }
    }
}

private extension Relationship {
    var summaryObjectText: String {
        switch self {
        case .closeFriend: "a close friend"
        case .family: "family"
        case .parent: "a parent"
        case .child: "your child"
        case .sibling: "a sibling"
        case .grandparent: "a grandparent"
        case .grandchild: "a grandchild"
        case .romantic: "your partner"
        case .colleague: "a colleague"
        case .boss: "your boss"
        case .mentor: "a mentor"
        case .teacher: "a teacher"
        case .neighbor: "a neighbor"
        case .acquaintance: "an acquaintance"
        }
    }

    var searchText: String {
        "\(displayName) \(pickerDescription) \(generationHint)"
    }
}

private struct RelationshipPickerRow: View {
    let relationship: Relationship
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: relationship.symbolName)
                .font(.headline)
                .frame(width: 28, height: 28)
                .foregroundStyle(Color.prosePalCoralDark)

            VStack(alignment: .leading, spacing: 3) {
                Text(relationship.displayName)
                    .font(.body.weight(.medium))
                    .foregroundStyle(.primary)
                Text(relationship.pickerDescription)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer(minLength: 8)

            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(Color.prosePalCoralDark)
            }
        }
        .contentShape(Rectangle())
        .padding(.vertical, 4)
    }
}

private extension Relationship {
    var pickerDescription: String {
        switch self {
        case .closeFriend: "Close, familiar, and easygoing."
        case .family: "Warm and familiar."
        case .parent: "Loving, grateful, and respectful."
        case .child: "Proud, encouraging, and affectionate."
        case .sibling: "Familiar, loyal, and lightly teasing when it fits."
        case .grandparent: "Respectful, warm, and appreciative."
        case .grandchild: "Affectionate, proud, and encouraging."
        case .romantic: "Loving, personal, and intimate."
        case .colleague: "Friendly and work-appropriate."
        case .boss: "Respectful and professional."
        case .mentor: "Grateful and appreciative."
        case .teacher: "Thankful, respectful, and specific."
        case .neighbor: "Friendly and neighbourly."
        case .acquaintance: "Polite and not too familiar."
        }
    }
}

struct TonePickerSheet: View {
    @Binding var selection: Tone
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""

    var body: some View {
        NavigationStack {
            List {
                if !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                   filteredTones.isEmpty {
                    ContentUnavailableView.search(text: searchText)
                }

                Section("Tone") {
                    ForEach(filteredTones) { tone in
                        Button {
                            selection = tone
                            playSelectionFeedback()
                            dismiss()
                        } label: {
                            TonePickerRow(tone: tone, isSelected: tone == selection)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search tones")
            .navigationTitle("Tone")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }

    private var filteredTones: [Tone] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return Tone.allCases }

        return Tone.allCases.filter {
            $0.searchText.localizedCaseInsensitiveContains(query)
        }
    }
}

private extension Tone {
    var searchText: String {
        "\(displayName) \(description) \(generationHint)"
    }
}

private struct TonePickerRow: View {
    let tone: Tone
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: tone.symbolName)
                .font(.headline)
                .frame(width: 28, height: 28)
                .foregroundStyle(Color.prosePalCoralDark)

            VStack(alignment: .leading, spacing: 3) {
                Text(tone.displayName)
                    .font(.body.weight(.medium))
                    .foregroundStyle(.primary)
                Text(tone.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer(minLength: 8)

            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(Color.prosePalCoralDark)
            }
        }
        .contentShape(Rectangle())
        .padding(.vertical, 4)
    }
}
struct GenerationModeSelector: View {
    let selectedLane: GenerationLane
    let usageStatus: UsageStatus
    let onSelect: (GenerationLane) -> Void

    private let lanes: [GenerationLane] = [.standard, .premium]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Generation")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text(usageStatus.isPremiumUnlocked ? "Premium is active. Standard remains available for everyday messages." : "Standard is for everyday messages. Premium helps with harder moments and higher limits.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            ViewThatFits(in: .horizontal) {
                HStack(spacing: 8) {
                    ForEach(lanes, id: \.rawValue) { lane in
                        laneButton(for: lane)
                    }
                }

                VStack(spacing: 8) {
                    ForEach(lanes, id: \.rawValue) { lane in
                        laneButton(for: lane)
                    }
                }
            }
            .padding(.vertical, 2)
        }
    }

    private func laneButton(for lane: GenerationLane) -> some View {
        GenerationLaneButton(
            lane: lane,
            symbolName: symbolName(for: lane),
            subtitle: subtitle(for: lane),
            isSelected: lane == selectedLane,
            isLocked: usageStatus.isPremiumLocked(lane)
        ) {
            onSelect(lane)
        }
    }

    private func symbolName(for lane: GenerationLane) -> String {
        switch lane {
        case .automatic: "wand.and.stars"
        case .standard: "sparkles"
        case .premium: "star.fill"
        case .local: "iphone"
        }
    }

    private func subtitle(for lane: GenerationLane) -> String {
        switch lane {
        case .automatic: "Best fit"
        case .standard: "Everyday"
        case .premium:
            usageStatus.isPremiumUnlocked ? "Active" : "Harder moments"
        case .local: "On device"
        }
    }
}

private struct GenerationLaneButton: View {
    let lane: GenerationLane
    let symbolName: String
    let subtitle: String
    let isSelected: Bool
    let isLocked: Bool
    var onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 6) {
                Image(systemName: symbolName)
                    .font(.headline)
                Text(lane.displayName)
                    .font(.caption.weight(.semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.86)
                Text(subtitle)
                    .font(.caption2)
                    .foregroundStyle(isSelected ? .white.opacity(0.82) : .secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: 68)
            .padding(.horizontal, 6)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(isSelected ? Color.prosePalCoral : Color.prosePalSecondaryGroupedBackground)
            )
            .foregroundStyle(isSelected ? .white : .primary)
            .overlay(alignment: .topTrailing) {
                if isLocked {
                    Image(systemName: "lock.fill")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(isSelected ? .white : .secondary)
                        .padding(8)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(lane.displayName), \(subtitle)")
    }
}

struct UsageStatusRow: View {
    let usageStatus: UsageStatus

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: usageStatus.isPremiumUnlocked ? "checkmark.seal.fill" : "gauge")
                .font(.callout.weight(.semibold))
                .foregroundStyle(Color.prosePalCoralDark)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 3) {
                Text(usageStatus.usageText)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.primary)
                Text(usageStatus.detailText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)
        }
        .padding(12)
        .background(Color.prosePalSecondaryGroupedBackground, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .accessibilityElement(children: .combine)
    }
}

struct ResultsView: View {
    @EnvironmentObject private var model: ProsePalAppModel

    var body: some View {
        Group {
            if model.generatedMessages.isEmpty {
                EmptyStateView(
                    title: "No drafts yet",
                    systemImage: "text.page",
                    detail: "Write a message and your drafts will appear here."
                )
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        resultsContextCard

                        generationStatus

                        ForEach(Array(model.generatedMessages.enumerated()), id: \.element.id) { index, message in
                            ResultCard(message: message, draftNumber: index + 1)
                        }
                    }
                    .padding(20)
                    .padding(.bottom, 96)
                }
                .background(Color.prosePalGroupedBackground)
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    resultsActionBar
                }
            }
        }
        .navigationTitle(resultsTitle)
        .hideTabBarOnIOS()
    }

    private var resultsActionBar: some View {
        VStack(spacing: 10) {
            adjustButton
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 10) {
                    startNewButton
                    regenerateButton
                }

                VStack(spacing: 10) {
                    startNewButton
                    regenerateButton
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .padding(.bottom, 12)
        .background(.bar)
        .overlay(alignment: .top) {
            Divider()
        }
    }

    private var resultsContextCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: model.draft.occasion.symbolName)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Color.prosePalCoralDark)
                    .frame(width: 36, height: 36)
                    .background(Color.prosePalCoral.opacity(0.12), in: Circle())

                VStack(alignment: .leading, spacing: 4) {
                    Text("Drafts")
                        .font(.title2.weight(.bold))
                    Text("Pick one to copy, or adjust the details and try again.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)
            }

            ViewThatFits(in: .horizontal) {
                HStack(spacing: 8) {
                    ResultContextPill(text: model.draft.occasion.displayName, systemImage: "calendar")
                    ResultContextPill(text: model.draft.relationship.displayName, systemImage: "person.2")
                    ResultContextPill(text: model.draft.tone.displayName, systemImage: "slider.horizontal.3")
                }

                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        ResultContextPill(text: model.draft.occasion.displayName, systemImage: "calendar")
                        ResultContextPill(text: model.draft.relationship.displayName, systemImage: "person.2")
                    }
                    ResultContextPill(text: model.draft.tone.displayName, systemImage: "slider.horizontal.3")
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.prosePalSecondaryGroupedBackground, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private var adjustButton: some View {
        Button {
            model.adjustCurrentMessage()
        } label: {
            Label("Adjust details", systemImage: "slider.horizontal.3")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
        .controlSize(.large)
    }

    private var startNewButton: some View {
        Button {
            model.startNewMessage()
        } label: {
            Label("Start new", systemImage: "square.and.pencil")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
        .controlSize(.large)
    }

    private var regenerateButton: some View {
        Button {
            model.startGeneration()
        } label: {
            Label(model.isGenerating ? "Writing" : "Regenerate", systemImage: "arrow.clockwise")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .disabled(model.isGenerating)
    }

    @ViewBuilder
    private var generationStatus: some View {
        if model.fallbackStatus != .none {
            VStack(alignment: .leading, spacing: 10) {
                Label("Generation used a backup route. You can retry shortly.", systemImage: "wand.and.stars.inverse")
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Button {
                    model.startGeneration()
                } label: {
                    Label("Retry generation", systemImage: "arrow.clockwise")
                }
                .font(.footnote.weight(.semibold))
                .disabled(model.isGenerating)
            }
            .padding(12)
            .background(Color.prosePalProGold.opacity(0.14), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        } else if let lane = model.laneUsed {
            Label("\(lane.displayName) generation", systemImage: "checkmark.seal")
                .font(.footnote.weight(.medium))
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var resultsTitle: String {
        guard let recipient = model.draft.recipientName.nilIfBlank else {
            return "Your messages"
        }
        return "Messages for \(recipient)"
    }

}

private struct ResultContextPill: View {
    let text: String
    let systemImage: String

    var body: some View {
        Label(text, systemImage: systemImage)
            .font(.caption.weight(.semibold))
            .lineLimit(1)
            .minimumScaleFactor(0.82)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(.regularMaterial, in: Capsule())
    }
}

struct ResultCard: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @EnvironmentObject private var model: ProsePalAppModel
    let message: GeneratedMessage
    let draftNumber: Int
    @State private var editedText = ""
    @State private var isEditing = false
    @State private var isCopied = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label("Option \(draftNumber)", systemImage: "text.page")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                if model.isSaved(message) {
                    Label("Saved", systemImage: "bookmark.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.prosePalCoralDark)
                }
            }

            Text(message.text)
                .font(.body)
                .lineSpacing(4)
                .textSelection(.enabled)

            resultActions
                .controlSize(.regular)
        }
        .padding(18)
        .background(Color.prosePalSecondaryGroupedBackground, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .contextMenu {
            Button {
                copyMessage()
            } label: {
                Label("Copy", systemImage: "doc.on.doc")
            }

            Button {
                model.logEditStarted(message.text, source: "result_context_menu")
                editedText = message.text
                isEditing = true
            } label: {
                Label("Edit", systemImage: "square.and.pencil")
            }

            Button {
                model.save(message)
            } label: {
                Label("Save", systemImage: "bookmark")
            }
            .disabled(model.isSaved(message))
        }
        .sheet(isPresented: $isEditing) {
            DraftEditorSheet(
                title: "Edit Option \(draftNumber)",
                text: $editedText,
                onCopy: { model.copyText(editedText) },
                onShare: { model.logShareText(editedText, source: "result_editor") },
                onSave: {
                    if model.saveText(editedText) {
                        isEditing = false
                    }
                }
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .onAppear {
            editedText = message.text
        }
    }

    @ViewBuilder
    private var resultActions: some View {
        VStack(spacing: 10) {
            copyButton

            secondaryResultActions
        }
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private var secondaryResultActions: some View {
        if dynamicTypeSize.isAccessibilitySize {
            VStack(spacing: 8) {
                shareLink
                    .frame(maxWidth: .infinity)
                editButton
                    .frame(maxWidth: .infinity)
                saveButton
                    .frame(maxWidth: .infinity)
            }
        } else {
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 8) {
                    shareLink
                        .frame(maxWidth: .infinity)
                    editButton
                        .frame(maxWidth: .infinity)
                    saveButton
                        .frame(maxWidth: .infinity)
                }

                VStack(spacing: 8) {
                    shareLink
                        .frame(maxWidth: .infinity)
                    editButton
                        .frame(maxWidth: .infinity)
                    saveButton
                        .frame(maxWidth: .infinity)
                }
            }
        }
    }

    private var copyButton: some View {
        Button {
            copyMessage()
        } label: {
            Label(isCopied ? "Copied" : "Copy", systemImage: isCopied ? "checkmark" : "doc.on.doc")
                .font(.subheadline.weight(.semibold))
                .frame(maxWidth: .infinity, minHeight: 48)
        }
        .buttonStyle(.borderedProminent)
        .tint(Color.prosePalCoral)
    }

    private var shareLink: some View {
        ShareLink(item: message.text) {
            Label("Share", systemImage: "square.and.arrow.up")
                .font(.subheadline.weight(.semibold))
                .frame(maxWidth: .infinity, minHeight: 44)
        }
        .simultaneousGesture(TapGesture().onEnded {
            model.logShareText(message.text, source: "result_card")
        })
        .buttonStyle(.bordered)
        .tint(Color.prosePalCoralDark)
    }

    private var editButton: some View {
        Button {
            model.logEditStarted(message.text, source: "result_card")
            editedText = message.text
            isEditing = true
        } label: {
            Label("Edit", systemImage: "square.and.pencil")
                .font(.subheadline.weight(.semibold))
                .frame(maxWidth: .infinity, minHeight: 44)
        }
        .buttonStyle(.bordered)
        .tint(Color.prosePalCoralDark)
    }

    private var saveButton: some View {
        Button {
            model.save(message)
        } label: {
            Label(model.isSaved(message) ? "Saved" : "Save", systemImage: model.isSaved(message) ? "bookmark.fill" : "bookmark")
                .font(.subheadline.weight(.semibold))
                .frame(maxWidth: .infinity, minHeight: 44)
        }
        .disabled(model.isSaved(message))
        .buttonStyle(.bordered)
        .tint(Color.prosePalCoralDark)
    }

    private func copyMessage() {
        model.copyText(message.text)
        isCopied = true

        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 1_700_000_000)
            isCopied = false
        }
    }
}

struct DraftEditorSheet: View {
    var title: String
    @Binding var text: String
    var onCopy: () -> Void
    var onShare: () -> Void = {}
    var onSave: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 8) {
                ZStack(alignment: .topLeading) {
                    TextEditor(text: $text)
                        .font(.body)
                        .lineSpacing(4)
                        .padding(12)
                        .frame(minHeight: 220)

                    if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Text("Write your message here")
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 17)
                            .padding(.vertical, 20)
                            .allowsHitTesting(false)
                    }
                }
                .background(Color.prosePalSecondaryGroupedBackground, in: RoundedRectangle(cornerRadius: 18, style: .continuous))

                Text("\(text.count) characters")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .padding(20)
            .padding(.bottom, 68)
            .background(Color.prosePalGroupedBackground)
            .navigationTitle(title)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                editorActions
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    .padding(.bottom, 12)
                    .background(.bar)
                    .overlay(alignment: .top) {
                        Divider()
                    }
            }
        }
    }

    private var editorActions: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 10) {
                Button {
                    onCopy()
                } label: {
                    Label("Copy", systemImage: "doc.on.doc")
                }

                ShareLink(item: text) {
                    Label("Share", systemImage: "square.and.arrow.up")
                }
                .simultaneousGesture(TapGesture().onEnded(onShare))

                Spacer(minLength: 8)

                Button {
                    onSave()
                } label: {
                    Label("Save", systemImage: "bookmark")
                }
                .buttonStyle(.borderedProminent)
            }
            .buttonStyle(.bordered)

            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 10) {
                    Button {
                        onCopy()
                    } label: {
                        Label("Copy", systemImage: "doc.on.doc")
                    }

                    ShareLink(item: text) {
                        Label("Share", systemImage: "square.and.arrow.up")
                    }
                    .simultaneousGesture(TapGesture().onEnded(onShare))
                }

                Button {
                    onSave()
                } label: {
                    Label("Save", systemImage: "bookmark")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            }
            .buttonStyle(.bordered)
        }
    }
}

struct PaywallSheet: View {
    @EnvironmentObject private var model: ProsePalAppModel
    let usageStatus: UsageStatus
    let onUseStandard: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 12) {
                        Label("ProsePal Pro", systemImage: "star.fill")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(Color.prosePalProGold)

                        Text("Keep the words flowing")
                            .font(.largeTitle.weight(.bold))
                            .minimumScaleFactor(0.78)

                        Text("Premium generation adds help for harder moments, higher limits, and more room to rewrite.")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    VStack(spacing: 12) {
                        PremiumFeatureRow(systemImage: "heart.text.square", title: "Harder moments", detail: "More support for nuanced, sensitive, or high-stakes messages.")
                        PremiumFeatureRow(systemImage: "infinity", title: "Higher limits", detail: "More room for everyday messages.")
                        PremiumFeatureRow(systemImage: "arrow.triangle.2.circlepath", title: "More rewrites", detail: "Try a warmer, shorter, or clearer version when the first draft is not quite right.")
                    }

                    UsageStatusRow(usageStatus: usageStatus)

                    productSection

                    VStack(spacing: 10) {
                        Button {
                            Task {
                                await model.purchasePremium(source: "paywall")
                            }
                        } label: {
                            Label(model.isPurchasingPremium ? "Working..." : "Continue with Premium", systemImage: "star.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .disabled(model.isPurchasingPremium || model.isLoadingSubscriptions || model.subscriptionProducts.isEmpty)

                        Text(model.premiumRenewalDisclosureText)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)

                        Button {
                            Task {
                                await model.restorePurchases(source: "paywall")
                            }
                        } label: {
                            Label(model.isRestoringPurchases ? "Restoring..." : "Restore purchases", systemImage: "arrow.clockwise")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.large)
                        .disabled(model.isRestoringPurchases)

                        Button {
                            onUseStandard()
                            dismiss()
                        } label: {
                            Label("Use Standard", systemImage: "sparkles")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.large)

                        Button("Not now") {
                            dismiss()
                        }
                        .font(.callout.weight(.semibold))
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Sync across devices")
                            .font(.headline)

                        Text("Sign in with Apple to keep purchases and saved messages connected to you.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)

                        AppleSignInControl(source: "paywall")
                            .environmentObject(model)
                    }
                    .padding(14)
                    .background(Color.prosePalSecondaryGroupedBackground, in: RoundedRectangle(cornerRadius: 18, style: .continuous))

                    HStack(spacing: 8) {
                        Link("Terms", destination: SettingsExternalLinks.terms)
                        Text("/")
                        Link("Privacy Policy", destination: SettingsExternalLinks.privacy)
                    }
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                }
                .padding(22)
            }
            .background(Color.prosePalGroupedBackground)
            .navigationTitle("Premium")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .task {
                await model.loadSubscriptionProducts(source: "paywall")
            }
        }
    }

    @ViewBuilder
    private var productSection: some View {
        if model.isLoadingSubscriptions {
            PaywallLoadingRow()
        } else if model.subscriptionProducts.isEmpty {
            PaywallUnavailableRow(
                message: model.subscriptionErrorMessage ?? SubscriptionError.notConfigured.userSafeMessage,
                onRetry: {
                    Task {
                        await model.loadSubscriptionProducts(source: "paywall_retry")
                    }
                }
            )
        } else {
            VStack(spacing: 10) {
                ForEach(model.subscriptionProducts) { product in
                    Button {
                        model.selectSubscriptionProduct(product)
                    } label: {
                        PaywallPlanRow(
                            title: product.displayName,
                            subtitle: product.durationLabel ?? "Premium access",
                            price: product.displayPrice,
                            badge: product.isRecommended ? "Best value" : nil,
                            isSelected: model.selectedSubscriptionProductID == product.id
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

struct PaywallPlanRow: View {
    let title: String
    let subtitle: String
    let price: String
    let badge: String?
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(isSelected ? Color.prosePalCoral : .secondary)
                .font(.title3)

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 8) {
                    Text(title)
                        .font(.headline)
                    if let badge {
                        Text(badge)
                            .font(.caption2.weight(.bold))
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(Color.prosePalCoralLight, in: Capsule())
                            .foregroundStyle(Color.prosePalCoralDark)
                    }
                }

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 10)

            Text(price)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
        }
        .padding(14)
        .background(Color.prosePalSecondaryGroupedBackground, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(isSelected ? Color.prosePalCoral.opacity(0.55) : Color.clear, lineWidth: 1.4)
        }
    }
}

struct PaywallLoadingRow: View {
    var body: some View {
        HStack(spacing: 12) {
            ProgressView()
                .controlSize(.regular)

            VStack(alignment: .leading, spacing: 3) {
                Text("Loading subscription options")
                    .font(.headline)
                Text("This should only take a moment.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)
        }
        .padding(14)
        .background(Color.prosePalSecondaryGroupedBackground, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .accessibilityElement(children: .combine)
    }
}

struct PaywallUnavailableRow: View {
    let message: String
    let onRetry: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Color.prosePalCoralDark)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Subscription options unavailable")
                        .font(.headline)
                    Text(message)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Button {
                onRetry()
            } label: {
                Label("Retry", systemImage: "arrow.clockwise")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
        }
        .padding(14)
        .background(Color.prosePalSecondaryGroupedBackground, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .accessibilityElement(children: .combine)
    }
}

struct AppleSignInControl: View {
    @EnvironmentObject private var model: ProsePalAppModel
    let source: String

    var body: some View {
        #if canImport(AuthenticationServices)
        if model.isAppleSignInConfigured {
            SignInWithAppleButton(.continue) { request in
                request.requestedScopes = [.email, .fullName]
                request.nonce = model.beginAppleSignInRequest(source: source)
            } onCompletion: { result in
                handle(result)
            }
            .signInWithAppleButtonStyle(.black)
            .frame(maxWidth: .infinity, minHeight: 52, maxHeight: 52)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .disabled(model.isSigningIn)
            .accessibilityLabel("Continue with Apple")
        } else {
            Button {
                _ = model.beginAppleSignInRequest(source: source)
            } label: {
                Label("Continue with Apple", systemImage: "apple.logo")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
        }
        #else
        Button {
            _ = model.beginAppleSignInRequest(source: source)
        } label: {
            Label("Continue with Apple", systemImage: "apple.logo")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
        .controlSize(.large)
        #endif
    }

    #if canImport(AuthenticationServices)
    private func handle(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            guard
                let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
                let tokenData = credential.identityToken,
                let token = String(data: tokenData, encoding: .utf8)
            else {
                Task { @MainActor in
                    await model.completeAppleSignIn(idToken: nil, source: source)
                }
                return
            }

            Task { @MainActor in
                await model.completeAppleSignIn(idToken: token, source: source)
            }
        case .failure(let error):
            if let authorizationError = error as? ASAuthorizationError,
               authorizationError.code == .canceled {
                model.cancelAppleSignIn(source: source)
            } else {
                model.failAppleSignIn(source: source)
            }
        }
    }
    #endif
}

struct PremiumFeatureRow: View {
    let systemImage: String
    let title: String
    let detail: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: systemImage)
                .font(.headline)
                .foregroundStyle(Color.prosePalCoralDark)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.headline)
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color.prosePalSecondaryGroupedBackground, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

struct SavedMessagesView: View {
    @EnvironmentObject private var model: ProsePalAppModel
    @State private var searchText = ""

    private var filteredSavedMessages: [SavedMessage] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return model.savedMessages }

        return model.savedMessages.filter { saved in
            saved.title.localizedCaseInsensitiveContains(query) ||
            saved.subtitle.localizedCaseInsensitiveContains(query) ||
            saved.text.localizedCaseInsensitiveContains(query)
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if model.savedMessages.isEmpty {
                    EmptyStateView(
                        title: "No Saved Messages",
                        systemImage: "bookmark",
                        detail: "When a draft feels right, save it here for later."
                    )
                } else {
                    List {
                        if filteredSavedMessages.isEmpty {
                            ContentUnavailableView.search(text: searchText)
                        } else {
                            ForEach(filteredSavedMessages) { saved in
                                NavigationLink {
                                    SavedMessageDetailView(saved: saved)
                                } label: {
                                    SavedMessageRow(saved: saved)
                                }
                            }
                            .onDelete { offsets in
                                offsets
                                    .map { filteredSavedMessages[$0] }
                                    .forEach(model.deleteSaved)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Saved")
            .searchable(text: $searchText, prompt: "Search saved messages")
        }
    }
}

struct SavedMessageRow: View {
    let saved: SavedMessage

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack {
                Label(saved.title, systemImage: saved.occasion.symbolName)
                    .font(.headline)
                    .lineLimit(1)
                Spacer()
                Text(saved.savedAt.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Text(saved.text)
                .font(.callout)
                .foregroundStyle(.secondary)
                .lineLimit(2)

            Text(saved.subtitle)
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .padding(.vertical, 6)
    }
}

struct SavedMessageDetailView: View {
    @EnvironmentObject private var model: ProsePalAppModel
    @Environment(\.dismiss) private var dismiss
    let saved: SavedMessage
    @State private var editedText: String
    @State private var isEditing = false
    @State private var isConfirmingDelete = false

    init(saved: SavedMessage) {
        self.saved = saved
        _editedText = State(initialValue: saved.text)
    }

    private var currentSaved: SavedMessage {
        model.savedMessages.first { $0.id == saved.id } ?? saved
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 12) {
                    Label(currentSaved.occasion.displayName, systemImage: currentSaved.occasion.symbolName)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)

                    Text(currentSaved.text)
                        .font(.body)
                        .lineSpacing(5)
                        .textSelection(.enabled)
                }
                .padding(18)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.prosePalSecondaryGroupedBackground, in: RoundedRectangle(cornerRadius: 22, style: .continuous))

                ModernPanel {
                    LabeledContent("Recipient", value: currentSaved.recipientName ?? "Not specified")
                    LabeledContent("Occasion", value: currentSaved.occasion.displayName)
                    LabeledContent("Relationship", value: currentSaved.relationship.displayName)
                    LabeledContent("Tone", value: currentSaved.tone.displayName)
                    LabeledContent("Length", value: currentSaved.length.displayName)
                    LabeledContent("Saved", value: currentSaved.savedAt.formatted(date: .abbreviated, time: .shortened))
                }

                HStack(spacing: 10) {
                    Button {
                        model.copyText(currentSaved.text)
                    } label: {
                        Label("Copy", systemImage: "doc.on.doc")
                    }

                    ShareLink(item: currentSaved.text) {
                        Label("Share", systemImage: "square.and.arrow.up")
                    }
                    .simultaneousGesture(TapGesture().onEnded {
                        model.logShareText(currentSaved.text, source: "saved_detail")
                    })

                    Button {
                        model.logEditStarted(currentSaved.text, source: "saved_detail")
                        editedText = currentSaved.text
                        isEditing = true
                    } label: {
                        Label("Edit", systemImage: "square.and.pencil")
                    }
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
            }
            .padding(20)
        }
        .background(Color.prosePalGroupedBackground)
        .navigationTitle(currentSaved.title)
        .toolbar {
            ToolbarItem(placement: .destructiveAction) {
                Button(role: .destructive) {
                    isConfirmingDelete = true
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
        }
        .confirmationDialog("Delete saved message?", isPresented: $isConfirmingDelete, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                model.deleteSaved(currentSaved)
                dismiss()
            }
        }
        .sheet(isPresented: $isEditing) {
            DraftEditorSheet(
                title: "Edit Saved Message",
                text: $editedText,
                onCopy: { model.copyText(editedText) },
                onShare: { model.logShareText(editedText, source: "saved_editor") },
                onSave: {
                    if model.updateSaved(currentSaved, text: editedText) {
                        isEditing = false
                    }
                }
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
    }
}

private enum SettingsExternalLinks {
    static let appleSubscriptions = URL(string: "https://apps.apple.com/account/subscriptions")!
    static let support = URL(string: "https://www.prosepal.app/support.html")!
    static let terms = URL(string: "https://www.prosepal.app/terms.html")!
    static let privacy = URL(string: "https://www.prosepal.app/privacy.html")!
    static let feedbackEmail = URL(string: "mailto:jarryd@prosepal.app?subject=ProsePal%20Feedback")!
}

struct SettingsView: View {
    @EnvironmentObject private var model: ProsePalAppModel
#if canImport(StoreKit)
    @Environment(\.requestReview) private var requestReview
#endif
    @State private var isShowingAccountSheet = false

    var body: some View {
        NavigationStack {
            List {
                accountSection
                subscriptionSection
                securitySection
                writingSection
                statsSection
                supportSection
                privacySection
                accountActionsSection
                aboutSection
#if DEBUG
                runtimeReadinessSection
#endif
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $isShowingAccountSheet) {
                AccountSignInSheet()
                    .environmentObject(model)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
            }
            .onChange(of: model.draft.spellingPreference) { _, preference in
                model.logSelectionChanged(kind: "spelling", value: preference.rawValue)
            }
            .onChange(of: model.draft.tone) { _, tone in
                model.logSelectionChanged(kind: "tone", value: tone.rawValue)
            }
        }
    }

    private var accountSection: some View {
        Section("Account") {
            if model.isSignedIn {
                SettingsRow(
                    systemImage: "person.crop.circle.fill",
                    title: "Apple account",
                    subtitle: model.signedInEmail ?? "Signed in with Apple",
                    trailingText: model.usageStatus.isPremiumUnlocked ? "Pro" : "Free",
                    tint: Color.prosePalCoralDark
                )
            } else {
                Button {
                    isShowingAccountSheet = true
                } label: {
                    SettingsRow(
                        systemImage: "apple.logo",
                        title: "Sign in with Apple",
                        subtitle: "Sync saved messages, purchases, and preferences",
                        trailingSystemImage: "chevron.right",
                        tint: .primary
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var subscriptionSection: some View {
        Section("Subscription") {
            Button {
                model.logPaywallOpened(trigger: "settings_subscription")
                model.isShowingPaywall = true
            } label: {
                SettingsRow(
                    systemImage: model.usageStatus.isPremiumUnlocked ? "star.fill" : "star",
                    title: model.usageStatus.isPremiumUnlocked ? "ProsePal Pro" : "Free Plan",
                    subtitle: model.isRefreshingSubscriptionEntitlement ? "Checking your subscription..." : model.usageStatus.usageText,
                    trailingText: model.usageStatus.isPremiumUnlocked ? "Active" : "Buy Pro",
                    tint: model.usageStatus.isPremiumUnlocked ? Color.prosePalProGold : Color.prosePalCoral
                )
            }
            .buttonStyle(.plain)

            externalSettingsLink(
                id: "manage_subscription",
                destination: SettingsExternalLinks.appleSubscriptions,
                systemImage: "creditcard",
                title: "Manage Subscription",
                subtitle: "Open Apple subscription settings"
            )

            Button {
                Task {
                    await model.restorePurchases(source: "settings")
                }
            } label: {
                SettingsRow(
                    systemImage: "arrow.clockwise",
                    title: "Restore Purchases",
                    subtitle: model.isRestoringPurchases ? "Restoring..." : "Reinstalled? Restore your Pro access"
                )
            }
            .buttonStyle(.plain)
            .disabled(model.isRestoringPurchases)
        }
    }

    private var securitySection: some View {
        Section("Security") {
            Toggle(
                isOn: Binding(
                    get: { model.biometricLockEnabled },
                    set: { model.setBiometricLockEnabled($0) }
                )
            ) {
                SettingsToggleLabel(
                    systemImage: "faceid",
                    title: "Face ID",
                    subtitle: model.isSignedIn ? "Require Face ID to open ProsePal" : "Sign in before enabling app lock"
                )
            }
        }
    }

    private var writingSection: some View {
        Section("Writing") {
            VStack(alignment: .leading, spacing: 10) {
                SettingsToggleLabel(
                    systemImage: "translate",
                    title: "Spelling",
                    subtitle: model.draft.spellingPreference.exampleText
                )

                Picker("Spelling", selection: $model.draft.spellingPreference) {
                    ForEach(SpellingPreference.allCases) { preference in
                        Text(preference.displayName).tag(preference)
                    }
                }
                .pickerStyle(.segmented)
            }
            .padding(.vertical, 4)

            Picker("Default tone", selection: $model.draft.tone) {
                ForEach(Tone.allCases) { tone in
                    Text(tone.displayName).tag(tone)
                }
            }

            ForEach([GenerationLane.standard, .premium], id: \.rawValue) { lane in
                Button {
                    model.selectLane(lane)
                } label: {
                    SettingsRow(
                        systemImage: lane == .premium ? "star" : "sparkles",
                        title: lane == .standard ? "Standard generation" : "Premium generation",
                        subtitle: lane == .standard ? "Everyday messages" : "Harder moments and higher limits",
                        trailingSystemImage: model.draft.requestedLane == lane ? "checkmark" : (model.usageStatus.isPremiumLocked(lane) ? "lock.fill" : nil),
                        tint: model.draft.requestedLane == lane ? Color.prosePalCoral : .secondary
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var statsSection: some View {
        Section("Your Stats") {
            LabeledContent("Generated drafts", value: "\(model.totalGeneratedCount)")
            LabeledContent("Saved messages", value: "\(model.savedMessages.count)")
            LabeledContent("Standard left", value: "\(model.usageStatus.standardRemaining) of \(model.usageStatus.standardLimit)")
        }
    }

    private var supportSection: some View {
        Section("Support") {
            externalSettingsLink(
                id: "support",
                destination: SettingsExternalLinks.support,
                systemImage: "questionmark.circle",
                title: "Help & FAQ",
                subtitle: "Common questions and support"
            )

            externalSettingsLink(
                id: "feedback",
                destination: SettingsExternalLinks.feedbackEmail,
                systemImage: "envelope",
                title: "Send Feedback",
                subtitle: "Questions, bugs, or feature requests"
            )

            Button {
                model.requestAppReview()
#if canImport(StoreKit)
                requestReview()
#endif
            } label: {
                SettingsRow(
                    systemImage: "star",
                    title: "Rate ProsePal",
                    subtitle: "Love the app? Leave a review"
                )
            }
            .buttonStyle(.plain)
        }
    }

    private var privacySection: some View {
        Section("Privacy & Legal") {
            externalSettingsLink(
                id: "terms",
                destination: SettingsExternalLinks.terms,
                systemImage: "doc.text",
                title: "Terms of Service",
                subtitle: "Read the current terms on prosepal.app",
                trailingSystemImage: "arrow.up.right"
            )

            externalSettingsLink(
                id: "privacy",
                destination: SettingsExternalLinks.privacy,
                systemImage: "hand.raised",
                title: "Privacy Policy",
                subtitle: "How ProsePal handles messages, accounts, and purchases",
                trailingSystemImage: "arrow.up.right"
            )
        }
    }

    private var accountActionsSection: some View {
        Section("Account Actions") {
            Button {
                model.requestDataExport()
            } label: {
                SettingsRow(
                    systemImage: "square.and.arrow.up",
                    title: "Export My Data",
                    subtitle: model.dataExportStatusText
                )
            }
            .buttonStyle(.plain)

            Button {
                Task {
                    await model.signOut()
                }
            } label: {
                SettingsRow(
                    systemImage: "rectangle.portrait.and.arrow.right",
                    title: "Sign Out",
                    subtitle: model.isSignedIn ? nil : "No account signed in",
                    tint: .secondary
                )
            }
            .buttonStyle(.plain)

            Button(role: .destructive) {
                model.requestAccountDeletion()
            } label: {
                SettingsRow(
                    systemImage: "trash",
                    title: "Delete Account",
                    subtitle: model.accountDeletionStatusText,
                    tint: .red
                )
            }
            .buttonStyle(.plain)
        }
    }

    private var aboutSection: some View {
        Section("About") {
            LabeledContent("Writing", value: model.writingRuntimeDisplayText)
            LabeledContent("Version", value: model.appVersionDisplayText)
        }
    }

    private var runtimeReadinessSection: some View {
        Section("Staging Setup") {
            ForEach(model.runtimeReadiness.settingsItems) { item in
                SettingsRow(
                    systemImage: item.systemImage,
                    title: item.title,
                    subtitle: item.detail,
                    trailingText: item.statusText,
                    tint: item.isReady ? .green : Color.prosePalCoral
                )
            }
        }
    }

    private func externalSettingsLink(
        id: String,
        destination: URL,
        systemImage: String,
        title: String,
        subtitle: String?,
        trailingSystemImage: String? = "arrow.up.right"
    ) -> some View {
        Link(destination: destination) {
            SettingsRow(
                systemImage: systemImage,
                title: title,
                subtitle: subtitle,
                trailingSystemImage: trailingSystemImage
            )
        }
        .simultaneousGesture(TapGesture().onEnded {
            model.openSettingsLink(id)
        })
        .buttonStyle(.plain)
    }
}

struct AccountSignInSheet: View {
    @EnvironmentObject private var model: ProsePalAppModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Sign in with Apple")
                            .font(.largeTitle.weight(.bold))
                            .minimumScaleFactor(0.78)

                        Text("Keep your saved messages, purchases, and writing preferences connected to you.")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    VStack(spacing: 12) {
                        PremiumFeatureRow(systemImage: "bookmark", title: "Saved messages", detail: "Keep your favourites with you across devices.")
                        PremiumFeatureRow(systemImage: "arrow.clockwise", title: "Purchase restore", detail: "Connect Pro access to your Apple account.")
                        PremiumFeatureRow(systemImage: "lock.shield", title: "Account protection", detail: "Use Apple sign-in for sensitive account actions.")
                    }

                    AppleSignInControl(source: "settings")
                        .environmentObject(model)

                    VStack(spacing: 4) {
                        Text("By continuing, you agree to the")
                        HStack(spacing: 4) {
                            Link("Terms", destination: SettingsExternalLinks.terms)
                            Text("and")
                            Link("Privacy Policy", destination: SettingsExternalLinks.privacy)
                        }
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .tint(Color.prosePalCoralDark)
                    .frame(maxWidth: .infinity)
                    .multilineTextAlignment(.center)
                }
                .padding(22)
            }
            .background(Color.prosePalGroupedBackground)
            .navigationTitle("Account")
            .onChange(of: model.isSignedIn) { _, isSignedIn in
                if isSignedIn {
                    dismiss()
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}

struct SettingsRow: View {
    let systemImage: String
    let title: String
    var subtitle: String?
    var trailingText: String?
    var trailingSystemImage: String?
    var tint: Color = .secondary

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.body.weight(.semibold))
                .foregroundStyle(tint)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.body)
                    .foregroundStyle(.primary)
                if let subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Spacer(minLength: 10)

            if let trailingText {
                Text(trailingText)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(tint)
                    .lineLimit(1)
            }

            if let trailingSystemImage {
                Image(systemName: trailingSystemImage)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(tint)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

struct SettingsToggleLabel: View {
    let systemImage: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: systemImage)
                .font(.body.weight(.semibold))
                .foregroundStyle(.secondary)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.body)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

struct ModernPanel<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        VStack(spacing: 12) {
            content
        }
        .padding(16)
        .background(Color.prosePalSecondaryGroupedBackground, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}

struct NoticeBanner: View {
    let notice: AppNotice

    var body: some View {
        Label(notice.title, systemImage: notice.systemImage)
            .font(.callout.weight(.semibold))
            .foregroundStyle(.primary)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(.regularMaterial, in: Capsule(style: .continuous))
            .shadow(color: .black.opacity(0.12), radius: 18, x: 0, y: 8)
    }
}

private struct WritingProgressOverlay: View {
    let draft: MessageDraft
    let onCancel: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var messageIndex = 0
    @ScaledMetric(relativeTo: .largeTitle) private var sparklesSize: CGFloat = 34

    private let messages = [
        "Finding the right words...",
        "Shaping the tone...",
        "Adding the details...",
        "Almost ready..."
    ]

    var body: some View {
        ZStack {
            ProsePalBrandBackdrop()

            VStack(spacing: 22) {
                VStack(spacing: 22) {
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.14))
                            .frame(width: 96, height: 96)
                        Circle()
                            .strokeBorder(Color.white.opacity(0.22), lineWidth: 1)
                            .frame(width: 96, height: 96)
                        Image(systemName: "sparkles")
                            .font(.system(size: sparklesSize, weight: .semibold))
                            .foregroundStyle(.white)
                            .scaleEffect(reduceMotion ? 1 : (messageIndex.isMultiple(of: 2) ? 1 : 1.05))
                            .animation(.easeInOut(duration: 0.22), value: messageIndex)
                    }

                    VStack(spacing: 8) {
                        Text("Writing")
                            .font(.title.weight(.bold))
                            .foregroundStyle(.white)
                        Text(progressContext)
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.84))
                            .lineLimit(2)
                            .multilineTextAlignment(.center)
                        Text(messages[messageIndex])
                            .font(.callout)
                            .foregroundStyle(Color.prosePalTextSecondary)
                            .contentTransition(.opacity)
                    }

                    ProgressView()
                        .tint(.white)
                        .controlSize(.large)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Writing \(draft.occasion.displayName) message. Please wait.")

                Button(role: .cancel, action: onCancel) {
                    Label("Cancel", systemImage: "xmark.circle")
                        .font(.callout.weight(.semibold))
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .tint(.white)
                .foregroundStyle(.white)
                .accessibilityHint("Stops writing and returns to the compose screen.")
            }
            .padding(28)
        }
        .ignoresSafeArea()
        .task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 1_900_000_000)
                guard !Task.isCancelled else { return }
                withAnimation(.easeInOut(duration: reduceMotion ? 0 : 0.22)) {
                    messageIndex = (messageIndex + 1) % messages.count
                }
            }
        }
    }

    private var progressContext: String {
        let length = draft.length == .standard ? "" : "\(draft.length.displayName) "
        return "\(draft.tone.displayName) \(length)\(draft.occasion.displayName) message"
    }
}

private struct ProsePalBrandBackdrop: View {
    var body: some View {
        LinearGradient(
            colors: [
                Color.prosePalDeepNavy,
                Color.prosePalNavy,
                Color.prosePalSurface
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .overlay {
            LinearGradient(
                colors: [
                    Color.prosePalCoral.opacity(0.16),
                    Color.clear,
                    Color.prosePalNavy.opacity(0.26)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
        .ignoresSafeArea()
    }
}

private extension View {
    @ViewBuilder
    func prosePalOnboardingToolbarStyle() -> some View {
        #if os(iOS)
        self.toolbarColorScheme(.dark, for: .navigationBar)
        #else
        self
        #endif
    }

    @ViewBuilder
    func hideTabBarOnIOS() -> some View {
        #if os(iOS)
        self.toolbar(.hidden, for: .tabBar)
        #else
        self
        #endif
    }
}

enum ComposeField: String, Hashable {
    case recipient
    case include
    case avoid
    case context
}

private extension String {
    var nilIfBlank: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    var commaSeparatedValues: [String] {
        split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    var trimmedForSaving: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var diagnosticsSelectionValue: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .replacingOccurrences(of: " ", with: "_")
    }
}

private func copyToPasteboard(_ text: String) {
    #if os(iOS)
    UIPasteboard.general.string = text
    #endif
}

private func announceAccessibilityNotice(_ title: String) {
    #if os(iOS)
    UIAccessibility.post(notification: .announcement, argument: title)
    #endif
}

private extension Date {
    var elapsedMilliseconds: Int {
        max(0, Int(Date().timeIntervalSince(self) * 1000))
    }
}

private extension GenerationError {
    var diagnosticsCategory: String {
        switch self {
        case .offline:
            "offline"
        case .timedOut:
            "timeout"
        case .rateLimited:
            "rate_limited"
        case .usageLimitReached:
            "usage_limit"
        case .contentBlocked:
            "content_blocked"
        case .serviceUnavailable:
            "service_unavailable"
        case .unexpectedResponse:
            "unexpected_response"
        }
    }
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

private func playSuccessFeedback() {
    #if os(iOS)
    UINotificationFeedbackGenerator().notificationOccurred(.success)
    #endif
}

private func playSelectionFeedback() {
    #if os(iOS)
    UISelectionFeedbackGenerator().selectionChanged()
    #endif
}

private extension Color {
    static var prosePalDeepNavy: Color {
        prosePalHex(0x151C26)
    }

    static var prosePalNavy: Color {
        prosePalHex(0x1D2633)
    }

    static var prosePalSurface: Color {
        prosePalHex(0x222E3D)
    }

    static var prosePalSurfaceElevated: Color {
        prosePalHex(0x283648)
    }

    static var prosePalCoral: Color {
        prosePalHex(0xD4736B)
    }

    static var prosePalCoralLight: Color {
        prosePalHex(0xFCE9E7)
    }

    static var prosePalCoralDark: Color {
        prosePalHex(0xA5564F)
    }

    static var prosePalProGold: Color {
        prosePalHex(0xFBBF24)
    }

    static var prosePalTextSecondary: Color {
        prosePalHex(0xB1BBC8)
    }

    static var prosePalGroupedBackground: Color {
        #if os(iOS)
        Color(uiColor: .systemGroupedBackground)
        #else
        Color.gray.opacity(0.08)
        #endif
    }

    static var prosePalSecondaryGroupedBackground: Color {
        #if os(iOS)
        Color(uiColor: .secondarySystemGroupedBackground)
        #else
        Color.white.opacity(0.72)
        #endif
    }

    private static func prosePalHex(_ value: Int, opacity: Double = 1) -> Color {
        Color(
            red: Double((value >> 16) & 0xFF) / 255,
            green: Double((value >> 8) & 0xFF) / 255,
            blue: Double(value & 0xFF) / 255,
            opacity: opacity
        )
    }
}

struct EmptyStateView: View {
    var title: String
    var systemImage: String
    var detail: String
    @ScaledMetric(relativeTo: .title) private var iconSize: CGFloat = 44

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: iconSize, weight: .semibold))
                .foregroundStyle(.secondary)
            Text(title)
                .font(.title3.weight(.semibold))
            Text(detail)
                .font(.callout)
                .foregroundStyle(.secondary)
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(32)
    }
}

#Preview {
    ProsePalRootView(
        model: ProsePalAppModel(
            client: MockMessageWritingClient(
                response: CardResponse(
                    messages: [
                        GeneratedMessage(text: "A preview draft from ProsePal.")
                    ],
                    laneUsed: .standard
                )
            ),
            clientContext: ClientContext(appVersion: "0.0.0", buildNumber: "1")
        )
    )
}
