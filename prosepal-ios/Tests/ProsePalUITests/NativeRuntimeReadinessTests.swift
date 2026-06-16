import XCTest
import ProsePalAPI
import ProsePalDomain
@testable import ProsePalUI

@MainActor
final class NativeRuntimeReadinessTests: XCTestCase {
    func testSettingsItemsShowMissingStagingConfigurationWithoutSecretValues() {
        let readiness = NativeRuntimeReadiness.unconfigured

        let items = readiness.settingsItems

        XCTAssertEqual(items.map(\.id), ["private-draft", "take-more-care", "dev-guard", "account", "subscriptions"])
        XCTAssertTrue(items.allSatisfy { !$0.isReady })
        XCTAssertTrue(items.allSatisfy { $0.statusText == "Missing" })
        XCTAssertFalse(items.contains { item in
            item.detail.contains("https://") ||
            item.detail.localizedCaseInsensitiveContains("secret") && item.detail.contains("=")
        })
    }

    func testSettingsItemsSummariseReadyStagingConfigurationWithoutRawValues() {
        let readiness = NativeRuntimeReadiness(
            isGenerationConfigured: true,
            isDevGatewaySecretConfigured: true,
            isAccountConfigured: true,
            isSubscriptionConfigured: true,
            premiumProductCount: 2,
            isRecommendedPremiumProductConfigured: true
        )

        let items = readiness.settingsItems

        XCTAssertTrue(items.allSatisfy(\.isReady))
        XCTAssertTrue(items.allSatisfy { $0.statusText == "Ready" })
        XCTAssertEqual(items.first { $0.id == "subscriptions" }?.detail, "2 product IDs configured, recommended plan set")
        XCTAssertFalse(items.contains { item in
            item.detail.contains("prod_") ||
            item.detail.contains("sk_") ||
            item.detail.contains("Bearer")
        })
    }

    func testDiagnosticsPayloadUsesBooleansAndCountsOnly() {
        let readiness = NativeRuntimeReadiness(
            isGenerationConfigured: true,
            isDevGatewaySecretConfigured: true,
            isAccountConfigured: false,
            isSubscriptionConfigured: true,
            premiumProductCount: 1,
            isRecommendedPremiumProductConfigured: false
        )

        let payload = readiness.diagnosticsPayload

        XCTAssertEqual(
            payload,
            "runtime_readiness generation_configured=true private_draft_configured=true take_more_care_configured=true dev_secret_configured=true account_configured=false subscription_configured=true premium_product_count=1 recommended_plan_configured=false"
        )
        XCTAssertFalse(payload.contains("http"))
        XCTAssertFalse(payload.contains("secret="))
        XCTAssertFalse(payload.contains("product_id="))
    }

    func testPrivateDraftAndTakeMoreCareReadinessAreSeparate() {
        let readiness = NativeRuntimeReadiness(
            isPrivateDraftConfigured: true,
            isCarefulGatewayConfigured: false
        )

        XCTAssertTrue(readiness.isGenerationConfigured)
        XCTAssertTrue(readiness.isPrivateDraftConfigured)
        XCTAssertFalse(readiness.isCarefulGatewayConfigured)
        XCTAssertEqual(readiness.settingsItems.first { $0.id == "private-draft" }?.statusText, "Ready")
        XCTAssertEqual(readiness.settingsItems.first { $0.id == "take-more-care" }?.statusText, "Missing")
    }

    func testAppModelStoresRuntimeReadinessForSettings() {
        let readiness = NativeRuntimeReadiness(isGenerationConfigured: true)
        let model = ProsePalAppModel(
            client: MockMessageWritingClient(
                response: CardResponse(messages: [], laneUsed: .standard)
            ),
            clientContext: ClientContext(appVersion: "0.0.0", buildNumber: "1"),
            runtimeReadiness: readiness
        )

        XCTAssertEqual(model.runtimeReadiness, readiness)
        XCTAssertEqual(model.runtimeReadiness.settingsItems.first?.statusText, "Ready")
    }
}
