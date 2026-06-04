import XCTest
import ProsePalAPI
import ProsePalDomain
@testable import ProsePalUI

@MainActor
final class UsagePolicyTests: XCTestCase {
    func testPremiumSelectionShowsPaywallWithoutChangingLane() {
        let model = makeModel()

        XCTAssertEqual(model.draft.requestedLane, .standard)
        model.selectLane(.premium)

        XCTAssertTrue(model.isShowingPaywall)
        XCTAssertEqual(model.draft.requestedLane, .standard)

        model.useStandardLaneFromPaywall()

        XCTAssertFalse(model.isShowingPaywall)
        XCTAssertEqual(model.draft.requestedLane, .standard)
    }

    func testStandardGenerationConsumesDisplayedAllowance() async {
        let model = makeModel(
            usageStatus: UsageStatus(standardLimit: 3, standardRemaining: 2),
            client: MockMessageWritingClient(response: sampleResponse())
        )
        model.draft.requestedLane = .standard

        await model.generate()

        XCTAssertTrue(model.isShowingResults)
        XCTAssertEqual(model.generatedMessages.count, 1)
        XCTAssertEqual(model.usageStatus.standardRemaining, 1)
    }

    func testStandardLimitBlocksGenerationAndShowsPaywall() async {
        let model = makeModel(
            usageStatus: UsageStatus(standardLimit: 3, standardRemaining: 0),
            client: MockMessageWritingClient(response: sampleResponse())
        )
        model.draft.requestedLane = .standard

        await model.generate()

        XCTAssertTrue(model.isShowingPaywall)
        XCTAssertFalse(model.isShowingResults)
        XCTAssertTrue(model.generatedMessages.isEmpty)
        XCTAssertEqual(model.errorMessage, "You've used your Standard drafts for today.")
    }

    func testFailedGenerationDoesNotConsumeDisplayedAllowance() async {
        let model = makeModel(
            usageStatus: UsageStatus(standardLimit: 3, standardRemaining: 1),
            client: FailingMessageWritingClient(error: .timedOut)
        )
        model.draft.requestedLane = .standard

        await model.generate()

        XCTAssertFalse(model.isShowingResults)
        XCTAssertEqual(model.usageStatus.standardRemaining, 1)
        XCTAssertEqual(model.errorMessage, "This is taking longer than expected. Please try again.")
    }

    private func makeModel(
        usageStatus: UsageStatus = UsageStatus(),
        client: MessageWritingClient? = nil
    ) -> ProsePalAppModel {
        ProsePalAppModel(
            client: client ?? MockMessageWritingClient(response: sampleResponse()),
            clientContext: ClientContext(appVersion: "0.0.0", buildNumber: "1"),
            usageStatus: usageStatus
        )
    }

    private func sampleResponse() -> CardResponse {
        CardResponse(
            messages: [GeneratedMessage(id: "draft-1", text: "A thoughtful draft.")],
            laneUsed: .standard,
            fallbackStatus: .none,
            retryEligibility: .ineligible
        )
    }
}

private struct FailingMessageWritingClient: MessageWritingClient {
    let error: GenerationError

    func generateCard(request: CardRequest) async throws -> CardResponse {
        throw error
    }
}
