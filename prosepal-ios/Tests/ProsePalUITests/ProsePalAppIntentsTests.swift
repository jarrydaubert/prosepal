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
        source: "  app_intent  "
    )

    #expect(request.personName == "Alex")
    #expect(request.source == "app_intent")
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
@MainActor
func momentModelAppliesLaunchRequest() {
    let model = MomentModel(service: NoOpMomentWritingService())

    model.applyLaunchRequest(MomentLaunchRequest(personName: "Alex", source: "app_intent"))

    #expect(model.personName == "Alex")
    #expect(model.canDraft)
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

    func takeMoreCare(
        _ bundle: MomentDraftBundle?,
        moment: MomentInput
    ) async throws -> MomentDraftBundle {
        MomentDraftBundle(messageText: "Careful draft", lane: .takeMoreCare)
    }
}
