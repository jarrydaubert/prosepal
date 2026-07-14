import StoreKit
import StoreKitTest
import XCTest
import ProsePalAPI

final class StoreKitSubscriptionClientStoreKitTests: XCTestCase {
    private static let yearlyID = "com.prosepal.pro.yearly"
    private static let monthlyID = "com.prosepal.pro.monthly"
    private static let weeklyID = "com.prosepal.pro.weekly"
    private static let retiredID = "com.prosepal.pro.retired"
    private static let productIDs = [yearlyID, monthlyID, weeklyID]

    private var session: SKTestSession!

    override func setUp() async throws {
        try await super.setUp()
        session = try SKTestSession(configurationFileNamed: "ProsePalStaging")
        session.resetToDefaultState()
        session.clearTransactions()
        session.disableDialogs = true

        let environmentProbe = try await Product.products(for: [Self.yearlyID])
        if environmentProbe.isEmpty {
            throw XCTSkip(
                "StoreKit Test did not install its local configuration. " +
                "Xcode 26.6 with the installed iOS 26.4/26.5 runtimes reports " +
                "SKInternalErrorDomain Code=3 before client code runs."
            )
        }
    }

    override func tearDownWithError() throws {
        if let session {
            session.clearTransactions()
            session.resetToDefaultState()
        }
        session = nil
        try super.tearDownWithError()
    }

    func testLoadsExactlyTheConfiguredProducts() async throws {
        let products = try await makeClient().loadProducts()

        XCTAssertEqual(Set(products.map(\.id)), Set(Self.productIDs))
        XCTAssertEqual(products.count, 3)
    }

    func testPurchaseUsesAccountTokenDefersFinishAndResolvesActiveEntitlement() async throws {
        let accountToken = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
        let result = try await makeClient(accountToken: accountToken).purchase(productID: Self.yearlyID)

        XCTAssertEqual(result.status, .purchased)
        guard case .active(let entitlement, let renewalState, let ownership) = result.entitlementState else {
            return XCTFail("Expected a verified active entitlement")
        }
        XCTAssertEqual(entitlement.productID, Self.yearlyID)
        XCTAssertEqual(renewalState, .subscribed)
        XCTAssertEqual(ownership, .linked(accountToken))

        let latest = await Transaction.latest(for: Self.yearlyID)
        guard case .verified(let transaction)? = latest else {
            return XCTFail("Expected a verified StoreKit transaction")
        }
        XCTAssertEqual(transaction.appAccountToken, accountToken)

        await result.finish()
    }

    func testAnonymousPurchaseHasNoAccountToken() async throws {
        let result = try await makeClient().purchase(productID: Self.monthlyID)

        guard case .active(_, _, let ownership) = result.entitlementState else {
            return XCTFail("Expected an active anonymous purchase")
        }
        XCTAssertEqual(ownership, .unlinked)
        let latest = await Transaction.latest(for: Self.monthlyID)
        guard case .verified(let transaction)? = latest else {
            return XCTFail("Expected a verified StoreKit transaction")
        }
        XCTAssertNil(transaction.appAccountToken)
        await result.finish()
    }

    func testAskToBuyReturnsPendingThenApprovalAppearsInUpdates() async throws {
        session.askToBuyEnabled = true
        let client = makeClient()
        let result = try await client.purchase(productID: Self.weeklyID)
        XCTAssertEqual(result.status, .pending)

        let pending = try XCTUnwrap(session.allTransactions().first)
        XCTAssertTrue(pending.pendingAskToBuyConfirmation)

        let updates = await client.transactionUpdates()
        async let update = Self.firstUpdate(from: updates)
        try session.approveAskToBuyTransaction(identifier: pending.identifier)
        let approved = await update
        XCTAssertEqual(approved?.verification, .verified)
        XCTAssertEqual(approved?.productID, Self.weeklyID)
        await approved?.finish()
    }

    func testSimulatedCancellationIsReportedWithoutEntitlement() async throws {
        try await session.setSimulatedError(
            .generic(.userCancelled),
            forAPI: .purchase
        )

        let result = try await makeClient().purchase(productID: Self.yearlyID)
        XCTAssertEqual(result.status, .cancelled)
        XCTAssertEqual(result.entitlementState, .inactive)
    }

    func testRestoreUsesAppStoreSyncAndReportsActiveOrInactive() async throws {
        let client = makeClient()
        let empty = try await client.restorePurchases()
        XCTAssertEqual(empty.status, .notEntitled)
        XCTAssertEqual(empty.entitlementState, .inactive)

        _ = try await session.buyProduct(identifier: Self.yearlyID)
        let restored = try await client.restorePurchases()
        XCTAssertEqual(restored.status, .restored)
        XCTAssertEqual(restored.entitlementState.entitlement?.productID, Self.yearlyID)
    }

