import Foundation
import OSLog

#if canImport(StoreKit)
import StoreKit
#endif

public struct SubscriptionProduct: Equatable, Identifiable, Sendable {
    public var id: String
    public var displayName: String
    public var displayPrice: String
    public var durationLabel: String?
    public var isRecommended: Bool

    public init(
        id: String,
        displayName: String,
        displayPrice: String,
        durationLabel: String? = nil,
        isRecommended: Bool = false
    ) {
        self.id = id
        self.displayName = displayName
        self.displayPrice = displayPrice
        self.durationLabel = durationLabel
        self.isRecommended = isRecommended
    }
}

public struct SubscriptionEntitlement: Equatable, Sendable {
    public var isActive: Bool
    public var productID: String?
    public var expiresAt: Date?

    public init(isActive: Bool, productID: String? = nil, expiresAt: Date? = nil) {
        self.isActive = isActive
        self.productID = productID
        self.expiresAt = expiresAt
    }

    public static let inactive = SubscriptionEntitlement(isActive: false)
}

public enum SubscriptionRenewalState: String, Equatable, Sendable {
    case subscribed
    case gracePeriod
    case billingRetry
    case expired
    case revoked
    case notApplicable
}

public enum SubscriptionEntitlementFailure: String, Equatable, Sendable {
    case notConfigured
    case productsUnavailable
    case verificationFailed
    case storeUnavailable
    case ownershipMismatch
    case unexpectedResponse

    public var userSafeMessage: String {
        switch self {
        case .notConfigured:
            SubscriptionError.notConfigured.userSafeMessage
        case .productsUnavailable:
            SubscriptionError.productsUnavailable.userSafeMessage
        case .verificationFailed:
            SubscriptionError.verificationFailed.userSafeMessage
        case .storeUnavailable:
            SubscriptionError.storeUnavailable.userSafeMessage
        case .ownershipMismatch:
            "This purchase belongs to a different ProsePal account. Sign in with the purchasing account or restore without signing in."
        case .unexpectedResponse:
            SubscriptionError.unexpectedResponse.userSafeMessage
        }
    }
}

public enum SubscriptionEntitlementState: Equatable, Sendable {
    case active(
        entitlement: SubscriptionEntitlement,
        renewalState: SubscriptionRenewalState,
        ownership: SubscriptionTransactionOwnership
    )
    case confirmedInactive(renewalState: SubscriptionRenewalState)
    case unknown(SubscriptionEntitlementFailure)

    public static func active(
        _ entitlement: SubscriptionEntitlement,
        renewalState: SubscriptionRenewalState = .subscribed,
        ownership: SubscriptionTransactionOwnership = .unlinked
    ) -> Self {
        .active(
            entitlement: entitlement,
            renewalState: renewalState,
            ownership: ownership
        )
    }

    public static let inactive: Self = .confirmedInactive(renewalState: .notApplicable)

    public var entitlement: SubscriptionEntitlement? {
        guard case .active(let entitlement, _, _) = self else { return nil }
        return entitlement
    }

    public var isConfirmed: Bool {
        if case .unknown = self { return false }
        return true
    }
}

public enum SubscriptionTransactionOwnership: Equatable, Sendable {
    case linked(UUID)
    case unlinked

    public func isCompatible(with expectedAccountToken: UUID?) -> Bool {
        guard let expectedAccountToken else { return true }
        switch self {
        case .linked(let token):
            return token == expectedAccountToken
        case .unlinked:
            return true
        }
    }
}

public enum SubscriptionPurchaseStatus: String, Equatable, Sendable {
    case purchased
    case restored
    case pending
    case cancelled
    case notEntitled
}

public struct SubscriptionPurchaseResult: Equatable, Sendable {
    public var status: SubscriptionPurchaseStatus
    public var entitlementState: SubscriptionEntitlementState

    private let delivery: SubscriptionTransactionDelivery?

    public init(
        status: SubscriptionPurchaseStatus,
        entitlementState: SubscriptionEntitlementState = .inactive,
        delivery: SubscriptionTransactionDelivery? = nil
    ) {
        self.status = status
        self.entitlementState = entitlementState
        self.delivery = delivery
    }

