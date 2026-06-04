import XCTest
import ProsePalAPI
import ProsePalDomain
@testable import ProsePalUI

@MainActor
final class LaunchStateTests: XCTestCase {
    func testFirstLaunchStartsInOnboardingAndPersistsCompletion() throws {
        let harness = try makeHarness()
        defer { harness.cleanup() }

        let firstLaunch = harness.makeModel()
        XCTAssertFalse(firstLaunch.hasCompletedOnboarding)

        firstLaunch.completeOnboarding()
        XCTAssertTrue(firstLaunch.hasCompletedOnboarding)

        let returningLaunch = harness.makeModel()
        XCTAssertTrue(returningLaunch.hasCompletedOnboarding)
    }

    private func makeHarness() throws -> LaunchStateHarness {
        let suiteName = "prosepal.launch.tests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defaults.removePersistentDomain(forName: suiteName)
        return LaunchStateHarness(suiteName: suiteName, defaults: defaults)
    }
}

@MainActor
private struct LaunchStateHarness {
    let suiteName: String
    let defaults: UserDefaults
    let onboardingKey = "onboarding-complete"

    func makeModel() -> ProsePalAppModel {
        ProsePalAppModel(
            client: MockMessageWritingClient(
                response: CardResponse(messages: [], laneUsed: .standard)
            ),
            clientContext: ClientContext(appVersion: "0.0.0", buildNumber: "1"),
            onboardingStore: defaults,
            onboardingCompletionKey: onboardingKey
        )
    }

    func cleanup() {
        defaults.removePersistentDomain(forName: suiteName)
    }
}