    func testExpirationAndRefundConvergeToConfirmedInactive() async throws {
        let client = makeClient()
        let transaction = try await session.buyProduct(identifier: Self.monthlyID)
        let active = await client.currentEntitlement()
        XCTAssertEqual(active.entitlement?.productID, Self.monthlyID)

        try session.expireSubscription(productIdentifier: Self.monthlyID)
        let expired = await client.currentEntitlement()
        XCTAssertEqual(expired, .confirmedInactive(renewalState: .expired))

        session.clearTransactions()
        let refunded = try await session.buyProduct(identifier: Self.weeklyID)
        try session.refundTransaction(identifier: UInt(refunded.id))
        let revoked = await client.currentEntitlement()
        XCTAssertEqual(revoked, .confirmedInactive(renewalState: .revoked))
        _ = transaction
    }

    func testGracePeriodGrantsWhileBillingRetryDoesNot() async throws {
        session.timeRate = .oneRenewalEveryTwoSeconds
        session.shouldEnterBillingRetryOnRenewal = true
        session.billingGracePeriodIsEnabled = true
        _ = try await session.buyProduct(identifier: Self.monthlyID)
        try session.forceRenewalOfSubscription(productIdentifier: Self.monthlyID)

        let grace = await eventuallyEntitlement(from: makeClient()) { state in
            if case .active(_, .gracePeriod, _) = state { return true }
            return false
        }
        guard case .active(_, .gracePeriod, _) = grace else {
            return XCTFail("Expected grace period to remain entitled")
        }

        session.billingGracePeriodIsEnabled = false
        try session.forceRenewalOfSubscription(productIdentifier: Self.monthlyID)
        let retry = await eventuallyEntitlement(from: makeClient()) {
            $0 == .confirmedInactive(renewalState: .billingRetry)
        }
        XCTAssertEqual(retry, .confirmedInactive(renewalState: .billingRetry))
    }

    func testTransientStatusFailureIsUnknownAndVerificationFailureStaysUnknown() async throws {
        try await session.setSimulatedError(.generic(.networkError(URLError(.notConnectedToInternet))), forAPI: .subscriptionStatus)
        let transientFailure = await makeClient().currentEntitlement()
        XCTAssertEqual(transientFailure, .unknown(.storeUnavailable))

        try await session.setSimulatedError(nil, forAPI: .subscriptionStatus)
        try await session.setSimulatedError(.verification(.invalidSignature), forAPI: .verification)
        _ = try await session.buyProduct(identifier: Self.yearlyID)
        let verificationFailure = await makeClient().currentEntitlement()
        XCTAssertEqual(verificationFailure, .unknown(.verificationFailed))
    }

    func testRetiredProductIsRecognizedOnlyWhenExplicitlyConfigured() async throws {
        _ = try await session.buyProduct(identifier: Self.retiredID)

        let recognized = await StoreKitSubscriptionClient(
            productIDs: Self.productIDs,
            retiredProductIDs: [Self.retiredID]
        ).currentEntitlement()
        XCTAssertEqual(recognized.entitlement?.productID, Self.retiredID)

        let unrelated = await makeClient().currentEntitlement()
        XCTAssertEqual(unrelated, .inactive)
    }

    func testAccountTokenMismatchFailsClosed() async throws {
        let purchasingAccount = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
        let currentAccount = UUID(uuidString: "22222222-2222-2222-2222-222222222222")!
        _ = try await session.buyProduct(
            identifier: Self.yearlyID,
            options: [.appAccountToken(purchasingAccount)]
        )

        let state = await makeClient(accountToken: currentAccount).currentEntitlement()
        XCTAssertEqual(state, .unknown(.ownershipMismatch))
    }

    func testExternallyCompletedPurchaseArrivesThroughTransactionUpdates() async throws {
        let client = makeClient()
        let updates = await client.transactionUpdates()
        async let pendingUpdate = Self.firstUpdate(from: updates)

        _ = try await session.buyProduct(identifier: Self.weeklyID)
        let update = await pendingUpdate

        XCTAssertEqual(update?.verification, .verified)
        XCTAssertEqual(update?.productID, Self.weeklyID)
        XCTAssertEqual(update?.effect, .grantsOrRenews)
        await update?.finish()
    }

    private func makeClient(accountToken: UUID? = nil) -> StoreKitSubscriptionClient {
        StoreKitSubscriptionClient(
            productIDs: Self.productIDs,
            appAccountTokenProvider: { accountToken }
        )
    }

    private static func firstUpdate(
        from updates: AsyncStream<SubscriptionTransactionUpdate>
    ) async -> SubscriptionTransactionUpdate? {
        await withTaskGroup(of: SubscriptionTransactionUpdate?.self) { group in
            group.addTask {
                for await update in updates { return update }
                return nil
            }
            group.addTask {
                try? await Task.sleep(for: .seconds(2))
                return nil
            }
            let first = await group.next() ?? nil
            group.cancelAll()
            return first
        }
    }

    private func eventuallyEntitlement(
        from client: StoreKitSubscriptionClient,
        matching predicate: (SubscriptionEntitlementState) -> Bool
    ) async -> SubscriptionEntitlementState {
        var latest: SubscriptionEntitlementState = .unknown(.storeUnavailable)
        for _ in 0..<30 {
            latest = await client.currentEntitlement()
            if predicate(latest) { return latest }
            try? await Task.sleep(for: .milliseconds(100))
        }
        return latest
    }
}
