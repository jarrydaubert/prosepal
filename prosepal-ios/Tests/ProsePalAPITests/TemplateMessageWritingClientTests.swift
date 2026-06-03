import XCTest
import ProsePalDomain
@testable import ProsePalAPI

final class TemplateMessageWritingClientTests: XCTestCase {
    func testTemplateClientReturnsDegradedTemplateResponse() async throws {
        let client = TemplateMessageWritingClient()
        let request = CardRequest(
            intent: CardIntent(
                occasion: .birthday,
                relationship: .parent,
                tone: .warm,
                recipientName: "Dad"
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
    }
}
