import XCTest
@testable import ProsePalDomain

final class CardContractTests: XCTestCase {
    func testDomainTextPolicyNormalizesAndCapsEveryGenerationIngress() {
        let longName = "  Alex\nMorgan  " + String(repeating: "x", count: 100)
        let longDetail = "  " + String(repeating: "🙂", count: ProsePalTextLimit.momentDetail + 20) + "  "
        let moment = MomentInput(
            personName: longName,
            relationship: .closeFriend,
            occasion: .birthday,
            trueThing: longDetail
        )
        let intent = CardIntent(
            occasion: .birthday,
            relationship: .closeFriend,
            tone: .heartfelt,
            recipientName: longName,
            thingsToInclude: [longDetail, "   "],
            thingsToAvoid: [longDetail],
            userContext: String(repeating: "c", count: ProsePalTextLimit.gatewayUserContext + 20)
        )

        XCTAssertEqual(moment.personName.count, ProsePalTextLimit.personName)
        XCTAssertTrue(moment.personName.hasPrefix("Alex Morgan"))
        XCTAssertEqual(moment.trueThing.count, ProsePalTextLimit.momentDetail)
        XCTAssertEqual(intent.recipientName?.count, ProsePalTextLimit.personName)
        XCTAssertEqual(intent.thingsToInclude.count, 1)
        XCTAssertEqual(intent.thingsToInclude[0].count, ProsePalTextLimit.momentDetail)
        XCTAssertEqual(intent.thingsToAvoid[0].count, ProsePalTextLimit.momentDetail)
        XCTAssertEqual(intent.userContext?.count, ProsePalTextLimit.gatewayUserContext)
    }

    func testMomentDetailLimitCountsExtendedGraphemeClusters() {
        let ordinary = String(repeating: "a", count: ProsePalTextLimit.momentDetail)
        let emoji = String(repeating: "🙂", count: ProsePalTextLimit.momentDetail)
        let composed = String(repeating: "e\u{301}", count: ProsePalTextLimit.momentDetail)
        let zwjNearBoundary = String(
            repeating: "z",
            count: ProsePalTextLimit.momentDetail - 2
        ) + "👩‍💻Q"
        let afterOldUTF16Cutoff = String(repeating: "🙂", count: 600) +
            "CONTENT_AFTER_OLD_UTF16_CUTOFF"

        for value in [ordinary, emoji, composed, zwjNearBoundary, afterOldUTF16Cutoff] {
            XCTAssertLessThanOrEqual(value.count, ProsePalTextLimit.momentDetail)
            XCTAssertEqual(ProsePalTextInput.momentDetail(value), value)
        }
        XCTAssertGreaterThan(afterOldUTF16Cutoff.utf16.count, ProsePalTextLimit.momentDetail)
    }

    func testAcceptedInputPreservesOrdinaryInstructionLookingLanguage() {
        let phrases = [
            "you are now part of our family",
            "disregard the past",
            "pretend to be brave",
            "act as if we never left",
            "ignore previous instructions"
        ]
        let context = phrases.joined(separator: "\n")
        let intent = CardIntent(
            occasion: .birthday,
            relationship: .closeFriend,
            tone: .heartfelt,
            thingsToInclude: phrases,
            thingsToAvoid: ["disregard the past"],
            userContext: " \n\(context)\n "
        )

        XCTAssertEqual(intent.thingsToInclude, phrases)
        XCTAssertEqual(intent.thingsToAvoid, ["disregard the past"])
        XCTAssertEqual(intent.userContext, context)
        XCTAssertEqual(ProsePalTextInput.momentDetail(context), context)
        XCTAssertEqual(ProsePalTextInput.draft(context), context)
    }

    func testGeneratedDraftValidatorRejectsInsteadOfTruncating() {
        let exactOrdinary = String(repeating: "a", count: ProsePalTextLimit.draft)
        let overOrdinary = exactOrdinary + "b"
        let exactZWJ = String(repeating: "👩‍💻", count: ProsePalTextLimit.draft - 1) + "A"
        let overZWJ = exactZWJ + "B"

        XCTAssertEqual(exactOrdinary.count, ProsePalTextLimit.draft)
        XCTAssertEqual(exactZWJ.count, ProsePalTextLimit.draft)
        XCTAssertEqual(ProsePalTextInput.generatedDraft(" \n\(exactOrdinary)\t "), exactOrdinary)
        XCTAssertEqual(ProsePalTextInput.generatedDraft(exactZWJ), exactZWJ)
        XCTAssertNil(ProsePalTextInput.generatedDraft(overOrdinary))
        XCTAssertNil(ProsePalTextInput.generatedDraft(overZWJ))
        XCTAssertNil(ProsePalTextInput.generatedDraft("A" + String(repeating: " ", count: 4_000) + "B"))
        XCTAssertNil(ProsePalTextInput.generatedDraft(" \n\t "))
        XCTAssertNil(ProsePalTextInput.generatedDraft("..."))
        XCTAssertNil(ProsePalTextInput.generatedDraft("!!!"))
        XCTAssertNil(ProsePalTextInput.generatedDraft("👩‍💻🙂"))
        XCTAssertEqual(ProsePalTextInput.generatedDraft("Ok."), "Ok.")
        XCTAssertEqual(ProsePalTextInput.generatedDraft("1"), "1")
    }

