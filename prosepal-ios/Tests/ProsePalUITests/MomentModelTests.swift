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

@Test
@MainActor
func crisisInputDoesNotStartMomentDrafting() async throws {
    let client = CountingMomentDraftClient()
    let service = RoutingMessageWritingService(
        privateClient: client,
        carefulClient: client
    )
    let model = MomentModel(service: service)

    model.personName = "Alex"
    model.trueThing = "I want to end my life."
    await model.draftNow()

    #expect(model.canDraft == false)
    #expect(model.safetySignal == .crisisSupport)
    #expect(model.bundle == nil)
    #expect(await client.draftCallCount == 0)
}

@Test
@MainActor
func momentChangesClearDraftWithoutStartingGeneration() async throws {
    let client = CountingMomentDraftClient()
    let service = RoutingMessageWritingService(
        privateClient: client,
        carefulClient: client
    )
    let model = MomentModel(service: service)

    model.personName = "Alex"
    model.bundle = MomentDraftBundle(messageText: "Old draft.", lane: .privateDraft)
    model.errorMessage = "Old error."

    model.personName = "Alexandra"
    model.resetDraftForMomentChange()

    #expect(model.bundle == nil)
    #expect(model.errorMessage == nil)
    #expect(model.isDrafting == false)
    #expect(await client.draftCallCount == 0)
}

@Test
@MainActor
func startNewMomentClearsActiveComposerWithoutStartingGeneration() async throws {
    let client = CountingMomentDraftClient()
    let service = RoutingMessageWritingService(
        privateClient: client,
        carefulClient: client
    )
    let model = MomentModel(service: service)

    model.personName = "Mira"
    model.relationship = .colleague
    model.occasion = .sympathy
    model.register = .assemble
    model.trueThing = "A detail"
    model.bundle = MomentDraftBundle(messageText: "Old draft.", lane: .takeMoreCare)
    model.errorMessage = "Old error."
    model.isDrafting = true

    model.startNewMoment()

    #expect(model.personName == "")
    #expect(model.relationship == .closeFriend)
    #expect(model.occasion == .birthday)
    #expect(model.register == .react)
    #expect(model.trueThing == "")
    #expect(model.bundle == nil)
    #expect(model.errorMessage == nil)
    #expect(model.isDrafting == false)
    #expect(await client.draftCallCount == 0)
}

@Test
@MainActor
func sensitiveMomentAlignsDefaultRegisterToTakeCare() async throws {
    let client = CountingMomentDraftClient()
    let service = RoutingMessageWritingService(
        privateClient: client,
        carefulClient: client
    )
    let model = MomentModel(service: service)

    model.occasion = .sympathy
    model.alignRegisterForMoment()

    #expect(model.register == .assemble)
    #expect(model.moment.isCarefulMode)
    #expect(model.moment.requiresCarefulLane)
}

@Test
@MainActor
func ordinaryMomentKeepsDefaultReactRegister() async throws {
    let client = CountingMomentDraftClient()
    let service = RoutingMessageWritingService(
        privateClient: client,
        carefulClient: client
    )
    let model = MomentModel(service: service)

    model.occasion = .thankYou
    model.alignRegisterForMoment()

    #expect(model.register == .react)
    #expect(!model.moment.requiresCarefulLane)
}

@Test
@MainActor
func ordinaryMomentResetsRegisterAfterSensitiveMoment() async throws {
    let client = CountingMomentDraftClient()
    let service = RoutingMessageWritingService(
        privateClient: client,
        carefulClient: client
    )
    let model = MomentModel(service: service)

    model.occasion = .petSympathy
    model.alignRegisterForMoment()
    #expect(model.register == .assemble)

    model.occasion = .birthday
    model.alignRegisterForMoment()

    #expect(model.register == .react)
    #expect(!model.moment.isCarefulMode)
    #expect(!model.moment.requiresCarefulLane)
}

