import ProsePalAPI
import ProsePalDomain
import ProsePalUI
import Foundation
import SwiftUI
import SwiftData

@main
struct ProsePalNativeApp: App {
    private let authSessionController = AuthSessionController(
        store: KeychainAuthSessionStore(service: "com.prosepal.native.auth")
    )
    private let relationshipVaultContainer = RelationshipVaultContainerFactory.make()
    private let authClient = AuthClientFactory.makeClient()
    private let accountMaintenanceClient = AccountMaintenanceClientFactory.makeClient()
    private let runtimeReadiness = RuntimeReadinessFactory.make()

    var body: some Scene {
        WindowGroup {
            let context = clientContext
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
                    runtimeReadiness: runtimeReadiness
                )
            )
            .modelContainer(relationshipVaultContainer)
        }
    }

    private var clientContext: ClientContext {
        ClientContext(
            appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.1.0",
            buildNumber: Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        )
    }
}

private enum RelationshipVaultContainerFactory {
    static func make() -> ModelContainer {
        do {
            let schema = Schema(RelationshipVaultSchema.models)
            let configuration = ModelConfiguration(schema: schema)
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Unable to create ProsePal relationship vault: \(error.localizedDescription)")
        }
    }
}

private enum RuntimeReadinessFactory {
    static func make() -> NativeRuntimeReadiness {
        let config = NativeRuntimeConfig()
        let gatewayURL = config.url(named: "PROSEPAL_GATEWAY_URL")
        let premiumProductIDs = config.list(named: "PROSEPAL_PREMIUM_PRODUCT_IDS")
        return NativeRuntimeReadiness(
            isPrivateDraftConfigured: true,
            isCarefulGatewayConfigured: gatewayURL != nil,
            isDevGatewaySecretConfigured: config.value(named: "PROSEPAL_DEV_GATEWAY_SECRET") != nil,
            isAccountConfigured: config.url(named: "PROSEPAL_SUPABASE_URL", fallback: "SUPABASE_URL") != nil &&
                config.value(named: "PROSEPAL_SUPABASE_ANON_KEY", fallback: "SUPABASE_ANON_KEY") != nil,
            isSubscriptionConfigured: !premiumProductIDs.isEmpty,
            premiumProductCount: premiumProductIDs.count,
            isRecommendedPremiumProductConfigured: config.value(named: "PROSEPAL_RECOMMENDED_PREMIUM_PRODUCT_ID") != nil
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
