import Foundation
import Observation
import ProsePalAPI
import ProsePalDomain

@MainActor
@Observable
public final class MomentModel {
    public var personName: String = "" {
        didSet { meaningBearingInputDidChange(from: oldValue, to: personName) }
    }
    public var relationship: Relationship = .closeFriend {
        didSet { meaningBearingInputDidChange(from: oldValue, to: relationship) }
    }
    public var occasion: Occasion = .birthday {
        didSet { meaningBearingInputDidChange(from: oldValue, to: occasion) }
    }
    public var register: MomentRegister = .react {
        didSet { meaningBearingInputDidChange(from: oldValue, to: register) }
    }
    public var tone: Tone = .heartfelt {
        didSet { meaningBearingInputDidChange(from: oldValue, to: tone) }
    }
    public var length: MessageLength = .standard {
        didSet { meaningBearingInputDidChange(from: oldValue, to: length) }
    }
    public var trueThing: String = "" {
        didSet { meaningBearingInputDidChange(from: oldValue, to: trueThing) }
    }
    public var bundle: MomentDraftBundle? {
        didSet {
            if Self.pressureDraftKey(for: bundle) != Self.pressureDraftKey(for: oldValue) {
                acknowledgedPressureDraftKey = nil
            }
            persistDraftRecovery()
        }
    }
    public var isDrafting = false
    public var errorMessage: String?
    public var draftUnavailableReason: MomentDraftUnavailableReason?
    public var isOnlineWritingPermissionRequestPresented = false
    public private(set) var draftSnapshots: [MomentDraftSnapshot] = []
    public var previousDraftBundle: MomentDraftBundle? {
        draftSnapshots.last?.bundle
    }
    public var previousDraftSnapshotReason: MomentDraftSnapshotReason? {
        draftSnapshots.last?.reason
    }
    public private(set) var acknowledgedPressureDraftKey: Int?

    @ObservationIgnored private let service: any MessageWritingService
    @ObservationIgnored private let onlineWritingPermissionStore: any OnlineWritingPermissionStoring
    @ObservationIgnored private let diagnostics: NativeDiagnosticsLogger
    @ObservationIgnored private let draftRecoveryStore: any MomentDraftRecoveryStoring
    @ObservationIgnored private var draftTask: Task<Void, Never>?
    @ObservationIgnored private var blockedOnlineWritingRequest: GenerationRequest?
    @ObservationIgnored private var draftGeneration = 0
    @ObservationIgnored private var isBatchUpdatingMeaningBearingInputs = false

    private enum GenerationRequest: Sendable {
        case draft(input: MomentInput, originalBundle: MomentDraftBundle?)
        case adjustment(
            input: MomentInput,
            bundle: MomentDraftBundle,
            adjustment: MomentAdjustment,
            acknowledgePressureResult: Bool
        )

        var trigger: String {
            switch self {
            case .draft:
                "manual"
            case .adjustment(_, _, let adjustment, _):
                "adjust_\(adjustment.rawValue)"
            }
        }

        var input: MomentInput {
            switch self {
            case .draft(let input, _),
                 .adjustment(let input, _, _, _):
                input
            }
        }

        var originalBundle: MomentDraftBundle? {
            switch self {
            case .draft(_, let bundle):
                bundle
            case .adjustment(_, let bundle, _, _):
                bundle
            }
        }

        var acknowledgesPressureResult: Bool {
            switch self {
            case .draft:
                false
            case .adjustment(_, _, _, let acknowledge):
                acknowledge
            }
        }

        var unexpectedErrorMessage: String {
            switch self {
            case .draft:
                "ProsePal could not write this yet."
            case .adjustment:
                "ProsePal could not reshape this yet."
            }
        }
    }

    public init(
        service: any MessageWritingService,
        onlineWritingPermissionStore: any OnlineWritingPermissionStoring = UnconfiguredOnlineWritingPermissionStore(),
        diagnostics: NativeDiagnosticsLogger = .shared,
        draftRecoveryStore: any MomentDraftRecoveryStoring = MomentDraftRecoveryNoopStore()
    ) {
        self.service = service
        self.onlineWritingPermissionStore = onlineWritingPermissionStore
        self.diagnostics = diagnostics
        self.draftRecoveryStore = draftRecoveryStore
        restoreRecoveredDraftIfAvailable()
    }