    public init(status: SubscriptionPurchaseStatus, entitlement: SubscriptionEntitlement) {
        self.init(
            status: status,
            entitlementState: entitlement.isActive ? .active(entitlement) : .inactive
        )
    }

    public var entitlement: SubscriptionEntitlement {
        entitlementState.entitlement ?? .inactive
    }

    public var transactionOwnership: SubscriptionTransactionOwnership? {
        delivery?.ownership
    }

    public var transactionProductID: String? {
        delivery?.productID
    }

    public func finish() async {
        await delivery?.finish()
    }
}

public struct SubscriptionTransactionDelivery: Sendable {
    public var productID: String
    public var ownership: SubscriptionTransactionOwnership

    private let finishAction: @Sendable () async -> Void

    public init(
        productID: String,
        ownership: SubscriptionTransactionOwnership,
        finishAction: @escaping @Sendable () async -> Void
    ) {
        self.productID = productID
        self.ownership = ownership
        self.finishAction = finishAction
    }

    public func finish() async {
        await finishAction()
    }
}

extension SubscriptionTransactionDelivery: Equatable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.productID == rhs.productID && lhs.ownership == rhs.ownership
    }
}

public struct SubscriptionTransactionUpdate: Sendable {
    public enum Verification: Equatable, Sendable {
        case verified
        case unverified
    }

    public var verification: Verification
    public var productID: String
    public var ownership: SubscriptionTransactionOwnership
    public var effect: SubscriptionTransactionEffect

    private let finishAction: (@Sendable () async -> Void)?

    public init(
        verification: Verification,
        productID: String,
        ownership: SubscriptionTransactionOwnership = .unlinked,
        effect: SubscriptionTransactionEffect = .grantsOrRenews,
        finishAction: (@Sendable () async -> Void)? = nil
    ) {
        self.verification = verification
        self.productID = productID
        self.ownership = ownership
        self.effect = effect
        self.finishAction = finishAction
    }

    public func finish() async {
        guard verification == .verified else { return }
        await finishAction?()
    }
}

public enum SubscriptionTransactionEffect: Equatable, Sendable {
    case grantsOrRenews
    case removesAccess
    case unknown
}

public enum SubscriptionError: Error, Equatable, Sendable {
    case notConfigured
    case productsUnavailable
    case productUnavailable
    case purchaseCancelled
    case purchasePending
    case verificationFailed
    case storeUnavailable
    case unexpectedResponse

    public var userSafeMessage: String {
        switch self {
        case .notConfigured:
            "Subscriptions are not configured for this build."
        case .productsUnavailable:
            "Subscription options could not be loaded. Please try again shortly."
        case .productUnavailable:
            "That subscription option is unavailable right now."
        case .purchaseCancelled:
            "Purchase cancelled."
        case .purchasePending:
            "Purchase pending approval."
        case .verificationFailed:
            "Purchase verification failed. Please try again."
        case .storeUnavailable:
            "The App Store is unavailable right now. Please try again shortly."
        case .unexpectedResponse:
            "Subscriptions are unavailable right now. Please try again shortly."
        }
    }

    public var entitlementFailure: SubscriptionEntitlementFailure {
        switch self {
        case .notConfigured:
            .notConfigured
        case .productsUnavailable, .productUnavailable:
            .productsUnavailable
        case .verificationFailed:
            .verificationFailed
        case .storeUnavailable:
            .storeUnavailable
        case .purchaseCancelled, .purchasePending, .unexpectedResponse:
            .unexpectedResponse
        }
    }
}

public protocol SubscriptionClient: Sendable {
    func loadProducts() async throws -> [SubscriptionProduct]
    func currentEntitlement() async -> SubscriptionEntitlementState
    func purchase(productID: String) async throws -> SubscriptionPurchaseResult
    func restorePurchases() async throws -> SubscriptionPurchaseResult
    func transactionUpdates() async -> AsyncStream<SubscriptionTransactionUpdate>
}

public extension SubscriptionClient {
    func transactionUpdates() async -> AsyncStream<SubscriptionTransactionUpdate> {
        AsyncStream { continuation in
            continuation.finish()
        }
    }
}

