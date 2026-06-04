import XCTest
import ProsePalAPI
import ProsePalDomain
@testable import ProsePalUI

@MainActor
final class SettingsParityStateTests: XCTestCase {
    func testAppleSignInPlaceholderDoesNotFakeSignedInState() {
        let model = makeModel()

        model.continueWithApplePlaceholder(source: "settings")

        XCTAssertFalse(model.isSignedIn)
        XCTAssertNotNil(model.notice)
    }

    func testPremiumPurchasePlaceholderDoesNotUnlockPremium() {
        let model = makeModel()

        model.purchasePremiumPlaceholder(source: "paywall")

        XCTAssertFalse(model.usageStatus.isPremiumUnlocked)
        XCTAssertEqual(model.draft.requestedLane, .standard)
        XCTAssertNotNil(model.notice)
    }

    func testPrivacyTogglesUpdateLocalPreferences() {
        let model = makeModel()

        model.setAnalyticsEnabled(true)
        model.setCrashReportsEnabled(true)

        XCTAssertTrue(model.analyticsEnabled)
        XCTAssertTrue(model.crashReportsEnabled)

        model.setAnalyticsEnabled(false)
        model.setCrashReportsEnabled(false)

        XCTAssertFalse(model.analyticsEnabled)
        XCTAssertFalse(model.crashReportsEnabled)
    }

    func testBiometricLockRequiresSignedInAccount() {
        let model = makeModel()

        model.setBiometricLockEnabled(true)

        XCTAssertFalse(model.biometricLockEnabled)

        model.isSignedIn = true
        model.setBiometricLockEnabled(true)

        XCTAssertTrue(model.biometricLockEnabled)
    }

    func testSuccessfulGenerationUpdatesDisplayedStats() async {
        let model = makeModel(
            client: MockMessageWritingClient(
                response: CardResponse(
                    messages: [
                        GeneratedMessage(id: "draft-1", text: "A thoughtful draft."),
                        GeneratedMessage(id: "draft-2", text: "Another thoughtful draft.")
                    ],
                    laneUsed: .standard,
                    fallbackStatus: .none
                )
            )
        )

        await model.generate()

        XCTAssertEqual(model.totalGeneratedCount, 2)
    }

    private func makeModel(client: MessageWritingClient? = nil) -> ProsePalAppModel {
        ProsePalAppModel(
            client: client ?? MockMessageWritingClient(
                response: CardResponse(messages: [], laneUsed: .standard)
            ),
            clientContext: ClientContext(appVersion: "0.0.0", buildNumber: "1")
        )
    }
}
