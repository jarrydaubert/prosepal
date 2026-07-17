import ProsePalAPI
import ProsePalDomain
import ProsePalUI
import Foundation
import SwiftUI
import SwiftData

@main
struct ProsePalNativeApp: App {
    private let authSessionController: AuthSessionController
    private let relationshipVault: RelationshipVaultContainerResult
    private let authClient: (any AuthClient)?
    private let appleAccountLifecycleClient: (any AppleAccountLifecycleClient)?
    private let appleCredentialStateProvider: (any AppleCredentialStateProviding)?
    private let accountMaintenanceClient: (any AccountMaintenanceClient)?
    private let runtimeReadiness: NativeRuntimeReadiness
    private let welcomeState: MomentWelcomeState
    private let draftRecoveryStore: any MomentDraftRecoveryStoring

    init() {
        let authClient: (any AuthClient)?
        let appleAccountLifecycleClient: (any AppleAccountLifecycleClient)?
        let appleCredentialStateProvider: (any AppleCredentialStateProviding)?
        let accountMaintenanceClient: (any AccountMaintenanceClient)?
        let authSessionStore: any AuthSessionStore
        let relationshipVault: RelationshipVaultContainerResult
        let runtimeReadiness: NativeRuntimeReadiness
        let welcomeState: MomentWelcomeState
        let draftRecoveryStore: any MomentDraftRecoveryStoring

        #if DEBUG
        if let uiTestScenario = ProsePalUITestScenario.current {
            let container = try! RelationshipVaultContainerFactory.makeEphemeral()
            relationshipVault = RelationshipVaultContainerResult(
                container: container,
                storageMode: .ephemeralFallback
            )
            authClient = ProsePalUITestAuthClient(behavior: uiTestScenario.authBehavior)
            appleAccountLifecycleClient = ProsePalUITestAppleAccountLifecycleClient()
            appleCredentialStateProvider = nil
            accountMaintenanceClient = ProsePalUITestAccountDeletionClient(
                behavior: uiTestScenario.accountDeletionBehavior
            )
            authSessionStore = ProsePalUITestAuthSessionStore(
                session: uiTestScenario.persistedSession
            )
            runtimeReadiness = NativeRuntimeReadiness(
                isPrivateDraftConfigured: true,
                isCarefulGatewayConfigured: true,
                isDevGatewaySecretConfigured: false,
                isAccountConfigured: true,
                isSubscriptionConfigured: true,
                premiumProductCount: 3,
                isRecommendedPremiumProductConfigured: true,
                isRelationshipVaultPersistent: false
            )
            welcomeState = uiTestScenario.makeWelcomeState()
            draftRecoveryStore = MomentDraftRecoveryNoopStore()
        } else {
            relationshipVault = RelationshipVaultContainerFactory.makePersistentOrEphemeral()
            authClient = AuthClientFactory.makeClient()
            appleAccountLifecycleClient = AppleAccountLifecycleClientFactory.makeClient()
            appleCredentialStateProvider = SystemAppleCredentialStateProvider()
            accountMaintenanceClient = AccountMaintenanceClientFactory.makeClient()
            authSessionStore = KeychainAuthSessionStore(
                service: "\(ProsePalAppIdentity.bundleIdentifier).auth"
            )
            runtimeReadiness = RuntimeReadinessFactory.make(
                isRelationshipVaultPersistent: relationshipVault.isPersistent
            )
            welcomeState = MomentWelcomeState()
            draftRecoveryStore = MomentDraftRecoveryStore()
        }
        #else
        relationshipVault = RelationshipVaultContainerFactory.makePersistentOrEphemeral()
        authClient = AuthClientFactory.makeClient()
        appleAccountLifecycleClient = AppleAccountLifecycleClientFactory.makeClient()
        #if canImport(AuthenticationServices)
        appleCredentialStateProvider = SystemAppleCredentialStateProvider()
        #else
        appleCredentialStateProvider = nil
        #endif
        accountMaintenanceClient = AccountMaintenanceClientFactory.makeClient()
        authSessionStore = KeychainAuthSessionStore(
            service: "\(ProsePalAppIdentity.bundleIdentifier).auth"
        )
        runtimeReadiness = RuntimeReadinessFactory.make(
            isRelationshipVaultPersistent: relationshipVault.isPersistent
        )
        welcomeState = MomentWelcomeState()
        draftRecoveryStore = MomentDraftRecoveryStore()
        #endif

        self.authClient = authClient
        self.appleAccountLifecycleClient = appleAccountLifecycleClient
        self.appleCredentialStateProvider = appleCredentialStateProvider
        self.accountMaintenanceClient = accountMaintenanceClient
        self.relationshipVault = relationshipVault
        self.runtimeReadiness = runtimeReadiness
        self.welcomeState = welcomeState
        self.draftRecoveryStore = draftRecoveryStore
        self.authSessionController = AuthSessionController(
            store: authSessionStore,
            authClient: authClient
        )
    }

