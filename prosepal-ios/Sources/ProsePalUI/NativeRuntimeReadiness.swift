import Foundation

public struct NativeRuntimeReadiness: Equatable, Sendable {
    public var isGenerationConfigured: Bool
    public var isPrivateDraftConfigured: Bool
    public var isCarefulGatewayConfigured: Bool
    public var isDevGatewaySecretConfigured: Bool
    public var isAccountConfigured: Bool
    public var isSubscriptionConfigured: Bool
    public var premiumProductCount: Int
    public var isRecommendedPremiumProductConfigured: Bool

    public init(
        isGenerationConfigured: Bool = false,
        isPrivateDraftConfigured: Bool? = nil,
        isCarefulGatewayConfigured: Bool? = nil,
        isDevGatewaySecretConfigured: Bool = false,
        isAccountConfigured: Bool = false,
        isSubscriptionConfigured: Bool = false,
        premiumProductCount: Int = 0,
        isRecommendedPremiumProductConfigured: Bool = false
    ) {
        let privateDraftConfigured = isPrivateDraftConfigured ?? isGenerationConfigured
        let carefulGatewayConfigured = isCarefulGatewayConfigured ?? isGenerationConfigured
        self.isPrivateDraftConfigured = privateDraftConfigured
        self.isCarefulGatewayConfigured = carefulGatewayConfigured
        self.isGenerationConfigured = privateDraftConfigured || carefulGatewayConfigured
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
                id: "private-draft",
                title: "Private Draft",
                detail: isPrivateDraftConfigured ? "Private draft can run when the device runtime is available" : "Private draft depends on device runtime support",
                statusText: isPrivateDraftConfigured ? "Device dependent" : "Unavailable",
                systemImage: "sparkles",
                isReady: isPrivateDraftConfigured
            ),
            NativeRuntimeReadinessItem(
                id: "take-more-care",
                title: "Take More Care",
                detail: isCarefulGatewayConfigured ? "Gateway URL configured" : "Add PROSEPAL_GATEWAY_URL to this scheme",
                statusText: isCarefulGatewayConfigured ? "Ready" : "Missing",
                systemImage: "heart.text.square",
                isReady: isCarefulGatewayConfigured
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
        "runtime_readiness generation_configured=\(isGenerationConfigured) private_draft_configured=\(isPrivateDraftConfigured) take_more_care_configured=\(isCarefulGatewayConfigured) dev_secret_configured=\(isDevGatewaySecretConfigured) account_configured=\(isAccountConfigured) subscription_configured=\(isSubscriptionConfigured) premium_product_count=\(premiumProductCount) recommended_plan_configured=\(isRecommendedPremiumProductConfigured)"
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
