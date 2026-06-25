import ProsePalUI
import Testing
import Foundation

@Test
@MainActor
func momentWelcomeStartsIncompleteAndPersistsCompletion() {
    let suiteName = "MomentWelcomeStateTests-\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: suiteName)!
    defer { defaults.removePersistentDomain(forName: suiteName) }

    let firstLaunch = MomentWelcomeState(
        store: defaults,
        completionKey: "moment-welcome-complete"
    )

    #expect(firstLaunch.hasCompletedWelcome == false)

    firstLaunch.completeWelcome()
    #expect(firstLaunch.hasCompletedWelcome == true)

    let returningLaunch = MomentWelcomeState(
        store: defaults,
        completionKey: "moment-welcome-complete"
    )

    #expect(returningLaunch.hasCompletedWelcome == true)
}
