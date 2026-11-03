import ProsePalAPI
import ProsePalDomain
import SwiftUI

#Preview("Plan — Free") {
    MomentPlanDetailPreview(state: .free)
}

#Preview("Plan — Pro") {
    MomentPlanDetailPreview(state: .pro)
}

#Preview("Plan — Unlocked") {
    MomentPlanDetailPreview(state: .unlocked)
}

private struct MomentPlanDetailPreview: View {
    private let state: MomentPlanDetailPreviewState

    @State private var account: MomentAccountModel

    init(state: MomentPlanDetailPreviewState) {
        self.state = state
        _account = State(initialValue: MomentAccountModel(
            clientContext: ClientContext(appVersion: "1.0", buildNumber: "1"),
            subscriptionClient: MomentPlanDetailPreviewSubscriptionClient(state: state),
            runtimeReadiness: NativeRuntimeReadiness(
                isSubscriptionConfigured: true,
                premiumProductCount: state == .pro ? 1 : 0,
                isRecommendedPremiumProductConfigured: state == .pro,
                isRelationshipVaultPersistent: true
            )
        ))
    }

    var body: some View {
        NavigationStack {
            MomentPlanDetailView(account: account)
        }
        .task {
            await account.refreshSubscriptionEntitlement(source: "plan_detail_preview")
            if account.isPremiumUnlocked {
                await account.loadSubscriptionProducts(source: "plan_detail_preview")
            }
        }
    }
}

private enum MomentPlanDetailPreviewState: Equatable, Sendable {
    case free
    case pro
    case unlocked
}

private struct MomentPlanDetailPreviewSubscriptionClient: SubscriptionClient {
    let state: MomentPlanDetailPreviewState

    func loadProducts() async throws -> [SubscriptionProduct] {
        guard state == .pro else { return [] }
        return [
            SubscriptionProduct(
                id: "com.prosepal.pro.monthly",
                displayName: "Monthly",
                displayPrice: "$4.99",
                durationLabel: "Every 1 month",
                isRecommended: true
            )
        ]
    }

    func currentEntitlement() async -> SubscriptionEntitlementState {
        switch state {
        case .free:
            .confirmedInactive(renewalState: .notApplicable)
        case .pro:
            .active(SubscriptionEntitlement(
                isActive: true,
                productID: "com.prosepal.pro.monthly"
            ))
        case .unlocked:
            .active(SubscriptionEntitlement(isActive: true))
        }
    }

    func purchase(productID: String) async throws -> SubscriptionPurchaseResult {
        SubscriptionPurchaseResult(status: .notEntitled)
    }

    func restorePurchases() async throws -> SubscriptionPurchaseResult {
        SubscriptionPurchaseResult(status: .notEntitled)
    }
}
