import Foundation
import ProsePalAPI
import ProsePalDomain
import Testing

@Test
func everydayMomentRoutesToPrivateClient() async throws {
    let privateClient = RecordingMomentDraftClient(
        bundle: MomentDraftBundle(messageText: "Private hello.", lane: .privateDraft)
    )
    let carefulClient = RecordingMomentDraftClient(
        bundle: MomentDraftBundle(messageText: "Careful hello.", lane: .takeMoreCare)
    )
    let service = RoutingMessageWritingService(
        privateClient: privateClient,
        carefulClient: carefulClient
    )

    let bundle = try await service.draft(for: MomentInput(
        personName: "Alex",
        relationship: .closeFriend,
        occasion: .birthday
    ))

    #expect(bundle.messageText == "Private hello.")
    #expect(bundle.lane == .privateDraft)
    #expect(await privateClient.draftCallCount == 1)
    #expect(await carefulClient.draftCallCount == 0)
}

@Test
func sensitiveMomentRoutesDirectlyToCarefulClient() async throws {
    let privateClient = RecordingMomentDraftClient(
        bundle: MomentDraftBundle(messageText: "Private sympathy.", lane: .privateDraft)
    )
    let carefulClient = RecordingMomentDraftClient(
        bundle: MomentDraftBundle(messageText: "Careful sympathy.", lane: .takeMoreCare)
    )
    let service = RoutingMessageWritingService(
        privateClient: privateClient,
        carefulClient: carefulClient
    )

    let bundle = try await service.draft(for: MomentInput(
        personName: "Sam",
        relationship: .family,
        occasion: .sympathy
    ))

    #expect(bundle.messageText == "Careful sympathy.")
    #expect(bundle.lane == .takeMoreCare)
    #expect(await privateClient.draftCallCount == 0)
    #expect(await carefulClient.draftCallCount == 1)
}

@Test
func gatewayCarefulClientRequestsWorkingStandardLaneButReturnsTakeMoreCareProductLane() async throws {
    let cardClient = RecordingCardMessageWritingClient(response: CardResponse(
        messages: [GeneratedMessage(id: "careful-1", text: "A careful gateway draft.")],
        laneUsed: .standard,
        fallbackStatus: .none,
        retryEligibility: .ineligible
    ))
    let client = GatewayCarefulMomentClient(
        client: cardClient,
        clientContext: ClientContext(appVersion: "0.0.0", buildNumber: "1")
    )

    let bundle = try await client.draft(for: MomentInput(
        personName: "Sam",
        relationship: .family,
        occasion: .sympathy
    ))

    #expect(bundle.messageText == "A careful gateway draft.")
    #expect(bundle.lane == .takeMoreCare)
    #expect(await cardClient.firstRequestedLane == .standard)
}

@Test
func carefulLaneEntitlementFailureFallsBackToPrivateDraft() async throws {
    let privateClient = RecordingMomentDraftClient(
        bundle: MomentDraftBundle(messageText: "A plain private draft.", lane: .privateDraft)
    )
    let carefulClient = FailingMomentDraftClient(
        error: GenerationError.usageLimitReached(
            message: "Premium generation is not available in this development gateway yet."
        )
    )
    let service = RoutingMessageWritingService(
        privateClient: privateClient,
        carefulClient: carefulClient
    )

    let bundle = try await service.draft(for: MomentInput(
        personName: "Sam",
        relationship: .family,
        occasion: .sympathy
    ))

    #expect(bundle.messageText == "A plain private draft.")
    #expect(bundle.lane == .privateDraft)
    #expect(await privateClient.draftCallCount == 1)
}