#if canImport(StoreKit)
public struct StoreKitSubscriptionClient: SubscriptionClient {
    private let productIDs: [String]
    private let retiredProductIDs: [String]
    private let recommendedProductID: String?
    private let appAccountTokenProvider: (@Sendable () async -> UUID?)?

    public init(
        productIDs: [String],
        retiredProductIDs: [String] = [],
        recommendedProductID: String? = nil,
        appAccountTokenProvider: (@Sendable () async -> UUID?)? = nil
    ) {
        let configuredProductIDs = productIDs.uniqueTrimmedValues
        self.productIDs = configuredProductIDs
        self.retiredProductIDs = retiredProductIDs.uniqueTrimmedValues
            .filter { !configuredProductIDs.contains($0) }
        self.recommendedProductID = recommendedProductID?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfBlank
        self.appAccountTokenProvider = appAccountTokenProvider
    }

    public func loadProducts() async throws -> [SubscriptionProduct] {
        guard !productIDs.isEmpty else { throw SubscriptionError.notConfigured }

        let diagnosticsContext = SubscriptionStoreDiagnosticsContext.storeKit2(
            requestedProductIDs: productIDs,
            recommendedProductID: recommendedProductID
        )
        SubscriptionDiagnosticsLogger.shared.productsLoadStarted(diagnosticsContext)

        let products: [Product]
        do {
            products = try await Product.products(for: productIDs)
        } catch {
            SubscriptionDiagnosticsLogger.shared.productsLoadFailed(
                diagnosticsContext,
                error: error
            )
            throw SubscriptionError.storeUnavailable
        }

        SubscriptionDiagnosticsLogger.shared.productsLoadReturned(
            diagnosticsContext,
            returnedProductIDs: products.map(\.id)
        )
        guard !products.isEmpty else { throw SubscriptionError.productsUnavailable }

        return products
            .sorted { left, right in
                let leftRank = sortRank(for: left)
                let rightRank = sortRank(for: right)
                if leftRank != rightRank { return leftRank < rightRank }
                return left.displayName < right.displayName
            }
            .map { product in
                SubscriptionProduct(
                    id: product.id,
                    displayName: product.displayName,
                    displayPrice: product.displayPrice,
                    durationLabel: product.prosePalDurationLabel,
                    isRecommended: product.id == recommendedProductID
                )
            }
    }

    public func currentEntitlement() async -> SubscriptionEntitlementState {
        guard !productIDs.isEmpty else { return .unknown(.notConfigured) }

        let entitlementProductIDs = productIDs + retiredProductIDs
        let expectedAccountToken = await appAccountTokenProvider?()
        var activeCandidate: StoreKitEntitlementCandidate?
        var observedVerificationFailure = false
        var observedOwnershipMismatch = false

        for productID in entitlementProductIDs {
            for await result in Transaction.currentEntitlements(for: productID) {
                let candidate = StoreKitEntitlementCandidate(result: result)
                switch evaluateStoreKitEntitlementCandidate(
                    candidate,
                    expectedAccountToken: expectedAccountToken,
                    now: Date()
                ) {
                case .active:
                    if activeCandidate == nil {
                        activeCandidate = candidate
                    }
                case .verificationFailed:
                    observedVerificationFailure = true
                case .ownershipMismatch:
                    observedOwnershipMismatch = true
                case .inactive:
                    break
                }
            }
        }

        let statusResolution = await subscriptionStatusResolution(
            expectedAccountToken: expectedAccountToken
        )
        if case .active = statusResolution {
            return statusResolution
        }
        if let activeCandidate {
            return .active(
                activeCandidate.entitlement,
                renewalState: .subscribed,
                ownership: activeCandidate.ownership
            )
        }
        if observedVerificationFailure {
            return .unknown(.verificationFailed)
        }
        if observedOwnershipMismatch {
            return .unknown(.ownershipMismatch)
        }
        return statusResolution
    }

