import XCTest
import ProsePalDomain
@testable import ProsePalUI

final class NativeDiagnosticsTests: XCTestCase {
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
            length: .standard
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
        XCTAssertFalse(payload.contains("spelling="))
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

        XCTAssertEqual(payload, "moment_launch_consumed source=app_intent person_present=true occasion=none")
        XCTAssertFalse(payload.contains("Private Person"))
    }
}