@Test
@MainActor
func launchRequestAlignsSensitiveMomentBeforeDrafting() async throws {
    let client = CountingMomentDraftClient()
    let service = RoutingMessageWritingService(
        privateClient: client,
        carefulClient: client
    )
    let model = MomentModel(service: service)

    model.applyLaunchRequest(MomentLaunchRequest(
        personName: "Sam",
        occasion: .apology
    ))

    #expect(model.register == .assemble)
    #expect(model.moment.requiresCarefulLane)
}

@Test
@MainActor
func takeMoreCareReplacesPrivateDraftWithCarefulDraft() async throws {
    let privateClient = CountingMomentDraftClient()
    let carefulClient = MomentModelRefiningClient(
        bundle: MomentDraftBundle(
            messageText: "A more careful draft.",
            lane: .takeMoreCare
        )
    )
    let service = RoutingMessageWritingService(
        privateClient: privateClient,
        carefulClient: carefulClient
    )
    let model = MomentModel(service: service)

    model.personName = "Alex"
    model.bundle = MomentDraftBundle(
        messageText: "A quick private draft.",
        lane: .privateDraft
    )

    model.takeMoreCare()

    for _ in 0..<40 {
        if model.bundle?.lane == .takeMoreCare { break }
        try await Task.sleep(for: .milliseconds(5))
    }

    #expect(model.bundle?.messageText == "A more careful draft.")
    #expect(model.bundle?.lane == .takeMoreCare)
    #expect(await carefulClient.lastCurrentMessage == "A quick private draft.")
}

@Test
@MainActor
func adjustingDraftStoresUndoSnapshotAndRestoreClearsIt() async throws {
    let originalBundle = MomentDraftBundle(
        messageText: "A quick private draft.",
        lane: .privateDraft
    )
    let refinedBundle = MomentDraftBundle(
        messageText: "A warmer draft.",
        lane: .privateDraft
    )
    let privateClient = MomentModelRefiningClient(bundle: refinedBundle)
    let service = RoutingMessageWritingService(
        privateClient: privateClient,
        carefulClient: MomentModelRefiningClient(bundle: refinedBundle)
    )
    let model = MomentModel(service: service)

    model.personName = "Alex"
    model.bundle = originalBundle
    model.adjust(.warmer)

    for _ in 0..<40 {
        if model.bundle?.messageText == "A warmer draft." { break }
        try await Task.sleep(for: .milliseconds(5))
    }

    #expect(model.bundle == refinedBundle)
    #expect(model.previousDraftBundle == originalBundle)
    #expect(model.canRestorePreviousDraft)

    model.restorePreviousDraft()

    #expect(model.bundle == originalBundle)
    #expect(model.previousDraftBundle == nil)
    #expect(!model.canRestorePreviousDraft)
}

@Test
@MainActor
func takeMoreCareStoresUndoSnapshotWhenItReplacesDraft() async throws {
    let originalBundle = MomentDraftBundle(
        messageText: "A quick private draft.",
        lane: .privateDraft
    )
    let carefulBundle = MomentDraftBundle(
        messageText: "A careful draft.",
        lane: .takeMoreCare
    )
    let privateClient = CountingMomentDraftClient()
    let carefulClient = MomentModelRefiningClient(bundle: carefulBundle)
    let service = RoutingMessageWritingService(
        privateClient: privateClient,
        carefulClient: carefulClient
    )
    let model = MomentModel(service: service)

    model.personName = "Alex"
    model.bundle = originalBundle
    model.takeMoreCare()

    for _ in 0..<40 {
        if model.bundle?.messageText == "A careful draft." { break }
        try await Task.sleep(for: .milliseconds(5))
    }

    #expect(model.bundle == carefulBundle)
    #expect(model.previousDraftBundle == originalBundle)
}