    public func purchase(productID: String) async throws -> SubscriptionPurchaseResult {
        guard productIDs.contains(productID) else { throw SubscriptionError.productUnavailable }

        let products = try await Product.products(for: [productID])
        guard let product = products.first else { throw SubscriptionError.productUnavailable }

        var purchaseOptions = Set<Product.PurchaseOption>()
        if let appAccountToken = await appAccountTokenProvider?() {
            purchaseOptions.insert(.appAccountToken(appAccountToken))
        }

        let result: Product.PurchaseResult
        do {
            result = try await product.purchase(options: purchaseOptions)
        } catch StoreKitError.userCancelled {
            return SubscriptionPurchaseResult(
                status: .cancelled,
                entitlementState: await currentEntitlement()
            )
        } catch {
            throw SubscriptionError.storeUnavailable
        }
        switch result {
        case .success(let verificationResult):
            let transaction = try verified(verificationResult)
            let entitlementState = await currentEntitlement()
            return SubscriptionPurchaseResult(
                status: .purchased,
                entitlementState: entitlementState,
                delivery: SubscriptionTransactionDelivery(
                    productID: transaction.productID,
                    ownership: transaction.subscriptionOwnership,
                    finishAction: { await transaction.finish() }
                )
            )
        case .pending:
            return SubscriptionPurchaseResult(
                status: .pending,
                entitlementState: await currentEntitlement()
            )
        case .userCancelled:
            return SubscriptionPurchaseResult(
                status: .cancelled,
                entitlementState: await currentEntitlement()
            )
        @unknown default:
            throw SubscriptionError.unexpectedResponse
        }
    }

    public func restorePurchases() async throws -> SubscriptionPurchaseResult {
        guard !productIDs.isEmpty else { throw SubscriptionError.notConfigured }

        do {
            try await AppStore.sync()
        } catch {
            throw SubscriptionError.storeUnavailable
        }

        let entitlementState = await currentEntitlement()
        return SubscriptionPurchaseResult(
            status: entitlementState.entitlement?.isActive == true ? .restored : .notEntitled,
            entitlementState: entitlementState
        )
    }

    public func transactionUpdates() async -> AsyncStream<SubscriptionTransactionUpdate> {
        let entitlementProductIDs = Set(productIDs + retiredProductIDs)

        return AsyncStream { continuation in
            let listenerTask = Task(priority: .background) {
                for await result in Transaction.updates {
                    guard !Task.isCancelled else { break }

                    switch result {
                    case .verified(let transaction):
                        guard entitlementProductIDs.contains(transaction.productID) else { continue }
                        continuation.yield(SubscriptionTransactionUpdate(
                            verification: .verified,
                            productID: transaction.productID,
                            ownership: transaction.subscriptionOwnership,
                            effect: transaction.subscriptionEffect,
                            finishAction: {
                                await transaction.finish()
                            }
                        ))
                    case .unverified(let transaction, _):
                        guard entitlementProductIDs.contains(transaction.productID) else { continue }
                        continuation.yield(SubscriptionTransactionUpdate(
                            verification: .unverified,
                            productID: transaction.productID,
                            ownership: transaction.subscriptionOwnership,
                            effect: .unknown
                        ))
                    }
                }

                continuation.finish()
            }

            continuation.onTermination = { @Sendable _ in
                listenerTask.cancel()
            }
        }
    }

    private func sortRank(for product: Product) -> Int {
        if product.id == recommendedProductID { return 0 }
        guard let period = product.subscription?.subscriptionPeriod else { return 50 }

        switch period.unit {
        case .year:
            return 10
        case .month:
            return 20
        case .week:
            return 30
        case .day:
            return 40
        @unknown default:
            return 50
        }
    }

