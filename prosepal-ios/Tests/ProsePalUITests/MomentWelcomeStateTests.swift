@testable import ProsePalUI
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

@Test
func onboardingFooterActionsMatchTheirVisiblePromises() {
    #expect(MomentOnboardingPage.welcome.primaryAction == .advance)
    #expect(MomentOnboardingPage.welcome.showsAccountSignIn)
    #expect(MomentOnboardingPage.howItWorks.primaryAction == .advance)
    #expect(MomentOnboardingPage.howItWorks.showsAccountSignIn == false)
    #expect(MomentOnboardingPage.privacy.primaryAction == .advance)
    #expect(MomentOnboardingPage.privacy.showsAccountSignIn == false)
    #expect(MomentOnboardingPage.ready.primaryAction == .complete)
    #expect(MomentOnboardingPage.ready.primaryTitle == "Start writing")
    #expect(MomentOnboardingPage.ready.showsAccountSignIn == false)
}
