import Foundation
import ProsePalAPI
import ProsePalDomain
import ProsePalUI
import Testing

@Test
func startMomentIntentIsDiscoverable() {
    #expect(StartMomentIntent.isDiscoverable)
}

@Test
func prosePalShortcutsExposeStartMomentEntryPoint() {
    #expect(ProsePalAppShortcuts.appShortcuts.count == 1)
}

@Test
func momentLaunchRequestTrimsPersonAndSource() {
    let request = MomentLaunchRequest(
        personName: "  Alex  ",
        occasion: .birthday,
        sharedText: "  I miss our Sunday calls.  ",
        source: "  app_intent  "
    )

    #expect(request.personName == "Alex")
    #expect(request.occasion == .birthday)
    #expect(request.sharedText == "I miss our Sunday calls.")
    #expect(request.source == "app_intent")
}

@Test
func momentLaunchRequestUsesDomainOwnedPersonAndSharedTextLimits() {
    let request = MomentLaunchRequest(
        personName: "Alex\nMorgan " + String(repeating: "x", count: 100),
        sharedText: String(repeating: "🙂", count: ProsePalTextLimit.momentDetail + 20),
        source: "app_intent"
    )

    #expect(request.personName?.count == ProsePalTextLimit.personName)
    #expect(request.personName?.hasPrefix("Alex Morgan") == true)
    #expect(request.sharedText?.count == ProsePalTextLimit.momentDetail)
    #expect(SharedMomentLaunchPayload.maxTextCharacterCount == ProsePalTextLimit.momentDetail)
}

@Test
func momentLaunchRequestCapsSharedTextToHandoffLimit() {
    let request = MomentLaunchRequest(
        sharedText: String(repeating: "x", count: SharedMomentLaunchPayload.maxTextCharacterCount + 20),
        source: "share_extension"
    )

    #expect(request.sharedText?.count == SharedMomentLaunchPayload.maxTextCharacterCount)
}

@Test
func momentLaunchStoreConsumesPendingLaunchOnce() {
    let suiteName = "prosepal.momentLaunchStore.\(UUID().uuidString)"
    let store = UserDefaults(suiteName: suiteName)!
    defer {
        store.removePersistentDomain(forName: suiteName)
    }

    let launchStore = MomentLaunchStore(store: store)
    launchStore.save(MomentLaunchRequest(personName: "Alex", source: "app_intent"))

    #expect(launchStore.consume()?.personName == "Alex")
    #expect(launchStore.consume() == nil)
}

@Test
func momentDeepLinkBuildsLaunchRequestFromQueryParameters() throws {
    let url = try #require(URL(string: "prosepal://moment?person=Alex%20Morgan&occasion=Thank%20You&source=widget"))

    let deepLink = try #require(MomentDeepLink(url: url))

    #expect(deepLink.launchRequest.personName == "Alex Morgan")
    #expect(deepLink.launchRequest.occasion == .thankYou)
    #expect(deepLink.launchRequest.source == "widget")
}

@Test
func momentDeepLinkAcceptsControlCenterSource() throws {
    let url = try #require(URL(string: "prosepal://moment?source=control_center"))

    let deepLink = try #require(MomentDeepLink(url: url))

    #expect(deepLink.launchRequest.source == "control_center")
}

@Test
func momentDeepLinkBuildsLaunchRequestFromPathPerson() throws {
    let url = try #require(URL(string: "prosepal://moment/Alex%20Morgan"))

    let deepLink = try #require(MomentDeepLink(url: url))

    #expect(deepLink.launchRequest.personName == "Alex Morgan")
    #expect(deepLink.launchRequest.source == "deep_link")
}

@Test
func momentDeepLinkAcceptsRawOccasionIdentifiers() throws {
    let url = try #require(URL(string: "prosepal://moment?person=Alex&moment=petSympathy"))

    let deepLink = try #require(MomentDeepLink(url: url))

    #expect(deepLink.launchRequest.occasion == .petSympathy)
}

@Test
func momentDeepLinkRejectsUnrelatedURLs() throws {
    let url = try #require(URL(string: "prosepal://settings?person=Alex"))

    #expect(MomentDeepLink(url: url) == nil)
}