    private func subscriptionStatusResolution(
        expectedAccountToken: UUID?
    ) async -> SubscriptionEntitlementState {
        let products: [Product]
        do {
            products = try await Product.products(for: productIDs)
        } catch {
            return .unknown(.storeUnavailable)
        }
        guard !products.isEmpty else { return .unknown(.productsUnavailable) }

        var inactiveState: SubscriptionRenewalState = .notApplicable
        do {
            for product in products {
                guard let subscription = product.subscription else { continue }
                for status in try await subscription.status {
                    let transaction: Transaction
                    switch status.transaction {
                    case .verified(let verifiedTransaction):
                        transaction = verifiedTransaction
                    case .unverified:
                        return .unknown(.verificationFailed)
                    }
                    guard productIDs.contains(transaction.productID) else { continue }
                    let ownership = transaction.subscriptionOwnership
                    guard ownership.isCompatible(with: expectedAccountToken) else {
                        return .unknown(.ownershipMismatch)
                    }
                    guard case .verified = status.renewalInfo else {
                        return .unknown(.verificationFailed)
                    }

                    let renewalState = status.state.prosePalRenewalState
                    switch renewalState {
                    case .subscribed, .gracePeriod:
                        return .active(
                            SubscriptionEntitlement(
                                isActive: true,
                                productID: transaction.productID,
                                expiresAt: transaction.expirationDate
                            ),
                            renewalState: renewalState,
                            ownership: ownership
                        )
                    case .billingRetry, .expired, .revoked:
                        inactiveState = renewalState
                    case .notApplicable:
                        break
                    }
                }
            }
        } catch {
            return .unknown(.storeUnavailable)
        }

        return .confirmedInactive(renewalState: inactiveState)
    }
}

enum StoreKitEntitlementVerification: Equatable, Sendable {
    case verified
    case unverified
}

struct StoreKitEntitlementCandidate: Equatable, Sendable {
    var verification: StoreKitEntitlementVerification
    var productID: String
    var revocationDate: Date?
    var expirationDate: Date?
    var appAccountToken: UUID?

    init(
        verification: StoreKitEntitlementVerification,
        productID: String,
        revocationDate: Date?,
        expirationDate: Date?,
        appAccountToken: UUID? = nil
    ) {
        self.verification = verification
        self.productID = productID
        self.revocationDate = revocationDate
        self.expirationDate = expirationDate
        self.appAccountToken = appAccountToken
    }

    init(result: VerificationResult<Transaction>) {
        switch result {
        case .verified(let transaction):
            self.init(
                verification: .verified,
                productID: transaction.productID,
                revocationDate: transaction.revocationDate,
                expirationDate: transaction.expirationDate,
                appAccountToken: transaction.appAccountToken
            )
        case .unverified(let transaction, _):
            self.init(
                verification: .unverified,
                productID: transaction.productID,
                revocationDate: transaction.revocationDate,
                expirationDate: transaction.expirationDate,
                appAccountToken: transaction.appAccountToken
            )
        }
    }

    var entitlement: SubscriptionEntitlement {
        SubscriptionEntitlement(
            isActive: true,
            productID: productID,
            expiresAt: expirationDate
        )
    }

    var ownership: SubscriptionTransactionOwnership {
        appAccountToken.map(SubscriptionTransactionOwnership.linked) ?? .unlinked
    }
}

enum StoreKitEntitlementCandidateEvaluation: Equatable, Sendable {
    case active
    case inactive
    case verificationFailed
    case ownershipMismatch
}

func evaluateStoreKitEntitlementCandidate(
    _ candidate: StoreKitEntitlementCandidate,
    expectedAccountToken: UUID?,
    now: Date
) -> StoreKitEntitlementCandidateEvaluation {
    guard candidate.verification == .verified else { return .verificationFailed }
    guard candidate.ownership.isCompatible(with: expectedAccountToken) else {
        return .ownershipMismatch
    }
    guard candidate.revocationDate == nil else { return .inactive }
    if let expirationDate = candidate.expirationDate, expirationDate < now {
        return .inactive
    }
    return .active
}

func resolveStoreKitEntitlementCandidate(
    _ candidate: StoreKitEntitlementCandidate,
    configuredProductIDs: Set<String>,
    now: Date
) throws -> SubscriptionEntitlement? {
    guard configuredProductIDs.contains(candidate.productID) else { return nil }
    let evaluation = evaluateStoreKitEntitlementCandidate(
        candidate,
        expectedAccountToken: nil,
        now: now
    )
    guard evaluation != .verificationFailed else {
        throw SubscriptionError.verificationFailed
    }
    guard evaluation == .active else { return nil }

    return candidate.entitlement
}

private func verified<T>(_ result: VerificationResult<T>) throws -> T {
    switch result {
    case .verified(let value):
        return value
    case .unverified:
        throw SubscriptionError.verificationFailed
    }
}

