import ProsePalAPI
import ProsePalDomain
import ProsePalUI
import Foundation
import SwiftUI
import SwiftData

@main
struct ProsePalNativeApp: App {
    private let authSessionController = AuthSessionController(
        store: KeychainAuthSessionStore(service: "\(ProsePalAppIdentity.bundleIdentifier).auth")
    )
    private let relationshipVault = RelationshipVaultContainerFactory.makePersistentOrEphemeral()
    private let authClient = AuthClientFactory.makeClient()
    private let accountMaintenanceClient = AccountMaintenanceClientFactory.makeClient()

    var body: some Scene {
        WindowGroup {
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
                    subscriptionClient: SubscriptionClientFactory.makeClient(
                        authSessionController: authSessionController
                    ),
                    accountMaintenanceClient: accountMaintenanceClient,
                    localAccountDataDeletion: {
                        try await RelationshipVaultLocalDataEraser.eraseAll(in: relationshipVault)
                    },
                    runtimeReadiness: RuntimeReadinessFactory.make(
                        isRelationshipVaultPersistent: relationshipVault.isPersistent
                    )
                )
            )
            .modelContainer(relationshipVaultContainer)
            .prosePalDebugAccessibilityOverrides()
        }
    }

    private var clientContext: ClientContext {
        ClientContext(
            appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.1.0",
            buildNumber: Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        )
    }
}

private enum ProsePalAppIdentity {
    static var bundleIdentifier: String {
        Bundle.main.bundleIdentifier ?? "com.prosepal.prosepal"
    }
}

private enum RuntimeReadinessFactory {
    static func make(isRelationshipVaultPersistent: Bool) -> NativeRuntimeReadiness {
        let config = NativeRuntimeConfig()
        let gatewayURL = config.url(named: "PROSEPAL_GATEWAY_URL")
        let premiumProductIDs = config.list(named: "PROSEPAL_PREMIUM_PRODUCT_IDS")
        return NativeRuntimeReadiness(
            isPrivateDraftConfigured: FoundationModelsPrivateDraftClient.isDefaultModelAvailable,
            isCarefulGatewayConfigured: gatewayURL != nil,
            isDevGatewaySecretConfigured: config.value(named: "PROSEPAL_DEV_GATEWAY_SECRET") != nil,
            isAccountConfigured: config.url(named: "PROSEPAL_SUPABASE_URL", fallback: "SUPABASE_URL") != nil &&
                config.value(named: "PROSEPAL_SUPABASE_ANON_KEY", fallback: "SUPABASE_ANON_KEY") != nil,
            isSubscriptionConfigured: !premiumProductIDs.isEmpty,
            premiumProductCount: premiumProductIDs.count,
            isRecommendedPremiumProductConfigured: config.value(named: "PROSEPAL_RECOMMENDED_PREMIUM_PRODUCT_ID") != nil,
            isRelationshipVaultPersistent: isRelationshipVaultPersistent
        )
    }
}

private enum AuthClientFactory {
    static func makeClient() -> (any AuthClient)? {
        let config = NativeRuntimeConfig()
        guard
            let projectURL = config.url(named: "PROSEPAL_SUPABASE_URL", fallback: "SUPABASE_URL"),
            let anonKey = config.value(named: "PROSEPAL_SUPABASE_ANON_KEY", fallback: "SUPABASE_ANON_KEY")
        else {
            return nil
        }

        return SupabaseAuthClient(projectURL: projectURL, anonKey: anonKey)
    }
}

private enum AccountMaintenanceClientFactory {
    static func makeClient() -> (any AccountMaintenanceClient)? {
        let config = NativeRuntimeConfig()
        guard
            let projectURL = config.url(named: "PROSEPAL_SUPABASE_URL", fallback: "SUPABASE_URL"),
            let anonKey = config.value(named: "PROSEPAL_SUPABASE_ANON_KEY", fallback: "SUPABASE_ANON_KEY")
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
        if ProsePalDebugLaunchArguments.usesMockWritingService {
            let mockClient = MockMomentDraftClient(bundle: MomentDraftBundle(
                messageText: "Mira, I have been thinking about our Sunday calls. I miss that easy rhythm with you, and I would love to find a time to catch up soon.",
                lane: .mock
            ), delay: ProsePalDebugLaunchArguments.mockWritingDelay)
            return RoutingMessageWritingService(
                privateClient: mockClient,
                carefulClient: mockClient
            )
        }
        #endif

        let privateClient = FoundationModelsPrivateDraftClient(
            memoryProvider: SwiftDataRelationshipMemoryProvider(container: relationshipVaultContainer)
        )
        let carefulClient: any MomentDraftClient

        if let gatewayEndpoint {
            let config = NativeRuntimeConfig()
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
                clientContext: clientContext
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
        NativeRuntimeConfig().url(named: "PROSEPAL_GATEWAY_URL")
    }
}

#if DEBUG
private enum ProsePalDebugLaunchArguments {
    static let mockWritingService = "--prosepal-use-mock-writing-service"
    static let slowMockWritingService = "--prosepal-slow-mock-writing-service"
    static let reduceTransparency = "--prosepal-force-reduce-transparency"

    static var usesMockWritingService: Bool {
        ProcessInfo.processInfo.arguments.contains(mockWritingService)
    }

    static var forcesReduceTransparency: Bool {
        ProcessInfo.processInfo.arguments.contains(reduceTransparency)
    }

    static var mockWritingDelay: Duration? {
        ProcessInfo.processInfo.arguments.contains(slowMockWritingService) ? .seconds(10) : nil
    }
}
#endif

private extension View {
    @ViewBuilder
    func prosePalDebugAccessibilityOverrides() -> some View {
        #if DEBUG
        if ProsePalDebugLaunchArguments.forcesReduceTransparency {
            self.environment(\.prosePalReduceTransparencyOverride, true)
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
        let config = NativeRuntimeConfig()
        let productIDs = config.list(named: "PROSEPAL_PREMIUM_PRODUCT_IDS")
        guard !productIDs.isEmpty else { return nil }

        #if canImport(StoreKit)
        return StoreKitSubscriptionClient(
            productIDs: productIDs,
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