    public var moment: MomentInput {
        MomentInput(
            personName: personName,
            relationship: relationship,
            occasion: occasion,
            register: register,
            trueThing: trueThing,
            tone: tone,
            length: length
        )
    }

    public var canDraft: Bool {
        moment.allowsDrafting
    }

    public var safetySignal: MomentSafetySignal {
        moment.safetySignal
    }

    public var hasVisiblePressureCheck: Bool {
        guard let bundle, bundle.pressureCheck.hasFindings else { return false }
        return acknowledgedPressureDraftKey != Self.pressureDraftKey(for: bundle)
    }

    public func keepPressureCheckedDraft() {
        guard let bundle, bundle.pressureCheck.hasFindings else { return }
        acknowledgedPressureDraftKey = Self.pressureDraftKey(for: bundle)
    }

    public func cleanUpPressureCheckedDraft() {
        guard let bundle, bundle.pressureCheck.hasFindings else { return }
        adjust(.moreDirect, acknowledgePressureResult: true)
    }

    public func applyLaunchRequest(_ request: MomentLaunchRequest) {
        batchUpdateMeaningBearingInputs {
            if let personName = request.personName {
                self.personName = ProsePalTextInput.personName(personName)
            }
            if let occasion = request.occasion {
                self.occasion = occasion
            }
            if let sharedText = request.sharedText {
                trueThing = ProsePalTextInput.momentDetail(sharedText)
            }
            alignRegisterForMoment()
        }
        resetDraftForMomentChange()
    }

    public func alignRegisterForMoment() {
        if moment.prefersCareRegister && register == .react {
            register = .assemble
        } else if !moment.prefersCareRegister && register == .assemble {
            register = .react
        }
    }

    public func resetDraftForMomentChange() {
        cancelActiveGeneration()
        bundle = nil
        draftSnapshots.removeAll()
        errorMessage = nil
        draftUnavailableReason = nil
        isDrafting = false
    }

    public func startNewMoment() {
        cancelActiveGeneration()
        batchUpdateMeaningBearingInputs {
            personName = ""
            relationship = .closeFriend
            occasion = .birthday
            register = .react
            tone = .heartfelt
            length = .standard
            trueThing = ""
        }
        bundle = nil
        draftSnapshots.removeAll()
        errorMessage = nil
        draftUnavailableReason = nil
        isDrafting = false
        clearDraftRecovery()
    }

    public func startDraft() {
        guard canDraft, !isDrafting else { return }
        launchDraft()
    }

    public func retryDraft() {
        guard canDraft else { return }
        if let blockedOnlineWritingRequest {
            startGeneration(blockedOnlineWritingRequest)
        } else {
            launchDraft()
        }
    }

    public func allowOnlineWritingAndRetry() {
        onlineWritingPermissionStore.grantCurrentPolicy()
        isOnlineWritingPermissionRequestPresented = false
        retryDraft()
    }

    public func deferOnlineWriting() {
        isOnlineWritingPermissionRequestPresented = false
    }

    public func rewriteDraft() {
        guard canDraft else { return }
        launchDraft()
    }

    public func stopGeneration() {
        cancelActiveGeneration()
    }

    public func composerDidDismiss() {
        cancelActiveGeneration()
    }

    public func appDidEnterBackground() {
        cancelActiveGeneration()
    }

    public var canRestorePreviousDraft: Bool {
        previousDraftBundle != nil && !isDrafting
    }

    public var canShowDraftHistory: Bool {
        !draftSnapshots.isEmpty && !isDrafting
    }

    public func restorePreviousDraft() {
        guard let snapshot = draftSnapshots.popLast() else { return }
        cancelActiveGeneration()
        bundle = snapshot.bundle
        errorMessage = nil
        draftUnavailableReason = nil
        isDrafting = false
    }

