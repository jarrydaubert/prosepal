import Foundation
import ProsePalDomain
import ProsePalUI
import Testing

@Test
@MainActor
func draftRecoveryStorageIdentityRemainsBackwardCompatible() {
    #expect(MomentDraftRecoveryState.schemaVersion == 1)
    #expect(MomentDraftRecoveryStore.defaultKey == "prosepal.native.activeDraftRecovery.v1")
}

@MainActor
@Test
func draftRecoveryStoreRejectsAndClearsAnUnsupportedSchema() throws {
    let suiteName = "MomentDraftRecoverySchemaTests.\(UUID().uuidString)"
    let defaults = try #require(UserDefaults(suiteName: suiteName))
    defaults.removePersistentDomain(forName: suiteName)
    defer {
        defaults.removePersistentDomain(forName: suiteName)
    }

    let key = "active-draft"
    let unsupportedState = MomentDraftRecoveryState(
        schemaVersion: MomentDraftRecoveryState.schemaVersion + 1,
        personName: "Mira",
        relationship: .family,
        occasion: .apology,
        register: .assemble,
        trueThing: "I missed the call.",
        bundle: MomentDraftBundle(messageText: "Recovered words.", lane: .careful),
        draftSnapshots: []
    )
    defaults.set(try JSONEncoder().encode(unsupportedState), forKey: key)

    let store = MomentDraftRecoveryStore(store: defaults, key: key)

    #expect(store.load() == nil)
    #expect(defaults.data(forKey: key) == nil)
}