@Test(arguments: [
    (Occasion.sympathy, GenerationError.usageLimitReached(message: "Premium unavailable.")),
    (Occasion.apology, GenerationError.serviceUnavailable(message: "Gateway unavailable."))
])
func sensitiveMomentsProducePrivateDraftWhenGatewayCarefulLaneFails(
    occasion: Occasion,
    gatewayError: GenerationError
) async throws {
    let privateClient = RecordingMomentDraftClient(
        bundle: MomentDraftBundle(messageText: "A simple fallback draft.", lane: .privateDraft)
    )
    let carefulClient = GatewayCarefulMomentClient(
        client: FailingCardMessageWritingClient(error: gatewayError),
        clientContext: ClientContext(appVersion: "0.0.0", buildNumber: "1")
    )
    let service = RoutingMessageWritingService(
        privateClient: privateClient,
        carefulClient: carefulClient
    )

    let bundle = try await service.draft(for: MomentInput(
        personName: "Alex",
        relationship: .closeFriend,
        occasion: occasion,
        register: .confess,
        trueThing: "I want to say this carefully."
    ))

    #expect(bundle.messageText == "A simple fallback draft.")
    #expect(bundle.lane == .privateDraft)
    #expect(await privateClient.draftCallCount == 1)
}

@Test
func carefulLaneContentBlockDoesNotFallbackToPrivateDraft() async {
    let privateClient = RecordingMomentDraftClient(
        bundle: MomentDraftBundle(messageText: "Private fallback.", lane: .privateDraft)
    )
    let carefulClient = FailingMomentDraftClient(
        error: GenerationError.contentBlocked(message: "This wording needs to change first.")
    )
    let service = RoutingMessageWritingService(
        privateClient: privateClient,
        carefulClient: carefulClient
    )

    do {
        _ = try await service.draft(for: MomentInput(
            personName: "Alex",
            relationship: .closeFriend,
            occasion: .sympathy
        ))
        Issue.record("Expected careful content-block to stop drafting.")
    } catch let error as GenerationError {
        #expect(error == .contentBlocked(message: "This wording needs to change first."))
    } catch {
        Issue.record("Expected GenerationError, got \(error).")
    }

    #expect(await privateClient.draftCallCount == 0)
}

@Test
func privateUnavailabilityFallsThroughToStandardGatewayDraft() async throws {
    let privateClient = FailingMomentDraftClient(
        error: GenerationError.serviceUnavailable(message: "Private draft unavailable.")
    )
    let carefulClient = RecordingMomentDraftClient(
        bundle: MomentDraftBundle(messageText: "Careful fallback.", lane: .takeMoreCare)
    )
    let service = RoutingMessageWritingService(
        privateClient: privateClient,
        carefulClient: carefulClient
    )

    let bundle = try await service.draft(for: MomentInput(
        personName: "Taylor",
        relationship: .colleague,
        occasion: .newJob
    ))

    #expect(bundle.messageText == "Careful fallback.")
    #expect(bundle.lane == .standardDraft)
    #expect(await carefulClient.draftCallCount == 1)
}

@Test
func privateContentBlockDoesNotFallThroughToCarefulClient() async {
    let privateClient = FailingMomentDraftClient(
        error: GenerationError.contentBlocked(message: "This needs a different kind of support.")
    )
    let carefulClient = RecordingMomentDraftClient(
        bundle: MomentDraftBundle(messageText: "Careful fallback.", lane: .takeMoreCare)
    )
    let service = RoutingMessageWritingService(
        privateClient: privateClient,
        carefulClient: carefulClient
    )

    do {
        _ = try await service.draft(for: MomentInput(
            personName: "Alex",
            relationship: .closeFriend,
            occasion: .birthday
        ))
        Issue.record("Expected content blocked errors to stay blocked.")
    } catch let error as GenerationError {
        #expect(error == .contentBlocked(message: "This needs a different kind of support."))
    } catch {
        Issue.record("Expected GenerationError, got \(error).")
    }

    #expect(await carefulClient.draftCallCount == 0)
}

