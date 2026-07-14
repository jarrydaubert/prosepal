import Foundation
import Testing
@testable import ProsePalAPI

@Test
func unverifiedUnconfiguredTransactionDoesNotAbortEntitlementResolution() throws {
    let configuredProductIDs: Set<String> = ["com.prosepal.pro.monthly"]
    let unrelated = StoreKitEntitlementCandidate(
        verification: .unverified,
        productID: "com.example.other.subscription",
        revocationDate: nil,
        expirationDate: nil
    )
    let configured = StoreKitEntitlementCandidate(
        verification: .verified,
        productID: "com.prosepal.pro.monthly",
        revocationDate: nil,
        expirationDate: Date(timeIntervalSince1970: 2_000)
    )

    #expect(try resolveStoreKitEntitlementCandidate(
        unrelated,
        configuredProductIDs: configuredProductIDs,
        now: Date(timeIntervalSince1970: 1_000)
    ) == nil)
    #expect(try resolveStoreKitEntitlementCandidate(
        configured,
        configuredProductIDs: configuredProductIDs,
        now: Date(timeIntervalSince1970: 1_000)
    ) == SubscriptionEntitlement(
        isActive: true,
        productID: "com.prosepal.pro.monthly",
        expiresAt: Date(timeIntervalSince1970: 2_000)
    ))
}

@Test
func unverifiedConfiguredTransactionStillFailsClosed() {
    let candidate = StoreKitEntitlementCandidate(
        verification: .unverified,
        productID: "com.prosepal.pro.monthly",
        revocationDate: nil,
        expirationDate: nil
    )

    #expect(throws: SubscriptionError.verificationFailed) {
        try resolveStoreKitEntitlementCandidate(
            candidate,
            configuredProductIDs: ["com.prosepal.pro.monthly"],
            now: Date(timeIntervalSince1970: 1_000)
        )
    }
}
