import ProsePalAPI
import ProsePalDomain
import ProsePalUI
import Foundation
import SwiftUI

@main
struct ProsePalNativeApp: App {
    private let authSessionController = AuthSessionController(
        store: KeychainAuthSessionStore(service: "com.prosepal.native.auth")
    )
    private let authClient = AuthClientFactory.makeClient()
    private let subscriptionClient = SubscriptionClientFactory.makeClient()
    private let runtimeReadiness = RuntimeReadinessFactory.make()

    var body: some Scene {
        WindowGroup {
            ProsePalRootView(
                model: ProsePalAppModel(
                    client: MessageWritingClientFactory.makeClient(
                        authSessionController: authSessionController
                    ),
                    clientContext: ClientContext(
                        appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.1.0",
                        buildNumber: Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
                    ),
                    authSessionController: authSessionController,
                    authClient: authClient,
                    subscriptionClient: subscriptionClient,
                    runtimeReadiness: runtimeReadiness
                )
            )
        }
    }
}

private enum RuntimeReadinessFactory {
    static func make() -> NativeRuntimeReadiness {
        let config = NativeRuntimeConfig()
        let premiumProductIDs = config.list(named: "PROSEPAL_PREMIUM_PRODUCT_IDS")
        return NativeRuntimeReadiness(
            isGenerationConfigured: config.url(named: "PROSEPAL_GATEWAY_URL") != nil,
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

private enum MessageWritingClientFactory {
    static func makeClient(authSessionController: AuthSessionController?) -> MessageWritingClient {
        let config = NativeRuntimeConfig()
        if let endpoint = gatewayEndpoint {
            let gatewayClient = GatewayMessageWritingClient(
                endpoint: endpoint,
                devGatewaySecret: config.value(named: "PROSEPAL_DEV_GATEWAY_SECRET"),
                authorizationTokenProvider: {
                    guard let authSessionController else { return nil }
                    return try await authSessionController.currentAccessToken()
                }
            )

            return MessageWritingRouter(
                standardClient: gatewayClient,
                premiumClient: gatewayClient
            )
        }

        return UnconfiguredGatewayMessageWritingClient()
    }

    private static var gatewayEndpoint: URL? {
        NativeRuntimeConfig().url(named: "PROSEPAL_GATEWAY_URL")
    }
}

private enum SubscriptionClientFactory {
    static func makeClient() -> (any SubscriptionClient)? {
        let config = NativeRuntimeConfig()
        let productIDs = config.list(named: "PROSEPAL_PREMIUM_PRODUCT_IDS")
        guard !productIDs.isEmpty else { return nil }

        #if canImport(StoreKit)
        return StoreKitSubscriptionClient(
            productIDs: productIDs,
            recommendedProductID: config.value(named: "PROSEPAL_RECOMMENDED_PREMIUM_PRODUCT_ID")
        )
        #else
        return nil
        #endif
    }
}

private struct UnconfiguredGatewayMessageWritingClient: MessageWritingClient {
    func generateCard(request: CardRequest) async throws -> CardResponse {
        throw GenerationError.serviceUnavailable(
            message: "Message generation is not available in this build. Add the ProsePal generation URL to continue."
        )
    }
}