@Test
func laneTimeoutCancelsTheUnderlyingOperationBeforeFallback() async {
    let privateClient = CancellationRecordingMomentDraftClient()
    let carefulClient = FailingMomentDraftClient(
        error: .contentBlocked(message: "Stop after the timeout fallback.")
    )
    let service = RoutingMessageWritingService(
        privateClient: privateClient,
        carefulClient: carefulClient,
        timeoutPolicy: GenerationTimeoutPolicy(
            onDevice: .milliseconds(20),
            gateway: .seconds(1)
        )
    )

    do {
        _ = try await service.draft(for: MomentInput(
            personName: "Alex",
            relationship: .closeFriend,
            occasion: .birthday
        ))
        Issue.record("Expected the careful fallback to stop after the private timeout.")
    } catch let error as GenerationError {
        #expect(error == .contentBlocked(message: "Stop after the timeout fallback."))
    } catch {
        Issue.record("Expected GenerationError, got \(error).")
    }

    #expect(await privateClient.didObserveCancellation)
}

@Test
func serviceAppliesLocalPressureCheckToReturnedDraft() async throws {
    let privateClient = RecordingMomentDraftClient(
        bundle: MomentDraftBundle(
            messageText: "I'm sorry but I was trying to help.",
            lane: .privateDraft
        )
    )
    let carefulClient = RecordingMomentDraftClient(
        bundle: MomentDraftBundle(
            messageText: "I'm sorry but I was trying to help.",
            lane: .takeMoreCare
        )
    )
    let service = RoutingMessageWritingService(
        privateClient: privateClient,
        carefulClient: carefulClient
    )

    let bundle = try await service.draft(for: MomentInput(
        personName: "Dad",
        relationship: .parent,
        occasion: .apology,
        register: .react
    ))

    #expect(bundle.pressureCheck.explainsBeforeApology)
    #expect(bundle.pressureCheck.userVisibleNotes.contains("This apology may sound conditional. Lead with the apology before explaining."))
}

@Test
func emptyPersonDoesNotStartDrafting() async {
    let service = RoutingMessageWritingService(
        privateClient: RecordingMomentDraftClient(
            bundle: MomentDraftBundle(messageText: "Private.", lane: .privateDraft)
        ),
        carefulClient: RecordingMomentDraftClient(
            bundle: MomentDraftBundle(messageText: "Careful.", lane: .takeMoreCare)
        )
    )

    do {
        _ = try await service.draft(for: MomentInput(
            personName: " ",
            relationship: .closeFriend,
            occasion: .birthday
        ))
        Issue.record("Expected empty person to fail before calling clients.")
    } catch let error as GenerationError {
        #expect(error.userSafeMessage == "Add who this is for to begin.")
    } catch {
        Issue.record("Expected GenerationError, got \(error).")
    }
}

@Test
func crisisMomentDoesNotCallAnyDraftClient() async {
    let privateClient = RecordingMomentDraftClient(
        bundle: MomentDraftBundle(messageText: "Private.", lane: .privateDraft)
    )
    let carefulClient = RecordingMomentDraftClient(
        bundle: MomentDraftBundle(messageText: "Careful.", lane: .takeMoreCare)
    )
    let service = RoutingMessageWritingService(
        privateClient: privateClient,
        carefulClient: carefulClient
    )

    do {
        _ = try await service.draft(for: MomentInput(
            personName: "Alex",
            relationship: .closeFriend,
            occasion: .thinkingOfYou,
            trueThing: "I want to die."
        ))
        Issue.record("Expected crisis moment to stop before drafting.")
    } catch let error as GenerationError {
        #expect(error.userSafeMessage == "This needs immediate support, not a draft.")
    } catch {
        Issue.record("Expected GenerationError, got \(error).")
    }

    #expect(await privateClient.draftCallCount == 0)
    #expect(await carefulClient.draftCallCount == 0)
}

