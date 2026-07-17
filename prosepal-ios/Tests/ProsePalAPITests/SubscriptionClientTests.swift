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

@Test
func configuredEntitlementCandidateEnforcesRevocationExpirationAndOwnership() {
    let now = Date(timeIntervalSince1970: 1_000)
    let accountA = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
    let accountB = UUID(uuidString: "22222222-2222-2222-2222-222222222222")!

    #expect(evaluateStoreKitEntitlementCandidate(
        StoreKitEntitlementCandidate(
            verification: .verified,
            productID: "com.prosepal.pro.yearly",
            revocationDate: nil,
            expirationDate: Date(timeIntervalSince1970: 2_000),
            appAccountToken: accountA
        ),
        expectedAccountToken: accountA,
        now: now
    ) == .active)
    #expect(evaluateStoreKitEntitlementCandidate(
        StoreKitEntitlementCandidate(
            verification: .verified,
            productID: "com.prosepal.pro.yearly",
            revocationDate: now,
            expirationDate: Date(timeIntervalSince1970: 2_000),
            appAccountToken: accountA
        ),
        expectedAccountToken: accountA,
        now: now
    ) == .inactive)
    #expect(evaluateStoreKitEntitlementCandidate(
        StoreKitEntitlementCandidate(
            verification: .verified,
            productID: "com.prosepal.pro.yearly",
            revocationDate: nil,
            expirationDate: Date(timeIntervalSince1970: 999),
            appAccountToken: accountA
        ),
        expectedAccountToken: accountA,
        now: now
    ) == .inactive)
    #expect(evaluateStoreKitEntitlementCandidate(
        StoreKitEntitlementCandidate(
            verification: .verified,
            productID: "com.prosepal.pro.yearly",
            revocationDate: nil,
            expirationDate: Date(timeIntervalSince1970: 2_000),
            appAccountToken: accountA
        ),
        expectedAccountToken: accountB,
        now: now
    ) == .ownershipMismatch)
}

@Test
func anonymousTransactionsRemainCompatibleUntilAnExplicitDifferentOwnerExists() {
    #expect(SubscriptionTransactionOwnership.unlinked.isCompatible(with: nil))
    #expect(SubscriptionTransactionOwnership.unlinked.isCompatible(
        with: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
    ))
    #expect(SubscriptionTransactionOwnership.linked(
        UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
    ).isCompatible(with: nil))
}
