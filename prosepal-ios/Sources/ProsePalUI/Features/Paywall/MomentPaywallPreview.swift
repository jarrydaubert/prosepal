import ProsePalAPI
import ProsePalDomain
import SwiftUI

#Preview("Paywall") {
    MomentPaywallPreview()
}

#Preview("Paywall — unavailable") {
    MomentPaywallUnavailablePreview()
}

private struct MomentPaywallPreview: View {
    @State private var account = MomentAccountModel(
        clientContext: ClientContext(appVersion: "1.0", buildNumber: "1"),
        subscriptionClient: PaywallPreviewSubscriptionClient(),
        runtimeReadiness: NativeRuntimeReadiness(
            isPrivateDraftConfigured: true,
            isCarefulGatewayConfigured: true,
            isAccountConfigured: true,
            isSubscriptionConfigured: true,
            premiumProductCount: 3,
            isRecommendedPremiumProductConfigured: true
        )
    )

    var body: some View {
        MomentPaywallSheet(account: account)
    }
}

private struct MomentPaywallUnavailablePreview: View {
    @State private var account = MomentAccountModel(
        clientContext: ClientContext(appVersion: "1.0", buildNumber: "1")
    )

    var body: some View {
        MomentPaywallSheet(account: account)
    }
}

private struct PaywallPreviewSubscriptionClient: SubscriptionClient {
    func loadProducts() async throws -> [SubscriptionProduct] {
        [
            SubscriptionProduct(
                id: "com.prosepal.pro.weekly",
                displayName: "Weekly",
                displayPrice: "$1.99",
                durationLabel: "Every 1 week"
            ),
            SubscriptionProduct(
                id: "com.prosepal.pro.monthly",
                displayName: "Monthly",
                displayPrice: "$4.99",
                durationLabel: "Every 1 month",
                isRecommended: true
            ),
            SubscriptionProduct(
                id: "com.prosepal.pro.yearly",
                displayName: "Yearly",
                displayPrice: "$39.99",
                durationLabel: "Every 1 year"
            )
        ]
    }

    func currentEntitlement() async -> SubscriptionEntitlementState {
        .confirmedInactive(renewalState: .notApplicable)
    }

    func purchase(productID: String) async throws -> SubscriptionPurchaseResult {
        SubscriptionPurchaseResult(status: .notEntitled)
    }

    func restorePurchases() async throws -> SubscriptionPurchaseResult {
        SubscriptionPurchaseResult(status: .notEntitled)
    }
}