@Test
func takeMoreCareUsesCarefulRefinementWithCurrentDraft() async throws {
    let privateClient = RecordingMomentDraftClient(
        bundle: MomentDraftBundle(messageText: "Private hello.", lane: .privateDraft)
    )
    let carefulClient = RefiningMomentDraftClient(
        bundle: MomentDraftBundle(messageText: "Careful hello.", lane: .takeMoreCare)
    )
    let service = RoutingMessageWritingService(
        privateClient: privateClient,
        carefulClient: carefulClient
    )
    let currentBundle = MomentDraftBundle(
        messageText: "Happy birthday. I hope today is lovely.",
        lane: .privateDraft
    )

    let bundle = try await service.takeMoreCare(
        currentBundle,
        moment: MomentInput(
            personName: "Alex",
            relationship: .closeFriend,
            occasion: .birthday
        )
    )

    #expect(bundle.messageText == "Careful hello.")
    #expect(bundle.lane == .takeMoreCare)
    #expect(await privateClient.draftCallCount == 0)
    #expect(await carefulClient.refineCallCount == 1)
    #expect(await carefulClient.lastCurrentMessage == "Happy birthday. I hope today is lovely.")
}

@Test
func takeMoreCareCarefulFailureFallsBackToPrivateDraft() async throws {
    let privateClient = RecordingMomentDraftClient(
        bundle: MomentDraftBundle(messageText: "Private fallback.", lane: .privateDraft)
    )
    let carefulClient = FailingMomentDraftClient(
        error: GenerationError.usageLimitReached(message: "Premium unavailable.")
    )
    let service = RoutingMessageWritingService(
        privateClient: privateClient,
        carefulClient: carefulClient
    )

    let bundle = try await service.takeMoreCare(
        MomentDraftBundle(messageText: "A quick draft.", lane: .privateDraft),
        moment: MomentInput(
            personName: "Alex",
            relationship: .closeFriend,
            occasion: .birthday
        )
    )

    #expect(bundle.messageText == "Private fallback.")
    #expect(bundle.lane == .privateDraft)
    #expect(await privateClient.draftCallCount == 1)
}

@Test
func takeMoreCareFallsBackToCarefulDraftWhenClientCannotRefine() async throws {
    let privateClient = RecordingMomentDraftClient(
        bundle: MomentDraftBundle(messageText: "Private hello.", lane: .privateDraft)
    )
    let carefulClient = RecordingMomentDraftClient(
        bundle: MomentDraftBundle(messageText: "Careful new draft.", lane: .takeMoreCare)
    )
    let service = RoutingMessageWritingService(
        privateClient: privateClient,
        carefulClient: carefulClient
    )
    let currentBundle = MomentDraftBundle(
        messageText: "Happy birthday. I hope today is lovely.",
        lane: .privateDraft
    )

    let bundle = try await service.takeMoreCare(
        currentBundle,
        moment: MomentInput(
            personName: "Alex",
            relationship: .closeFriend,
            occasion: .birthday
        )
    )

    #expect(bundle.messageText == "Careful new draft.")
    #expect(bundle.lane == .takeMoreCare)
    #expect(await privateClient.draftCallCount == 0)
    #expect(await carefulClient.draftCallCount == 1)
}

@Test
func adjustPrivateDraftFallsThroughToCarefulClientWhenPrivateIsUnavailable() async throws {
    let privateClient = FailingMomentDraftClient(
        error: GenerationError.serviceUnavailable(message: "Private draft unavailable.")
    )
    let carefulClient = RecordingMomentDraftClient(
        bundle: MomentDraftBundle(messageText: "Careful warmer draft.", lane: .takeMoreCare)
    )
    let service = RoutingMessageWritingService(
        privateClient: privateClient,
        carefulClient: carefulClient
    )

    let bundle = try await service.adjust(
        MomentDraftBundle(messageText: "A first draft.", lane: .privateDraft),
        with: .warmer,
        moment: MomentInput(
            personName: "Alex",
            relationship: .closeFriend,
            occasion: .birthday
        )
    )

    #expect(bundle.messageText == "Careful warmer draft.")
    #expect(bundle.lane == .standardDraft)
    #expect(await carefulClient.adjustCallCount == 1)
}

