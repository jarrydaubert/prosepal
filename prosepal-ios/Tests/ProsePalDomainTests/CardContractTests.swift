import XCTest
@testable import ProsePalDomain

final class CardContractTests: XCTestCase {
    func testCardRequestEncodesStableGatewayContractFields() throws {
        let request = CardRequest(
            idempotencyKey: "fixed-key",
            intent: CardIntent(
                occasion: .birthday,
                relationship: .parent,
                tone: .heartfelt,
                length: .brief,
                spellingPreference: .uk,
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
        let intent = try XCTUnwrap(object["intent"] as? [String: Any])
        XCTAssertEqual(intent["occasion"] as? String, "birthday")
        XCTAssertEqual(intent["relationship"] as? String, "parent")
        XCTAssertEqual(intent["tone"] as? String, "heartfelt")
        XCTAssertEqual(intent["length"] as? String, "brief")
        XCTAssertEqual(intent["spellingPreference"] as? String, "uk")
        XCTAssertEqual(intent["localeIdentifier"] as? String, "en_GB")
        XCTAssertNil(object["model"])
        XCTAssertNil(object["provider"])
    }

    func testCardResponseCarriesLaneAndFallbackWithoutProviderDetails() throws {
        let response = CardResponse(
            messages: [GeneratedMessage(id: "1", text: "Happy birthday.")],
            laneUsed: .premium,
            fallbackStatus: .degradedToStandard,
            usage: UsageSummary(remaining: 4, limit: 10),
            retryEligibility: .eligible
        )

        let data = try JSONEncoder().encode(response)
        let object = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])

        XCTAssertEqual(object["laneUsed"] as? String, "premium")
        XCTAssertEqual(object["fallbackStatus"] as? String, "degradedToStandard")
        XCTAssertEqual(object["retryEligibility"] as? String, "eligible")
        let usage = try XCTUnwrap(object["usage"] as? [String: Any])
        XCTAssertEqual(usage["remaining"] as? Int, 4)
        XCTAssertEqual(usage["limit"] as? Int, 10)
        XCTAssertNil(object["model"])
        XCTAssertNil(object["provider"])
    }

    func testDomainTaxonomyMatchesFlutterProductCatalogueShape() {
        XCTAssertEqual(Occasion.allCases.count, 40)
        XCTAssertEqual(Array(Occasion.allCases.prefix(10)), [
            .birthday,
            .thankYou,
            .sympathy,
            .wedding,
            .christmas,
            .getWell,
            .congrats,
            .mothersDay,
            .fathersDay,
            .baby
        ])
        XCTAssertEqual(Array(Occasion.allCases.suffix(3)), [.petBirthday, .newPet, .petSympathy])

        XCTAssertEqual(Relationship.allCases.count, 14)
        XCTAssertEqual(Array(Relationship.allCases.prefix(4)), [.closeFriend, .family, .parent, .child])
        XCTAssertEqual(Array(Relationship.allCases.suffix(2)), [.neighbor, .acquaintance])

        XCTAssertEqual(Tone.allCases, [
            .heartfelt,
            .casual,
            .funny,
            .formal,
            .inspirational,
            .playful,
            .sarcastic,
            .nostalgic,
            .poetic
        ])

        XCTAssertEqual(MessageLength.allCases, [.brief, .standard, .detailed])
        XCTAssertEqual(SpellingPreference.allCases, [.automatic, .us, .uk])
    }

    func testTaxonomyCarriesNativePickerMetadata() {
        XCTAssertEqual(Occasion.diwali.displayName, "Diwali")
        XCTAssertEqual(Occasion.diwali.group, .culturalHolidays)
        XCTAssertTrue(Occasion.diwali.searchText.localizedCaseInsensitiveContains("festival of lights"))
        XCTAssertEqual(Relationship.teacher.group, .professional)
        XCTAssertEqual(Tone.poetic.description, "Lyrical and elegant")
        XCTAssertEqual(MessageLength.detailed.generationHint, "5-7 sentences")
        XCTAssertEqual(SpellingPreference.uk.localeIdentifier, "en_GB")
    }

    func testMomentSafetySignalBlocksCrisisDrafting() {
        let moment = MomentInput(
            personName: "Alex",
            relationship: .closeFriend,
            occasion: .thinkingOfYou,
            trueThing: "I want to kill myself tonight."
        )

        XCTAssertEqual(moment.safetySignal, .crisisSupport)
        XCTAssertFalse(moment.allowsDrafting)
    }

    func testMomentSafetySignalAllowsOrdinaryHardMoments() {
        let moment = MomentInput(
            personName: "Alex",
            relationship: .closeFriend,
            occasion: .apology,
            register: .confess,
            trueThing: "I explained before I apologised."
        )

        XCTAssertEqual(moment.safetySignal, .none)
        XCTAssertTrue(moment.allowsDrafting)
        XCTAssertTrue(moment.isCarefulMode)
    }
}
