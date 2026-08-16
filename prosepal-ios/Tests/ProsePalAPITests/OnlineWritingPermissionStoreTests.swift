import Foundation
import ProsePalAPI
import Testing

@Test
func persistedOnlineWritingPermissionIsVersionedAndRevocable() throws {
    let suiteName = "OnlineWritingPermissionStoreTests.\(UUID().uuidString)"
    let defaults = try #require(UserDefaults(suiteName: suiteName))
    defer { defaults.removePersistentDomain(forName: suiteName) }

    let key = "permission"
    let store = UserDefaultsOnlineWritingPermissionStore(
        defaults: defaults,
        key: key,
        currentPolicyVersion: 2
    )

    #expect(store.state() == .notGranted)

    defaults.set(1, forKey: key)
    #expect(store.state() == .stalePolicyGrant)

    store.grantCurrentPolicy()
    #expect(store.state() == .currentGrant)
    #expect(defaults.integer(forKey: key) == 2)

    store.revoke()
    #expect(store.state() == .notGranted)
    #expect(defaults.object(forKey: key) == nil)
}
