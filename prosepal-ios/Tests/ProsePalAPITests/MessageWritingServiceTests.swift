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
func privateUnavailabilityFallsThroughToCarefulClient() async throws {
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
    #expect(bundle.lane == .takeMoreCare)
    #expect(await carefulClient.draftCallCount == 1)
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
func savedMomentDraftRecordPreservesMomentMetadata() {
    let createdAt = Date(timeIntervalSince1970: 1_800_000_000)
    let moment = MomentInput(
        personName: "Mum",
        relationship: .parent,
        occasion: .mothersDay,
        register: .confess,
        trueThing: "You always show up.",
        tone: .heartfelt,
        length: .brief,
        spellingPreference: .uk
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
        self.bundle
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
