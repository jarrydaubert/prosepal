import ProsePalAPI
import ProsePalDomain
import ProsePalUI
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
            return GatewayMessageWritingClient(endpoint: endpoint)
        }

        return TemplateMessageWritingClient()
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
}