    func testCardRequestEncodesStableGatewayContractFields() throws {
        let request = CardRequest(
            idempotencyKey: "fixed-key",
            intent: CardIntent(
                occasion: .birthday,
                relationship: .parent,
                tone: .heartfelt,
                length: .brief,
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
        XCTAssertEqual(intent["spellingPreference"] as? String, "automatic")
        XCTAssertEqual(intent["localeIdentifier"] as? String, Locale.current.identifier)
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

    func testMomentInputBuildsGatewayIntentFromMomentFields() {
        let moment = MomentInput(
            personName: "  Dad  ",
            relationship: .parent,
            occasion: .birthday,
            register: .react,
            trueThing: "  He always makes Sunday tea.  ",
            tone: .heartfelt,
            length: .detailed
        )

        let intent = moment.cardIntent

        XCTAssertEqual(intent.occasion, .birthday)
        XCTAssertEqual(intent.relationship, .parent)
        XCTAssertEqual(intent.tone, .heartfelt)
        XCTAssertEqual(intent.length, .detailed)
        XCTAssertEqual(intent.spellingPreference, "automatic")
        XCTAssertEqual(intent.localeIdentifier, Locale.current.identifier)
        XCTAssertEqual(intent.recipientName, "Dad")
        XCTAssertEqual(intent.thingsToInclude, ["He always makes Sunday tea."])
        XCTAssertEqual(intent.thingsToAvoid, [])
        XCTAssertEqual(intent.userContext, "Everyday moments that need a quick, warm message.")
    }

    func testMomentInputOmitsBlankOptionalGatewayIntentFields() {
        let moment = MomentInput(
            personName: "   ",
            relationship: .colleague,
            occasion: .thankYou,
            register: .react,
            trueThing: "   ",
            tone: .formal,
            length: .brief
        )

        let intent = moment.cardIntent

        XCTAssertNil(intent.recipientName)
        XCTAssertEqual(intent.thingsToInclude, [])
        XCTAssertEqual(intent.thingsToAvoid, [])
        XCTAssertEqual(intent.userContext, "Everyday moments that need a quick, warm message.")
        XCTAssertEqual(intent.spellingPreference, "automatic")
        XCTAssertEqual(intent.localeIdentifier, Locale.current.identifier)
    }

    func testSensitiveMomentUsesCarefulRegisterCopyForGatewayIntent() {
        let moment = MomentInput(
            personName: "Alex",
            relationship: .closeFriend,
            occasion: .sympathy,
            register: .react,
            trueThing: "Their dad died yesterday."
        )

        XCTAssertEqual(moment.recommendedRegister, .assemble)
        XCTAssertTrue(moment.requiresCarefulLane)
        XCTAssertEqual(moment.cardIntent.userContext, "Harder moments where your words should lead.")
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
    }

    func testTaxonomyCarriesNativePickerMetadata() {
        XCTAssertEqual(Occasion.diwali.displayName, "Diwali")
        XCTAssertEqual(Occasion.diwali.group, .culturalHolidays)
        XCTAssertTrue(Occasion.diwali.searchText.localizedCaseInsensitiveContains("festival of lights"))
        XCTAssertEqual(Relationship.teacher.group, .professional)
        XCTAssertEqual(Tone.poetic.description, "Lyrical and elegant")
        XCTAssertEqual(MessageLength.detailed.generationHint, "5-7 sentences")
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

    func testLocalPressureCheckFindsReassuranceAsking() {
        let moment = MomentInput(
            personName: "Alex",
            relationship: .romantic,
            occasion: .thinkingOfYou,
            trueThing: "Please tell me you still love me."
        )

        let check = PressureCheck.local(
            messageText: "I miss you. Are we okay?",
            moment: moment
        )

        XCTAssertTrue(check.asksForReassurance)
        XCTAssertFalse(check.explainsBeforeApology)
        XCTAssertTrue(check.userVisibleNotes.contains("This asks them to reassure you. Consider making the message easier to receive."))
    }

    func testLocalPressureCheckFindsConditionalApology() {
        let moment = MomentInput(
            personName: "Mum",
            relationship: .parent,
            occasion: .apology,
            register: .confess
        )

        let check = PressureCheck.local(
            messageText: "I'm sorry if what I said upset you.",
            moment: moment
        )

        XCTAssertTrue(check.explainsBeforeApology)
        XCTAssertTrue(check.userVisibleNotes.contains("This apology may sound conditional. Lead with the apology before explaining."))
    }

    func testLocalPressureCheckFindsHeavyEverydayLanguage() {
        let moment = MomentInput(
            personName: "Sam",
            relationship: .closeFriend,
            occasion: .birthday,
            register: .react
        )

        let check = PressureCheck.local(
            messageText: "Happy birthday. You're all I have.",
            moment: moment
        )

        XCTAssertTrue(check.mayFeelTooHeavy)
        XCTAssertTrue(check.userVisibleNotes.contains("This may feel heavy for this moment. Consider making it lighter or more specific."))
    }

    func testMomentDraftBundleMergesLocalPressureCheckWithoutDroppingModelNotes() {
        let bundle = MomentDraftBundle(
            messageText: "I'm sorry but I was tired.",
            lane: .privateDraft,
            pressureCheck: PressureCheck(notes: ["Keep this short."])
        )
        let moment = MomentInput(
            personName: "Dad",
            relationship: .parent,
            occasion: .apology,
            register: .confess
        )

        let checked = bundle.applyingLocalPressureCheck(for: moment)

        XCTAssertTrue(checked.pressureCheck.explainsBeforeApology)
        XCTAssertTrue(checked.pressureCheck.userVisibleNotes.contains("Keep this short."))
        XCTAssertTrue(checked.pressureCheck.userVisibleNotes.contains("This apology may sound conditional. Lead with the apology before explaining."))
    }
}