    var body: some Scene {
        WindowGroup {
            if ProsePalTestRuntime.isUnitTestHost {
                Color.clear
            } else {
                let context = clientContext
                let relationshipVaultContainer = relationshipVault.container
                MomentAppRootView(
                    service: MessageWritingServiceFactory.makeService(
                        authSessionController: authSessionController,
                        clientContext: context,
                        relationshipVaultContainer: relationshipVaultContainer
                    ),
                    account: MomentAccountModel(
                        clientContext: context,
                        authSessionController: authSessionController,
                        authClient: authClient,
                        appleAccountLifecycleClient: appleAccountLifecycleClient,
                        appleCredentialStateProvider: appleCredentialStateProvider,
                        subscriptionClient: SubscriptionClientFactory.makeClient(
                            authSessionController: authSessionController
                        ),
                        accountMaintenanceClient: accountMaintenanceClient,
                        localAccountDataDeletion: {
                            try await RelationshipVaultLocalDataEraser.eraseAll(in: relationshipVault)
                        },
                        runtimeReadiness: runtimeReadiness
                    ),
                    welcomeState: welcomeState,
                    draftRecoveryStore: draftRecoveryStore
                )
                .modelContainer(relationshipVaultContainer)
                .prosePalDebugAccessibilityOverrides()
            }
        }
    }

    private var clientContext: ClientContext {
        ClientContext(
            appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.1.0",
            buildNumber: Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        )
    }
}

private enum ProsePalTestRuntime {
    static var isUnitTestHost: Bool {
        ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil &&
            !ProcessInfo.processInfo.arguments.contains("--prosepal-ui-testing")
    }
}

private enum ProsePalAppIdentity {
    static var bundleIdentifier: String {
        Bundle.main.bundleIdentifier ?? "com.prosepal.prosepal"
    }
}

private extension NativeRuntimeConfig {
    static var prosePalApp: Self {
        #if DEBUG
        Self(allowsInsecureLoopback: true)
        #else
        Self()
        #endif
    }
}

private enum RuntimeReadinessFactory {
    static func make(isRelationshipVaultPersistent: Bool) -> NativeRuntimeReadiness {
        let config = NativeRuntimeConfig.prosePalApp
        let gatewayURL = config.url(named: "PROSEPAL_GATEWAY_URL")
        let premiumProductIDs = config.list(named: "PROSEPAL_PREMIUM_PRODUCT_IDS")
        return NativeRuntimeReadiness(
            isPrivateDraftConfigured: FoundationModelsPrivateDraftClient.isDefaultModelAvailable,
            isCarefulGatewayConfigured: gatewayURL != nil,
            isDevGatewaySecretConfigured: config.value(named: "PROSEPAL_DEV_GATEWAY_SECRET") != nil,
            isAccountConfigured: config.url(named: "PROSEPAL_SUPABASE_URL", fallback: "SUPABASE_URL") != nil &&
                config.supabasePublishableKey(
                    named: "PROSEPAL_SUPABASE_ANON_KEY",
                    fallback: "SUPABASE_ANON_KEY"
                ) != nil,
            isSubscriptionConfigured: !premiumProductIDs.isEmpty,
            premiumProductCount: premiumProductIDs.count,
            isRecommendedPremiumProductConfigured: config.value(named: "PROSEPAL_RECOMMENDED_PREMIUM_PRODUCT_ID") != nil,
            isRelationshipVaultPersistent: isRelationshipVaultPersistent
        )
    }
}

private enum AuthClientFactory {
    static func makeClient() -> (any AuthClient)? {
        let config = NativeRuntimeConfig.prosePalApp
        guard
            let projectURL = config.url(named: "PROSEPAL_SUPABASE_URL", fallback: "SUPABASE_URL"),
            let anonKey = config.supabasePublishableKey(
                named: "PROSEPAL_SUPABASE_ANON_KEY",
                fallback: "SUPABASE_ANON_KEY"
            )
        else {
            return nil
        }

        return SupabaseAuthClient(projectURL: projectURL, anonKey: anonKey)
    }
}

