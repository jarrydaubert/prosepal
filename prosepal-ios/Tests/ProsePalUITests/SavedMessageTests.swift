import XCTest
import ProsePalAPI
import ProsePalDomain
@testable import ProsePalUI

@MainActor
final class SavedMessageTests: XCTestCase {
    func testSaveCapturesDraftMetadataAndPreventsDuplicates() throws {
        let harness = try makeHarness()
        defer { harness.cleanup() }

        let model = harness.makeModel()
        model.draft.occasion = .thankYouTeacher
        model.draft.relationship = .teacher
        model.draft.tone = .nostalgic
        model.draft.length = .detailed
        model.draft.recipientName = "Mrs Patel"

        let message = GeneratedMessage(id: "draft-1", text: "Thank you for everything.")

        XCTAssertTrue(model.save(message))
        XCTAssertFalse(model.save(message))
        XCTAssertEqual(model.savedMessages.count, 1)

        let saved = try XCTUnwrap(model.savedMessages.first)
        XCTAssertEqual(saved.text, "Thank you for everything.")
        XCTAssertEqual(saved.occasion, .thankYouTeacher)
        XCTAssertEqual(saved.relationship, .teacher)
        XCTAssertEqual(saved.tone, .nostalgic)
        XCTAssertEqual(saved.length, .detailed)
        XCTAssertEqual(saved.recipientName, "Mrs Patel")
        XCTAssertEqual(saved.title, "Mrs Patel")
        XCTAssertEqual(saved.subtitle, "Thank You Teacher / Teacher / Nostalgic")
    }

    func testSavedMessagesPersistUpdateAndDeleteLocally() throws {
        let harness = try makeHarness()
        defer { harness.cleanup() }

        let model = harness.makeModel()
        model.draft.occasion = .birthday
        model.draft.relationship = .parent
        model.draft.tone = .heartfelt
        model.draft.length = .standard

        XCTAssertTrue(model.save(GeneratedMessage(id: "draft-1", text: " Happy birthday, Dad. ")))
        let saved = try XCTUnwrap(model.savedMessages.first)

        let reloaded = harness.makeModel()
        XCTAssertEqual(reloaded.savedMessages.count, 1)
        XCTAssertEqual(reloaded.savedMessages.first?.text, "Happy birthday, Dad.")

        XCTAssertTrue(reloaded.updateSaved(saved, text: "Happy birthday, Dad. I love you."))
        XCTAssertEqual(reloaded.savedMessages.first?.text, "Happy birthday, Dad. I love you.")

        let reloadedAfterUpdate = harness.makeModel()
        XCTAssertEqual(reloadedAfterUpdate.savedMessages.first?.text, "Happy birthday, Dad. I love you.")

        reloadedAfterUpdate.deleteSaved(try XCTUnwrap(reloadedAfterUpdate.savedMessages.first))
        XCTAssertTrue(reloadedAfterUpdate.savedMessages.isEmpty)

        let reloadedAfterDelete = harness.makeModel()
        XCTAssertTrue(reloadedAfterDelete.savedMessages.isEmpty)
    }

    private func makeHarness() throws -> SavedMessageHarness {
        let suiteName = "prosepal.saved.tests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defaults.removePersistentDomain(forName: suiteName)
        return SavedMessageHarness(suiteName: suiteName, defaults: defaults)
    }
}

@MainActor
private struct SavedMessageHarness {
    let suiteName: String
    let defaults: UserDefaults
    let key = "saved-messages"

    func makeModel() -> ProsePalAppModel {
        ProsePalAppModel(
            client: TemplateMessageWritingClient(),
            clientContext: ClientContext(appVersion: "0.0.0", buildNumber: "1"),
            savedMessagesStore: defaults,
            savedMessagesKey: key
        )
    }

    func cleanup() {
        defaults.removePersistentDomain(forName: suiteName)
    }
}
