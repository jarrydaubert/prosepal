import XCTest
import ProsePalAPI
import ProsePalDomain
@testable import ProsePalUI

@MainActor
final class NativeRuntimeReadinessTests: XCTestCase {
    func testSettingsItemsShowMissingStagingConfigurationWithoutSecretValues() {
        let readiness = NativeRuntimeReadiness.unconfigured

        let items = readiness.settingsItems

        XCTAssertEqual(items.map(\.id), ["private-draft", "sensitive-writing", "dev-guard", "account", "subscriptions"])
        XCTAssertTrue(items.allSatisfy { !$0.isReady })
        XCTAssertEqual(items.first { $0.id == "private-draft" }?.statusText, "Unavailable")
        XCTAssertTrue(items.filter { $0.id != "private-draft" }.allSatisfy { $0.statusText == "Missing" })
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
        XCTAssertEqual(items.first { $0.id == "private-draft" }?.statusText, "Device dependent")
        XCTAssertTrue(items.filter { $0.id != "private-draft" }.allSatisfy { $0.statusText == "Ready" })
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
            "runtime_readiness generation_configured=true private_draft_configured=true careful_gateway_configured=true dev_secret_configured=true account_configured=false subscription_configured=true premium_product_count=1 recommended_plan_configured=false relationship_vault_persistent=true"
        )
        XCTAssertFalse(payload.contains("http"))
        XCTAssertFalse(payload.contains("secret="))
        XCTAssertFalse(payload.contains("product_id="))
    }

    func testDiagnosticsPayloadSummarisesTemporaryVaultWithoutStoreDetails() {
        let readiness = NativeRuntimeReadiness(isRelationshipVaultPersistent: false)

        let payload = readiness.diagnosticsPayload

        XCTAssertTrue(payload.contains("relationship_vault_persistent=false"))
        XCTAssertFalse(payload.contains("/"))
        XCTAssertFalse(payload.contains("RelationshipVault.store"))
    }

    func testPrivateDraftAndSensitiveWritingReadinessAreSeparate() {
        let readiness = NativeRuntimeReadiness(
            isPrivateDraftConfigured: true,
            isCarefulGatewayConfigured: false
        )

        XCTAssertTrue(readiness.isGenerationConfigured)
        XCTAssertTrue(readiness.isPrivateDraftConfigured)
        XCTAssertFalse(readiness.isCarefulGatewayConfigured)
        XCTAssertEqual(readiness.settingsItems.first { $0.id == "private-draft" }?.statusText, "Device dependent")
        XCTAssertEqual(readiness.settingsItems.first { $0.id == "sensitive-writing" }?.statusText, "Missing")
    }

    func testMomentAccountModelStoresRuntimeReadinessForSettings() {
        let readiness = NativeRuntimeReadiness(isGenerationConfigured: true)
        let model = MomentAccountModel(
            clientContext: ClientContext(appVersion: "0.0.0", buildNumber: "1"),
            runtimeReadiness: readiness
        )

        XCTAssertEqual(model.runtimeReadiness, readiness)
        XCTAssertEqual(model.runtimeReadiness.settingsItems.first?.statusText, "Device dependent")
    }
}
