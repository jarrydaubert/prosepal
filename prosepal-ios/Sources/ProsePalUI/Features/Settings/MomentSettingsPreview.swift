import ProsePalAPI
import ProsePalDomain
import SwiftData
import SwiftUI

#Preview("Settings") {
    MomentSettingsPreview()
}

private struct MomentSettingsPreview: View {
    private let container: ModelContainer

    @State private var account: MomentAccountModel

    init() {
        container = try! RelationshipVaultContainerFactory.makeEphemeral()
        _account = State(initialValue: MomentAccountModel(
            clientContext: ClientContext(appVersion: "1.0", buildNumber: "1"),
            runtimeReadiness: NativeRuntimeReadiness(
                isPrivateDraftConfigured: true,
                isCarefulGatewayConfigured: true,
                isAccountConfigured: true,
                isSubscriptionConfigured: true,
                premiumProductCount: 3,
                isRecommendedPremiumProductConfigured: true
            )
        ))
    }

    var body: some View {
        NavigationStack {
            MomentSettingsView(account: account) {}
        }
        .modelContainer(container)
    }
}
