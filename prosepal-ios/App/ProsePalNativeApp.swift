import ProsePalAPI
import ProsePalDomain
import ProsePalUI
import Foundation
import SwiftUI

@main
struct ProsePalNativeApp: App {
    var body: some Scene {
        WindowGroup {
            ProsePalRootView(
                model: ProsePalAppModel(
                    client: MessageWritingClientFactory.makeClient(),
                    clientContext: ClientContext(
                        appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.1.0",
                        buildNumber: Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
                    )
                )
            )
        }
    }
}

private enum MessageWritingClientFactory {
    static func makeClient() -> MessageWritingClient {
        if let endpoint = gatewayEndpoint {
            let gatewayClient = GatewayMessageWritingClient(
                endpoint: endpoint,
                devGatewaySecret: gatewayDevSecret
            )

            return MessageWritingRouter(
                standardClient: gatewayClient,
                premiumClient: gatewayClient
            )
        }

        return UnconfiguredGatewayMessageWritingClient()
    }

    private static var gatewayEndpoint: URL? {
        if let environmentValue = ProcessInfo.processInfo.environment["PROSEPAL_GATEWAY_URL"],
           let url = URL(string: environmentValue),
           !environmentValue.isEmpty {
            return url
        }

        if let infoValue = Bundle.main.object(forInfoDictionaryKey: "PROSEPAL_GATEWAY_URL") as? String,
           let url = URL(string: infoValue),
           !infoValue.isEmpty {
            return url
        }

        return nil
    }

    private static var gatewayDevSecret: String? {
        configValue(named: "PROSEPAL_DEV_GATEWAY_SECRET")
    }

    private static func configValue(named key: String) -> String? {
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
