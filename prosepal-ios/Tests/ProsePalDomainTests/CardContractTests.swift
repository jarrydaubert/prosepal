import XCTest
@testable import ProsePalDomain

final class CardContractTests: XCTestCase {
    func testCardRequestEncodesStableGatewayContractFields() throws {
        let request = CardRequest(
            idempotencyKey: "fixed-key",
            intent: CardIntent(
                occasion: .birthday,
                relationship: .parent,
                tone: .warm,
                length: .short,
                localeIdentifier: "en_GB",
                recipientName: "Dad",
                thingsToInclude: ["a quiet cup of tea"],
                thingsToAvoid: ["provider names"],
                userContext: "Keep it sincere."
            ),
            requestedLane: .standard,
            clientContext: ClientContext(appVersion: "2.0.0", buildNumber: "100")
        )

        let data = try JSONEncoder().encode(request)
        let object = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])

        XCTAssertEqual(object["idempotencyKey"] as? String, "fixed-key")
        XCTAssertEqual(object["requestedLane"] as? String, "standard")
        XCTAssertEqual(object["promptContractVersion"] as? Int, 1)
        XCTAssertEqual(object["outputContractVersion"] as? Int, 1)
        XCTAssertNil(object["model"])
        XCTAssertNil(object["provider"])
    }

    func testCardResponseCarriesLaneAndFallbackWithoutProviderDetails() throws {
        let response = CardResponse(
            messages: [GeneratedMessage(id: "1", text: "Happy birthday.")],
            laneUsed: .premium,
            fallbackStatus: .degradedToStandard,
            retryEligibility: .eligible
        )

        let data = try JSONEncoder().encode(response)
        let object = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])

        XCTAssertEqual(object["laneUsed"] as? String, "premium")
        XCTAssertEqual(object["fallbackStatus"] as? String, "degradedToStandard")
        XCTAssertEqual(object["retryEligibility"] as? String, "eligible")
        XCTAssertNil(object["model"])
        XCTAssertNil(object["provider"])
    }
}

