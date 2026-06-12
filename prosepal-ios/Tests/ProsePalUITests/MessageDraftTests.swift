import XCTest
import ProsePalDomain
@testable import ProsePalUI

final class MessageDraftTests: XCTestCase {
    func testDraftBuildsStructuredIntentFromExpandedFormFields() {
        var draft = MessageDraft()
        draft.occasion = .thankYouTeacher
        draft.relationship = .teacher
        draft.tone = .nostalgic
        draft.length = .detailed
        draft.spellingPreference = .uk
        draft.recipientName = "Mrs Patel"
        draft.thingsToInclude = "patient feedback, exam confidence"
        draft.thingsToAvoid = "generic phrases"
        draft.personalContext = "She helped me after school."

        let intent = draft.intent

        XCTAssertEqual(intent.occasion, .thankYouTeacher)
        XCTAssertEqual(intent.relationship, .teacher)
        XCTAssertEqual(intent.tone, .nostalgic)
        XCTAssertEqual(intent.length, .detailed)
        XCTAssertEqual(intent.spellingPreference, .uk)
        XCTAssertEqual(intent.localeIdentifier, "en_GB")
        XCTAssertEqual(intent.recipientName, "Mrs Patel")
        XCTAssertEqual(intent.thingsToInclude, ["patient feedback", "exam confidence"])
        XCTAssertEqual(intent.thingsToAvoid, ["generic phrases"])
        XCTAssertEqual(intent.userContext, "She helped me after school.")
    }

    func testDraftTrimsOptionalFieldsBeforeBuildingIntent() {
        var draft = MessageDraft()
        draft.recipientName = "  "
        draft.thingsToInclude = " quiet tea, , old photos "
        draft.thingsToAvoid = " age jokes,  "
        draft.personalContext = "  "

        let intent = draft.intent

        XCTAssertNil(intent.recipientName)
        XCTAssertEqual(intent.thingsToInclude, ["quiet tea", "old photos"])
        XCTAssertEqual(intent.thingsToAvoid, ["age jokes"])
        XCTAssertNil(intent.userContext)
    }
}