private enum AppleAccountLifecycleClientFactory {
    static func makeClient() -> (any AppleAccountLifecycleClient)? {
        let config = NativeRuntimeConfig.prosePalApp
        guard
            let projectURL = config.url(named: "PROSEPAL_SUPABASE_URL", fallback: "SUPABASE_URL"),
            let anonKey = config.supabasePublishableKey(
                named: "PROSEPAL_SUPABASE_ANON_KEY",
                fallback: "SUPABASE_ANON_KEY"
            )
        else {
            return nil
        }

        return SupabaseAppleAccountLifecycleClient(
            projectURL: projectURL,
            anonKey: anonKey
        )
    }
}

private enum AccountMaintenanceClientFactory {
    static func makeClient() -> (any AccountMaintenanceClient)? {
        let config = NativeRuntimeConfig.prosePalApp
        guard
            let projectURL = config.url(named: "PROSEPAL_SUPABASE_URL", fallback: "SUPABASE_URL"),
            let anonKey = config.supabasePublishableKey(
                named: "PROSEPAL_SUPABASE_ANON_KEY",
                fallback: "SUPABASE_ANON_KEY"
            )
        else {
            return nil
        }

        return SupabaseAccountMaintenanceClient(projectURL: projectURL, anonKey: anonKey)
    }
}

private enum MessageWritingServiceFactory {
    static func makeService(
        authSessionController: AuthSessionController?,
        clientContext: ClientContext,
        relationshipVaultContainer: ModelContainer
    ) -> any MessageWritingService {
        #if DEBUG
        if ProsePalDebugLaunchArguments.forcesOfflineWritingService {
            let failingClient = DebugFailingMomentDraftClient(error: .offline)
            return RoutingMessageWritingService(
                privateClient: failingClient,
                carefulClient: failingClient
            )
        }

        if ProsePalDebugLaunchArguments.forcesGenerationErrorWritingService {
            let failingClient = DebugFailingMomentDraftClient(error: .serviceUnavailable(
                message: "Message generation is temporarily unavailable. Please try again shortly."
            ))
            return RoutingMessageWritingService(
                privateClient: failingClient,
                carefulClient: failingClient
            )
        }

        if ProsePalDebugLaunchArguments.forcesQuotaWritingService {
            let failingClient = DebugFailingMomentDraftClient(error: .usageLimitReached(
                message: "You've used your included Standard generation. Premium unlocks more messages."
            ))
            return RoutingMessageWritingService(
                privateClient: failingClient,
                carefulClient: failingClient
            )
        }

        if ProsePalDebugLaunchArguments.usesMockWritingService {
            let mockClient = MockMomentDraftClient(bundle: MomentDraftBundle(
                messageText: "Mira, I have been thinking about our Sunday calls. I miss that easy rhythm with you, and I would love to find a time to catch up soon.",
                lane: .mock
            ), delay: ProsePalDebugLaunchArguments.mockWritingDelay)
            return RoutingMessageWritingService(
                privateClient: mockClient,
                carefulClient: mockClient,
                timeoutPolicy: ProsePalDebugLaunchArguments.mockWritingTimeoutPolicy
            )
        }
        #endif

        let privateClient = FoundationModelsPrivateDraftClient(
            memoryProvider: SwiftDataRelationshipMemoryProvider(container: relationshipVaultContainer)
        )
        let carefulClient: any MomentDraftClient

        if let gatewayEndpoint {
            let config = NativeRuntimeConfig.prosePalApp
            let gatewayClient = GatewayMessageWritingClient(
                endpoint: gatewayEndpoint,
                devGatewaySecret: config.value(named: "PROSEPAL_DEV_GATEWAY_SECRET"),
                authorizationTokenProvider: {
                    guard let authSessionController else { return nil }
                    return try await authSessionController.currentAccessToken()
                }
            )
            carefulClient = GatewayCarefulMomentClient(
                client: gatewayClient,
                clientContext: clientContext,
                requestKeyStore: CarefulRequestKeyStore(
                    persistence: UserDefaultsCarefulRequestKeyPersistence()
                )
            )
        } else {
            carefulClient = UnconfiguredMomentDraftClient()
        }

        return RoutingMessageWritingService(
            privateClient: privateClient,
            carefulClient: carefulClient
        )
    }

    private static var gatewayEndpoint: URL? {
        NativeRuntimeConfig.prosePalApp.url(named: "PROSEPAL_GATEWAY_URL")
    }
}

#if DEBUG
private struct DebugFailingMomentDraftClient: MomentDraftClient {
    let error: GenerationError

    func draft(for moment: MomentInput) async throws -> MomentDraftBundle {
        throw error
    }

