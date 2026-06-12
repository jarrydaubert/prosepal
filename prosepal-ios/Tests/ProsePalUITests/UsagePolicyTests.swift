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

    func testStandardGenerationWithoutGatewayUsageDoesNotConsumeLocalPlaceholderAllowance() async {
        let model = makeModel(
            usageStatus: UsageStatus(standardLimit: 3, standardRemaining: 2),
            client: MockMessageWritingClient(response: sampleResponse())
        )
        model.draft.requestedLane = .standard

        await model.generate()

        XCTAssertTrue(model.isShowingResults)
        XCTAssertEqual(model.generatedMessages.count, 1)
        XCTAssertEqual(model.usageStatus.standardRemaining, 2)
        XCTAssertFalse(model.usageStatus.hasAuthoritativeUsage)
    }

    func testGatewayUsageSummaryOverridesLocalDisplayedAllowance() async {
        let model = makeModel(
            usageStatus: UsageStatus(standardLimit: 3, standardRemaining: 2),
            client: MockMessageWritingClient(
                response: sampleResponse(
                    usage: UsageSummary(remaining: 7, limit: 10)
                )
            )
        )
        model.draft.requestedLane = .standard

        await model.generate()

        XCTAssertTrue(model.isShowingResults)
        XCTAssertEqual(model.usageStatus.standardRemaining, 7)
        XCTAssertEqual(model.usageStatus.standardLimit, 10)
        XCTAssertTrue(model.usageStatus.hasAuthoritativeUsage)
    }

    func testGenerateSendsCurrentDraftAsStructuredGatewayRequest() async throws {
        let client = RecordingMessageWritingClient(response: sampleResponse())
        let model = makeModel(client: client)
        model.draft.occasion = .apology
        model.draft.relationship = .closeFriend
        model.draft.tone = .heartfelt
        model.draft.length = .detailed
        model.draft.spellingPreference = .uk
        model.draft.recipientName = "Alex"
        model.draft.thingsToInclude = "I was late, I should have called"
        model.draft.thingsToAvoid = "making excuses"
        model.draft.personalContext = "We missed dinner plans."

        await model.generate()

        let requests = await client.recordedRequests()
        let request = try XCTUnwrap(requests.first)
        XCTAssertEqual(request.requestedLane, .standard)
        XCTAssertEqual(request.clientContext.platform, "ios")
        XCTAssertEqual(request.intent.occasion, .apology)
        XCTAssertEqual(request.intent.relationship, .closeFriend)
        XCTAssertEqual(request.intent.tone, .heartfelt)
        XCTAssertEqual(request.intent.length, .detailed)
        XCTAssertEqual(request.intent.spellingPreference, .uk)
        XCTAssertEqual(request.intent.localeIdentifier, "en_GB")
        XCTAssertEqual(request.intent.recipientName, "Alex")
        XCTAssertEqual(request.intent.thingsToInclude, ["I was late", "I should have called"])
        XCTAssertEqual(request.intent.thingsToAvoid, ["making excuses"])
        XCTAssertEqual(request.intent.userContext, "We missed dinner plans.")
    }

    func testRegenerateReusesSameDraftInputsWithFreshRequestID() async {
        let client = RecordingMessageWritingClient(response: sampleResponse())
        let model = makeModel(client: client)
        model.draft.occasion = .christmas
        model.draft.relationship = .family
        model.draft.tone = .casual
        model.draft.recipientName = "Nan"

        await model.generate()
        await model.generate()

        let requests = await client.recordedRequests()
        XCTAssertEqual(requests.count, 2)
        XCTAssertEqual(requests[0].intent, requests[1].intent)
        XCTAssertEqual(requests[0].requestedLane, requests[1].requestedLane)
        XCTAssertNotEqual(requests[0].idempotencyKey, requests[1].idempotencyKey)
        XCTAssertTrue(model.isShowingResults)
    }

    func testGatewayUsageSummaryClampsRemainingToServerLimit() {
        var usageStatus = UsageStatus(standardLimit: 3, standardRemaining: 1)

        usageStatus.applyGatewayUsageSummary(UsageSummary(remaining: 14, limit: 8))

        XCTAssertEqual(usageStatus.standardRemaining, 8)
        XCTAssertEqual(usageStatus.standardLimit, 8)
        XCTAssertTrue(usageStatus.hasAuthoritativeUsage)
    }

    func testGatewayUsageSummaryClampsExistingRemainingWhenOnlyLimitChanges() {
        var usageStatus = UsageStatus(standardLimit: 10, standardRemaining: 9)

        usageStatus.applyGatewayUsageSummary(UsageSummary(limit: 4))

        XCTAssertEqual(usageStatus.standardRemaining, 4)
        XCTAssertEqual(usageStatus.standardLimit, 4)
    }

    func testAuthoritativeStandardLimitBlocksGenerationAndShowsPaywall() async {
        let model = makeModel(
            usageStatus: UsageStatus(
                standardLimit: 3,
                standardRemaining: 0,
                hasAuthoritativeUsage: true
            ),
            client: MockMessageWritingClient(response: sampleResponse())
        )
        model.draft.requestedLane = .standard

        await model.generate()

        XCTAssertTrue(model.isShowingPaywall)
        XCTAssertFalse(model.isShowingResults)
        XCTAssertTrue(model.generatedMessages.isEmpty)
        XCTAssertEqual(model.errorMessage, "You've used your Standard drafts for today.")
    }

    func testPlaceholderStandardLimitDoesNotBlockGatewayGeneration() async {
        let model = makeModel(
            usageStatus: UsageStatus(standardLimit: 3, standardRemaining: 0),
            client: MockMessageWritingClient(response: sampleResponse())
        )
        model.draft.requestedLane = .standard

        await model.generate()

        XCTAssertFalse(model.isShowingPaywall)
        XCTAssertTrue(model.isShowingResults)
        XCTAssertEqual(model.generatedMessages.count, 1)
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

    func testAdjustCurrentMessageReturnsToComposeWithoutDroppingDraft() {
        let model = makeModel()
        model.draft.occasion = .christmas
        model.draft.recipientName = "Sam"
        model.generatedMessages = [GeneratedMessage(id: "draft-1", text: "A thoughtful draft.")]
        model.isShowingResults = true

        model.adjustCurrentMessage()

        XCTAssertFalse(model.isShowingResults)
        XCTAssertEqual(model.draft.occasion, .christmas)
        XCTAssertEqual(model.draft.recipientName, "Sam")
        XCTAssertEqual(model.generatedMessages.count, 1)
    }

    func testStartNewMessageResetsDraftResultsAndErrors() {
        let model = makeModel()
        model.draft.occasion = .christmas
        model.draft.relationship = .colleague
        model.draft.recipientName = "Sam"
        model.generatedMessages = [GeneratedMessage(id: "draft-1", text: "A thoughtful draft.")]
        model.errorMessage = "Try again."
        model.fallbackStatus = .degradedToStandard
        model.laneUsed = .standard
        model.isShowingResults = true

        model.startNewMessage()

        XCTAssertFalse(model.isShowingResults)
        XCTAssertTrue(model.generatedMessages.isEmpty)
        XCTAssertNil(model.errorMessage)
        XCTAssertEqual(model.fallbackStatus, .none)
        XCTAssertNil(model.laneUsed)
        XCTAssertEqual(model.draft, MessageDraft())
        XCTAssertEqual(model.selectedTab, .compose)
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

    private func sampleResponse(usage: UsageSummary? = nil) -> CardResponse {
        CardResponse(
            messages: [GeneratedMessage(id: "draft-1", text: "A thoughtful draft.")],
            laneUsed: .standard,
            fallbackStatus: .none,
            usage: usage,
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

private actor RecordingMessageWritingClient: MessageWritingClient {
    let response: CardResponse
    private var capturedRequests: [CardRequest] = []

    init(response: CardResponse) {
        self.response = response
    }

    func recordedRequests() -> [CardRequest] {
        capturedRequests
    }

    func generateCard(request: CardRequest) async throws -> CardResponse {
        capturedRequests.append(request)
        return response
    }
}
