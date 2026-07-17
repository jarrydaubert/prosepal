import Foundation
import ProsePalAPI
import ProsePalDomain
import ProsePalUI
import Testing

@Test(arguments: GenerationEntryPoint.allCases)
@MainActor
func everyGenerationEntryPointUsesTheModelOwnedLifecycle(
    entryPoint: GenerationEntryPoint
) async throws {
    let service = LifecycleRecordingWritingService()
    let model = MomentModel(service: service)
    model.personName = "Alex"

    switch entryPoint {
    case .initialDraft:
        model.startDraft()
    case .retry:
        model.retryDraft()
    case .rewrite:
        model.rewriteDraft()
    case .adjustment:
        model.bundle = MomentDraftBundle(messageText: "Original.", lane: .privateDraft)
        model.adjust(.warmer)
    }

    try await waitForLifecycle("\(entryPoint) did not finish through MomentModel.") {
        await service.calls().count == 1 && !model.isDrafting
    }

    #expect(await service.calls() == [entryPoint.expectedCall])
    #expect(model.bundle?.messageText == entryPoint.expectedMessage)
}

@Test
@MainActor
func cancellationBeforeProviderWorkDoesNotCallTheService() async throws {
    let service = LifecycleRecordingWritingService()
    let model = MomentModel(service: service)
    model.personName = "Alex"

    model.startDraft()
    model.stopGeneration()
    for _ in 0..<5 { await Task.yield() }

    #expect(await service.calls().isEmpty)
    #expect(model.bundle == nil)
    #expect(model.errorMessage == nil)
    #expect(!model.isDrafting)
}

@Test
@MainActor
func retrySupersedesActiveGenerationAndSuppressesItsLateResult() async throws {
    let service = LateResultWritingService()
    let model = MomentModel(service: service)
    model.personName = "Alex"

    model.startDraft()
    try await waitForLifecycle("The initial generation did not start.") {
        await service.callCount() == 1
    }

    model.retryDraft()
    try await waitForLifecycle("The retry did not supersede the initial generation.") {
        await service.callCount() == 2
    }

    await service.resume(at: 1, message: "Retry result.")
    try await waitForLifecycle("The retry result did not become current.") {
        model.bundle?.messageText == "Retry result."
    }

    await service.resume(at: 0, message: "Stale initial result.")
    for _ in 0..<5 { await Task.yield() }

    #expect(model.bundle?.messageText == "Retry result.")
    #expect(!model.isDrafting)
}

@Test(arguments: GenerationCancellationCause.allCases)
@MainActor
func activeGenerationCancelsForEveryLifecycleCause(
    cause: GenerationCancellationCause
) async throws {
    let service = LifecycleBlockingWritingService()
    let model = MomentModel(service: service)
    model.personName = "Alex"
    model.startDraft()

    try await waitForLifecycle("Provider work did not start for \(cause).") {
        await service.startedCount() == 1
    }

    cause.cancel(model)

    try await waitForLifecycle("Provider work did not observe cancellation for \(cause).") {
        await service.cancelledCount() == 1
    }

    #expect(model.bundle == nil)
    #expect(model.errorMessage == nil)
    #expect(!model.isDrafting)
}

@Test(arguments: MeaningBearingMutation.allCases)
@MainActor
func everyMeaningBearingInputMutationCancelsActiveGeneration(
    mutation: MeaningBearingMutation
) async throws {
    let service = LifecycleBlockingWritingService()
    let model = MomentModel(service: service)
    model.personName = "Alex"
    model.startDraft()

    try await waitForLifecycle("Provider work did not start before mutating \(mutation).") {
        await service.startedCount() == 1
    }

    mutation.apply(to: model)

    try await waitForLifecycle("Mutating \(mutation) did not cancel provider work.") {
        await service.cancelledCount() == 1
    }

    #expect(model.bundle == nil)
    #expect(model.errorMessage == nil)
    #expect(!model.isDrafting)
}

@Test
@MainActor
func totalDeadlineCancelsProviderAndDoesNotStartFallback() async throws {
    let privateClient = DeadlineCancellationClient()
    let carefulClient = CountingDeadlineFallbackClient()
    let service = RoutingMessageWritingService(
        privateClient: privateClient,
        carefulClient: carefulClient,
        timeoutPolicy: GenerationTimeoutPolicy(
            onDevice: .seconds(5),
            gateway: .seconds(5),
            total: .milliseconds(25)
        )
    )
    let model = MomentModel(service: service)
    model.personName = "Alex"

    model.startDraft()

    try await waitForLifecycle(
        "The total generation deadline did not finish.",
        timeout: .seconds(2)
    ) {
        !model.isDrafting
    }

    #expect(model.bundle == nil)
    #expect(model.draftUnavailableReason == .timedOut(lane: .total))
    #expect(model.errorMessage == GenerationError.timedOut(lane: .total).userSafeMessage)
    #expect(await privateClient.callCount() == 1)
    #expect(await privateClient.cancellationCount() == 1)
    #expect(await carefulClient.callCount() == 0)
}

enum GenerationEntryPoint: String, CaseIterable, CustomStringConvertible, Sendable {
    case initialDraft
    case retry
    case rewrite
    case adjustment

    var description: String { rawValue }

    var expectedCall: LifecycleGenerationCall {
        switch self {
        case .initialDraft, .retry, .rewrite:
            .draft
        case .adjustment:
            .adjustment
        }
    }

