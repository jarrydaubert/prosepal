import Foundation

public struct NativeRuntimeReadiness: Equatable, Sendable {
    public var isGenerationConfigured: Bool
    public var isDevGatewaySecretConfigured: Bool
    public var isAccountConfigured: Bool
    public var isSubscriptionConfigured: Bool
    public var premiumProductCount: Int
    public var isRecommendedPremiumProductConfigured: Bool

    public init(
        isGenerationConfigured: Bool = false,
        isDevGatewaySecretConfigured: Bool = false,
        isAccountConfigured: Bool = false,
        isSubscriptionConfigured: Bool = false,
        premiumProductCount: Int = 0,
        isRecommendedPremiumProductConfigured: Bool = false
    ) {
        self.isGenerationConfigured = isGenerationConfigured
        self.isDevGatewaySecretConfigured = isDevGatewaySecretConfigured
        self.isAccountConfigured = isAccountConfigured
        self.isSubscriptionConfigured = isSubscriptionConfigured
        self.premiumProductCount = max(0, premiumProductCount)
        self.isRecommendedPremiumProductConfigured = isRecommendedPremiumProductConfigured
    }

    public static let unconfigured = NativeRuntimeReadiness()

    var settingsItems: [NativeRuntimeReadinessItem] {
        [
            NativeRuntimeReadinessItem(
                id: "generation",
                title: "Generation",
                detail: isGenerationConfigured ? "Gateway URL configured" : "Add PROSEPAL_GATEWAY_URL to this scheme",
                statusText: isGenerationConfigured ? "Ready" : "Missing",
                systemImage: "sparkles",
                isReady: isGenerationConfigured
            ),
            NativeRuntimeReadinessItem(
                id: "dev-guard",
                title: "Staging Guard",
                detail: isDevGatewaySecretConfigured ? "Local guard header will be sent" : "Add PROSEPAL_DEV_GATEWAY_SECRET to the local scheme",
                statusText: isDevGatewaySecretConfigured ? "Ready" : "Missing",
                systemImage: "lock.shield",
                isReady: isDevGatewaySecretConfigured
            ),
            NativeRuntimeReadinessItem(
                id: "account",
                title: "Apple Sign-In",
                detail: isAccountConfigured ? "Account backend configured" : "Add Supabase URL and anon key to this scheme",
                statusText: isAccountConfigured ? "Ready" : "Missing",
                systemImage: "apple.logo",
                isReady: isAccountConfigured
            ),
            NativeRuntimeReadinessItem(
                id: "subscriptions",
                title: "Purchases",
                detail: subscriptionDetail,
                statusText: isSubscriptionConfigured ? "Ready" : "Missing",
                systemImage: "star",
                isReady: isSubscriptionConfigured
            )
        ]
    }

    var diagnosticsPayload: String {
        "runtime_readiness generation_configured=\(isGenerationConfigured) dev_secret_configured=\(isDevGatewaySecretConfigured) account_configured=\(isAccountConfigured) subscription_configured=\(isSubscriptionConfigured) premium_product_count=\(premiumProductCount) recommended_plan_configured=\(isRecommendedPremiumProductConfigured)"
    }

    private var subscriptionDetail: String {
        guard isSubscriptionConfigured else {
            return "Add premium product IDs to this scheme"
        }

        let productText = premiumProductCount == 1 ? "1 product ID configured" : "\(premiumProductCount) product IDs configured"
        if isRecommendedPremiumProductConfigured {
            return "\(productText), recommended plan set"
        }
        return productText
    }
}

struct NativeRuntimeReadinessItem: Identifiable, Equatable, Sendable {
    var id: String
    var title: String
    var detail: String
    var statusText: String
    var systemImage: String
    var isReady: Bool
}