@Test
func savedMomentDraftRecordPreservesMomentMetadata() {
    let createdAt = Date(timeIntervalSince1970: 1_800_000_000)
    let moment = MomentInput(
        personName: "Mum",
        relationship: .parent,
        occasion: .mothersDay,
        register: .confess,
        trueThing: "You always show up.",
        tone: .heartfelt,
        length: .brief
    )

    let record = SavedMomentDraftRecord(
        moment: moment,
        messageText: "Thank you for always showing up.",
        lane: .takeMoreCare,
        createdAt: createdAt
    )

    #expect(record.title == "Mum")
    #expect(record.subtitle == "Mother's Day · Parent")
    #expect(record.relationship == Relationship.parent)
    #expect(record.occasion == Occasion.mothersDay)
    #expect(record.register == MomentRegister.confess)
    #expect(record.tone == Tone.heartfelt)
    #expect(record.length == MessageLength.brief)
    #expect(record.lane == MomentDraftLane.takeMoreCare)
    #expect(record.trueThing == "You always show up.")
    #expect(record.createdAt == createdAt)
}

private actor RecordingMomentDraftClient: MomentDraftClient {
    private let bundle: MomentDraftBundle
    private(set) var draftCallCount = 0
    private(set) var adjustCallCount = 0

    init(bundle: MomentDraftBundle) {
        self.bundle = bundle
    }

    func draft(for moment: MomentInput) async throws -> MomentDraftBundle {
        draftCallCount += 1
        return bundle
    }

    func adjust(
        _ bundle: MomentDraftBundle,
        with adjustment: MomentAdjustment,
        moment: MomentInput
    ) async throws -> MomentDraftBundle {
        adjustCallCount += 1
        return self.bundle
    }
}

private actor RecordingCardMessageWritingClient: MessageWritingClient {
    private let response: CardResponse
    private(set) var requests: [CardRequest] = []

    init(response: CardResponse) {
        self.response = response
    }

    var firstRequestedLane: GenerationLane? {
        requests.first?.requestedLane
    }

    func generateCard(request: CardRequest) async throws -> CardResponse {
        requests.append(request)
        return response
    }
}

private struct FailingCardMessageWritingClient: MessageWritingClient {
    let error: GenerationError

    func generateCard(request: CardRequest) async throws -> CardResponse {
        throw error
    }
}

private struct FailingMomentDraftClient: MomentDraftClient {
    let error: GenerationError

    func draft(for moment: MomentInput) async throws -> MomentDraftBundle {
        throw error
    }

    func adjust(
        _ bundle: MomentDraftBundle,
        with adjustment: MomentAdjustment,
        moment: MomentInput
    ) async throws -> MomentDraftBundle {
        throw error
    }
}

private actor CancellationRecordingMomentDraftClient: MomentDraftClient {
    private(set) var didObserveCancellation = false

    func draft(for moment: MomentInput) async throws -> MomentDraftBundle {
        do {
            try await Task.sleep(for: .seconds(5))
            return MomentDraftBundle(messageText: "Too late.", lane: .privateDraft)
        } catch is CancellationError {
            didObserveCancellation = true
            throw CancellationError()
        }
    }

    func adjust(
        _ bundle: MomentDraftBundle,
        with adjustment: MomentAdjustment,
        moment: MomentInput
    ) async throws -> MomentDraftBundle {
        try await draft(for: moment)
    }
}

private actor RefiningMomentDraftClient: MomentDraftRefinementClient {
    private let bundle: MomentDraftBundle
    private(set) var refineCallCount = 0
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
        refineCallCount += 1
        lastCurrentMessage = currentMessage
        return bundle
    }
}