@Test
@MainActor
func failedAdjustmentKeepsCurrentDraftAndUndoSnapshot() async throws {
    let originalBundle = MomentDraftBundle(
        messageText: "Original draft.",
        lane: .privateDraft
    )
    let currentBundle = MomentDraftBundle(
        messageText: "Current draft.",
        lane: .privateDraft
    )
    let sequencingClient = SequencedMomentModelRefinementClient(
        outcomes: [
            .success(currentBundle),
            .failure(GenerationError.serviceUnavailable(message: "Unavailable.")),
            .failure(GenerationError.serviceUnavailable(message: "Unavailable."))
        ]
    )
    let service = RoutingMessageWritingService(
        privateClient: sequencingClient,
        carefulClient: sequencingClient
    )
    let model = MomentModel(service: service)

    model.personName = "Alex"
    model.bundle = originalBundle
    model.adjust(.warmer)

    for _ in 0..<40 {
        if model.bundle == currentBundle { break }
        try await Task.sleep(for: .milliseconds(5))
    }

    #expect(model.bundle == currentBundle)
    #expect(model.previousDraftBundle == originalBundle)

    model.adjust(.shorter)

    for _ in 0..<40 {
        if model.errorMessage != nil { break }
        try await Task.sleep(for: .milliseconds(5))
    }

    #expect(model.bundle == currentBundle)
    #expect(model.previousDraftBundle == originalBundle)
    #expect(model.errorMessage == "Unavailable.")
    #expect(model.canRestorePreviousDraft)
}

@Test
@MainActor
func takeMoreCareDoesNotRequirePremiumEntitlementInMomentModel() async throws {
    let privateClient = CountingMomentDraftClient()
    let carefulClient = MomentModelRefiningClient(
        bundle: MomentDraftBundle(
            messageText: "A careful draft for everyone.",
            lane: .takeMoreCare
        )
    )
    let service = RoutingMessageWritingService(
        privateClient: privateClient,
        carefulClient: carefulClient
    )
    let model = MomentModel(service: service)

    model.personName = "Alex"
    model.bundle = MomentDraftBundle(
        messageText: "A quick private draft.",
        lane: .privateDraft
    )
    model.takeMoreCare()

    for _ in 0..<40 {
        if model.bundle?.messageText == "A careful draft for everyone." { break }
        try await Task.sleep(for: .milliseconds(5))
    }

    #expect(model.bundle?.messageText == "A careful draft for everyone.")
    #expect(model.bundle?.lane == .takeMoreCare)
    #expect(model.errorMessage == nil)
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

private actor CountingMomentDraftClient: MomentDraftClient {
    private(set) var draftCallCount = 0

    func draft(for moment: MomentInput) async throws -> MomentDraftBundle {
        draftCallCount += 1
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

private actor MomentModelRefiningClient: MomentDraftRefinementClient {
    private let bundle: MomentDraftBundle
    private(set) var lastCurrentMessage: String?

    init(bundle: MomentDraftBundle) {
        self.bundle = bundle
    }

    func draft(for moment: MomentInput) async throws -> MomentDraftBundle {
        bundle
    }

    func adjust(
        _ bundle: MomentDraftBundle,
        with adjustment: MomentAdjustment,
        moment: MomentInput
    ) async throws -> MomentDraftBundle {
        self.bundle
    }

    func refine(
        currentMessage: String?,
        moment: MomentInput
    ) async throws -> MomentDraftBundle {
        lastCurrentMessage = currentMessage
        return bundle
    }
}

private actor SequencedMomentModelRefinementClient: MomentDraftRefinementClient {
    enum Outcome {
        case success(MomentDraftBundle)
        case failure(Error)
    }

    private var outcomes: [Outcome]

    init(outcomes: [Outcome]) {
        self.outcomes = outcomes
    }

    func draft(for moment: MomentInput) async throws -> MomentDraftBundle {
        try nextOutcome()
    }

    func adjust(
        _ bundle: MomentDraftBundle,
        with adjustment: MomentAdjustment,
        moment: MomentInput
    ) async throws -> MomentDraftBundle {
        try nextOutcome()
    }

    func refine(
        currentMessage: String?,
        moment: MomentInput
    ) async throws -> MomentDraftBundle {
        try nextOutcome()
    }

    private func nextOutcome() throws -> MomentDraftBundle {
        guard !outcomes.isEmpty else {
            throw GenerationError.serviceUnavailable(message: "No queued outcome.")
        }

        switch outcomes.removeFirst() {
        case .success(let bundle):
            return bundle
        case .failure(let error):
            throw error
        }
    }
}
