import Foundation
import ProsePalAPI
import ProsePalDomain
import Testing

private final class TestOnlineWritingPermissionStore: OnlineWritingPermissionStoring, @unchecked Sendable {
    private var permissionState: OnlineWritingPermissionState

    init(state: OnlineWritingPermissionState = .currentGrant) {
        permissionState = state
    }

    func state() -> OnlineWritingPermissionState { permissionState }
    func grantCurrentPolicy() { permissionState = .currentGrant }
    func revoke() { permissionState = .notGranted }
}

private func grantedOnlineWritingPermissionStore() -> TestOnlineWritingPermissionStore {
    TestOnlineWritingPermissionStore()
}

@Test
func everydayMomentRoutesToPrivateClient() async throws {
    let privateClient = RecordingMomentDraftClient(
        bundle: MomentDraftBundle(messageText: "Private hello.", lane: .privateDraft)
    )
    let carefulClient = RecordingMomentDraftClient(
        bundle: MomentDraftBundle(messageText: "Careful hello.", lane: .careful)
    )
    let service = RoutingMessageWritingService(
        onlineWritingPermissionStore: grantedOnlineWritingPermissionStore(),
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
func privateRouteDoesNotRequireOnlineWritingPermission() async throws {
    let privateClient = RecordingMomentDraftClient(
        bundle: MomentDraftBundle(messageText: "Private hello.", lane: .privateDraft)
    )
    let carefulClient = RecordingMomentDraftClient(
        bundle: MomentDraftBundle(messageText: "Forbidden online draft.", lane: .careful)
    )
    let service = RoutingMessageWritingService(
        onlineWritingPermissionStore: TestOnlineWritingPermissionStore(state: .notGranted),
        privateClient: privateClient,
        carefulClient: carefulClient
    )

    let bundle = try await service.draft(for: MomentInput(
        personName: "Alex",
        relationship: .closeFriend,
        occasion: .birthday
    ))

    #expect(bundle.messageText == "Private hello.")
    #expect(await privateClient.draftCallCount == 1)
    #expect(await carefulClient.draftCallCount == 0)
}

@Test
func sensitiveMomentRoutesDirectlyToCarefulClient() async throws {
    let privateClient = RecordingMomentDraftClient(
        bundle: MomentDraftBundle(messageText: "Private sympathy.", lane: .privateDraft)
    )
    let carefulClient = RecordingMomentDraftClient(
        bundle: MomentDraftBundle(messageText: "Careful sympathy.", lane: .careful)
    )
    let service = RoutingMessageWritingService(
        onlineWritingPermissionStore: grantedOnlineWritingPermissionStore(),
        privateClient: privateClient,
        carefulClient: carefulClient
    )

    let bundle = try await service.draft(for: MomentInput(
        personName: "Sam",
        relationship: .family,
        occasion: .sympathy
    ))

    #expect(bundle.messageText == "Careful sympathy.")
    #expect(bundle.lane == .careful)
    #expect(await privateClient.draftCallCount == 0)
    #expect(await carefulClient.draftCallCount == 1)
}

@Test
func directCarefulRouteRequiresCurrentOnlineWritingPermission() async {
    let privateClient = RecordingMomentDraftClient(
        bundle: MomentDraftBundle(messageText: "Forbidden private draft.", lane: .privateDraft)
    )
    let carefulClient = RecordingMomentDraftClient(
        bundle: MomentDraftBundle(messageText: "Forbidden online draft.", lane: .careful)
    )
    let service = RoutingMessageWritingService(
        onlineWritingPermissionStore: TestOnlineWritingPermissionStore(state: .notGranted),
        privateClient: privateClient,
        carefulClient: carefulClient
    )

    await expectOnlineWritingPermissionRequired {
        try await service.draft(for: MomentInput(
            personName: "Sam",
            relationship: .family,
            occasion: .sympathy
        ))
    }

    #expect(await privateClient.draftCallCount == 0)
    #expect(await carefulClient.draftCallCount == 0)
}

@Test
func privateFallbackRequiresCurrentOnlineWritingPermission() async {
    let privateClient = FailingMomentDraftClient(
        error: .serviceUnavailable(message: "Private writing is unavailable.")
    )
    let carefulClient = RecordingMomentDraftClient(
        bundle: MomentDraftBundle(messageText: "Forbidden online fallback.", lane: .careful)
    )
    let service = RoutingMessageWritingService(
        onlineWritingPermissionStore: TestOnlineWritingPermissionStore(state: .notGranted),
        privateClient: privateClient,
        carefulClient: carefulClient
    )

    await expectOnlineWritingPermissionRequired {
        try await service.draft(for: MomentInput(
            personName: "Taylor",
            relationship: .colleague,
            occasion: .newJob
        ))
    }

    #expect(await carefulClient.draftCallCount == 0)
}

@Test(arguments: [MomentDraftLane.privateDraft, .standardDraft, .careful])
func onlineAdjustmentRequiresCurrentPermissionAndNeverCallsCarefulClient(
    lane: MomentDraftLane
) async {
    let privateClient = FailingMomentDraftClient(
        error: .serviceUnavailable(message: "Private adjustment is unavailable.")
    )
    let carefulClient = RecordingMomentDraftClient(
        bundle: MomentDraftBundle(messageText: "Forbidden online adjustment.", lane: .careful)
    )
    let service = RoutingMessageWritingService(
        onlineWritingPermissionStore: TestOnlineWritingPermissionStore(state: .notGranted),
        privateClient: privateClient,
        carefulClient: carefulClient
    )

    await expectOnlineWritingPermissionRequired {
        try await service.adjust(
            MomentDraftBundle(messageText: "Keep this draft.", lane: lane),
            with: .warmer,
            moment: MomentInput(
                personName: "Alex",
                relationship: .closeFriend,
                occasion: .birthday
            )
        )
    }

    #expect(await carefulClient.adjustCallCount == 0)
}

@Test
func currentGrantAllowsOnlineAdjustment() async throws {
    let carefulClient = RecordingMomentDraftClient(
        bundle: MomentDraftBundle(messageText: "Allowed online adjustment.", lane: .careful)
    )
    let service = RoutingMessageWritingService(
        onlineWritingPermissionStore: grantedOnlineWritingPermissionStore(),
        privateClient: carefulClient,
        carefulClient: carefulClient
    )

    let bundle = try await service.adjust(
        MomentDraftBundle(messageText: "Current draft.", lane: .standardDraft),
        with: .moreDirect,
        moment: MomentInput(
            personName: "Alex",
            relationship: .closeFriend,
            occasion: .birthday
        )
    )

    #expect(bundle.messageText == "Allowed online adjustment.")
    #expect(await carefulClient.adjustCallCount == 1)
}

@Test
func revocationBlocksTheNextOnlineCallOnTheSameService() async throws {
    let permissionStore = TestOnlineWritingPermissionStore()
    let carefulClient = RecordingMomentDraftClient(
        bundle: MomentDraftBundle(messageText: "Allowed first draft.", lane: .careful)
    )
    let service = RoutingMessageWritingService(
        onlineWritingPermissionStore: permissionStore,
        privateClient: carefulClient,
        carefulClient: carefulClient
    )
    let moment = MomentInput(
        personName: "Sam",
        relationship: .family,
        occasion: .sympathy
    )

    _ = try await service.draft(for: moment)
    #expect(await carefulClient.draftCallCount == 1)

    permissionStore.revoke()
    await expectOnlineWritingPermissionRequired {
        try await service.draft(for: moment)
    }

    #expect(await carefulClient.draftCallCount == 1)
}

@Test(arguments: [OnlineWritingPermissionState.notGranted, .stalePolicyGrant])
func revokedOrStaleGrantBlocksEverySubsequentOnlineCall(
    state: OnlineWritingPermissionState
) async {
    let permissionStore = TestOnlineWritingPermissionStore(
        state: state == .stalePolicyGrant ? .stalePolicyGrant : .currentGrant
    )
    if state == .notGranted {
        permissionStore.revoke()
    }
    let carefulClient = RecordingMomentDraftClient(
        bundle: MomentDraftBundle(messageText: "Forbidden online draft.", lane: .careful)
    )
    let service = RoutingMessageWritingService(
        onlineWritingPermissionStore: permissionStore,
        privateClient: carefulClient,
        carefulClient: carefulClient
    )

    await expectOnlineWritingPermissionRequired {
        try await service.draft(for: MomentInput(
            personName: "Sam",
            relationship: .family,
            occasion: .sympathy
        ))
    }

    #expect(await carefulClient.draftCallCount == 0)
}

@Test
func gatewayCarefulClientRequestsWorkingStandardLaneButReturnsCarefulProductLane() async throws {
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
    #expect(bundle.lane == .careful)
    #expect(await cardClient.firstRequestedLane == .standard)
}

@Test
func gatewayAdjustmentUsesOnlyNamedAdjustmentAndCurrentDraftContext() async throws {
    let cardClient = RecordingCardMessageWritingClient(response: CardResponse(
        messages: [GeneratedMessage(id: "direct-1", text: "A direct gateway draft.")],
        laneUsed: .standard,
        fallbackStatus: .none,
        retryEligibility: .ineligible
    ))
    let client = GatewayCarefulMomentClient(
        client: cardClient,
        clientContext: ClientContext(appVersion: "0.0.0", buildNumber: "1")
    )
    let original = MomentDraftBundle(
        messageText: "Please tell me that everything is okay.",
        lane: .careful
    )

    _ = try await client.adjust(
        original,
        with: .moreDirect,
        moment: MomentInput(
            personName: "Sam",
            relationship: .family,
            occasion: .sympathy
        )
    )

    let intent = await cardClient.firstIntent
    #expect(intent?.thingsToInclude.contains("Please make the message direct.") == true)
    #expect(intent?.userContext?.contains("Current message to reshape: \(original.messageText)") == true)
    #expect(intent?.userContext?.localizedCaseInsensitiveContains("take more care") == false)
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
        onlineWritingPermissionStore: grantedOnlineWritingPermissionStore(),
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
        onlineWritingPermissionStore: grantedOnlineWritingPermissionStore(),
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
        onlineWritingPermissionStore: grantedOnlineWritingPermissionStore(),
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
        bundle: MomentDraftBundle(messageText: "Careful fallback.", lane: .careful)
    )
    let service = RoutingMessageWritingService(
        onlineWritingPermissionStore: grantedOnlineWritingPermissionStore(),
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
func unexpectedPrivateClientFailureFallsThroughToStandardGatewayDraft() async throws {
    let privateClient = UnexpectedlyFailingMomentDraftClient()
    let carefulClient = RecordingMomentDraftClient(
        bundle: MomentDraftBundle(messageText: "Careful fallback.", lane: .careful)
    )
    let service = RoutingMessageWritingService(
        onlineWritingPermissionStore: grantedOnlineWritingPermissionStore(),
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
        bundle: MomentDraftBundle(messageText: "Careful fallback.", lane: .careful)
    )
    let service = RoutingMessageWritingService(
        onlineWritingPermissionStore: grantedOnlineWritingPermissionStore(),
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
        onlineWritingPermissionStore: grantedOnlineWritingPermissionStore(),
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
func cancellationBeforeRoutingDoesNotCallEitherProvider() async {
    let gate = CancellationTestGate()
    let privateClient = RecordingMomentDraftClient(
        bundle: MomentDraftBundle(messageText: "Private.", lane: .privateDraft)
    )
    let carefulClient = RecordingMomentDraftClient(
        bundle: MomentDraftBundle(messageText: "Careful.", lane: .careful)
    )
    let service = RoutingMessageWritingService(
        onlineWritingPermissionStore: grantedOnlineWritingPermissionStore(),
        privateClient: privateClient,
        carefulClient: carefulClient
    )
    let task = Task {
        await gate.wait()
        return try await service.draft(for: cancellationTestMoment)
    }

    task.cancel()
    await gate.open()

    do {
        _ = try await task.value
        Issue.record("Expected cancellation before routing to throw.")
    } catch is CancellationError {
        // Expected.
    } catch {
        Issue.record("Expected CancellationError, got \(error).")
    }

    #expect(await privateClient.draftCallCount == 0)
    #expect(await carefulClient.draftCallCount == 0)
}

@Test(arguments: ServiceCancellationRoute.allCases)
func cancellationDuringProviderWorkNeverStartsFallback(
    route: ServiceCancellationRoute
) async throws {
    let cancellingClient = CancellationDisguisingMomentDraftClient()
    let fallbackClient = RecordingMomentDraftClient(
        bundle: MomentDraftBundle(messageText: "Forbidden fallback.", lane: .privateDraft)
    )
    let service: RoutingMessageWritingService

    service = RoutingMessageWritingService(
        onlineWritingPermissionStore: grantedOnlineWritingPermissionStore(),
        privateClient: cancellingClient,
        carefulClient: fallbackClient
    )

    let task = Task {
        switch route {
        case .draft:
            return try await service.draft(for: cancellationTestMoment)
        case .adjustment:
            return try await service.adjust(
                MomentDraftBundle(messageText: "Original.", lane: .privateDraft),
                with: .warmer,
                moment: cancellationTestMoment
            )
        }
    }

    try await waitForServiceCancellation("\(route) did not reach provider work.") {
        await cancellingClient.startedCount() == 1
    }
    task.cancel()

    do {
        _ = try await task.value
        Issue.record("Expected \(route) cancellation to throw.")
    } catch is CancellationError {
        // Expected.
    } catch {
        Issue.record("Expected CancellationError for \(route), got \(error).")
    }

    #expect(await cancellingClient.cancellationCount() == 1)
    #expect(await fallbackClient.draftCallCount == 0)
    #expect(await fallbackClient.adjustCallCount == 0)
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
            lane: .careful
        )
    )
    let service = RoutingMessageWritingService(
        onlineWritingPermissionStore: grantedOnlineWritingPermissionStore(),
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
        onlineWritingPermissionStore: grantedOnlineWritingPermissionStore(),
        privateClient: RecordingMomentDraftClient(
            bundle: MomentDraftBundle(messageText: "Private.", lane: .privateDraft)
        ),
        carefulClient: RecordingMomentDraftClient(
            bundle: MomentDraftBundle(messageText: "Careful.", lane: .careful)
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
        bundle: MomentDraftBundle(messageText: "Careful.", lane: .careful)
    )
    let service = RoutingMessageWritingService(
        onlineWritingPermissionStore: grantedOnlineWritingPermissionStore(),
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
func adjustPrivateDraftFallsThroughToCarefulClientWhenPrivateIsUnavailable() async throws {
    let privateClient = FailingMomentDraftClient(
        error: GenerationError.serviceUnavailable(message: "Private draft unavailable.")
    )
    let carefulClient = RecordingMomentDraftClient(
        bundle: MomentDraftBundle(messageText: "Careful warmer draft.", lane: .careful)
    )
    let service = RoutingMessageWritingService(
        onlineWritingPermissionStore: grantedOnlineWritingPermissionStore(),
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
func unexpectedPrivateAdjustmentFailureFallsThroughToCarefulClient() async throws {
    let privateClient = UnexpectedlyFailingMomentDraftClient()
    let carefulClient = RecordingMomentDraftClient(
        bundle: MomentDraftBundle(messageText: "Careful warmer draft.", lane: .careful)
    )
    let service = RoutingMessageWritingService(
        onlineWritingPermissionStore: grantedOnlineWritingPermissionStore(),
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
        lane: .careful,
        createdAt: createdAt
    )

    #expect(record.title == "Mum")
    #expect(record.subtitle == "Mother's Day · Parent")
    #expect(record.relationship == Relationship.parent)
    #expect(record.occasion == Occasion.mothersDay)
    #expect(record.register == MomentRegister.confess)
    #expect(record.tone == Tone.heartfelt)
    #expect(record.length == MessageLength.brief)
    #expect(record.lane == MomentDraftLane.careful)
    #expect(record.trueThing == "You always show up.")
    #expect(record.createdAt == createdAt)
}

private func expectOnlineWritingPermissionRequired(
    _ operation: () async throws -> MomentDraftBundle
) async {
    do {
        _ = try await operation()
        Issue.record("Expected online writing permission to be required.")
    } catch let error as GenerationError {
        #expect(error == .onlineWritingPermissionRequired)
    } catch {
        Issue.record("Expected GenerationError, got \(error).")
    }
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

    var firstIntent: CardIntent? {
        requests.first?.intent
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

private struct UnexpectedlyFailingMomentDraftClient: MomentDraftClient {
    private struct UnexpectedPrivateClientError: Error {}

    func draft(for moment: MomentInput) async throws -> MomentDraftBundle {
        throw UnexpectedPrivateClientError()
    }

    func adjust(
        _ bundle: MomentDraftBundle,
        with adjustment: MomentAdjustment,
        moment: MomentInput
    ) async throws -> MomentDraftBundle {
        throw UnexpectedPrivateClientError()
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

enum ServiceCancellationRoute: String, CaseIterable, CustomStringConvertible, Sendable {
    case draft
    case adjustment

    var description: String { rawValue }
}

private actor CancellationDisguisingMomentDraftClient: MomentDraftClient {
    private var started = 0
    private var cancellations = 0

    func draft(for moment: MomentInput) async throws -> MomentDraftBundle {
        try await blockUntilCancelled()
    }

    func adjust(
        _ bundle: MomentDraftBundle,
        with adjustment: MomentAdjustment,
        moment: MomentInput
    ) async throws -> MomentDraftBundle {
        try await blockUntilCancelled()
    }

    func startedCount() -> Int { started }
    func cancellationCount() -> Int { cancellations }

    private func blockUntilCancelled() async throws -> MomentDraftBundle {
        started += 1
        do {
            try await Task.sleep(for: .seconds(60))
            return MomentDraftBundle(messageText: "Too late.", lane: .privateDraft)
        } catch is CancellationError {
            cancellations += 1
            throw GenerationError.serviceUnavailable(
                message: "A cancelled provider must not trigger fallback."
            )
        }
    }
}

private actor CancellationTestGate {
    private var isOpen = false
    private var waiters: [CheckedContinuation<Void, Never>] = []

    func wait() async {
        guard !isOpen else { return }
        await withCheckedContinuation { continuation in
            waiters.append(continuation)
        }
    }

    func open() {
        isOpen = true
        let pending = waiters
        waiters.removeAll()
        pending.forEach { $0.resume() }
    }
}

private func waitForServiceCancellation(
    _ failureMessage: String,
    timeout: Duration = .seconds(5),
    condition: @escaping @Sendable () async -> Bool
) async throws {
    let clock = ContinuousClock()
    let deadline = clock.now.advanced(by: timeout)
    while !(await condition()) {
        guard clock.now < deadline else {
            throw ServiceCancellationWaitTimedOut(message: failureMessage)
        }
        try await Task.sleep(for: .milliseconds(2))
    }
}

private struct ServiceCancellationWaitTimedOut: Error, CustomStringConvertible {
    let message: String

    var description: String { message }
}

private let cancellationTestMoment = MomentInput(
    personName: "Alex",
    relationship: .closeFriend,
    occasion: .birthday
)