    func adjust(
        _ bundle: MomentDraftBundle,
        with adjustment: MomentAdjustment,
        moment: MomentInput
    ) async throws -> MomentDraftBundle {
        throw error
    }
}

private enum ProsePalDebugLaunchArguments {
    static let mockWritingService = "--prosepal-use-mock-writing-service"
    static let offlineWritingService = "--prosepal-force-offline-writing-service"
    static let generationErrorWritingService = "--prosepal-force-generation-error-writing-service"
    static let quotaWritingService = "--prosepal-force-quota-writing-service"
    static let slowMockWritingService = "--prosepal-slow-mock-writing-service"
    static let mockSubscriptionService = "--prosepal-use-mock-subscription-service"
    static let slowMockSubscriptionService = "--prosepal-slow-mock-subscription-service"
    static let mockPurchaseFailure = "--prosepal-mock-purchase-failure"
    static let mockRestoreFailure = "--prosepal-mock-restore-failure"
    static let forcePremium = "--prosepal-force-premium"
    static let reduceTransparency = "--prosepal-force-reduce-transparency"
    static let accessibilityTextSize = "--prosepal-force-accessibility-text-size"

    static var usesMockWritingService: Bool {
        ProcessInfo.processInfo.arguments.contains(mockWritingService)
    }

    static var forcesOfflineWritingService: Bool {
        ProcessInfo.processInfo.arguments.contains(offlineWritingService)
    }

    static var forcesGenerationErrorWritingService: Bool {
        ProcessInfo.processInfo.arguments.contains(generationErrorWritingService)
    }

    static var forcesQuotaWritingService: Bool {
        ProcessInfo.processInfo.arguments.contains(quotaWritingService)
    }

    static var usesMockSubscriptionService: Bool {
        ProcessInfo.processInfo.arguments.contains(mockSubscriptionService) ||
            ProcessInfo.processInfo.arguments.contains(forcePremium)
    }

    static var forcesPremiumSubscription: Bool {
        ProcessInfo.processInfo.arguments.contains(forcePremium)
    }

    static var mockSubscriptionDelay: Duration? {
        ProcessInfo.processInfo.arguments.contains(slowMockSubscriptionService) ? .seconds(2) : nil
    }

    static var forcesMockPurchaseFailure: Bool {
        ProcessInfo.processInfo.arguments.contains(mockPurchaseFailure)
    }

    static var forcesMockRestoreFailure: Bool {
        ProcessInfo.processInfo.arguments.contains(mockRestoreFailure)
    }

    static var forcesReduceTransparency: Bool {
        ProcessInfo.processInfo.arguments.contains(reduceTransparency)
    }

    static var forcesAccessibilityTextSize: Bool {
        ProcessInfo.processInfo.arguments.contains(accessibilityTextSize)
    }

    static var mockWritingDelay: Duration? {
        // Hold the generation state until the UI test cancels through Stop.
        // Hosted accessibility inspection can stall for minutes, so a short
        // wall-clock delay cannot be a deterministic synchronization boundary.
        ProcessInfo.processInfo.arguments.contains(slowMockWritingService) ? .seconds(3_600) : nil
    }

    static var mockWritingTimeoutPolicy: GenerationTimeoutPolicy {
        guard ProcessInfo.processInfo.arguments.contains(slowMockWritingService) else {
            return GenerationTimeoutPolicy()
        }

        // This DEBUG-only seam exercises cancellation-driven UI feedback. Keep
        // the production deadline from resolving the mock before hosted
        // accessibility inspection reaches the progress state.
        return GenerationTimeoutPolicy(
            onDevice: .seconds(7_200),
            gateway: .seconds(7_200),
            total: .seconds(7_200)
        )
    }
}
#endif

private extension View {
    @ViewBuilder
    func prosePalDebugAccessibilityOverrides() -> some View {
        #if DEBUG
        if ProsePalDebugLaunchArguments.forcesReduceTransparency &&
            ProsePalDebugLaunchArguments.forcesAccessibilityTextSize {
            self
                .environment(\.prosePalReduceTransparencyOverride, true)
                .environment(\.dynamicTypeSize, .accessibility3)
        } else if ProsePalDebugLaunchArguments.forcesReduceTransparency {
            self.environment(\.prosePalReduceTransparencyOverride, true)
        } else if ProsePalDebugLaunchArguments.forcesAccessibilityTextSize {
            self.environment(\.dynamicTypeSize, .accessibility3)
        } else {
            self
        }
        #else
        self
        #endif
    }
}

