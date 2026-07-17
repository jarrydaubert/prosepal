@testable import ProsePalUI
import Testing

@Test
func savedDraftEditReportsSuccessOnlyAfterPersistence() throws {
    var text = "Persisted text"
    var didSave = false
    var didRollback = false

    try persistSavedDraftEdit(
        update: { text = "Edited text" },
        save: { didSave = true },
        rollback: { didRollback = true }
    )

    #expect(text == "Edited text")
    #expect(didSave)
    #expect(!didRollback)
}

@Test
func failedSavedDraftEditRestoresPersistedTextAndPropagatesFailure() {
    var text = "Persisted text"

    #expect(throws: SavedDraftPersistenceTestError.persistenceFailed) {
        try persistSavedDraftEdit(
            update: { text = "Edited text" },
            save: { throw SavedDraftPersistenceTestError.persistenceFailed },
            rollback: { text = "Persisted text" }
        )
    }

    #expect(text == "Persisted text")
}

@Test
func cancelledSavedDraftDeletionDoesNotMutateOrPersist() throws {
    var didDelete = false
    var didSave = false
    var didRollback = false

    let didDeleteDraft = try persistSavedDraftDeletion(
        confirmed: false,
        delete: { didDelete = true },
        save: { didSave = true },
        rollback: { didRollback = true }
    )

    #expect(!didDeleteDraft)
    #expect(!didDelete)
    #expect(!didSave)
    #expect(!didRollback)
}

@Test
func confirmedSavedDraftDeletionDismissesOnlyAfterPersistence() throws {
    var didDelete = false
    var didSave = false
    var didRollback = false

    let didDeleteDraft = try persistSavedDraftDeletion(
        confirmed: true,
        delete: { didDelete = true },
        save: { didSave = true },
        rollback: { didRollback = true }
    )

    #expect(didDeleteDraft)
    #expect(didDelete)
    #expect(didSave)
    #expect(!didRollback)
}

@Test
func failedSavedDraftDeletionRollsBackAndPropagatesFailure() {
    var didDelete = false
    var didRollback = false

    #expect(throws: SavedDraftPersistenceTestError.persistenceFailed) {
        try persistSavedDraftDeletion(
            confirmed: true,
            delete: { didDelete = true },
            save: { throw SavedDraftPersistenceTestError.persistenceFailed },
            rollback: { didRollback = true }
        )
    }

    #expect(didDelete)
    #expect(didRollback)
}

private enum SavedDraftPersistenceTestError: Error {
    case persistenceFailed
}
