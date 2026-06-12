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
}
