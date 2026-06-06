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
                    authClient: authClient
                )
            )
        }
    }
}

private enum AuthClientFactory {
    static func makeClient() -> (any AuthClient)? {
        guard
            let projectURLString = NativeConfig.value(named: "PROSEPAL_SUPABASE_URL") ?? NativeConfig.value(named: "SUPABASE_URL"),
            let projectURL = URL(string: projectURLString),
            let anonKey = NativeConfig.value(named: "PROSEPAL_SUPABASE_ANON_KEY") ?? NativeConfig.value(named: "SUPABASE_ANON_KEY")
        else {
            return nil
        }

        return SupabaseAuthClient(projectURL: projectURL, anonKey: anonKey)
    }
}

private enum MessageWritingClientFactory {
    static func makeClient(authSessionController: AuthSessionController?) -> MessageWritingClient {
        if let endpoint = gatewayEndpoint {
            let gatewayClient = GatewayMessageWritingClient(
                endpoint: endpoint,
                devGatewaySecret: gatewayDevSecret,
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
        if let configValue = NativeConfig.value(named: "PROSEPAL_GATEWAY_URL"),
           let url = URL(string: configValue) {
            return url
        }

        return nil
    }

    private static var gatewayDevSecret: String? {
        NativeConfig.value(named: "PROSEPAL_DEV_GATEWAY_SECRET")
    }
}

private enum NativeConfig {
    static func value(named key: String) -> String? {
        if let environmentValue = ProcessInfo.processInfo.environment[key]?.trimmingCharacters(in: .whitespacesAndNewlines),
           !environmentValue.isEmpty {
            return environmentValue
        }

        if let infoValue = Bundle.main.object(forInfoDictionaryKey: key) as? String {
            let trimmedValue = infoValue.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmedValue.isEmpty {
                return trimmedValue
            }
        }

        return nil
    }
}

private struct UnconfiguredGatewayMessageWritingClient: MessageWritingClient {
    func generateCard(request: CardRequest) async throws -> CardResponse {
        throw GenerationError.serviceUnavailable(
            message: "Message generation is not available in this build. Add the ProsePal generation URL to continue."
        )
    }
}