    var expectedMessage: String {
        switch self {
        case .initialDraft, .retry, .rewrite:
            "Draft result."
        case .adjustment:
            "Adjusted result."
        }
    }
}

enum GenerationCancellationCause: String, CaseIterable, CustomStringConvertible, Sendable {
    case stop
    case reset
    case startOver
    case composerDismissal
    case appBackground

    var description: String { rawValue }

    @MainActor
    func cancel(_ model: MomentModel) {
        switch self {
        case .stop:
            model.stopGeneration()
        case .reset:
            model.resetDraftForMomentChange()
        case .startOver:
            model.startNewMoment()
        case .composerDismissal:
            model.composerDidDismiss()
        case .appBackground:
            model.appDidEnterBackground()
        }
    }
}

enum MeaningBearingMutation: String, CaseIterable, CustomStringConvertible, Sendable {
    case personName
    case relationship
    case occasion
    case register
    case tone
    case length
    case trueThing

    var description: String { rawValue }

    @MainActor
    func apply(to model: MomentModel) {
        switch self {
        case .personName:
            model.personName = "Jordan"
        case .relationship:
            model.relationship = .colleague
        case .occasion:
            model.occasion = .thankYou
        case .register:
            model.register = .assemble
        case .tone:
            model.tone = .formal
        case .length:
            model.length = .brief
        case .trueThing:
            model.trueThing = "A new detail"
        }
    }
}

enum LifecycleGenerationCall: Equatable, Sendable {
    case draft
    case adjustment
}

private actor LifecycleRecordingWritingService: MessageWritingService {
    private var recordedCalls: [LifecycleGenerationCall] = []

    func draft(for moment: MomentInput) async throws -> MomentDraftBundle {
        recordedCalls.append(.draft)
        return MomentDraftBundle(messageText: "Draft result.", lane: .privateDraft)
    }

    func adjust(
        _ bundle: MomentDraftBundle,
        with adjustment: MomentAdjustment,
        moment: MomentInput
    ) async throws -> MomentDraftBundle {
        recordedCalls.append(.adjustment)
        return MomentDraftBundle(messageText: "Adjusted result.", lane: bundle.lane)
    }

    func calls() -> [LifecycleGenerationCall] {
        recordedCalls
    }
}

private actor LifecycleBlockingWritingService: MessageWritingService {
    private var started = 0
    private var cancelled = 0

    func draft(for moment: MomentInput) async throws -> MomentDraftBundle {
        try await block()
    }

    func adjust(
        _ bundle: MomentDraftBundle,
        with adjustment: MomentAdjustment,
        moment: MomentInput
    ) async throws -> MomentDraftBundle {
        try await block()
    }

    func startedCount() -> Int { started }
    func cancelledCount() -> Int { cancelled }

    private func block() async throws -> MomentDraftBundle {
        started += 1
        do {
            try await Task.sleep(for: .seconds(60))
            return MomentDraftBundle(messageText: "Too late.", lane: .privateDraft)
        } catch is CancellationError {
            cancelled += 1
            throw CancellationError()
        }
    }
}

private actor LateResultWritingService: MessageWritingService {
    private var continuations: [CheckedContinuation<MomentDraftBundle, Error>] = []

    func draft(for moment: MomentInput) async throws -> MomentDraftBundle {
        try await withCheckedThrowingContinuation { continuation in
            continuations.append(continuation)
        }
    }

    func adjust(
        _ bundle: MomentDraftBundle,
        with adjustment: MomentAdjustment,
        moment: MomentInput
    ) async throws -> MomentDraftBundle {
        try await draft(for: moment)
    }

    func callCount() -> Int { continuations.count }

    func resume(at index: Int, message: String) {
        continuations[index].resume(returning: MomentDraftBundle(
            messageText: message,
            lane: .privateDraft
        ))
    }
}

private actor DeadlineCancellationClient: MomentDraftClient {
    private var calls = 0
    private var cancellations = 0

    func draft(for moment: MomentInput) async throws -> MomentDraftBundle {
        calls += 1
        do {
            try await Task.sleep(for: .seconds(60))
            return MomentDraftBundle(messageText: "Too late.", lane: .privateDraft)
        } catch is CancellationError {
            cancellations += 1
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

    func callCount() -> Int { calls }
    func cancellationCount() -> Int { cancellations }
}

private actor CountingDeadlineFallbackClient: MomentDraftClient {
    private var calls = 0

    func draft(for moment: MomentInput) async throws -> MomentDraftBundle {
        calls += 1
        return MomentDraftBundle(messageText: "Fallback.", lane: .careful)
    }

    func adjust(
        _ bundle: MomentDraftBundle,
        with adjustment: MomentAdjustment,
        moment: MomentInput
    ) async throws -> MomentDraftBundle {
        try await draft(for: moment)
    }

    func callCount() -> Int { calls }
}

@MainActor
private func waitForLifecycle(
    _ failureMessage: String,
    timeout: Duration = .seconds(5),
    condition: @escaping @MainActor () async -> Bool
) async throws {
    let clock = ContinuousClock()
    let deadline = clock.now.advanced(by: timeout)
    while !(await condition()) {
        guard clock.now < deadline else {
            throw LifecycleWaitTimedOut(message: failureMessage)
        }
        try await Task.sleep(for: .milliseconds(2))
    }
}

private struct LifecycleWaitTimedOut: Error, CustomStringConvertible {
    let message: String

    var description: String { message }
}
