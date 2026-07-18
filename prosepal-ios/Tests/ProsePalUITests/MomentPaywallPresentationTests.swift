import ProsePalAPI
import ProsePalDomain
import SwiftUI
import Testing
@testable import ProsePalUI

@Test
func paywallShowsLoadingWhileProductsAreBeingFetchedEvenIfStaleProductsExist() {
    let presentation = MomentPaywallProductPresentation.current(
        isLoadingSubscriptions: true,
        products: [.weeklyFixture()],
        errorMessage: nil
    )

    #expect(presentation == .loading)
}

@Test
func paywallExplainsAnEmptyCatalogueWithTheAccountErrorMessage() {
    let presentation = MomentPaywallProductPresentation.current(
        isLoadingSubscriptions: false,
        products: [],
        errorMessage: SubscriptionError.productsUnavailable.userSafeMessage
    )

    #expect(presentation == .unavailable(
        message: SubscriptionError.productsUnavailable.userSafeMessage
    ))
}

@Test
func paywallFallsBackToTheNotConfiguredMessageWhenNoErrorWasRecorded() {
    let presentation = MomentPaywallProductPresentation.current(
        isLoadingSubscriptions: false,
        products: [],
        errorMessage: nil
    )

    #expect(presentation == .unavailable(
        message: SubscriptionError.notConfigured.userSafeMessage
    ))
}

@Test
func paywallShowsPlansInCatalogueOrderOnceProductsArrive() {
    let products: [SubscriptionProduct] = [.weeklyFixture(), .monthlyFixture(isRecommended: true)]

    let presentation = MomentPaywallProductPresentation.current(
        isLoadingSubscriptions: false,
        products: products,
        errorMessage: nil
    )

    #expect(presentation == .plans(products))
}

@MainActor
@Test
func paywallSheetRendersForAnUnconfiguredAccountWithoutStoreAccess() {
    let account = MomentAccountModel(
        clientContext: ClientContext(appVersion: "1.0", buildNumber: "1")
    )
    let renderer = ImageRenderer(
        content: MomentPaywallSheet(account: account).frame(width: 390, height: 844)
    )

    #expect(renderer.cgImage != nil)
}

@MainActor
@Test
func paywallPlanRowRendersSelectionAndRecommendationBadge() {
    let renderer = ImageRenderer(
        content: MomentPaywallPlanRow(
            title: "Monthly",
            subtitle: "Every 1 month",
            price: "$4.99",
            badge: "Best value",
            isSelected: true
        ).frame(width: 390)
    )

    #expect(renderer.cgImage != nil)
}

private extension SubscriptionProduct {
    static func weeklyFixture() -> SubscriptionProduct {
        SubscriptionProduct(
            id: "com.prosepal.pro.weekly",
            displayName: "Weekly",
            displayPrice: "$1.99",
            durationLabel: "Every 1 week"
        )
    }

    static func monthlyFixture(isRecommended: Bool = false) -> SubscriptionProduct {
        SubscriptionProduct(
            id: "com.prosepal.pro.monthly",
            displayName: "Monthly",
            displayPrice: "$4.99",
            durationLabel: "Every 1 month",
            isRecommended: isRecommended
        )
    }
}
