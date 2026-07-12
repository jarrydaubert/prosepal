func persistSavedDraftEdit(
    update: () -> Void,
    save: () throws -> Void,
    rollback: () -> Void
) throws {
    update()
    do {
        try save()
    } catch {
        rollback()
        throw error
    }
}

@discardableResult
func persistSavedDraftDeletion(
    confirmed: Bool,
    delete: () -> Void,
    save: () throws -> Void,
    rollback: () -> Void
) throws -> Bool {
    guard confirmed else { return false }

    delete()
    do {
        try save()
        return true
    } catch {
        rollback()
        throw error
    }
}