    public func restoreDraftSnapshot(id: UUID) {
        guard let index = draftSnapshots.firstIndex(where: { $0.id == id }) else { return }
        let snapshot = draftSnapshots[index]
        cancelActiveGeneration()
        draftSnapshots.removeSubrange(index...)
        bundle = snapshot.bundle
        errorMessage = nil
        draftUnavailableReason = nil
        isDrafting = false
    }

    public var previousDraftActionTitle: String {
        previousDraftSnapshotReason == .edit ? "Undo edit" : "Undo rewrite"
    }

    public var keepCurrentDraftActionTitle: String {
        previousDraftSnapshotReason == .edit ? "Keep edits" : "Keep rewrite"
    }

    public var previousDraftActionDiagnosticsName: String {
        previousDraftSnapshotReason == .edit ? "undo_edit" : "undo_rewrite"
    }

    public var keepCurrentDraftActionDiagnosticsName: String {
        previousDraftSnapshotReason == .edit ? "keep_edit" : "keep_rewrite"
    }

    public func keepCurrentRewrite() {
        keepCurrentDraftChange()
    }

    public func keepCurrentDraftChange() {
        guard canRestorePreviousDraft else { return }
        draftSnapshots.removeAll()
        errorMessage = nil
        draftUnavailableReason = nil
        persistDraftRecovery()
    }

    public func updateActiveDraftMessage(_ messageText: String) {
        guard !isDrafting, var currentBundle = bundle else { return }
        guard currentBundle.messageText != messageText else { return }

        if previousDraftSnapshotReason != .edit {
            storeRecoverableDraftSnapshot(currentBundle, reason: .edit)
        }

        currentBundle.messageText = ProsePalTextInput.draft(messageText)
        currentBundle.pressureCheck = .local(messageText: messageText, moment: moment)
        bundle = currentBundle
        errorMessage = nil
        draftUnavailableReason = nil
    }

    private func launchDraft() {
        startGeneration(.draft(input: moment, originalBundle: bundle))
    }

    private func startGeneration(_ request: GenerationRequest) {
        cancelActiveGeneration()
        let generation = draftGeneration
        isDrafting = true
        errorMessage = nil
        draftUnavailableReason = nil
        draftTask = Task { [weak self] in
            await self?.runGeneration(request, generation: generation)
        }
    }

    private func runGeneration(_ request: GenerationRequest, generation: Int) async {
        let requestID = UUID().uuidString
        let startedAt = Date()
        diagnostics.momentDraftStarted(
            requestID: requestID,
            moment: request.input,
            trigger: request.trigger
        )
        defer {
            finishDrafting(generation: generation)
        }

        do {
            try Task.checkCancellation()
            let nextBundle: MomentDraftBundle
            switch request {
            case .draft(let input, _):
                nextBundle = try await service.draft(for: input)
            case .adjustment(let input, let bundle, let adjustment, _):
                nextBundle = try await service.adjust(bundle, with: adjustment, moment: input)
            }
            try Task.checkCancellation()
            guard isCurrentGeneration(generation) else { return }
            storeRecoverableDraftSnapshot(request.originalBundle, reason: .rewrite)
            bundle = nextBundle
            if request.acknowledgesPressureResult {
                acknowledgedPressureDraftKey = Self.pressureDraftKey(for: nextBundle)
            }
            diagnostics.momentDraftSucceeded(
                requestID: requestID,
                bundle: nextBundle,
                durationMs: Self.durationMs(since: startedAt)
            )
        } catch is CancellationError {
            return
        } catch let error as GenerationError {
            guard !Task.isCancelled, isCurrentGeneration(generation) else { return }
            errorMessage = error.userSafeMessage
            draftUnavailableReason = MomentDraftUnavailableReason(error)
            if error == .onlineWritingPermissionRequired {
                blockedOnlineWritingRequest = request
                isOnlineWritingPermissionRequestPresented = true
            }
            diagnostics.momentDraftFailed(
                requestID: requestID,
                category: error.diagnosticsCategory,
                durationMs: Self.durationMs(since: startedAt)
            )
        } catch {
            guard !Task.isCancelled, isCurrentGeneration(generation) else { return }
            errorMessage = request.unexpectedErrorMessage
            draftUnavailableReason = .unexpected
            diagnostics.momentDraftFailed(
                requestID: requestID,
                category: "unexpected_error",
                durationMs: Self.durationMs(since: startedAt)
            )
        }
    }

