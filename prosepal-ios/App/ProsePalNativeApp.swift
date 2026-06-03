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
                    client: TemplateMessageWritingClient(),
                    clientContext: ClientContext(
                        appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.1.0",
                        buildNumber: Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
                    )
                )
            )
        }
    }
}
