import XCTest
import ProsePalDomain
@testable import ProsePalAPI

final class MessageWritingClientTests: XCTestCase {
    func testMockClientReturnsProvidedGatewayResponse() async throws {
        let response = CardResponse(
            messages: [GeneratedMessage(id: "draft-1", text: "A gateway-shaped draft.")],
            laneUsed: .standard,
            fallbackStatus: .none,
            retryEligibility: .ineligible
        )
        let client = MockMessageWritingClient(response: response)
        let request = CardRequest(
            intent: CardIntent(
                occasion: .birthday,
                relationship: .parent,
                tone: .heartfelt
            ),
            clientContext: ClientContext(appVersion: "0.0.0", buildNumber: "1")
        )

        let generated = try await client.generateCard(request: request)

        XCTAssertEqual(generated, response)
    }
}
