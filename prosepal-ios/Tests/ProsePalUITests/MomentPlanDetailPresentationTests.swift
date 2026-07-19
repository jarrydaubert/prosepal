import ProsePalAPI
import ProsePalDomain
import SwiftUI
import Testing
@testable import ProsePalUI

@Test
func planStatusPresentsTheActiveProductAheadOfTheSelectedFallback() {
    let presentation = MomentPlanStatusPresentation.current(
        entitlement: SubscriptionEntitlement(isActive: true),
        activeProduct: .monthlyFixture(),
        selectedProduct: .yearlyFixture()
    )

    #expect(presentation == MomentPlanStatusPresentation(
        subtitle: "Monthly · active",
        price: "$4.99/mo"
    ))
}

@Test
func planStatusFallsBackToTheSelectedProductWhenTheActiveProductIsUnavailable() {
    let presentation = MomentPlanStatusPresentation.current(
        entitlement: SubscriptionEntitlement(isActive: true),
        activeProduct: nil,
        selectedProduct: .yearlyFixture()
    )

    #expect(presentation == MomentPlanStatusPresentation(
        subtitle: "Yearly · active",
        price: "$39.99/yr"
    ))
}

@Test
func planStatusExplainsAnActiveEntitlementWithoutLoadedProductMetadata() {
    let presentation = MomentPlanStatusPresentation.current(
        entitlement: SubscriptionEntitlement(isActive: true),
        activeProduct: nil,
        selectedProduct: nil
    )

    #expect(presentation == MomentPlanStatusPresentation(
        subtitle: "Active subscription",
        price: "Unlocked"
    ))
}

@MainActor
@Test
func freePlanDetailRendersWithoutSubscriptionServices() {
    let account = MomentAccountModel(
        clientContext: ClientContext(appVersion: "1.0", buildNumber: "1")
    )
    let renderer = ImageRenderer(
        content: MomentPlanDetailView(account: account).frame(width: 390, height: 844)
    )

    #expect(renderer.cgImage != nil)
}

@MainActor
@Test
func premiumPlanDetailRendersWithDeterministicEntitlementAndProductState() async {
    let account = MomentAccountModel(
        clientContext: ClientContext(appVersion: "1.0", buildNumber: "1"),
        subscriptionClient: MomentPlanDetailTestSubscriptionClient(),
        runtimeReadiness: NativeRuntimeReadiness(
            isSubscriptionConfigured: true,
            premiumProductCount: 1,
            isRecommendedPremiumProductConfigured: true
        )
    )

    #expect(await account.refreshSubscriptionEntitlement(source: "plan_detail_test"))
    await account.loadSubscriptionProducts(source: "plan_detail_test")

    let renderer = ImageRenderer(
        content: MomentPlanDetailView(account: account).frame(width: 390, height: 844)
    )

    #expect(renderer.cgImage != nil)
}

private struct MomentPlanDetailTestSubscriptionClient: SubscriptionClient {
    func loadProducts() async throws -> [SubscriptionProduct] {
        [.monthlyFixture()]
    }

    func currentEntitlement() async -> SubscriptionEntitlementState {
        .active(SubscriptionEntitlement(
            isActive: true,
            productID: SubscriptionProduct.monthlyFixture().id
        ))
    }

    func purchase(productID: String) async throws -> SubscriptionPurchaseResult {
        SubscriptionPurchaseResult(status: .notEntitled)
    }

    func restorePurchases() async throws -> SubscriptionPurchaseResult {
        SubscriptionPurchaseResult(status: .notEntitled)
    }
}

private extension SubscriptionProduct {
    static func monthlyFixture() -> SubscriptionProduct {
        SubscriptionProduct(
            id: "com.prosepal.pro.monthly",
            displayName: "Monthly",
            displayPrice: "$4.99",
            durationLabel: "Every 1 month",
            isRecommended: true
        )
    }

    static func yearlyFixture() -> SubscriptionProduct {
        SubscriptionProduct(
            id: "com.prosepal.pro.yearly",
            displayName: "Yearly",
            displayPrice: "$39.99",
            durationLabel: "Every 1 year"
        )
    }
}
