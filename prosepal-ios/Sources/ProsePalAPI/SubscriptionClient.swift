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

public enum SubscriptionPurchaseStatus: String, Equatable, Sendable {
    case purchased
    case restored
    case pending
    case cancelled
    case notEntitled
}

public struct SubscriptionPurchaseResult: Equatable, Sendable {
    public var status: SubscriptionPurchaseStatus
    public var entitlement: SubscriptionEntitlement

    public init(status: SubscriptionPurchaseStatus, entitlement: SubscriptionEntitlement = .inactive) {
        self.status = status
        self.entitlement = entitlement
    }
}

public struct SubscriptionTransactionUpdate: Sendable {
    public enum Verification: Equatable, Sendable {
        case verified
        case unverified
    }

    public var verification: Verification
    public var productID: String

    private let finishAction: (@Sendable () async -> Void)?

    public init(
        verification: Verification,
        productID: String,
        finishAction: (@Sendable () async -> Void)? = nil
    ) {
        self.verification = verification
        self.productID = productID
        self.finishAction = finishAction
    }

    public func finish() async {
        guard verification == .verified else { return }
        await finishAction?()
    }
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
}

public protocol SubscriptionClient: Sendable {
    func loadProducts() async throws -> [SubscriptionProduct]
    func currentEntitlement() async throws -> SubscriptionEntitlement
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
    private let recommendedProductID: String?
    private let appAccountTokenProvider: (@Sendable () async -> UUID?)?

    public init(
        productIDs: [String],
        recommendedProductID: String? = nil,
        appAccountTokenProvider: (@Sendable () async -> UUID?)? = nil
    ) {
        self.productIDs = productIDs.uniqueTrimmedValues
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
            throw error
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

    public func currentEntitlement() async throws -> SubscriptionEntitlement {
        guard !productIDs.isEmpty else { throw SubscriptionError.notConfigured }

        for await result in Transaction.currentEntitlements {
            let transaction = try verified(result)
            guard productIDs.contains(transaction.productID) else { continue }
            guard transaction.revocationDate == nil else { continue }
            if let expirationDate = transaction.expirationDate, expirationDate < Date() {
                continue
            }
            return SubscriptionEntitlement(
                isActive: true,
                productID: transaction.productID,
                expiresAt: transaction.expirationDate
            )
        }

        return .inactive
    }

    public func purchase(productID: String) async throws -> SubscriptionPurchaseResult {
        guard productIDs.contains(productID) else { throw SubscriptionError.productUnavailable }

        let products = try await Product.products(for: [productID])
        guard let product = products.first else { throw SubscriptionError.productUnavailable }

        var purchaseOptions = Set<Product.PurchaseOption>()
        if let appAccountToken = await appAccountTokenProvider?() {
            purchaseOptions.insert(.appAccountToken(appAccountToken))
        }

        let result = try await product.purchase(options: purchaseOptions)
        switch result {
        case .success(let verificationResult):
            let transaction = try verified(verificationResult)
            let entitlement = try await currentEntitlement()
            await transaction.finish()
            return SubscriptionPurchaseResult(
                status: .purchased,
                entitlement: entitlement
            )
        case .pending:
            return SubscriptionPurchaseResult(
                status: .pending,
                entitlement: (try? await currentEntitlement()) ?? .inactive
            )
        case .userCancelled:
            return SubscriptionPurchaseResult(
                status: .cancelled,
                entitlement: (try? await currentEntitlement()) ?? .inactive
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

        let entitlement = try await currentEntitlement()
        return SubscriptionPurchaseResult(
            status: entitlement.isActive ? .restored : .notEntitled,
            entitlement: entitlement
        )
    }

    public func transactionUpdates() async -> AsyncStream<SubscriptionTransactionUpdate> {
        let configuredProductIDs = Set(productIDs)

        return AsyncStream { continuation in
            let listenerTask = Task(priority: .background) {
                for await result in Transaction.updates {
                    guard !Task.isCancelled else { break }

                    switch result {
                    case .verified(let transaction):
                        guard configuredProductIDs.contains(transaction.productID) else { continue }
                        continuation.yield(SubscriptionTransactionUpdate(
                            verification: .verified,
                            productID: transaction.productID,
                            finishAction: {
                                await transaction.finish()
                            }
                        ))
                    case .unverified(let transaction, _):
                        guard configuredProductIDs.contains(transaction.productID) else { continue }
                        continuation.yield(SubscriptionTransactionUpdate(
                            verification: .unverified,
                            productID: transaction.productID
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
#endif

private struct SubscriptionStoreDiagnosticsContext: Sendable {
    var implementation: String
    var buildConfiguration: String
    var scheme: String
    var mockStoreActive: Bool
    var requestedProductIDs: [String]
    var recommendedProductID: String?

    static func storeKit2(requestedProductIDs: [String], recommendedProductID: String?) -> Self {
        SubscriptionStoreDiagnosticsContext(
            implementation: "storekit2",
            buildConfiguration: currentBuildConfiguration,
            scheme: "not_detectable",
            mockStoreActive: false,
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
            "subscription_store event=products_request_started implementation=\(context.implementation, privacy: .public) build_configuration=\(context.buildConfiguration, privacy: .public) scheme=\(context.scheme, privacy: .public) mock_store_active=\(context.mockStoreActive, privacy: .public) requested_product_count=\(context.requestedProductIDs.count, privacy: .public) requested_product_ids=\(context.requestedProductIDs.diagnosticsList, privacy: .public) recommended_product_configured=\((context.recommendedProductID != nil), privacy: .public)"
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