@Test
func momentDeepLinkDoesNotTrustArbitrarySourceText() throws {
    let url = try #require(URL(string: "prosepal://moment?person=Alex&source=Private%20raw%20text"))

    let deepLink = try #require(MomentDeepLink(url: url))

    #expect(deepLink.launchRequest.source == "deep_link")
}

@Test
func momentDeepLinkIgnoresUnknownOccasionText() throws {
    let url = try #require(URL(string: "prosepal://moment?person=Alex&moment=Private%20raw%20text"))

    let deepLink = try #require(MomentDeepLink(url: url))

    #expect(deepLink.launchRequest.occasion == nil)
}

@Test
func momentLaunchStorePreservesSafeOccasionWhenProvided() throws {
    let suiteName = "prosepal.startMomentIntent.\(UUID().uuidString)"
    let store = UserDefaults(suiteName: suiteName)!
    defer {
        store.removePersistentDomain(forName: suiteName)
    }

    let launchStore = MomentLaunchStore(store: store)
    launchStore.save(MomentLaunchRequest(
        personName: "Alex",
        occasion: .sympathy,
        source: "app_intent"
    ))

    let request = try #require(launchStore.consume())
    #expect(request.personName == "Alex")
    #expect(request.occasion == .sympathy)
    #expect(request.source == "app_intent")
}

@Test
func sharedMomentLaunchPayloadTrimsAndCapsText() throws {
    let longText = String(repeating: "a", count: SharedMomentLaunchPayload.maxTextCharacterCount + 50)

    let payload = SharedMomentLaunchPayload(text: "  \(longText)  ")

    #expect(payload.text?.count == SharedMomentLaunchPayload.maxTextCharacterCount)
    #expect(payload.sourceURL == nil)
    #expect(payload.hasMomentContext)
}

@Test
func sharedMomentLaunchStoreConsumesPendingPayloadOnce() throws {
    let suiteName = "prosepal.sharedMomentLaunchStore.\(UUID().uuidString)"
    let store = UserDefaults(suiteName: suiteName)!
    defer {
        store.removePersistentDomain(forName: suiteName)
    }

    let launchStore = SharedMomentLaunchStore(store: store)
    launchStore.save(SharedMomentLaunchPayload(
        text: "Shared note",
        sourceURL: URL(string: "https://example.com/note")
    ))

    let payload = try #require(launchStore.consume())
    #expect(payload.text == "Shared note")
    #expect(payload.sourceURL == URL(string: "https://example.com/note"))
    #expect(launchStore.consume() == nil)
}

@Test
func momentDeepLinkAcceptsShareExtensionSourceWithoutRawText() throws {
    let url = try #require(URL(string: "prosepal://moment?source=share_extension"))

    let deepLink = try #require(MomentDeepLink(url: url))

    #expect(deepLink.launchRequest.source == "share_extension")
    #expect(deepLink.launchRequest.sharedText == nil)
}

@Test
@MainActor
func momentModelAppliesLaunchRequest() {
    let model = MomentModel(service: NoOpMomentWritingService())

    model.applyLaunchRequest(MomentLaunchRequest(
        personName: "Alex",
        occasion: .wedding,
        sharedText: "They helped me through a hard week.",
        source: "app_intent"
    ))

    #expect(model.personName == "Alex")
    #expect(model.occasion == .wedding)
    #expect(model.trueThing == "They helped me through a hard week.")
    #expect(model.canDraft)
}

@Test
@MainActor
func momentModelAppliesSharedTextFromLaunchRequest() {
    let model = MomentModel(service: NoOpMomentWritingService())

    model.applyLaunchRequest(MomentLaunchRequest(
        sharedText: "I found a note I want to answer carefully.",
        source: "share_extension"
    ))

    #expect(model.trueThing == "I found a note I want to answer carefully.")
}

private struct NoOpMomentWritingService: MessageWritingService {
    func draft(for moment: MomentInput) async throws -> MomentDraftBundle {
        MomentDraftBundle(messageText: "Draft", lane: .mock)
    }

    func adjust(
        _ bundle: MomentDraftBundle,
        with adjustment: MomentAdjustment,
        moment: MomentInput
    ) async throws -> MomentDraftBundle {
        bundle
    }

}