    public func adjust(_ adjustment: MomentAdjustment) {
        adjust(adjustment, acknowledgePressureResult: false)
    }

    private func adjust(_ adjustment: MomentAdjustment, acknowledgePressureResult: Bool) {
        guard let bundle else { return }
        startGeneration(.adjustment(
            input: moment,
            bundle: bundle,
            adjustment: adjustment,
            acknowledgePressureResult: acknowledgePressureResult
        ))
    }

    private func nextDraftGeneration() -> Int {
        draftGeneration += 1
        return draftGeneration
    }

    private func isCurrentGeneration(_ generation: Int) -> Bool {
        draftGeneration == generation
    }

    private func finishDrafting(generation: Int) {
        if isCurrentGeneration(generation) {
            isDrafting = false
            draftTask = nil
        }
    }

    private func cancelActiveGeneration() {
        draftTask?.cancel()
        draftTask = nil
        blockedOnlineWritingRequest = nil
        isOnlineWritingPermissionRequestPresented = false
        _ = nextDraftGeneration()
        isDrafting = false
    }

    private func meaningBearingInputDidChange<Value: Equatable>(
        from oldValue: Value,
        to newValue: Value
    ) {
        guard !isBatchUpdatingMeaningBearingInputs, oldValue != newValue else { return }
        resetDraftForMomentChange()
    }

    private func batchUpdateMeaningBearingInputs(_ update: () -> Void) {
        isBatchUpdatingMeaningBearingInputs = true
        defer { isBatchUpdatingMeaningBearingInputs = false }
        update()
    }

    private static func durationMs(since startedAt: Date) -> Int {
        max(0, Int(Date().timeIntervalSince(startedAt) * 1_000))
    }

    private func storeRecoverableDraftSnapshot(
        _ bundle: MomentDraftBundle?,
        reason: MomentDraftSnapshotReason
    ) {
        guard let bundle else { return }
        if draftSnapshots.last?.bundle == bundle,
           draftSnapshots.last?.reason == reason {
            return
        }

        draftSnapshots.append(MomentDraftSnapshot(bundle: bundle, reason: reason))
        if draftSnapshots.count > 12 {
            draftSnapshots.removeFirst(draftSnapshots.count - 12)
        }
    }

    private func restoreRecoveredDraftIfAvailable() {
        guard let state = draftRecoveryStore.load() else { return }

        batchUpdateMeaningBearingInputs {
            personName = state.personName
            relationship = state.relationship
            occasion = state.occasion
            register = state.register
            tone = state.tone
            length = state.length
            trueThing = state.trueThing
        }
        draftSnapshots = state.draftSnapshots
        bundle = state.bundle
        errorMessage = nil
        draftUnavailableReason = nil
        isDrafting = false
    }

    private func persistDraftRecovery() {
        guard let bundle else {
            clearDraftRecovery()
            return
        }

        let state = MomentDraftRecoveryState(
            personName: personName,
            relationship: relationship,
            occasion: occasion,
            register: register,
            tone: tone,
            length: length,
            trueThing: trueThing,
            bundle: bundle,
            draftSnapshots: draftSnapshots
        )
        draftRecoveryStore.save(state)
    }

    private func clearDraftRecovery() {
        draftRecoveryStore.clear()
    }

    private static func pressureDraftKey(for bundle: MomentDraftBundle?) -> Int? {
        guard let bundle else { return nil }
        var hasher = Hasher()
        hasher.combine(bundle.messageText)
        hasher.combine(bundle.lane.rawValue)
        hasher.combine(bundle.pressureCheck.asksForReassurance)
        hasher.combine(bundle.pressureCheck.explainsBeforeApology)
        hasher.combine(bundle.pressureCheck.mayFeelTooHeavy)
        for note in bundle.pressureCheck.userVisibleNotes {
            hasher.combine(note)
        }
        return hasher.finalize()
    }
}
