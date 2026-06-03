import XCTest
import ProsePalDomain
@testable import ProsePalAPI

final class TemplateMessageWritingClientTests: XCTestCase {
    func testTemplateClientReturnsDegradedTemplateResponse() async throws {
        let client = TemplateMessageWritingClient()
        let request = CardRequest(
            intent: CardIntent(
                occasion: .diwali,
                relationship: .teacher,
                tone: .poetic,
                length: .detailed,
                spellingPreference: .uk,
                recipientName: "Dad",
                thingsToInclude: ["festival lights"],
                thingsToAvoid: ["cliches"],
                userContext: "Keep it grateful."
            ),
            requestedLane: .premium,
            clientContext: ClientContext(appVersion: "2.0.0", buildNumber: "100")
        )

        let response = try await client.generateCard(request: request)

        XCTAssertEqual(response.laneUsed, .template)
        XCTAssertEqual(response.fallbackStatus, .degradedToTemplate)
        XCTAssertEqual(response.retryEligibility, .eligible)
        XCTAssertEqual(response.messages.count, 3)
        XCTAssertTrue(response.messages[0].text.contains("Dad"))
        XCTAssertTrue(response.messages[0].text.contains("Diwali"))
        XCTAssertTrue(response.messages[0].text.contains("teacher"))
        XCTAssertTrue(response.messages[0].text.contains("poetic"))
        XCTAssertTrue(response.messages[0].text.contains("UK English"))
    }
}