private enum SubscriptionClientFactory {
    static func makeClient(authSessionController: AuthSessionController?) -> (any SubscriptionClient)? {
        let config = NativeRuntimeConfig.prosePalApp
        let productIDs = config.list(named: "PROSEPAL_PREMIUM_PRODUCT_IDS")
        let retiredProductIDs = config.list(named: "PROSEPAL_RETIRED_PREMIUM_PRODUCT_IDS")

        #if DEBUG
        if ProsePalDebugLaunchArguments.usesMockSubscriptionService {
            return DebugSubscriptionClient(
                productIDs: productIDs,
                isPremiumUnlocked: ProsePalDebugLaunchArguments.forcesPremiumSubscription,
                operationDelay: ProsePalDebugLaunchArguments.mockSubscriptionDelay,
                purchaseFails: ProsePalDebugLaunchArguments.forcesMockPurchaseFailure,
                restoreFails: ProsePalDebugLaunchArguments.forcesMockRestoreFailure
            )
        }
        #endif

        guard !productIDs.isEmpty else { return nil }

        #if canImport(StoreKit)
        return StoreKitSubscriptionClient(
            productIDs: productIDs,
            retiredProductIDs: retiredProductIDs,
            recommendedProductID: config.value(named: "PROSEPAL_RECOMMENDED_PREMIUM_PRODUCT_ID"),
            appAccountTokenProvider: {
                guard let authSessionController else { return nil }

                guard
                    let session = try? await authSessionController.currentSession(),
                    let userID = session.user?.id,
                    let uuid = UUID(uuidString: userID)
                else {
                    return nil
                }

                return uuid
            }
        )
        #else
        return nil
        #endif
    }
}

#if DEBUG
private struct DebugSubscriptionClient: SubscriptionClient {
    var productIDs: [String]
    var isPremiumUnlocked: Bool
    var operationDelay: Duration?
    var purchaseFails: Bool
    var restoreFails: Bool

    func loadProducts() async throws -> [SubscriptionProduct] {
        try await waitForConfiguredDelay()
        return products
    }

    func currentEntitlement() async -> SubscriptionEntitlementState {
        isPremiumUnlocked
            ? .active(activeEntitlement(productID: yearlyProductID))
            : .inactive
    }

    func purchase(productID: String) async throws -> SubscriptionPurchaseResult {
        try await waitForConfiguredDelay()
        if purchaseFails {
            throw SubscriptionError.storeUnavailable
        }
        return SubscriptionPurchaseResult(
            status: .purchased,
            entitlement: activeEntitlement(productID: productID)
        )
    }

    func restorePurchases() async throws -> SubscriptionPurchaseResult {
        try await waitForConfiguredDelay()
        if restoreFails {
            throw SubscriptionError.storeUnavailable
        }
        return SubscriptionPurchaseResult(
            status: isPremiumUnlocked ? .restored : .notEntitled,
            entitlement: isPremiumUnlocked ? activeEntitlement(productID: yearlyProductID) : .inactive
        )
    }

    private var products: [SubscriptionProduct] {
        [
            SubscriptionProduct(
                id: yearlyProductID,
                displayName: "Yearly",
                displayPrice: "$39.99",
                durationLabel: "Yearly",
                isRecommended: true
            ),
            SubscriptionProduct(
                id: monthlyProductID,
                displayName: "Monthly",
                displayPrice: "$5.99",
                durationLabel: "Monthly"
            ),
            SubscriptionProduct(
                id: weeklyProductID,
                displayName: "Weekly",
                displayPrice: "$1.99",
                durationLabel: "Weekly"
            )
        ]
    }

    private func waitForConfiguredDelay() async throws {
        guard let operationDelay else { return }
        try await Task.sleep(for: operationDelay)
    }

    private var yearlyProductID: String {
        productIDs.first { $0.localizedCaseInsensitiveContains("yearly") } ?? "com.prosepal.pro.yearly"
    }

    private var monthlyProductID: String {
        productIDs.first { $0.localizedCaseInsensitiveContains("monthly") } ?? "com.prosepal.pro.monthly"
    }

    private var weeklyProductID: String {
        productIDs.first { $0.localizedCaseInsensitiveContains("weekly") } ?? "com.prosepal.pro.weekly"
    }

    private func activeEntitlement(productID: String) -> SubscriptionEntitlement {
        SubscriptionEntitlement(
            isActive: true,
            productID: productID,
            expiresAt: Calendar.current.date(byAdding: .year, value: 1, to: Date())
        )
    }
}
#endif
