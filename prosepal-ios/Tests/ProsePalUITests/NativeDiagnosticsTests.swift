import XCTest
import ProsePalDomain
@testable import ProsePalUI

final class NativeDiagnosticsTests: XCTestCase {
    func testGenerationStartedPayloadDoesNotIncludeRawUserContent() {
        var draft = MessageDraft()
        draft.occasion = .apology
        draft.relationship = .closeFriend
        draft.tone = .heartfelt
        draft.length = .detailed
        draft.spellingPreference = .uk
        draft.recipientName = "Private Recipient"
        draft.thingsToInclude = "secret include one, secret include two"
        draft.thingsToAvoid = "private avoid detail"
        draft.personalContext = "This is a sensitive personal situation."

        let payload = NativeDiagnosticsPayload.generationStarted(
            requestID: "1234567890abcdefghijklmnopqrstuvwxyz",
            draft: draft
        )

        XCTAssertTrue(payload.contains("request_id=1234567890ab..."))
        XCTAssertTrue(payload.contains("lane=standard"))
        XCTAssertTrue(payload.contains("occasion=apology"))
        XCTAssertTrue(payload.contains("relationship=closeFriend"))
        XCTAssertTrue(payload.contains("tone=heartfelt"))
        XCTAssertTrue(payload.contains("length=detailed"))
        XCTAssertTrue(payload.contains("spelling=uk"))
        XCTAssertTrue(payload.contains("recipient_present=true"))
        XCTAssertTrue(payload.contains("include_count=2"))
        XCTAssertTrue(payload.contains("avoid_count=1"))
        XCTAssertTrue(payload.contains("context_chars=39"))

        XCTAssertFalse(payload.contains("Private Recipient"))
        XCTAssertFalse(payload.contains("secret include"))
        XCTAssertFalse(payload.contains("private avoid"))
        XCTAssertFalse(payload.contains("sensitive personal situation"))
    }

    func testGenerationSucceededPayloadUsesCountsNotGeneratedText() {
        let payload = NativeDiagnosticsPayload.generationSucceeded(
            requestID: "request-id-with-sensitive-correlation",
            laneUsed: .standard,
            fallbackStatus: .none,
            messageCount: 3,
            totalMessageCharacters: 712,
            usageSource: "gateway",
            standardRemaining: 1,
            durationMs: 982
        )

        XCTAssertTrue(payload.contains("request_id=request-id-w..."))
        XCTAssertTrue(payload.contains("lane_used=standard"))
        XCTAssertTrue(payload.contains("fallback=none"))
        XCTAssertTrue(payload.contains("message_count=3"))
        XCTAssertTrue(payload.contains("total_message_chars=712"))
        XCTAssertTrue(payload.contains("usage_source=gateway"))
        XCTAssertTrue(payload.contains("standard_remaining=1"))
        XCTAssertTrue(payload.contains("duration_ms=982"))
        XCTAssertFalse(payload.contains("generated"))
    }

    func testMessageActionPayloadUsesCharacterCountOnly() {
        let payload = NativeDiagnosticsPayload.messageAction(
            action: "copy",
            source: "result_card",
            messageCharacters: 144
        )

        XCTAssertEqual(payload, "message_action action=copy source=result_card message_chars=144")
    }

    func testMomentDraftStartedPayloadDoesNotIncludeRawMomentContent() {
        let moment = MomentInput(
            personName: "Private Person",
            relationship: .romantic,
            occasion: .apology,
            register: .confess,
            trueThing: "I said something specific and sensitive.",
            tone: .heartfelt,
            length: .standard,
            spellingPreference: .uk
        )

        let payload = NativeDiagnosticsPayload.momentDraftStarted(
            requestID: "moment-request-123456789",
            moment: moment,
            trigger: "take_more_care"
        )

        XCTAssertTrue(payload.contains("request_id=moment-reque..."))
        XCTAssertTrue(payload.contains("trigger=take_more_care"))
        XCTAssertTrue(payload.contains("register=confess"))
        XCTAssertTrue(payload.contains("occasion=apology"))
        XCTAssertTrue(payload.contains("relationship=romantic"))
        XCTAssertTrue(payload.contains("tone=heartfelt"))
        XCTAssertTrue(payload.contains("length=standard"))
        XCTAssertTrue(payload.contains("spelling=uk"))
        XCTAssertTrue(payload.contains("person_present=true"))
        XCTAssertTrue(payload.contains("true_chars=40"))
        XCTAssertTrue(payload.contains("safety=none"))

        XCTAssertFalse(payload.contains("Private Person"))
        XCTAssertFalse(payload.contains("something specific"))
        XCTAssertFalse(payload.contains("sensitive"))
    }

    func testMomentDraftSucceededPayloadUsesCountsNotDraftText() {
        let bundle = MomentDraftBundle(
            messageText: "A private generated draft that must not be logged.",
            lane: .takeMoreCare,
            pressureCheck: PressureCheck(
                asksForReassurance: true,
                notes: ["A safe note that still should only be counted."]
            ),
            truthBeads: [
                TruthBead(personName: "Private Person", text: "Secret detail")
            ],
            missingInformation: ["Missing private context"],
            riskNotes: ["Private risk note"]
        )

        let payload = NativeDiagnosticsPayload.momentDraftSucceeded(
            requestID: "moment-success-123456789",
            bundle: bundle,
            durationMs: 321
        )

        XCTAssertTrue(payload.contains("request_id=moment-succe..."))
        XCTAssertTrue(payload.contains("lane=takeMoreCare"))
        XCTAssertTrue(payload.contains("pressure_findings=true"))
        XCTAssertTrue(payload.contains("truth_bead_count=1"))
        XCTAssertTrue(payload.contains("missing_count=1"))
        XCTAssertTrue(payload.contains("risk_count=1"))
        XCTAssertTrue(payload.contains("message_chars=50"))
        XCTAssertTrue(payload.contains("duration_ms=321"))

        XCTAssertFalse(payload.contains("private generated draft"))
        XCTAssertFalse(payload.contains("Secret detail"))
        XCTAssertFalse(payload.contains("Missing private context"))
        XCTAssertFalse(payload.contains("Private risk note"))
    }

    func testMomentLaunchConsumedPayloadDoesNotIncludeRawPerson() {
        let payload = NativeDiagnosticsPayload.momentLaunchConsumed(
            MomentLaunchRequest(personName: "Private Person", source: "app_intent")
        )

        XCTAssertEqual(payload, "moment_launch_consumed source=app_intent person_present=true")
        XCTAssertFalse(payload.contains("Private Person"))
    }
}
