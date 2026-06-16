import ProsePalAPI
import ProsePalDomain
import ProsePalUI
import Testing

@Test
@MainActor
func staleDraftResultDoesNotReplaceLatestMomentDraft() async throws {
    let client = ControlledMomentDraftClient()
    let service = RoutingMessageWritingService(
        privateClient: client,
        carefulClient: client
    )
    let model = MomentModel(service: service)

    model.personName = "Slow"
    let firstDraft = Task {
        await model.draftNow()
    }
    await client.waitForDraftCount(1)

    model.personName = "Fast"
    let latestDraft = Task {
        await model.draftNow()
    }
    await client.waitForDraftCount(2)

    await client.resumeDraft(at: 1, text: "Fast draft.")
    await latestDraft.value
    #expect(model.bundle?.messageText == "Fast draft.")

    await client.resumeDraft(at: 0, text: "Slow draft.")
    await firstDraft.value
    #expect(model.bundle?.messageText == "Fast draft.")
    #expect(model.isDrafting == false)
}

private actor ControlledMomentDraftClient: MomentDraftClient {
    private struct PendingDraft {
        var moment: MomentInput
        var continuation: CheckedContinuation<MomentDraftBundle, Error>
    }

    private var pendingDrafts: [PendingDraft] = []

    func draft(for moment: MomentInput) async throws -> MomentDraftBundle {
        try await withCheckedThrowingContinuation { continuation in
            pendingDrafts.append(PendingDraft(
                moment: moment,
                continuation: continuation
            ))
        }
    }

    func adjust(
        _ bundle: MomentDraftBundle,
        with adjustment: MomentAdjustment,
        moment: MomentInput
    ) async throws -> MomentDraftBundle {
        try await draft(for: moment)
    }

    func waitForDraftCount(_ count: Int) async {
        while pendingDrafts.count < count {
            try? await Task.sleep(for: .milliseconds(5))
        }
    }

    func resumeDraft(at index: Int, text: String) {
        let pending = pendingDrafts[index]
        pending.continuation.resume(returning: MomentDraftBundle(
            messageText: text,
            lane: .privateDraft
        ))
    }
}
