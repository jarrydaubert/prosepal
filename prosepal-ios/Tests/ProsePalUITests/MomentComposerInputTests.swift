import Foundation
import ProsePalAPI
import ProsePalDomain
import ProsePalUI
import Testing

// The composer has no voice-entry control. Moment detail is a typed-only field,
// so these cover the paths the removed dictation surface used to share.

@Test
@MainActor
func typedMomentDetailReachesGeneration() async throws {
    let client = RecordingMomentDraftClient()
    let service = RoutingMessageWritingService(privateClient: client, carefulClient: client)
    let model = MomentModel(service: service)

    model.personName = "Mira"
    model.trueThing = "She sat with me at the hospital."
    model.startDraft()

    try await expectEventually("The typed detail never reached the service.") {
        await client.moments().count == 1
    }

    let moments = await client.moments()
    #expect(moments.first?.trueThing == "She sat with me at the hospital.")
    #expect(model.bundle?.messageText == "Draft.")
}

@Test
@MainActor
func momentDetailIsOptionalSoTheComposerCompletesWithoutIt() async throws {
    let client = RecordingMomentDraftClient()
    let service = RoutingMessageWritingService(privateClient: client, carefulClient: client)
    let model = MomentModel(service: service)

    model.personName = "Mira"
    model.startDraft()

    try await expectEventually("Generation did not complete without a moment detail.") {
        model.bundle != nil
    }

    let moments = await client.moments()
    #expect(moments.first?.trueThing.isEmpty == true)
    #expect(model.isDrafting == false)
}

@Test
@MainActor
func typedMomentDetailIsNormalizedToTheMomentDetailLimit() {
    let overLimit = String(repeating: "a", count: ProsePalTextLimit.momentDetail + 50)

    #expect(ProsePalTextInput.momentDetail(overLimit).count == ProsePalTextLimit.momentDetail)
}

private actor RecordingMomentDraftClient: MomentDraftClient {
    private var recordedMoments: [MomentInput] = []

    func moments() -> [MomentInput] {
        recordedMoments
    }

    func draft(for moment: MomentInput) async throws -> MomentDraftBundle {
        recordedMoments.append(moment)
        return MomentDraftBundle(messageText: "Draft.", lane: .privateDraft)
    }

    func adjust(
        _ bundle: MomentDraftBundle,
        with adjustment: MomentAdjustment,
        moment: MomentInput
    ) async throws -> MomentDraftBundle {
        try await draft(for: moment)
    }
}
