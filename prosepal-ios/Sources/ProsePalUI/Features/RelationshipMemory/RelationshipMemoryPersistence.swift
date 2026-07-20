/// Relationship-memory writes that must not report success before the store
/// commits. Both operations roll the context back and rethrow so a caller can
/// surface an honest failure instead of a stale optimistic result.

func performConfirmedMemoryDeletion(
    delete: () -> Void,
    save: () throws -> Void,
    rollback: () -> Void
) throws {
    delete()
    do {
        try save()
    } catch {
        rollback()
        throw error
    }
}

func performRelationshipMemorySave(
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