private extension Product {
    var prosePalDurationLabel: String? {
        guard let period = subscription?.subscriptionPeriod else { return nil }

        let unit: String
        switch period.unit {
        case .day:
            unit = period.value == 1 ? "day" : "days"
        case .week:
            unit = period.value == 1 ? "week" : "weeks"
        case .month:
            unit = period.value == 1 ? "month" : "months"
        case .year:
            unit = period.value == 1 ? "year" : "years"
        @unknown default:
            return nil
        }

        return "Every \(period.value) \(unit)"
    }
}

private extension Transaction {
    var subscriptionOwnership: SubscriptionTransactionOwnership {
        appAccountToken.map(SubscriptionTransactionOwnership.linked) ?? .unlinked
    }

    var subscriptionEffect: SubscriptionTransactionEffect {
        if revocationDate != nil {
            return .removesAccess
        }
        if let expirationDate, expirationDate < Date() {
            return .removesAccess
        }
        return .grantsOrRenews
    }
}

private extension Product.SubscriptionInfo.RenewalState {
    var prosePalRenewalState: SubscriptionRenewalState {
        switch self {
        case .subscribed:
            .subscribed
        case .inGracePeriod:
            .gracePeriod
        case .inBillingRetryPeriod:
            .billingRetry
        case .expired:
            .expired
        case .revoked:
            .revoked
        default:
            .notApplicable
        }
    }
}
#endif

private struct SubscriptionStoreDiagnosticsContext: Sendable {
    var implementation: String
    var buildConfiguration: String
    var requestedProductIDs: [String]
    var recommendedProductID: String?

    static func storeKit2(requestedProductIDs: [String], recommendedProductID: String?) -> Self {
        SubscriptionStoreDiagnosticsContext(
            implementation: "storekit2",
            buildConfiguration: currentBuildConfiguration,
            requestedProductIDs: requestedProductIDs,
            recommendedProductID: recommendedProductID
        )
    }

    private static var currentBuildConfiguration: String {
        #if DEBUG
        "debug"
        #else
        "release"
        #endif
    }
}

private struct SubscriptionDiagnosticsLogger: Sendable {
    static let shared = SubscriptionDiagnosticsLogger()

    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.prosepal.prosepal", category: "subscription")

    func productsLoadStarted(_ context: SubscriptionStoreDiagnosticsContext) {
        logger.info(
            "subscription_store event=products_request_started implementation=\(context.implementation, privacy: .public) build_configuration=\(context.buildConfiguration, privacy: .public) requested_product_count=\(context.requestedProductIDs.count, privacy: .public) requested_product_ids=\(context.requestedProductIDs.diagnosticsList, privacy: .public) recommended_product_configured=\((context.recommendedProductID != nil), privacy: .public)"
        )
    }

    func productsLoadReturned(
        _ context: SubscriptionStoreDiagnosticsContext,
        returnedProductIDs: [String]
    ) {
        logger.info(
            "subscription_store event=products_request_returned implementation=\(context.implementation, privacy: .public) returned_product_count=\(returnedProductIDs.count, privacy: .public) returned_product_ids=\(returnedProductIDs.diagnosticsList, privacy: .public) outcome=\(returnedProductIDs.isEmpty ? "empty" : "success", privacy: .public)"
        )
    }

    func productsLoadFailed(
        _ context: SubscriptionStoreDiagnosticsContext,
        error: Error
    ) {
        logger.warning(
            "subscription_store event=products_request_threw implementation=\(context.implementation, privacy: .public) error_type=\(String(describing: type(of: error)), privacy: .public) error_message=\(error.localizedDescription.diagnosticsSingleLine, privacy: .public)"
        )
    }
}

private extension Array where Element == String {
    var uniqueTrimmedValues: [String] {
        var seen = Set<String>()
        return compactMap { value in
            let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty, !seen.contains(trimmed) else { return nil }
            seen.insert(trimmed)
            return trimmed
        }
    }

    var diagnosticsList: String {
        isEmpty ? "none" : joined(separator: ",")
    }
}

private extension String {
    var diagnosticsSingleLine: String {
        replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "\r", with: " ")
    }

    var nilIfBlank: String? {
        isEmpty ? nil : self
    }
}
