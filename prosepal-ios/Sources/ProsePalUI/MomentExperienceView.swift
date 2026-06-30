import Foundation
import ProsePalAPI
import ProsePalDomain
import SwiftData
import SwiftUI
#if canImport(AuthenticationServices)
import AuthenticationServices
#endif
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

public enum MomentDraftUnavailableReason: Equatable, Sendable {
    case offline
    case timedOut
    case rateLimited
    case usageLimitReached
    case contentBlocked
    case serviceUnavailable
    case unexpectedResponse
    case unexpected

    init(_ error: GenerationError) {
        switch error {
        case .offline:
            self = .offline
        case .timedOut:
            self = .timedOut
        case .rateLimited:
            self = .rateLimited
        case .usageLimitReached:
            self = .usageLimitReached
        case .contentBlocked:
            self = .contentBlocked
        case .serviceUnavailable:
            self = .serviceUnavailable
        case .unexpectedResponse:
            self = .unexpectedResponse
        }
    }
}

public enum MomentDraftSnapshotReason: String, Codable, Equatable, Sendable {
    case edit
    case rewrite
}

public struct MomentDraftSnapshot: Codable, Equatable, Identifiable, Sendable {
    public var id: UUID
    public var bundle: MomentDraftBundle
    public var reason: MomentDraftSnapshotReason
    public var createdAt: Date

    public init(
        id: UUID = UUID(),
        bundle: MomentDraftBundle,
        reason: MomentDraftSnapshotReason,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.bundle = bundle
        self.reason = reason
        self.createdAt = createdAt
    }
}

public struct MomentDraftRecoveryState: Codable, Equatable, Sendable {
    public static let schemaVersion = 1

    public var schemaVersion: Int
    public var personName: String
    public var relationship: Relationship
    public var occasion: Occasion
    public var register: MomentRegister
    public var trueThing: String
    public var bundle: MomentDraftBundle
    public var draftSnapshots: [MomentDraftSnapshot]
    public var savedAt: Date

    public init(
        schemaVersion: Int = Self.schemaVersion,
        personName: String,
        relationship: Relationship,
        occasion: Occasion,
        register: MomentRegister,
        trueThing: String,
        bundle: MomentDraftBundle,
        draftSnapshots: [MomentDraftSnapshot],
        savedAt: Date = Date()
    ) {
        self.schemaVersion = schemaVersion
        self.personName = personName.trimmingCharacters(in: .whitespacesAndNewlines)
        self.relationship = relationship
        self.occasion = occasion
        self.register = register
        self.trueThing = trueThing.trimmingCharacters(in: .whitespacesAndNewlines)
        self.bundle = bundle
        self.draftSnapshots = Array(draftSnapshots.suffix(12))
        self.savedAt = savedAt
    }

    public var hasRecoverableDraft: Bool {
        !personName.isEmpty && !bundle.messageText.isEmpty
    }
}

@MainActor
public protocol MomentDraftRecoveryStoring {
    func load() -> MomentDraftRecoveryState?
    func save(_ state: MomentDraftRecoveryState)
    func clear()
}

public struct MomentDraftRecoveryNoopStore: MomentDraftRecoveryStoring {
    public init() {}

    public func load() -> MomentDraftRecoveryState? { nil }
    public func save(_ state: MomentDraftRecoveryState) {}
    public func clear() {}
}

public struct MomentDraftRecoveryStore: MomentDraftRecoveryStoring {
    public static let defaultKey = "prosepal.native.activeDraftRecovery.v1"

    private let store: UserDefaults
    private let key: String

    public init(
        store: UserDefaults = .standard,
        key: String = MomentDraftRecoveryStore.defaultKey
    ) {
        self.store = store
        self.key = key
    }

    public func load() -> MomentDraftRecoveryState? {
        guard let data = store.data(forKey: key),
              let state = try? JSONDecoder().decode(MomentDraftRecoveryState.self, from: data)
        else {
            return nil
        }

        guard state.schemaVersion == MomentDraftRecoveryState.schemaVersion,
              state.hasRecoverableDraft
        else {
            clear()
            return nil
        }

        return state
    }

    public func save(_ state: MomentDraftRecoveryState) {
        guard state.hasRecoverableDraft,
              let data = try? JSONEncoder().encode(state)
        else {
            clear()
            return
        }

        store.set(data, forKey: key)
    }

    public func clear() {
        store.removeObject(forKey: key)
    }
}

@MainActor
@Observable
public final class MomentModel {
    public var personName: String = ""
    public var relationship: Relationship = .closeFriend
    public var occasion: Occasion = .birthday
    public var register: MomentRegister = .react
    public var trueThing: String = ""
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
    public private(set) var draftSnapshots: [MomentDraftSnapshot] = []
    public var previousDraftBundle: MomentDraftBundle? {
        draftSnapshots.last?.bundle
    }
    public var previousDraftSnapshotReason: MomentDraftSnapshotReason? {
        draftSnapshots.last?.reason
    }
    public private(set) var acknowledgedPressureDraftKey: Int?

    @ObservationIgnored private let service: any MessageWritingService
    @ObservationIgnored private let diagnostics: NativeDiagnosticsLogger
    @ObservationIgnored private let generationTimeout: Duration
    @ObservationIgnored private let draftRecoveryStore: any MomentDraftRecoveryStoring
    @ObservationIgnored private var draftTask: Task<Void, Never>?
    @ObservationIgnored private var draftGeneration = 0

    public init(
        service: any MessageWritingService,
        diagnostics: NativeDiagnosticsLogger = .shared,
        generationTimeout: Duration = .seconds(20),
        draftRecoveryStore: any MomentDraftRecoveryStoring = MomentDraftRecoveryNoopStore()
    ) {
        self.service = service
        self.diagnostics = diagnostics
        self.generationTimeout = generationTimeout
        self.draftRecoveryStore = draftRecoveryStore
        restoreRecoveredDraftIfAvailable()
    }

    public var moment: MomentInput {
        MomentInput(
            personName: personName,
            relationship: relationship,
            occasion: occasion,
            register: register,
            trueThing: trueThing
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
        if bundle.lane == .takeMoreCare {
            adjust(.moreDirect, acknowledgePressureResult: true)
        } else {
            takeMoreCare(acknowledgePressureResult: true)
        }
    }

    public func applyLaunchRequest(_ request: MomentLaunchRequest) {
        if let personName = request.personName {
            self.personName = personName
        }
        if let occasion = request.occasion {
            self.occasion = occasion
        }
        if let sharedText = request.sharedText {
            trueThing = sharedText
        }
        alignRegisterForMoment()
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
        draftTask?.cancel()
        _ = nextDraftGeneration()
        bundle = nil
        draftSnapshots.removeAll()
        errorMessage = nil
        draftUnavailableReason = nil
        isDrafting = false
    }

    public func startNewMoment() {
        draftTask?.cancel()
        _ = nextDraftGeneration()
        personName = ""
        relationship = .closeFriend
        occasion = .birthday
        register = .react
        trueThing = ""
        bundle = nil
        draftSnapshots.removeAll()
        errorMessage = nil
        draftUnavailableReason = nil
        isDrafting = false
        clearDraftRecovery()
    }

    public func draftNow() async {
        await draftNow(generation: nextDraftGeneration(), trigger: "manual")
    }

    public var canRestorePreviousDraft: Bool {
        previousDraftBundle != nil && !isDrafting
    }

    public var canShowDraftHistory: Bool {
        !draftSnapshots.isEmpty && !isDrafting
    }

    public func restorePreviousDraft() {
        guard let snapshot = draftSnapshots.popLast() else { return }
        draftTask?.cancel()
        _ = nextDraftGeneration()
        bundle = snapshot.bundle
        errorMessage = nil
        draftUnavailableReason = nil
        isDrafting = false
    }

    public func restoreDraftSnapshot(id: UUID) {
        guard let index = draftSnapshots.firstIndex(where: { $0.id == id }) else { return }
        let snapshot = draftSnapshots[index]
        draftTask?.cancel()
        _ = nextDraftGeneration()
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

        currentBundle.messageText = messageText
        currentBundle.pressureCheck = .local(messageText: messageText, moment: moment)
        bundle = currentBundle
        errorMessage = nil
        draftUnavailableReason = nil
    }

    private func draftNow(generation: Int, trigger: String = "automatic") async {
        guard canDraft else { return }
        let input = moment
        let originalBundle = bundle
        let requestID = UUID().uuidString
        let startedAt = Date()
        isDrafting = true
        errorMessage = nil
        draftUnavailableReason = nil
        diagnostics.momentDraftStarted(
            requestID: requestID,
            moment: input,
            trigger: trigger
        )
        defer {
            finishDrafting(generation: generation)
        }

        do {
            let nextBundle = try await withGenerationTimeout {
                try await self.service.draft(for: input)
            }
            guard isCurrentGeneration(generation) else { return }
            storeRecoverableDraftSnapshot(originalBundle, reason: .rewrite)
            bundle = nextBundle
            diagnostics.momentDraftSucceeded(
                requestID: requestID,
                bundle: nextBundle,
                durationMs: Self.durationMs(since: startedAt)
            )
        } catch is CancellationError {
            return
        } catch let error as GenerationError {
            guard isCurrentGeneration(generation) else { return }
            errorMessage = error.userSafeMessage
            draftUnavailableReason = MomentDraftUnavailableReason(error)
            diagnostics.momentDraftFailed(
                requestID: requestID,
                category: error.diagnosticsCategory,
                durationMs: Self.durationMs(since: startedAt)
            )
        } catch {
            guard isCurrentGeneration(generation) else { return }
            errorMessage = "ProsePal could not write this yet."
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
        draftTask?.cancel()
        let generation = nextDraftGeneration()
        draftTask = Task { [weak self, bundle] in
            await self?.adjustNow(
                bundle,
                adjustment: adjustment,
                generation: generation,
                acknowledgePressureResult: acknowledgePressureResult
            )
        }
    }

    public func takeMoreCare() {
        takeMoreCare(acknowledgePressureResult: false)
    }

    private func takeMoreCare(acknowledgePressureResult: Bool) {
        guard canDraft else { return }
        draftTask?.cancel()
        let generation = nextDraftGeneration()
        let currentBundle = bundle
        draftTask = Task { [weak self, currentBundle] in
            await self?.takeMoreCareNow(
                currentBundle,
                generation: generation,
                acknowledgePressureResult: acknowledgePressureResult
            )
        }
    }

    private func adjustNow(
        _ bundle: MomentDraftBundle,
        adjustment: MomentAdjustment,
        generation: Int,
        acknowledgePressureResult: Bool
    ) async {
        let input = moment
        let requestID = UUID().uuidString
        let startedAt = Date()
        isDrafting = true
        errorMessage = nil
        draftUnavailableReason = nil
        diagnostics.momentDraftStarted(
            requestID: requestID,
            moment: input,
            trigger: "adjust_\(adjustment.rawValue)"
        )
        defer {
            finishDrafting(generation: generation)
        }

        do {
            let nextBundle = try await withGenerationTimeout {
                try await self.service.adjust(bundle, with: adjustment, moment: input)
            }
            guard isCurrentGeneration(generation) else { return }
            storeRecoverableDraftSnapshot(bundle, reason: .rewrite)
            self.bundle = nextBundle
            if acknowledgePressureResult {
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
            guard isCurrentGeneration(generation) else { return }
            errorMessage = error.userSafeMessage
            draftUnavailableReason = MomentDraftUnavailableReason(error)
            diagnostics.momentDraftFailed(
                requestID: requestID,
                category: error.diagnosticsCategory,
                durationMs: Self.durationMs(since: startedAt)
            )
        } catch {
            guard isCurrentGeneration(generation) else { return }
            errorMessage = "ProsePal could not reshape this yet."
            draftUnavailableReason = .unexpected
            diagnostics.momentDraftFailed(
                requestID: requestID,
                category: "unexpected_error",
                durationMs: Self.durationMs(since: startedAt)
            )
        }
    }

    private func takeMoreCareNow(
        _ bundle: MomentDraftBundle?,
        generation: Int,
        acknowledgePressureResult: Bool
    ) async {
        let input = moment
        let requestID = UUID().uuidString
        let startedAt = Date()
        isDrafting = true
        errorMessage = nil
        draftUnavailableReason = nil
        diagnostics.momentDraftStarted(
            requestID: requestID,
            moment: input,
            trigger: "take_more_care"
        )
        defer {
            finishDrafting(generation: generation)
        }

        do {
            let nextBundle = try await withGenerationTimeout {
                try await self.service.takeMoreCare(bundle, moment: input)
            }
            guard isCurrentGeneration(generation) else { return }
            storeRecoverableDraftSnapshot(bundle, reason: .rewrite)
            self.bundle = nextBundle
            if acknowledgePressureResult {
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
            guard isCurrentGeneration(generation) else { return }
            errorMessage = error.userSafeMessage
            draftUnavailableReason = MomentDraftUnavailableReason(error)
            diagnostics.momentDraftFailed(
                requestID: requestID,
                category: error.diagnosticsCategory,
                durationMs: Self.durationMs(since: startedAt)
            )
        } catch {
            guard isCurrentGeneration(generation) else { return }
            errorMessage = "ProsePal could not take more care with this yet."
            draftUnavailableReason = .unexpected
            diagnostics.momentDraftFailed(
                requestID: requestID,
                category: "unexpected_error",
                durationMs: Self.durationMs(since: startedAt)
            )
        }
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
        }
    }

    private func withGenerationTimeout(
        _ operation: @escaping @Sendable () async throws -> MomentDraftBundle
    ) async throws -> MomentDraftBundle {
        let race = MomentDraftGenerationTimeoutRace()
        let generationTimeout = generationTimeout

        return try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                race.start(
                    continuation: continuation,
                    timeout: generationTimeout,
                    operation: operation
                )
            }
        } onCancel: {
            race.cancel()
        }
    }

    private func clearCancelledDraftingState(generation: Int) {
        if isCurrentGeneration(generation) && isDrafting {
            isDrafting = false
        }
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

        personName = state.personName
        relationship = state.relationship
        occasion = state.occasion
        register = state.register
        trueThing = state.trueThing
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

private final class MomentDraftGenerationTimeoutRace: @unchecked Sendable {
    private let lock = NSLock()
    private var continuation: CheckedContinuation<MomentDraftBundle, Error>?
    private var operationTask: Task<Void, Never>?
    private var timeoutTask: Task<Void, Never>?

    func start(
        continuation: CheckedContinuation<MomentDraftBundle, Error>,
        timeout: Duration,
        operation: @escaping @Sendable () async throws -> MomentDraftBundle
    ) {
        lock.lock()
        self.continuation = continuation
        lock.unlock()

        let operationTask = Task {
            do {
                let bundle = try await operation()
                resume(.success(bundle))
            } catch {
                resume(.failure(error))
            }
        }

        let timeoutTask = Task {
            do {
                try await Task.sleep(for: timeout)
                resume(.failure(GenerationError.timedOut))
            } catch {
                return
            }
        }

        lock.lock()
        self.operationTask = operationTask
        self.timeoutTask = timeoutTask
        lock.unlock()
    }

    func cancel() {
        resume(.failure(CancellationError()))
    }

    private func resume(_ result: Result<MomentDraftBundle, Error>) {
        lock.lock()
        guard let continuation else {
            lock.unlock()
            return
        }
        self.continuation = nil
        let operationTask = operationTask
        let timeoutTask = timeoutTask
        self.operationTask = nil
        self.timeoutTask = nil
        lock.unlock()

        operationTask?.cancel()
        timeoutTask?.cancel()
        continuation.resume(with: result)
    }
}

private struct MomentDraftUnavailableNotice {
    var title: String
    var detail: String
    var systemImage: String
    var canRetry: Bool
}

private struct MomentShareRequest: Identifiable {
    let id = UUID()
    let activityItems: [Any]

    static func text(_ text: String) -> MomentShareRequest {
        MomentShareRequest(activityItems: [text])
    }
}

private struct MomentVoiceCaptureSheet: View {
    @Bindable var capture: MomentVoiceCaptureModel
    @Environment(\.dismiss) private var dismiss

    let onUseTranscript: (String) -> Void

    private var trimmedTranscript: String {
        capture.transcript.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 8) {
                    Label(statusTitle, systemImage: statusSystemImage)
                        .font(.headline)

                    Text(capture.statusText)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .accessibilityElement(children: .combine)

                ScrollView {
                    Text(transcriptPreview)
                        .font(.body)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .textSelection(.enabled)
                        .padding(16)
                        .background(Color.secondary.opacity(0.09), in: RoundedRectangle(cornerRadius: 14))
                }
                .frame(minHeight: 160)

                Spacer(minLength: 8)

                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 10) {
                        recordControl
                        useTranscriptButton
                    }

                    VStack(spacing: 10) {
                        recordControl
                        useTranscriptButton
                    }
                }
            }
            .padding(20)
            .navigationTitle("Voice Input")
            .toolbarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        capture.reset()
                        dismiss()
                    }
                }
            }
        }
        .onDisappear {
            capture.reset()
        }
    }

    private var statusTitle: String {
        switch capture.state {
        case .idle:
            "Ready"
        case .requestingPermission:
            "Checking access"
        case .recording:
            "Recording"
        case .finished:
            "Review"
        case .unavailable:
            "Unavailable"
        case .failed:
            "Stopped"
        }
    }

    private var statusSystemImage: String {
        switch capture.state {
        case .recording:
            "waveform.circle.fill"
        case .unavailable, .failed:
            "exclamationmark.triangle.fill"
        default:
            "mic.circle.fill"
        }
    }

    private var transcriptPreview: String {
        trimmedTranscript.isEmpty ? "Captured words will appear here." : capture.transcript
    }

    @ViewBuilder
    private var recordControl: some View {
        if capture.isRecording {
            Button {
                capture.stop()
            } label: {
                Label("Stop recording", systemImage: "stop.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.red)
        } else {
            Button {
                Task {
                    await capture.start()
                }
            } label: {
                Label(capture.canUseTranscript ? "Record again" : "Record", systemImage: "mic.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.prosePalCoral)
            .disabled(capture.isRequestingPermission)
        }
    }

    private var useTranscriptButton: some View {
        Button {
            onUseTranscript(trimmedTranscript)
            capture.reset()
            dismiss()
        } label: {
            Label("Use words", systemImage: "checkmark")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
        .disabled(!capture.canUseTranscript)
    }
}

private extension View {
    @ViewBuilder
    func momentShareSheet(_ request: Binding<MomentShareRequest?>) -> some View {
        #if canImport(UIKit)
        sheet(isPresented: Binding(
            get: { request.wrappedValue != nil },
            set: { isPresented in
                if !isPresented {
                    request.wrappedValue = nil
                }
            }
        )) {
            if let request = request.wrappedValue {
                MomentActivityView(activityItems: request.activityItems)
            }
        }
        #else
        self
        #endif
    }
}

#if canImport(UIKit)
private struct MomentActivityView: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
#endif

public struct MomentAppRootView: View {
    @State private var model: MomentModel
    @State private var account: MomentAccountModel
    @State private var welcomeState: MomentWelcomeState
    @State private var selectedTab: MomentRootTab = .moment
    @State private var didLogStartup = false
    @Query(sort: \SavedMomentDraftRecord.createdAt, order: .reverse)
    private var savedDrafts: [SavedMomentDraftRecord]

    private let launchStore: MomentLaunchStore
    private let sharedLaunchStore: SharedMomentLaunchStore
    private let diagnostics: NativeDiagnosticsLogger

    public init(
        service: any MessageWritingService,
        account: MomentAccountModel,
        welcomeState: @autoclosure @escaping () -> MomentWelcomeState = MomentWelcomeState(),
        launchStore: MomentLaunchStore = MomentLaunchStore(),
        sharedLaunchStore: SharedMomentLaunchStore = SharedMomentLaunchStore(),
        diagnostics: NativeDiagnosticsLogger = .shared
    ) {
        _model = State(initialValue: MomentModel(
            service: service,
            draftRecoveryStore: MomentDraftRecoveryStore()
        ))
        _account = State(initialValue: account)
        _welcomeState = State(initialValue: welcomeState())
        self.launchStore = launchStore
        self.sharedLaunchStore = sharedLaunchStore
        self.diagnostics = diagnostics
    }

    public var body: some View {
        Group {
            if welcomeState.hasCompletedWelcome {
                tabs
            } else {
                MomentWelcomeView {
                    welcomeState.completeWelcome()
                }
            }
        }
        .animation(.easeInOut(duration: 0.22), value: welcomeState.hasCompletedWelcome)
        .onAppear {
            logStartupIfNeeded()
            consumePendingLaunch()
        }
        .onChange(of: welcomeState.hasCompletedWelcome) { _, completed in
            if completed {
                consumePendingLaunch()
            }
        }
        .onOpenURL { url in
            consumeDeepLink(url)
        }
        .task {
            await account.loadInitialState()
        }
    }

    private func logStartupIfNeeded() {
        guard !didLogStartup else { return }
        didLogStartup = true
        diagnostics.appStarted(
            hasCompletedOnboarding: welcomeState.hasCompletedWelcome,
            savedMessageCount: savedDrafts.count
        )
        diagnostics.runtimeReadiness(account.runtimeReadiness)
    }

    private func consumePendingLaunch() {
        guard let request = launchStore.consume() else { return }
        applyLaunchRequest(request)
    }

    private func consumeDeepLink(_ url: URL) {
        guard let deepLink = MomentDeepLink(url: url) else { return }
        var request = deepLink.launchRequest
        if request.source == "share_extension",
           let sharedPayload = sharedLaunchStore.consume(),
           let sharedText = sharedPayload.text ?? sharedPayload.sourceURL?.absoluteString {
            request.sharedText = sharedText
        }
        applyLaunchRequest(request)
    }

    private func applyLaunchRequest(_ request: MomentLaunchRequest) {
        selectedTab = .moment
        diagnostics.momentLaunchConsumed(request)
        model.applyLaunchRequest(request)
    }

    private var tabs: some View {
        currentTab
            .safeAreaInset(edge: .bottom) {
                if shouldShowRootDock {
                    MomentRootDock(selection: $selectedTab)
                        .padding(.horizontal, 26)
                        .padding(.bottom, 12)
                }
            }
            .tint(.prosePalCoral)
            .preferredColorScheme(.light)
    }

    private var shouldShowRootDock: Bool {
        if selectedTab == .settings {
            return false
        }
        if selectedTab == .moment {
            return model.bundle == nil && model.errorMessage == nil
        }
        return true
    }

    @ViewBuilder
    private var currentTab: some View {
        switch selectedTab {
        case .moment:
            NavigationStack {
                MomentSheetView(
                    model: model,
                    account: account,
                    onOpenDrafts: {
                        selectedTab = .saved
                    },
                    onOpenSettings: {
                        selectedTab = .settings
                    }
                )
#if os(iOS)
                    .toolbar(.hidden, for: .navigationBar)
#endif
                    .momentNavigationBarColorScheme()
            }

        case .saved:
            NavigationStack {
                SavedMomentDraftsView {
                    selectedTab = .moment
                }
                    .momentNavigationBarColorScheme()
            }

        case .settings:
            NavigationStack {
                MomentSettingsView(account: account) {
                    selectedTab = .moment
                }
                    .momentNavigationBarColorScheme()
            }
        }
    }
}

@MainActor
@Observable
public final class MomentWelcomeState {
    public nonisolated static let defaultCompletionKey = "prosepal.native.momentWelcomeCompleted.v1"

    public private(set) var hasCompletedWelcome: Bool

    @ObservationIgnored private let store: UserDefaults
    @ObservationIgnored private let completionKey: String

    public init(
        store: UserDefaults = .standard,
        completionKey: String = MomentWelcomeState.defaultCompletionKey
    ) {
        self.store = store
        self.completionKey = completionKey
        self.hasCompletedWelcome = store.bool(forKey: completionKey)
    }

    public func completeWelcome() {
        hasCompletedWelcome = true
        store.set(true, forKey: completionKey)
    }
}

private enum MomentRootTab: Hashable {
    case moment
    case saved
    case settings
}

private struct MomentRootDock: View {
    @Binding var selection: MomentRootTab

    var body: some View {
        HStack(spacing: 6) {
            dockButton(
                tab: .saved,
                label: "Drafts",
                systemImage: "rectangle.stack"
            )

            Button {
                selection = .moment
            } label: {
                Image(systemName: "pencil.and.scribble")
                    .font(.title3.weight(.semibold))
                    .frame(width: 46, height: 46)
                    .foregroundStyle(.white)
                    .background(Color.prosePalCoral, in: Circle())
                    .shadow(color: Color.prosePalCoralDeep.opacity(0.24), radius: 12, x: 0, y: 5)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Write")
            .accessibilityAddTraits(selection == .moment ? [.isSelected] : [])

            dockButton(
                tab: .saved,
                label: "Library",
                systemImage: "bookmark"
            )
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .frame(maxWidth: 250)
        .momentControlBarSurface()
    }

    private func dockButton(
        tab: MomentRootTab,
        label: String,
        systemImage: String
    ) -> some View {
        Button {
            selection = tab
        } label: {
            VStack(spacing: 4) {
                Image(systemName: systemImage)
                    .font(.system(size: 18, weight: .medium))

                Text(label)
                    .font(.caption2.weight(.medium))
            }
            .foregroundStyle(selection == tab ? Color.prosePalCoral : Color.prosePalSlate.opacity(0.82))
            .frame(width: 78, height: 46)
            .contentShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selection == tab ? [.isSelected] : [])
    }
}

private struct MomentWelcomeView: View {
    let onStart: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var hasAppeared = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                Spacer(minLength: 44)

                VStack(alignment: .leading, spacing: 14) {
                    Text("Words for the moment.")
                        .font(.system(.largeTitle, design: .serif).weight(.bold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.white, .prosePalCoral.opacity(0.92)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .fixedSize(horizontal: false, vertical: true)

                    Text("Start with who this is for. ProsePal keeps a private draft nearby, then helps you take more care when the moment needs it.")
                        .font(.title3)
                        .foregroundStyle(.white.opacity(0.76))
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(22)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background {
                    MomentHeroBackground(isCareful: false)
                }

                VStack(spacing: 12) {
                    MomentWelcomeRow(
                        systemImage: "person.crop.circle",
                        title: "Person first",
                        detail: "Begin with someone real, not a blank prompt."
                    )
                    MomentWelcomeRow(
                        systemImage: "lock",
                        title: "Private by default",
                        detail: "Relationship details are saved only when you choose."
                    )
                    MomentWelcomeRow(
                        systemImage: "heart.text.square",
                        title: "Care for harder moments",
                        detail: "Sensitive messages stay quieter and lean on your words."
                    )
                }

                Spacer(minLength: 96)
            }
            .padding(.horizontal, 24)
            .padding(.top, 34)
            .opacity(hasAppeared ? 1 : 0)
            .offset(y: reduceMotion || hasAppeared ? 0 : 18)
        }
        .background {
            MomentAtmosphericBackground(isCareful: false)
        }
        .task {
            guard !hasAppeared else { return }
            if reduceMotion {
                hasAppeared = true
            } else {
                withAnimation(.spring(response: 0.56, dampingFraction: 0.88)) {
                    hasAppeared = true
                }
            }
        }
        .tint(.prosePalCoral)
        .safeAreaInset(edge: .bottom) {
            Button {
                onStart()
            } label: {
                Label("Start with someone", systemImage: "arrow.right")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.capsule)
            .tint(.prosePalCoral)
            .controlSize(.large)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .momentControlBarSurface()
        }
    }
}

private struct MomentWelcomeRow: View {
    let systemImage: String
    let title: String
    let detail: String

    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            MomentSymbolBadge(systemImage: systemImage, style: .coral, size: 38)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(detail)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            MomentCardBackground(isCareful: false, prominence: .standard)
        }
        .accessibilityElement(children: .combine)
    }
}

private struct MomentSheetView: View {
    @Bindable var model: MomentModel
    @Bindable var account: MomentAccountModel
    let onOpenDrafts: () -> Void
    let onOpenSettings: () -> Void
    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Query(sort: \RelationshipTruthBeadRecord.updatedAt, order: .reverse)
    private var truthBeads: [RelationshipTruthBeadRecord]
    @Query(sort: \RelationshipVoiceCardRecord.updatedAt, order: .reverse)
    private var voiceCards: [RelationshipVoiceCardRecord]
    @FocusState private var focusedField: Field?
    @State private var saveNotice: String?
    @State private var isShowingRelationshipPicker = false
    @State private var isShowingMomentPicker = false
    @State private var isShowingPaywall = false
    @State private var newTruthBeadText = ""
    @State private var newVoiceCardSummary = ""
    @State private var isAddingTruthBead = false
    @State private var isAddingVoiceCard = false
    @State private var editingTruthBead: RelationshipTruthBeadRecord?
    @State private var editingVoiceCard: RelationshipVoiceCardRecord?
    @State private var isShowingMemoryExplanation = false
    @State private var isShowingVoiceCardExplanation = false
    @State private var isShowingVoiceCapture = false
    @State private var isShowingDraftHistory = false
    @State private var voiceCapture = MomentVoiceCaptureModel()
    @State private var hasCommittedPersonEntry = false
    @State private var hasEntered = false
    @State private var shareRequest: MomentShareRequest?
    @State private var isShowingDraftSource = false
    @State private var isShowingReviseMode = false
    @State private var selectedDraftRevisionTab: DraftRevisionTab = .draft

    private let diagnostics = NativeDiagnosticsLogger.shared

    private enum Field: Hashable {
        case person
        case truth
        case draft
        case memory
        case voice
    }

    private enum ScrollAnchor: Hashable {
        case activePrimary
    }

    private enum DraftRevisionTab: String, CaseIterable, Identifiable {
        case draft
        case changes
        case original

        var id: String { rawValue }

        var title: String {
            switch self {
            case .draft:
                return "Draft"
            case .changes:
                return "Changes"
            case .original:
                return "Original"
            }
        }
    }

    var body: some View {
        GeometryReader { proxy in
            VStack(spacing: 0) {
                topChrome
                    .padding(.horizontal, topChromeHorizontalPadding)
                    .padding(.top, 4)
                    .padding(.bottom, topChromeBottomPadding)

                ScrollViewReader { scrollProxy in
                    ScrollView {
                        momentContent(viewportHeight: proxy.size.height)
                    }
                    .onChange(of: focusedField) { oldValue, newValue in
                        handleFocusChange(from: oldValue, to: newValue, scrollProxy: scrollProxy)
                        handleDraftFocusForRevise(newValue)
                    }
                    .onChange(of: model.occasion) { _, _ in
                        realignActivePrimaryIfNeeded(scrollProxy: scrollProxy, delayNanoseconds: 120_000_000)
                    }
                    .onChange(of: model.bundle?.id) { _, newValue in
                        isShowingDraftSource = false
                        isShowingReviseMode = false
                        if newValue != nil {
                            selectedDraftRevisionTab = .draft
                        }
                        realignActivePrimaryIfNeeded(scrollProxy: scrollProxy, delayNanoseconds: 80_000_000)
                    }
                    .onChange(of: model.errorMessage) { _, _ in
                        realignActivePrimaryIfNeeded(scrollProxy: scrollProxy, delayNanoseconds: 80_000_000)
                    }
                }
            }
        }
        .background {
            MomentAtmosphericBackground(isCareful: model.moment.isCarefulMode)
                .animation(.easeInOut(duration: 0.28), value: model.moment.isCarefulMode)
        }
        .safeAreaInset(edge: .bottom) {
            bottomInsetContent
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    endFocusedEditing()
                }
            }
        }
        .momentTabBarVisibility(isVisible: shouldShowTabRail)
        .sheet(isPresented: $isShowingRelationshipPicker) {
            MomentRelationshipPickerSheet(selection: $model.relationship)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $isShowingMomentPicker) {
            MomentOccasionPickerSheet(selection: $model.occasion)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $isShowingPaywall) {
            MomentPaywallSheet(account: account)
        }
        .sheet(isPresented: $isShowingVoiceCapture) {
            MomentVoiceCaptureSheet(capture: voiceCapture) { transcript in
                applyVoiceTranscript(transcript)
            }
        }
        #if os(iOS)
        .fullScreenCover(isPresented: $isShowingDraftHistory) {
            draftHistorySheet
        }
        #else
        .sheet(isPresented: $isShowingDraftHistory) {
            draftHistorySheet
        }
        #endif
        .momentShareSheet($shareRequest)
        .sheet(item: $editingTruthBead, onDismiss: {
            model.resetDraftForMomentChange()
        }) { bead in
            NavigationStack {
                RelationshipMemoryDetailView(bead: bead)
            }
        }
        .sheet(item: $editingVoiceCard, onDismiss: {
            model.resetDraftForMomentChange()
        }) { voiceCard in
            NavigationStack {
                RelationshipVoiceCardDetailView(voiceCard: voiceCard)
            }
        }
        .alert("Why this appears", isPresented: $isShowingMemoryExplanation) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("You saved this detail for \(currentPersonName). ProsePal uses approved memory only when drafting for this person, and does not log the text.")
        }
        .alert("Why this appears", isPresented: $isShowingVoiceCardExplanation) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("You saved this voice card for \(currentPersonName). ProsePal uses it as style guidance only, and does not log the text.")
        }
        .onChange(of: model.personName) { _, newValue in
            if newValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                hasCommittedPersonEntry = false
            }
            model.resetDraftForMomentChange()
        }
        .onChange(of: model.relationship) { _, newValue in
            diagnostics.selectionChanged(kind: "moment_relationship", value: newValue.rawValue)
            model.resetDraftForMomentChange()
        }
        .onChange(of: model.occasion) { _, newValue in
            diagnostics.selectionChanged(kind: "moment", value: newValue.rawValue)
            model.alignRegisterForMoment()
            model.resetDraftForMomentChange()
        }
        .onChange(of: model.register) { _, newValue in
            diagnostics.selectionChanged(kind: "moment_register", value: newValue.rawValue)
            model.resetDraftForMomentChange()
        }
        .onChange(of: model.trueThing) { _, _ in model.resetDraftForMomentChange() }
        .onAppear {
            if model.bundle != nil && !currentPersonName.isEmpty {
                hasCommittedPersonEntry = true
            }
        }
        .task {
            guard !hasEntered else { return }
            if reduceMotion {
                hasEntered = true
            } else {
                withAnimation(.spring(response: 0.44, dampingFraction: 0.88)) {
                    hasEntered = true
                }
            }
        }
    }

    private func momentContent(viewportHeight: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            if let bundle = model.bundle, isShowingReviseMode {
                draftReviseContent(bundle)
            } else if let bundle = model.bundle, !isShowingDraftSource {
                draftResultContent(bundle)
            } else if !shouldUseActiveMomentLayout {
                initialPrimaryContent
            } else {
                activePrimaryContent
                    .id(ScrollAnchor.activePrimary)
                    .frame(
                        minHeight: shouldHoldSecondaryContentBelowFirstViewport
                            ? activePrimaryViewportHeight(for: viewportHeight)
                            : nil,
                        alignment: .top
                    )

                if model.safetySignal == .crisisSupport {
                    crisisSupportSection
                } else {
                    activeSetupSection
                    memorySection
                    if model.moment.isCarefulMode {
                        carefulModeSection
                    }
                    if shouldShowDraftResultSection {
                        draftSection
                    }
                }
            }
            if let saveNotice {
                Text(saveNotice)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .transition(.opacity)
            }

            Color.clear
                .frame(height: bottomScrollSpacerHeight)
                .accessibilityHidden(true)
        }
        .padding(.horizontal, 20)
        .padding(.top, 0)
        .padding(.bottom, 16)
        .opacity(hasEntered ? 1 : 0)
        .offset(y: reduceMotion || hasEntered ? 0 : 12)
    }

    private var draftHistorySheet: some View {
        Self.MomentDraftHistorySheet(model: model) { snapshot in
            diagnostics.messageAction(
                "restore_draft_history",
                source: "moment_draft",
                messageCharacters: snapshot.bundle.messageText.count
            )
            model.restoreDraftSnapshot(id: snapshot.id)
            isShowingDraftHistory = false
        }
    }

    private var currentPersonName: String {
        model.personName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var bottomScrollSpacerHeight: CGFloat {
        if focusedField != nil {
            return 96
        }
        if model.bundle != nil && isShowingReviseMode {
            return dynamicTypeSize.isAccessibilitySize ? 132 : 96
        }
        if model.bundle != nil && !isShowingDraftSource {
            return dynamicTypeSize.isAccessibilitySize ? 132 : 98
        }
        return model.bundle == nil && model.errorMessage == nil ? 132 : 170
    }

    private var shouldHoldSecondaryContentBelowFirstViewport: Bool {
        focusedField == nil &&
            (model.bundle == nil || isShowingDraftSource) &&
            !currentPersonName.isEmpty &&
            model.safetySignal != .crisisSupport
    }

    private var shouldUseActiveMomentLayout: Bool {
        !currentPersonName.isEmpty && hasCommittedPersonEntry
    }

    private var shouldShowCommittedPersonHeader: Bool {
        !currentPersonName.isEmpty && hasCommittedPersonEntry
    }

    private func activePrimaryViewportHeight(for viewportHeight: CGFloat) -> CGFloat {
        max(viewportHeight + floatingTabRailExclusionHeight, 0)
    }

    private var floatingTabRailExclusionHeight: CGFloat {
        dynamicTypeSize.isAccessibilitySize ? 164 : 136
    }

    private var shouldShowDraftResultSection: Bool {
        model.bundle != nil || model.errorMessage != nil
    }

    private var shouldShowDraftStartSection: Bool {
        model.isDrafting ||
            model.bundle != nil ||
            model.errorMessage != nil ||
            model.safetySignal == .crisisSupport
    }

    private var shouldShowTabRail: Bool {
        focusedField == nil &&
            currentPersonName.isEmpty &&
            !dynamicTypeSize.isAccessibilitySize
    }

    private var shouldShowFloatingDraftActionRail: Bool {
        !dynamicTypeSize.isAccessibilitySize
    }

    @ViewBuilder
    private var bottomInsetContent: some View {
        if let bundle = model.bundle, isShowingReviseMode, focusedField == nil {
            draftRevisionKeepButton(bundle: bundle)
                .padding(.horizontal, 18)
                .padding(.top, 10)
                .padding(.bottom, 12)
        } else if let bundle = model.bundle, focusedField == nil, shouldShowFloatingDraftActionRail {
            draftFloatingControls(bundle: bundle)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .momentControlBarSurface()
        } else {
            MomentBottomRailClearance(isCareful: model.moment.isCarefulMode)
                .frame(height: focusedField == nil ? 76 : 56)
        }
    }

    @ViewBuilder
    private func draftFloatingControls(bundle: MomentDraftBundle) -> some View {
        if isShowingDraftSource {
            actionRail(bundle: bundle)
        } else {
            draftRefineRail(bundle: bundle)
        }
    }

    private var topChromeHorizontalPadding: CGFloat {
        model.bundle != nil && !isShowingDraftSource ? 18 : 20
    }

    private var topChromeBottomPadding: CGFloat {
        model.bundle != nil && !isShowingDraftSource ? 5 : 18
    }

    @ViewBuilder
    private var topChrome: some View {
        if model.bundle != nil && isShowingReviseMode {
            draftReviseTopChrome
        } else if model.bundle != nil && !isShowingDraftSource {
            draftResultTopChrome
        } else {
            momentTopChrome
        }
    }

    private var momentTopChrome: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .center) {
                Button {
                    onOpenDrafts()
                } label: {
                    Image(systemName: "line.3.horizontal")
                        .font(.system(size: 18, weight: .medium))
                        .frame(width: 38, height: 38)
                        .contentShape(Circle())
                }
                .buttonStyle(.plain)
                .foregroundStyle(Color.prosePalCoralDeep)
                .accessibilityLabel("Open drafts")

                Spacer(minLength: 12)

                Button {
                    onOpenSettings()
                } label: {
                    Text(accountInitials)
                        .font(.caption.weight(.semibold))
                        .frame(width: 34, height: 34)
                        .foregroundStyle(Color.prosePalCoralDeep)
                        .background(Color.prosePalCoralCard.opacity(0.42), in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Open settings")
            }
            .frame(minHeight: 42)

            Text("Today")
                .font(.system(size: dynamicTypeSize.isAccessibilitySize ? 34 : 36, design: .serif).weight(.medium))
                .foregroundStyle(Color.prosePalInk)
                .lineLimit(1)
                .minimumScaleFactor(0.84)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var draftResultTopChrome: some View {
        HStack(alignment: .center) {
            Button {
                isShowingReviseMode = false
                isShowingDraftSource = true
            } label: {
                Label("Today", systemImage: "chevron.left")
                    .font(.system(.body, design: .default).weight(.regular))
                    .labelStyle(.titleAndIcon)
                    .lineLimit(1)
                    .minimumScaleFactor(0.88)
                    .frame(minWidth: 76, alignment: .leading)
            }
            .buttonStyle(.plain)
            .foregroundStyle(Color.prosePalCoralDeep)
            .accessibilityLabel("Back to today")

            Spacer(minLength: 8)

            Text("A draft")
                .font(.headline.weight(.semibold))
                .foregroundStyle(Color.prosePalInk)
                .lineLimit(1)

            Spacer(minLength: 8)

            Button {
                if let bundle = model.bundle {
                    save(bundle)
                }
            } label: {
                Image(systemName: "bookmark")
                    .font(.system(size: 19, weight: .regular))
                    .frame(width: 44, height: 44)
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .foregroundStyle(Color.prosePalCoralDeep)
            .accessibilityLabel("Keep this draft")
        }
        .frame(height: 48)
        .frame(maxWidth: .infinity)
    }

    private var draftReviseTopChrome: some View {
        HStack(alignment: .center) {
            Button {
                endFocusedEditing()
                isShowingReviseMode = false
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 17, weight: .regular))
                    .frame(width: 44, height: 44)
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .foregroundStyle(Color.prosePalCoralDeep)
            .accessibilityLabel("Back to draft")

            Spacer(minLength: 8)

            Text("Revise")
                .font(.headline.weight(.semibold))
                .foregroundStyle(Color.prosePalInk)
                .lineLimit(1)

            Spacer(minLength: 8)

            Button {
                endFocusedEditing()
                isShowingReviseMode = false
            } label: {
                Text("Done")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Color.prosePalCoralDeep)
                    .frame(minWidth: 54, minHeight: 44, alignment: .trailing)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Done revising")
        }
        .frame(height: 48)
        .frame(maxWidth: .infinity)
    }

    private var accountInitials: String {
        guard let signedInEmail = account.signedInEmail,
              let firstCharacter = signedInEmail.trimmingCharacters(in: .whitespacesAndNewlines).first
        else {
            return "PP"
        }
        return String(firstCharacter).uppercased()
    }

    private var initialPrimaryContent: some View {
        VStack(alignment: .leading, spacing: 18) {
            personPageSection
            toneSelectorSection
        }
    }

    private var activePrimaryContent: some View {
        VStack(alignment: .leading, spacing: 18) {
            truthSection
            toneSelectorSection
            if shouldShowDraftStartSection {
                draftStartSection
            }
        }
    }

    private func draftResultContent(_ bundle: MomentDraftBundle) -> some View {
        VStack(alignment: .leading, spacing: 13) {
            draftResultCard(bundle)

            if model.hasVisiblePressureCheck {
                pressureCheck(bundle)
            } else {
                draftMarginNote(bundle)
            }

            if dynamicTypeSize.isAccessibilitySize {
                draftRefineRail(bundle: bundle)
                    .padding(.top, 2)
                    .momentControlBarSurface()
            }
        }
    }

    private func draftReviseContent(_ bundle: MomentDraftBundle) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            draftRevisionSegmentedControl
            draftRevisionPage(bundle)
            draftRevisionSuggestionCard(bundle)
            draftRevisionToneRow(bundle)
        }
    }

    private var toneSelectorSection: some View {
        MomentRegisterSelector(
            selection: $model.register,
            registers: availableRegisters,
            isCareful: model.moment.isCarefulMode
        )
    }

    private var draftStartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 12) {
                MomentSymbolBadge(
                    systemImage: model.moment.isCarefulMode ? "heart.text.square" : "square.and.pencil",
                    style: model.moment.isCarefulMode ? .care : .coral,
                    size: 34
                )

                VStack(alignment: .leading, spacing: 3) {
                    Text(draftStartTitle)
                        .font(.subheadline.weight(.semibold))

                    Text(draftStartDetail)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 8)

                if model.isDrafting {
                    ProgressView()
                        .controlSize(.small)
                        .tint(model.moment.isCarefulMode ? .prosePalCare : .prosePalCoral)
                }
            }

            Button {
                focusedField = nil
                Task {
                    await model.draftNow()
                }
            } label: {
                Label(draftStartButtonTitle, systemImage: model.isDrafting ? "hourglass" : "sparkles")
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.capsule)
            .controlSize(.large)
            .tint(model.moment.isCarefulMode ? .prosePalCare : .prosePalCoral)
            .disabled(!model.canDraft || model.isDrafting)
        }
        .padding(14)
        .background {
            MomentCardBackground(
                isCareful: model.moment.isCarefulMode,
                prominence: .accent
            )
        }
    }

    private var draftStartTitle: String {
        if model.isDrafting {
            return "Writing your draft"
        }
        if model.safetySignal == .crisisSupport {
            return "Immediate support first"
        }
        if model.errorMessage != nil {
            return "Ready to try again"
        }
        if model.bundle != nil {
            return "Draft ready"
        }
        return "Ready when you are"
    }

    private var draftStartDetail: String {
        if model.isDrafting {
            return "You can keep editing after this finishes."
        }
        if model.errorMessage != nil {
            return "Nothing new happens until you tap again."
        }
        if model.bundle != nil {
            return "Edit the draft below, or scroll to copy, save, and adjust."
        }
        if model.safetySignal == .crisisSupport {
            return "ProsePal will not draft this as a message."
        }
        if model.canDraft {
            return "Nothing is sent until you tap Write draft."
        }
        return "Add who this is for before writing a draft."
    }

    private var draftStartButtonTitle: String {
        if model.isDrafting {
            return "Writing"
        }
        if model.errorMessage != nil {
            return "Try again"
        }
        if model.bundle != nil {
            return "Rewrite draft"
        }
        if model.safetySignal == .crisisSupport {
            return "Draft unavailable"
        }
        return "Write draft"
    }

    private var writingPageActionTitle: String {
        if model.isDrafting {
            return "Writing"
        }
        if model.errorMessage != nil {
            return "Try again"
        }
        if model.bundle != nil {
            return "Rewrite"
        }
        if model.safetySignal == .crisisSupport {
            return "Draft unavailable"
        }
        return "Help me write"
    }

    private var noteWordCount: Int {
        model.trueThing
            .split { $0.isWhitespace || $0.isNewline }
            .count
    }

    private var noteCountLabel: String {
        if noteWordCount == 1 {
            return "1 word"
        }
        return "\(noteWordCount) words"
    }

    private func handleFocusChange(from oldValue: Field?, to newValue: Field?, scrollProxy: ScrollViewProxy) {
        guard newValue == nil, oldValue == .person || oldValue == .truth else { return }
        realignActivePrimaryIfNeeded(scrollProxy: scrollProxy, delayNanoseconds: 180_000_000)
    }

    private func handleDraftFocusForRevise(_ newValue: Field?) {
        guard newValue == .draft,
              model.bundle != nil,
              !isShowingDraftSource,
              !isShowingReviseMode
        else {
            return
        }

        isShowingReviseMode = true
        focusedField = nil
    }

    private func endFocusedEditing() {
        if !currentPersonName.isEmpty {
            hasCommittedPersonEntry = true
        }
        focusedField = nil
    }

    private func submitPersonEntry(focusNote: Bool = false) {
        guard !currentPersonName.isEmpty else {
            focusedField = nil
            return
        }
        hasCommittedPersonEntry = true
        focusedField = focusNote ? .truth : nil
    }

    private func realignActivePrimaryIfNeeded(
        scrollProxy: ScrollViewProxy,
        delayNanoseconds: UInt64 = 0
    ) {
        guard shouldHoldSecondaryContentBelowFirstViewport else { return }
        Task { @MainActor in
            if delayNanoseconds > 0 {
                try? await Task.sleep(nanoseconds: delayNanoseconds)
            }
            guard shouldHoldSecondaryContentBelowFirstViewport else { return }
            if reduceMotion {
                scrollProxy.scrollTo(ScrollAnchor.activePrimary, anchor: .top)
            } else {
                withAnimation(.snappy(duration: 0.22)) {
                    scrollProxy.scrollTo(ScrollAnchor.activePrimary, anchor: .top)
                }
            }
        }
    }

    private var approvedBeadsForCurrentPerson: [RelationshipTruthBeadRecord] {
        let normalizedName = currentPersonName.momentNormalizedSearchKey
        guard !normalizedName.isEmpty else { return [] }
        return truthBeads.filter {
            $0.isUserApproved && $0.personName.momentNormalizedSearchKey == normalizedName
        }
    }

    private var voiceCardForCurrentPerson: RelationshipVoiceCardRecord? {
        let normalizedName = currentPersonName.momentNormalizedSearchKey
        guard !normalizedName.isEmpty else { return nil }
        return voiceCards.first {
            $0.personName.momentNormalizedSearchKey == normalizedName
        }
    }

    @ViewBuilder
    private var header: some View {
        if shouldUseAccessibilityIntroHeader {
            accessibilityIntroHeader
        } else {
            standardHeader
        }
    }

    private var shouldUseAccessibilityIntroHeader: Bool {
        dynamicTypeSize.isAccessibilitySize && !shouldShowCommittedPersonHeader
    }

    private var accessibilityIntroHeader: some View {
        VStack(alignment: .leading, spacing: 10) {
                Text(model.moment.isCarefulMode ? "TAKE CARE" : "PRIVATE")
                .font(.caption.weight(.bold))
                .foregroundStyle(model.moment.isCarefulMode ? Color.prosePalCare : Color.prosePalCoralDeep)

            Text("Who are you showing up for?")
                .font(.system(.title2, design: .serif).weight(.bold))
                .foregroundStyle(Color.prosePalInk)
                .lineLimit(4)
                .minimumScaleFactor(0.84)
                .fixedSize(horizontal: false, vertical: true)

            Text("Start with the person.")
                .font(.body)
                .foregroundStyle(Color.prosePalSlate)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
        .animation(.easeInOut(duration: 0.24), value: model.moment.isCarefulMode)
    }

    private var standardHeader: some View {
        HStack(alignment: .center, spacing: 16) {
            VStack(alignment: .leading, spacing: 9) {
                Text(model.moment.isCarefulMode ? "EXTRA CARE" : "PRIVATE BY DEFAULT")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(model.moment.isCarefulMode ? Color.prosePalCare : Color.prosePalCoralDeep)
                    .tracking(0.6)

                Text(shouldShowCommittedPersonHeader ? "For \(currentPersonName)" : "Who are you showing up for?")
                    .font(.system(shouldShowCommittedPersonHeader ? .title3 : .title, design: .serif).weight(.bold))
                    .foregroundStyle(Color.prosePalInk)
                    .fixedSize(horizontal: false, vertical: true)

                if !shouldShowCommittedPersonHeader {
                    Text("Start with the person. Shape one true detail, then let the draft form around it.")
                        .font(.callout)
                        .foregroundStyle(Color.prosePalSlate)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Spacer(minLength: 8)

            VStack(spacing: 8) {
                if !shouldShowCommittedPersonHeader {
                    MomentSymbolBadge(
                        systemImage: model.moment.isCarefulMode ? "heart.text.square.fill" : "lock.fill",
                        style: model.moment.isCarefulMode ? .heroCare : .hero,
                        size: 58
                    )
                } else {
                    Button {
                        hasCommittedPersonEntry = false
                        focusedField = nil
                        model.startNewMoment()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.callout.weight(.bold))
                            .frame(width: 34, height: 34)
                            .background(Color.prosePalCoralCard.opacity(0.74), in: Circle())
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(Color.prosePalCoralDeep)
                    .accessibilityLabel("Start over")
                }

                if shouldShowCommittedPersonHeader {
                    Text(model.moment.isCarefulMode ? "Careful" : "Private")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(Color.prosePalSlate)
                }
            }
        }
        .padding(.horizontal, 4)
        .padding(.vertical, shouldShowCommittedPersonHeader ? 8 : 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .animation(.easeInOut(duration: 0.24), value: model.moment.isCarefulMode)
    }

    private var personPageSection: some View {
        MomentWritingPageSurface(
            prompt: "Who is this for?",
            isCareful: model.moment.isCarefulMode,
            showsRules: false,
            minHeight: dynamicTypeSize.isAccessibilitySize ? 96 : 62
        ) {
            TextField("Name or person", text: $model.personName, prompt: Text("Alex, Mum, my manager"))
                .momentNameInputBehavior()
                .submitLabel(.next)
                .onSubmit {
                    submitPersonEntry(focusNote: true)
                }
                .focused($focusedField, equals: .person)
                .font(.system(.title2, design: .serif))
                .foregroundStyle(Color.prosePalInk)
                .textFieldStyle(.plain)
                .accessibilityLabel("Name or person")
        } footer: {
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 12) {
                    Text("Start with the person. The note comes next.")
                        .font(.caption)
                        .foregroundStyle(Color.prosePalSlate)

                    Spacer(minLength: 8)

                    personPageNextButton
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("Start with the person. The note comes next.")
                        .font(.caption)
                        .foregroundStyle(Color.prosePalSlate)

                    personPageNextButton
                }
            }
        }
    }

    private var personPageNextButton: some View {
        Button {
            submitPersonEntry()
        } label: {
            Label("Next", systemImage: "arrow.right")
                .font(.subheadline.weight(.semibold))
                .lineLimit(1)
        }
        .buttonStyle(.borderedProminent)
        .buttonBorderShape(.capsule)
        .controlSize(.regular)
        .tint(model.moment.isCarefulMode ? .prosePalCare : .prosePalCoral)
        .disabled(currentPersonName.isEmpty)
    }

    private var initialSetupSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            MomentSectionLabel(
                title: "Moment setup",
                systemImage: model.moment.isCarefulMode ? "heart.text.square" : "sparkle",
                isCareful: model.moment.isCarefulMode
            )

            TextField("Name or person", text: $model.personName, prompt: Text("Alex, Mum, my manager"))
                .momentNameInputBehavior()
                .submitLabel(.next)
                .onSubmit {
                    submitPersonEntry(focusNote: true)
                }
                .focused($focusedField, equals: .person)
                .font(.title3.weight(.semibold))
                .padding(16)
                .momentInputSurface(isCareful: model.moment.isCarefulMode, cornerRadius: 18)

            Button {
                endFocusedEditing()
                diagnostics.pickerOpened("relationship")
                isShowingRelationshipPicker = true
            } label: {
                MomentSelectionRow(
                    title: "Who they are to you",
                    value: model.relationship.displayName,
                    detail: model.relationship.group.displayName,
                    systemImage: model.relationship.symbolName,
                    isCareful: model.moment.isCarefulMode
                )
            }
            .buttonStyle(.plain)

            Button {
                endFocusedEditing()
                diagnostics.pickerOpened("moment")
                isShowingMomentPicker = true
            } label: {
                MomentSelectionRow(
                    title: "What is the moment?",
                    value: model.occasion.displayName,
                    detail: model.moment.prefersCareRegister ? "Handled with extra care" : model.occasion.group.displayName,
                    systemImage: model.occasion.symbolName,
                    isCareful: model.moment.isCarefulMode
                )
            }
            .buttonStyle(.plain)
        }
        .prosePalMomentCard(isCareful: model.moment.isCarefulMode)
    }

    private var activeSetupSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(spacing: 10) {
                    relationshipSelectionButton(isCondensed: false)
                    momentSelectionButton(isCondensed: false)
                }
            } else {
                HStack(alignment: .top, spacing: 10) {
                    relationshipSelectionButton(isCondensed: true)
                    momentSelectionButton(isCondensed: true)
                }
            }
        }
        .padding(12)
        .background {
            MomentCardBackground(
                isCareful: model.moment.isCarefulMode,
                prominence: .standard
            )
        }
    }

    private func relationshipSelectionButton(isCondensed: Bool) -> some View {
        Button {
            endFocusedEditing()
            diagnostics.pickerOpened("relationship")
            isShowingRelationshipPicker = true
        } label: {
            MomentCompactSelectionRow(
                title: "Relationship",
                value: model.relationship.displayName,
                detail: model.relationship.group.displayName,
                systemImage: model.relationship.symbolName,
                isCondensed: isCondensed,
                isCareful: model.moment.isCarefulMode
            )
        }
        .buttonStyle(.plain)
    }

    private func momentSelectionButton(isCondensed: Bool) -> some View {
        Button {
            endFocusedEditing()
            diagnostics.pickerOpened("moment")
            isShowingMomentPicker = true
        } label: {
            MomentCompactSelectionRow(
                title: "Moment",
                value: model.occasion.displayName,
                detail: model.moment.prefersCareRegister ? "Handled with extra care" : model.occasion.group.displayName,
                systemImage: model.occasion.symbolName,
                isCondensed: isCondensed,
                isCareful: model.moment.isCarefulMode
            )
        }
        .buttonStyle(.plain)
    }

    private var availableRegisters: [MomentRegister] {
        if model.moment.prefersCareRegister {
            return MomentRegister.allCases.filter { $0 != .react }
        }
        return MomentRegister.allCases
    }

    private var truthSection: some View {
        MomentWritingPageSurface(
            prompt: "The note",
            isCareful: model.moment.isCarefulMode,
            minHeight: dynamicTypeSize.isAccessibilitySize ? 150 : 102
        ) {
            TextField(
                "Write the rough version",
                text: $model.trueThing,
                prompt: Text("One true detail. ProsePal will help."),
                axis: .vertical
            )
            .font(.system(.title3, design: .serif))
            .lineSpacing(5)
            .foregroundStyle(Color.prosePalInk)
            .textFieldStyle(.plain)
            .lineLimit(dynamicTypeSize.isAccessibilitySize ? 4...12 : 3...9)
            .focused($focusedField, equals: .truth)
            .submitLabel(.done)
            .onSubmit {
                endFocusedEditing()
            }
            .accessibilityLabel("Moment note")
        } footer: {
            writingPageFooter
        }
    }

    @ViewBuilder
    private var writingPageFooter: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 12) {
                noteTools

                Spacer(minLength: 8)

                writeFromPageButton
            }

            VStack(alignment: .leading, spacing: 12) {
                noteTools
                writeFromPageButton
            }
        }
    }

    private var noteTools: some View {
        HStack(spacing: 10) {
            Button {
                endFocusedEditing()
                voiceCapture.reset()
                diagnostics.messageAction("voice_input_opened", source: "moment", messageCharacters: 0)
                isShowingVoiceCapture = true
            } label: {
                Image(systemName: "mic.fill")
                    .font(.subheadline.weight(.medium))
                    .frame(width: 34, height: 34)
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .foregroundStyle(model.moment.isCarefulMode ? Color.prosePalCare : Color.prosePalCoral)
            .accessibilityLabel("Record moment detail")

            if noteWordCount > 0 {
                Text(noteCountLabel)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.prosePalSlate)
                    .lineLimit(1)
            }
        }
    }

    private var writeFromPageButton: some View {
        Button {
            focusedField = nil
            Task {
                await model.draftNow()
            }
        } label: {
            Label(writingPageActionTitle, systemImage: model.isDrafting ? "hourglass" : "sparkles")
                .font(.subheadline.weight(.semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.82)
                .frame(maxWidth: dynamicTypeSize.isAccessibilitySize ? .infinity : nil)
        }
        .buttonStyle(.borderedProminent)
        .buttonBorderShape(.capsule)
        .controlSize(.regular)
        .tint(model.moment.isCarefulMode ? .prosePalCare : .prosePalCoral)
        .disabled(!model.canDraft || model.isDrafting)
    }

    private var memorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                MomentSectionLabel(title: "Relationship memory", systemImage: "checkmark.seal")

                Text("Only details you save here are reused for \(currentPersonName).")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if shouldShowEmptyMemoryQuickActions {
                emptyMemoryQuickActions
            } else {
                truthBeadControls

                Divider()
                    .padding(.vertical, 2)

                voiceCardControls
            }
        }
        .prosePalMomentCard(prominence: approvedBeadsForCurrentPerson.isEmpty && voiceCardForCurrentPerson == nil ? .standard : .elevated)
    }

    private var shouldShowEmptyMemoryQuickActions: Bool {
        approvedBeadsForCurrentPerson.isEmpty &&
            voiceCardForCurrentPerson == nil &&
            !isAddingTruthBead &&
            !isAddingVoiceCard
    }

    private var emptyMemoryQuickActions: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 8) {
                memoryAddButton(title: "Add detail", systemImage: "plus") {
                    beginAddingTruthBead()
                }
                memoryAddButton(title: "Add voice", systemImage: "waveform") {
                    beginAddingVoiceCard()
                }
            }

            VStack(spacing: 8) {
                memoryAddButton(title: "Add detail", systemImage: "plus") {
                    beginAddingTruthBead()
                }
                memoryAddButton(title: "Add voice", systemImage: "waveform") {
                    beginAddingVoiceCard()
                }
            }
        }
    }

    private var truthBeadControls: some View {
        Group {
            if approvedBeadsForCurrentPerson.isEmpty {
                if isAddingTruthBead {
                    truthBeadInputRow
                } else {
                    compactEmptyMemoryAction(
                        title: "No saved details yet.",
                        actionTitle: "Add detail",
                        systemImage: "plus"
                    ) {
                        beginAddingTruthBead()
                    }
                }
            } else {
                VStack(spacing: 8) {
                    ForEach(approvedBeadsForCurrentPerson) { bead in
                        MomentTruthBeadRow(
                            bead: bead,
                            onEdit: {
                                editingTruthBead = bead
                            },
                            onExplain: {
                                isShowingMemoryExplanation = true
                            },
                            onDelete: {
                                deleteTruthBead(bead)
                            }
                        )
                    }

                    if isAddingTruthBead {
                        truthBeadInputRow
                    } else {
                        memoryAddButton(title: "Add another detail", systemImage: "plus") {
                            beginAddingTruthBead()
                        }
                    }
                }
            }
        }
    }

    private var truthBeadInputRow: some View {
        HStack(spacing: 10) {
            TextField("A detail to remember", text: $newTruthBeadText, prompt: Text("Loves Sunday walks"))
                .focused($focusedField, equals: .memory)
                .submitLabel(.done)
                .padding(14)
                .momentInputSurface(cornerRadius: 16)
                .onSubmit {
                    addTruthBead()
                }

            Button {
                addTruthBead()
            } label: {
                Image(systemName: "plus")
                    .font(.headline.weight(.semibold))
                    .frame(width: 42, height: 42)
            }
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.circle)
            .tint(.prosePalCoral)
            .disabled(newTruthBeadText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .accessibilityLabel("Add relationship memory")
        }
    }

    private func compactEmptyMemoryAction(
        title: String,
        actionTitle: String,
        systemImage: String,
        action: @escaping () -> Void
    ) -> some View {
        HStack(spacing: 10) {
            Text(title)
                .font(.footnote)
                .foregroundStyle(.secondary)

            Spacer(minLength: 8)

            Button(action: action) {
                Label(actionTitle, systemImage: systemImage)
            }
            .buttonStyle(.bordered)
            .buttonBorderShape(.capsule)
            .controlSize(.small)
            .tint(.prosePalCoral)
        }
    }

    private func memoryAddButton(
        title: String,
        systemImage: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                MomentSymbolBadge(systemImage: systemImage, style: .subtle, size: 24)
                Text(title)
                    .font(.caption.weight(.semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.86)
            }
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(Color.prosePalPaper.opacity(0.78), in: Capsule(style: .continuous))
        .overlay {
            Capsule(style: .continuous)
                .stroke(Color.prosePalNavy.opacity(0.14), lineWidth: 1)
        }
        .controlSize(.small)
        .foregroundStyle(Color.prosePalNavy)
    }

    private func beginAddingTruthBead() {
        withAnimation(.easeInOut(duration: 0.18)) {
            isAddingTruthBead = true
        }
        focusedField = .memory
    }

    private func beginAddingVoiceCard() {
        withAnimation(.easeInOut(duration: 0.18)) {
            isAddingVoiceCard = true
        }
        focusedField = .voice
    }

    private var voiceCardControls: some View {
        VStack(alignment: .leading, spacing: 10) {
            VStack(alignment: .leading, spacing: 3) {
                Label("Voice card", systemImage: "waveform")
                    .font(.subheadline.weight(.semibold))

                Text("How messages to \(currentPersonName) should sound.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            if let voiceCard = voiceCardForCurrentPerson {
                MomentVoiceCardRow(
                    voiceCard: voiceCard,
                    onEdit: {
                        editingVoiceCard = voiceCard
                    },
                    onExplain: {
                        isShowingVoiceCardExplanation = true
                    },
                    onDelete: {
                        deleteVoiceCard(voiceCard)
                    }
                )
            } else {
                if isAddingVoiceCard {
                    voiceCardInputRow
                } else {
                    compactEmptyMemoryAction(
                        title: "No voice card yet.",
                        actionTitle: "Add voice",
                        systemImage: "waveform"
                    ) {
                        beginAddingVoiceCard()
                    }
                }
            }
        }
    }

    private var voiceCardInputRow: some View {
        HStack(spacing: 10) {
            TextField("Warm, short, no fuss", text: $newVoiceCardSummary, prompt: Text("Warm, short, no fuss"))
                .focused($focusedField, equals: .voice)
                .submitLabel(.done)
                .padding(14)
                .momentInputSurface(cornerRadius: 16)
                .onSubmit {
                    addVoiceCard()
                }

            Button {
                addVoiceCard()
            } label: {
                Image(systemName: "plus")
                    .font(.headline.weight(.semibold))
                    .frame(width: 42, height: 42)
            }
            .buttonStyle(.bordered)
            .buttonBorderShape(.circle)
            .tint(.prosePalNavy)
            .disabled(newVoiceCardSummary.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .accessibilityLabel("Add voice card")
        }
    }

    private var crisisSupportSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("This needs immediate support", systemImage: "exclamationmark.triangle.fill")
                .font(.headline)
                .foregroundStyle(Color.prosePalWarning)

            Text("ProsePal will not draft this as a message. If you or someone else is in immediate danger, call local emergency services now.")
                .font(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            VStack(alignment: .leading, spacing: 8) {
                Text("UK and Ireland: Samaritans, 116 123.")
                Text("US and Canada: 988 Suicide & Crisis Lifeline.")
                Text("If you can, stay near another person or contact someone you trust.")
            }
            .font(.footnote.weight(.medium))
            .foregroundStyle(.primary)

            HStack(spacing: 10) {
                Link(destination: URL(string: "tel:116123")!) {
                    Label("Call 116 123", systemImage: "phone")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)

                Link(destination: URL(string: "tel:988")!) {
                    Label("Call 988", systemImage: "phone")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            }
            .controlSize(.large)
        }
        .prosePalMomentCard(prominence: .warning)
    }

    private var carefulModeSection: some View {
        HStack(alignment: .center, spacing: 12) {
            MomentSymbolBadge(systemImage: "heart.text.square", style: .care, size: 34)

            VStack(alignment: .leading, spacing: 4) {
                Text("Careful mode")
                    .font(.headline)

                Text("For this moment, ProsePal leans on your words, keeps the tone quieter, and avoids inventing feelings.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .prosePalMomentCard(isCareful: true, prominence: .accent)
    }

    @ViewBuilder
    private var draftSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label("Private draft", systemImage: "lock")
                    .font(.headline)
                    .foregroundStyle(model.moment.isCarefulMode ? Color.prosePalCare : Color.primary)
                Spacer()
                if model.isDrafting {
                    HStack(spacing: 7) {
                        ProgressView()
                            .controlSize(.small)
                        Text("Writing")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                    .transition(.opacity.combined(with: .scale(scale: 0.96)))
                }
            }

            if let notice = draftUnavailableNotice {
                draftUnavailableView(notice)
            } else if let bundle = model.bundle {
                draftBody(bundle)

                if model.hasVisiblePressureCheck {
                    pressureCheck(bundle)
                }

                if dynamicTypeSize.isAccessibilitySize {
                    actionRail(bundle: bundle)
                        .padding(.top, 4)
                }
            } else if model.canDraft {
                Text("Writing a private draft...")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            } else {
                Text("Add a person to begin.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
        }
        .prosePalMomentCard(isCareful: model.moment.isCarefulMode, prominence: model.bundle == nil ? .standard : .elevated)
    }

    private var draftUnavailableNotice: MomentDraftUnavailableNotice? {
        guard let errorMessage = model.errorMessage else { return nil }

        switch model.draftUnavailableReason {
        case .offline:
            return MomentDraftUnavailableNotice(
                title: "Connection needed",
                detail: "Private Draft could not finish offline on this device. Check your connection and try again.",
                systemImage: "wifi.slash",
                canRetry: true
            )
        case .timedOut:
            return MomentDraftUnavailableNotice(
                title: "That took too long",
                detail: "The writing route did not answer in time. Your words are still here, so try again when the connection settles.",
                systemImage: "clock",
                canRetry: true
            )
        case .rateLimited, .usageLimitReached:
            return MomentDraftUnavailableNotice(
                title: "Writing paused for now",
                detail: errorMessage,
                systemImage: "hourglass",
                canRetry: false
            )
        case .contentBlocked:
            return MomentDraftUnavailableNotice(
                title: "This needs a different kind of support",
                detail: errorMessage,
                systemImage: "exclamationmark.triangle",
                canRetry: false
            )
        case .serviceUnavailable, .unexpectedResponse:
            if model.moment.requiresCarefulLane || model.register == .assemble {
                return MomentDraftUnavailableNotice(
                    title: "Take more care is unavailable",
                    detail: account.runtimeReadiness.isCarefulGatewayConfigured
                        ? "The careful writing route did not answer. Try again, or add one true detail and use the private draft when available."
                        : "This scheme needs the Take more care gateway settings before sensitive moments can use that route.",
                    systemImage: "heart.text.square",
                    canRetry: account.runtimeReadiness.isCarefulGatewayConfigured
                )
            }

            return MomentDraftUnavailableNotice(
                title: "Private Draft is unavailable",
                detail: account.runtimeReadiness.isPrivateDraftConfigured
                    ? errorMessage
                    : "This build does not have the private writing client ready yet. Settings shows what is missing.",
                systemImage: "lock",
                canRetry: account.runtimeReadiness.isPrivateDraftConfigured
            )
        case .unexpected, .none:
            if model.moment.requiresCarefulLane || model.register == .assemble {
                return MomentDraftUnavailableNotice(
                    title: "Take more care is unavailable",
                    detail: "The careful writing route did not answer. Try again, or add one true detail and use the private draft when available.",
                    systemImage: "heart.text.square",
                    canRetry: true
                )
            }

            return MomentDraftUnavailableNotice(
                title: "Draft unavailable",
                detail: "ProsePal could not write this yet. Try again, or add one more true detail first.",
                systemImage: "square.and.pencil",
                canRetry: true
            )
        }
    }

    private var draftRevisionSegmentedControl: some View {
        HStack(spacing: 2) {
            ForEach(DraftRevisionTab.allCases) { tab in
                Button {
                    selectedDraftRevisionTab = tab
                } label: {
                    Text(tab.title)
                        .font(.subheadline.weight(selectedDraftRevisionTab == tab ? .semibold : .medium))
                        .foregroundStyle(selectedDraftRevisionTab == tab ? Color.prosePalInk : Color.prosePalSlate)
                        .lineLimit(1)
                        .minimumScaleFactor(0.84)
                        .frame(maxWidth: .infinity)
                        .frame(height: 31)
                        .background {
                            if selectedDraftRevisionTab == tab {
                                RoundedRectangle(cornerRadius: 11, style: .continuous)
                                    .fill(Color.prosePalPaper.opacity(0.96))
                                    .shadow(color: Color.prosePalCoralDeep.opacity(0.08), radius: 6, x: 0, y: 2)
                            }
                        }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(3)
        .frame(maxWidth: .infinity)
        .background {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.prosePalPaper.opacity(0.52))
                .overlay {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.prosePalNavy.opacity(0.10), lineWidth: 1)
                }
        }
    }

    private func draftRevisionPage(_ bundle: MomentDraftBundle) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            if selectedDraftRevisionTab == .draft {
                TextField("Draft text", text: activeDraftText, axis: .vertical)
                    .font(.system(.title3, design: .serif))
                    .lineSpacing(7)
                    .foregroundStyle(Color.prosePalInk)
                    .lineLimit(dynamicTypeSize.isAccessibilitySize ? 6...24 : 4...16)
                    .textFieldStyle(.plain)
                    .focused($focusedField, equals: .draft)
                    .submitLabel(.done)
                    .onSubmit {
                        endFocusedEditing()
                    }
                    .disabled(model.isDrafting)
                    .accessibilityLabel("Draft text")
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                Text(draftRevisionDisplayText(for: bundle))
                    .font(.system(.title3, design: .serif))
                    .lineSpacing(7)
                    .foregroundStyle(Color.prosePalInk)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityLabel(selectedDraftRevisionTab == .original ? "Original text" : "Draft changes")
            }
        }
        .frame(maxWidth: .infinity, minHeight: dynamicTypeSize.isAccessibilitySize ? 190 : 136, alignment: .topLeading)
        .background(alignment: .topLeading) {
            MomentRevisionRuledLines()
                .accessibilityHidden(true)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.prosePalPaper.opacity(0.96))
                .overlay {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.prosePalNavy.opacity(0.12), lineWidth: 1)
                }
                .shadow(color: Color.prosePalCoralDeep.opacity(0.10), radius: 12, x: 0, y: 6)
        }
    }

    private func draftRevisionDisplayText(for bundle: MomentDraftBundle) -> String {
        switch selectedDraftRevisionTab {
        case .draft:
            return bundle.messageText
        case .changes:
            return bundle.messageText
        case .original:
            let original = model.trueThing.trimmingCharacters(in: .whitespacesAndNewlines)
            return original.isEmpty ? bundle.messageText : original
        }
    }

    private func draftRevisionSuggestionCard(_ bundle: MomentDraftBundle) -> some View {
        VStack(alignment: .leading, spacing: 11) {
            Label(draftRevisionSuggestionTitle(for: bundle), systemImage: "wand.and.stars")
                .font(.caption.weight(.medium))
                .foregroundStyle(Color.prosePalSlate)
                .labelStyle(.titleAndIcon)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(draftRevisionSuggestionOptions(for: bundle), id: \.self) { option in
                        Button {
                            applyRevisionSuggestion(option)
                        } label: {
                            Text(option)
                                .font(.system(.body, design: .serif))
                                .foregroundStyle(Color.prosePalSlate)
                                .lineLimit(1)
                                .padding(.horizontal, 14)
                                .frame(height: 30)
                                .background(Color.prosePalPaper.opacity(0.80), in: Capsule(style: .continuous))
                                .overlay {
                                    Capsule(style: .continuous)
                                        .stroke(Color.prosePalNavy.opacity(0.12), lineWidth: 1)
                                }
                        }
                        .buttonStyle(.plain)
                        .disabled(model.isDrafting)
                    }
                }
            }
            .scrollClipDisabled()
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.prosePalPaper.opacity(0.56))
                .overlay {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.prosePalNavy.opacity(0.10), lineWidth: 1)
                }
        }
    }

    private func draftRevisionToneRow(_ bundle: MomentDraftBundle) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(MomentAdjustment.allCases) { adjustment in
                    draftRevisionToneChip(
                        title: adjustment.displayName,
                        systemImage: adjustment.systemImage,
                        isSelected: adjustment == .warmer
                    ) {
                        model.adjust(adjustment)
                    }
                }
            }
        }
        .scrollClipDisabled()
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Revision tones")
    }

    private func draftRevisionToneChip(
        title: String,
        systemImage: String,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Label {
                Text(title)
                    .font(.subheadline.weight(isSelected ? .semibold : .medium))
            } icon: {
                Image(systemName: systemImage)
                    .font(.caption.weight(.medium))
            }
            .labelStyle(.titleAndIcon)
            .lineLimit(1)
            .minimumScaleFactor(0.82)
            .padding(.horizontal, 14)
            .frame(height: 36)
            .foregroundStyle(isSelected ? Color.prosePalCoralDeep : Color.prosePalSlate)
            .background(
                isSelected ? Color.prosePalCoral.opacity(0.12) : Color.prosePalPaper.opacity(0.62),
                in: Capsule(style: .continuous)
            )
            .overlay {
                Capsule(style: .continuous)
                    .stroke(
                        isSelected ? Color.prosePalCoral.opacity(0.22) : Color.prosePalNavy.opacity(0.10),
                        lineWidth: 1
                    )
            }
        }
        .buttonStyle(.plain)
        .disabled(model.isDrafting)
    }

    private func draftRevisionKeepButton(bundle: MomentDraftBundle) -> some View {
        Button {
            endFocusedEditing()
            save(bundle)
            isShowingReviseMode = false
        } label: {
            Label("Keep this draft", systemImage: "checkmark")
                .font(.headline.weight(.semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.86)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
        }
        .buttonStyle(.plain)
        .foregroundStyle(Color.prosePalPaper)
        .background(Color.prosePalCoral, in: Capsule(style: .continuous))
        .shadow(color: Color.prosePalCoralDeep.opacity(0.18), radius: 10, x: 0, y: 5)
        .disabled(model.isDrafting)
    }

    private func draftRevisionSuggestionTitle(for bundle: MomentDraftBundle) -> String {
        let target = draftRevisionSuggestionTarget(in: bundle.messageText)
        return "Replace \"\(target)\""
    }

    private func draftRevisionSuggestionOptions(for bundle: MomentDraftBundle) -> [String] {
        let target = draftRevisionSuggestionTarget(in: bundle.messageText).lowercased()

        if target.contains("thinking") {
            return ["wondering", "missing", "hoping"]
        }
        if target.contains("miss") {
            return ["remember", "value", "hope"]
        }
        return ["gentler", "warmer", "clearer", "shorter"]
    }

    private func draftRevisionSuggestionTarget(in text: String) -> String {
        let preferredTargets = ["thinking", "miss", "love", "happy", "easy"]
        let lowercased = text.lowercased()
        return preferredTargets.first { lowercased.contains($0) } ?? "this"
    }

    private func applyRevisionSuggestion(_ option: String) {
        guard selectedDraftRevisionTab == .draft,
              var currentBundle = model.bundle
        else {
            return
        }

        let target = draftRevisionSuggestionTarget(in: currentBundle.messageText)
        guard target != "this",
              let range = currentBundle.messageText.range(
                of: target,
                options: [.caseInsensitive, .diacriticInsensitive]
              )
        else {
            return
        }

        currentBundle.messageText.replaceSubrange(range, with: option)
        model.updateActiveDraftMessage(currentBundle.messageText)
    }

    private func draftResultCard(_ bundle: MomentDraftBundle) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center, spacing: 8) {
                Text(draftResultToneLabel(for: bundle))
                    .font(.system(size: 13, weight: .medium, design: .serif))
                    .italic()
                    .foregroundStyle(draftResultAccentColor(for: bundle))
                    .lineLimit(1)
                    .minimumScaleFactor(0.84)

                Spacer(minLength: 10)

                draftVariantDots
            }
            .padding(.top, 15)
            .padding(.horizontal, 20)

            TextField("Draft text", text: activeDraftText, axis: .vertical)
                .font(.system(.title3, design: .serif))
                .lineSpacing(7)
                .foregroundStyle(Color.prosePalInk)
                .lineLimit(dynamicTypeSize.isAccessibilitySize ? 7...28 : 5...20)
                .textFieldStyle(.plain)
                .focused($focusedField, equals: .draft)
                .submitLabel(.done)
                .onSubmit {
                    endFocusedEditing()
                }
                .disabled(model.isDrafting)
                .accessibilityLabel("Draft text")
                .fixedSize(horizontal: false, vertical: true)
                .frame(
                    maxWidth: .infinity,
                    minHeight: dynamicTypeSize.isAccessibilitySize ? 260 : 236,
                    alignment: .topLeading
                )
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 14)

            Label("Still unmistakably you", systemImage: "checkmark.seal")
                .font(.footnote)
                .foregroundStyle(Color.prosePalCare)
                .labelStyle(.titleAndIcon)
                .padding(.horizontal, 20)
                .padding(.bottom, 13)

            Rectangle()
                .fill(Color.prosePalNavy.opacity(0.12))
                .frame(height: 0.5)
                .padding(.horizontal, 12)

            HStack(alignment: .center, spacing: 4) {
                draftResultFooterButton(title: "Copy", systemImage: "doc.on.doc") {
                    copy(bundle.messageText)
                }

                draftResultFooterButton(title: "Another", systemImage: "arrow.clockwise") {
                    focusedField = nil
                    Task {
                        await model.draftNow()
                    }
                }
                .disabled(model.isDrafting || !model.canDraft)

                Spacer(minLength: 4)

                draftResultFooterButton(title: "Keep this", systemImage: "checkmark", isAccent: true) {
                    save(bundle)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            let shape = RoundedRectangle(cornerRadius: 20, style: .continuous)

            ZStack(alignment: .leading) {
                shape
                    .fill(Color.prosePalPaper.opacity(0.96))

                Rectangle()
                    .fill(draftResultAccentColor(for: bundle))
                    .frame(width: 3)
                    .padding(.vertical, 1)
            }
            .clipShape(shape)
            .overlay {
                shape.stroke(Color.prosePalNavy.opacity(0.12), lineWidth: 1)
            }
            .shadow(color: Color.prosePalCoralDeep.opacity(0.10), radius: 18, x: 0, y: 9)
        }
    }

    private func draftResultToneLabel(for bundle: MomentDraftBundle) -> String {
        if bundle.lane == .takeMoreCare {
            return "Careful & steady"
        }

        switch model.register {
        case .react:
            return "Warm & concise"
        case .confess:
            return "Your words, polished"
        case .assemble:
            return "Diplomatic & warm"
        }
    }

    private var draftVariantDots: some View {
        HStack(spacing: 5) {
            Capsule(style: .continuous)
                .fill(Color.prosePalCoral)
                .frame(width: 18, height: 6)

            Circle()
                .fill(Color.prosePalSlate.opacity(0.36))
                .frame(width: 6, height: 6)

            Circle()
                .fill(Color.prosePalSlate.opacity(0.36))
                .frame(width: 6, height: 6)
        }
        .accessibilityHidden(true)
    }

    private func draftResultFooterButton(
        title: String,
        systemImage: String,
        isAccent: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Label {
                Text(title)
                    .font(.subheadline.weight(isAccent ? .semibold : .medium))
            } icon: {
                Image(systemName: systemImage)
                    .font(.caption.weight(.medium))
            }
            .labelStyle(.titleAndIcon)
            .lineLimit(1)
            .minimumScaleFactor(0.78)
            .frame(height: 36)
            .padding(.horizontal, 8)
            .foregroundStyle(isAccent ? Color.prosePalCoralDeep : Color.prosePalSlate)
        }
        .buttonStyle(.plain)
    }

    private func draftMarginNote(_ bundle: MomentDraftBundle) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "square.and.pencil")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(draftResultAccentColor(for: bundle))
                .frame(width: 30, height: 30)
                .background(
                    draftResultAccentColor(for: bundle).opacity(0.12),
                    in: RoundedRectangle(cornerRadius: 9, style: .continuous)
                )

            VStack(alignment: .leading, spacing: 3) {
                Text("Margin note")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.prosePalInk)

                Text(draftMarginNoteText(for: bundle))
                    .font(.system(.subheadline, design: .serif))
                    .italic()
                    .lineSpacing(3)
                    .foregroundStyle(Color.prosePalSlate)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.vertical, 13)
        .padding(.horizontal, 15)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.prosePalPaper.opacity(0.52))
                .overlay {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.prosePalNavy.opacity(0.10), lineWidth: 1)
                }
        }
    }

    private func draftMarginNoteText(for bundle: MomentDraftBundle) -> String {
        if bundle.lane == .takeMoreCare || model.register == .assemble {
            return "The draft keeps your decision clear while softening the landing."
        }
        if model.register == .confess {
            return "The draft keeps one true detail visible without making the message feel overworked."
        }
        return "The draft stays close to your note and turns it into something ready to send."
    }

    private func draftRefineRail(bundle: MomentDraftBundle) -> some View {
        HStack(alignment: .center, spacing: 10) {
            Image(systemName: "wand.and.stars")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(draftResultAccentColor(for: bundle))
                .frame(width: 30, height: 30)
                .background(
                    draftResultAccentColor(for: bundle).opacity(0.12),
                    in: Circle()
                )

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    if model.canShowDraftHistory {
                        draftRefineChip(title: "History", systemImage: "clock.arrow.circlepath") {
                            diagnostics.messageAction(
                                "open_draft_history",
                                source: "moment_draft",
                                messageCharacters: bundle.messageText.count
                            )
                            isShowingDraftHistory = true
                        }
                    }

                    ForEach(MomentAdjustment.allCases) { adjustment in
                        draftRefineChip(
                            title: adjustment.displayName,
                            systemImage: adjustment.systemImage
                        ) {
                            model.adjust(adjustment)
                        }
                    }

                    if bundle.lane != .takeMoreCare {
                        draftRefineChip(title: "Take care", systemImage: "heart.text.square") {
                            takeMoreCare()
                        }
                    }
                }
            }
            .scrollClipDisabled()
        }
        .frame(height: 40)
    }

    private func draftRefineChip(
        title: String,
        systemImage: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Label {
                Text(title)
                    .font(.subheadline.weight(.medium))
            } icon: {
                Image(systemName: systemImage)
                    .font(.caption.weight(.medium))
            }
            .labelStyle(.titleAndIcon)
            .lineLimit(1)
            .minimumScaleFactor(0.82)
            .padding(.horizontal, 14)
            .frame(height: 36)
            .foregroundStyle(Color.prosePalSlate)
            .background(Color.prosePalPaper.opacity(0.68), in: Capsule(style: .continuous))
            .overlay {
                Capsule(style: .continuous)
                    .stroke(Color.prosePalNavy.opacity(0.10), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .disabled(model.isDrafting)
    }

    private func draftResultAccentColor(for bundle: MomentDraftBundle) -> Color {
        bundle.lane == .takeMoreCare ? Color.prosePalCare : Color.prosePalCoral
    }

private struct MomentRevisionRuledLines: View {
    var lineHeight: CGFloat = 34

    var body: some View {
        Canvas { context, size in
            var path = Path()
            var y = lineHeight - 1

            while y < size.height {
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: size.width, y: y))
                y += lineHeight
            }

            context.stroke(
                path,
                with: .color(Color.prosePalCoral.opacity(0.10)),
                lineWidth: 0.6
            )
        }
    }
}

private struct MomentDraftHistorySheet: View {
    @Environment(\.dismiss) private var dismiss

    @Bindable var model: MomentModel
    let onRestore: (MomentDraftSnapshot) -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                topChrome

                if timelineItems.isEmpty {
                    emptyState
                } else {
                    VStack(spacing: 0) {
                        ForEach(Array(timelineItems.enumerated()), id: \.element.id) { index, item in
                            MomentDraftHistoryRow(
                                item: item,
                                isLast: index == timelineItems.count - 1
                            ) { snapshot in
                                onRestore(snapshot)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 18)
            .padding(.top, 14)
            .padding(.bottom, 26)
        }
        .scrollIndicators(.hidden)
        .background {
            MomentAtmosphericBackground(isCareful: model.moment.isCarefulMode)
        }
    }

    private var topChrome: some View {
        ZStack {
            HStack {
                Button {
                    dismiss()
                } label: {
                    Label("Draft", systemImage: "chevron.left")
                        .font(.subheadline.weight(.medium))
                        .labelStyle(.titleAndIcon)
                        .foregroundStyle(Color.prosePalCoralDeep)
                        .lineLimit(1)
                        .padding(.horizontal, 11)
                        .frame(height: 36)
                        .background(Color.prosePalPaper.opacity(0.70), in: Capsule(style: .continuous))
                        .overlay {
                            Capsule(style: .continuous)
                                .stroke(Color.prosePalNavy.opacity(0.10), lineWidth: 1)
                        }
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Back to draft")

                Spacer()
            }

            Text("Version history")
                .font(.headline.weight(.semibold))
                .foregroundStyle(Color.prosePalInk)
                .lineLimit(1)
                .minimumScaleFactor(0.84)
        }
        .frame(height: 44)
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 32, weight: .medium))
                .foregroundStyle(Color.prosePalCoral.opacity(0.68))

            Text("No draft history")
                .font(.system(size: 23, design: .serif).weight(.medium))
                .foregroundStyle(Color.prosePalInk)

            Text("Edits and rewrites you can recover appear here.")
                .font(.callout)
                .foregroundStyle(Color.prosePalSlate)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 26)
        .padding(.vertical, 34)
        .background(Color.prosePalPaper.opacity(0.94), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.prosePalNavy.opacity(0.10), lineWidth: 1)
        }
    }

    private var timelineItems: [MomentDraftHistoryItem] {
        var items: [MomentDraftHistoryItem] = []

        if let bundle = model.bundle {
            items.append(MomentDraftHistoryItem(
                id: "current-\(bundle.id.uuidString)",
                title: currentTitle(for: bundle),
                marker: "Current",
                text: bundle.messageText,
                systemImage: "feather",
                isCurrent: true
            ))
        }

        items.append(contentsOf: model.draftSnapshots.reversed().map { snapshot in
            MomentDraftHistoryItem(
                id: "snapshot-\(snapshot.id.uuidString)",
                title: title(for: snapshot.reason),
                marker: snapshot.createdAt.formatted(date: .omitted, time: .shortened),
                text: snapshot.bundle.messageText,
                systemImage: systemImage(for: snapshot.reason),
                snapshot: snapshot
            )
        })

        let originalNote = model.trueThing.trimmingCharacters(in: .whitespacesAndNewlines)
        if !originalNote.isEmpty {
            items.append(MomentDraftHistoryItem(
                id: "original-note",
                title: "Your note",
                marker: "Original",
                text: originalNote,
                systemImage: "pencil",
                isOriginal: true
            ))
        }

        return items
    }

    private func currentTitle(for bundle: MomentDraftBundle) -> String {
        if bundle.lane == .takeMoreCare {
            return "Careful & steady"
        }

        switch model.register {
        case .react:
            return "Warm & concise"
        case .confess:
            return "Your words, polished"
        case .assemble:
            return "Diplomatic & warm"
        }
    }

    private func title(for reason: MomentDraftSnapshotReason) -> String {
        switch reason {
        case .edit:
            "Before edit"
        case .rewrite:
            "Before rewrite"
        }
    }

    private func systemImage(for reason: MomentDraftSnapshotReason) -> String {
        switch reason {
        case .edit:
            "pencil"
        case .rewrite:
            "sparkles"
        }
    }

    private struct MomentDraftHistoryItem: Identifiable {
        var id: String
        var title: String
        var marker: String
        var text: String
        var systemImage: String
        var isCurrent = false
        var isOriginal = false
        var snapshot: MomentDraftSnapshot?
    }

    private struct MomentDraftHistoryRow: View {
        let item: MomentDraftHistoryItem
        let isLast: Bool
        let onRestore: (MomentDraftSnapshot) -> Void

        var body: some View {
            HStack(alignment: .top, spacing: 14) {
                timelineStem

                timelineCard
                    .padding(.bottom, isLast ? 0 : 16)
            }
        }

        private var timelineStem: some View {
            VStack(spacing: 0) {
                ZStack {
                    Circle()
                        .fill(item.isCurrent ? Color.prosePalCoral : Color.prosePalPaper)
                        .frame(width: 34, height: 34)
                        .overlay {
                            Circle()
                                .stroke(
                                    item.isCurrent ? Color.clear : Color.prosePalNavy.opacity(0.14),
                                    lineWidth: 1
                                )
                        }

                    Image(systemName: item.systemImage)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(item.isCurrent ? Color.white : Color.prosePalSlate)
                }

                if !isLast {
                    Rectangle()
                        .fill(Color.prosePalNavy.opacity(0.14))
                        .frame(width: 1.5)
                        .frame(maxHeight: .infinity)
                }
            }
            .frame(width: 34)
            .accessibilityHidden(true)
        }

        private var timelineCard: some View {
            VStack(alignment: .leading, spacing: 7) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(item.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.prosePalInk)
                        .lineLimit(1)
                        .minimumScaleFactor(0.84)

                    Spacer(minLength: 8)

                    Text(item.marker)
                        .font(.caption2.monospacedDigit())
                        .foregroundStyle(Color.prosePalSlate.opacity(0.82))
                        .lineLimit(1)
                }

                Text(item.text)
                    .font(.system(.callout, design: .serif))
                    .lineSpacing(3)
                    .foregroundStyle(item.isOriginal ? Color.prosePalSlate.opacity(0.86) : Color.prosePalSlate)
                    .italic(item.isOriginal)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)

                if item.isCurrent {
                    Label("Showing now", systemImage: "checkmark")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.prosePalCare)
                        .padding(.top, 1)
                } else if let snapshot = item.snapshot {
                    Button {
                        onRestore(snapshot)
                    } label: {
                        Label("Restore", systemImage: "arrow.counterclockwise")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color.prosePalCoralDeep)
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 1)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.prosePalPaper.opacity(0.96), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(
                        item.isCurrent ? Color.prosePalCoral.opacity(0.28) : Color.prosePalNavy.opacity(0.09),
                        lineWidth: 1
                    )
            }
            .shadow(
                color: Color.prosePalCoralDeep.opacity(item.isCurrent ? 0.12 : 0.06),
                radius: item.isCurrent ? 10 : 5,
                x: 0,
                y: item.isCurrent ? 5 : 2
            )
            .accessibilityElement(children: .combine)
        }
    }
}

    private func draftUnavailableView(_ notice: MomentDraftUnavailableNotice) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 10) {
                MomentSymbolBadge(
                    systemImage: notice.systemImage,
                    style: notice.canRetry ? .coral : .warning,
                    size: 34
                )

                VStack(alignment: .leading, spacing: 4) {
                    Text(notice.title)
                        .font(.subheadline.weight(.semibold))
                    Text(notice.detail)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .accessibilityElement(children: .combine)

            if notice.canRetry && model.canDraft {
                Button {
                    Task {
                        await model.draftNow()
                    }
                } label: {
                    Label("Try again", systemImage: "arrow.clockwise")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .disabled(model.isDrafting)
            }
        }
        .padding(14)
        .background {
            MomentCardBackground(
                isCareful: model.moment.requiresCarefulLane || model.register == .assemble,
                prominence: notice.canRetry ? .accent : .warning
            )
        }
    }

    private var activeDraftText: Binding<String> {
        Binding {
            model.bundle?.messageText ?? ""
        } set: { nextText in
            model.updateActiveDraftMessage(nextText)
        }
    }

    private func draftBody(_ bundle: MomentDraftBundle) -> some View {
        MomentWritingPageSurface(
            prompt: bundle.lane == .takeMoreCare ? "Careful draft" : "Your draft",
            isCareful: bundle.lane == .takeMoreCare,
            showsRules: false,
            showsFooter: false,
            minHeight: dynamicTypeSize.isAccessibilitySize ? 190 : 150
        ) {
            TextField("Draft text", text: activeDraftText, axis: .vertical)
                .font(.system(.title3, design: .serif))
                .lineSpacing(5)
                .foregroundStyle(Color.prosePalInk)
                .lineLimit(dynamicTypeSize.isAccessibilitySize ? 8...24 : 5...18)
                .textFieldStyle(.plain)
                .focused($focusedField, equals: .draft)
                .submitLabel(.done)
                .onSubmit {
                    endFocusedEditing()
                }
                .disabled(model.isDrafting)
                .accessibilityLabel("Draft text")
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        } footer: {
            EmptyView()
        }
    }

    private func pressureCheck(_ bundle: MomentDraftBundle) -> some View {
        let check = bundle.pressureCheck

        return VStack(alignment: .leading, spacing: 12) {
            Label("Pressure check", systemImage: "checkmark.seal")
                .font(.subheadline.weight(.semibold))

            VStack(alignment: .leading, spacing: 6) {
                ForEach(check.userVisibleNotes, id: \.self) { note in
                    Text(note)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }

            ViewThatFits(in: .horizontal) {
                HStack(spacing: 10) {
                    keepPressureDraftButton(bundle)
                    cleanUpPressureButton(bundle)
                }

                VStack(spacing: 8) {
                    keepPressureDraftButton(bundle)
                    cleanUpPressureButton(bundle)
                }
            }
            .controlSize(.regular)
        }
        .padding(14)
        .background(Color.prosePalCare.opacity(0.10), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.prosePalCare.opacity(0.20), lineWidth: 1)
        }
    }

    private func keepPressureDraftButton(_ bundle: MomentDraftBundle) -> some View {
        Button {
            diagnostics.messageAction(
                "keep_pressure_checked_draft",
                source: "pressure_check",
                messageCharacters: bundle.messageText.count
            )
            model.keepPressureCheckedDraft()
        } label: {
            Label("Keep draft", systemImage: "checkmark")
                .lineLimit(1)
                .minimumScaleFactor(0.82)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
        .buttonBorderShape(.capsule)
        .tint(.prosePalNavy)
        .frame(maxWidth: .infinity)
        .disabled(model.isDrafting)
    }

    private func cleanUpPressureButton(_ bundle: MomentDraftBundle) -> some View {
        Button {
            diagnostics.messageAction(
                "clean_up_pressure",
                source: "pressure_check",
                messageCharacters: bundle.messageText.count
            )
            model.cleanUpPressureCheckedDraft()
        } label: {
            Label(cleanUpPressureTitle(for: bundle), systemImage: "wand.and.stars")
                .lineLimit(1)
                .minimumScaleFactor(0.78)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .buttonBorderShape(.capsule)
        .tint(model.moment.isCarefulMode ? .prosePalCare : .prosePalCoral)
        .frame(maxWidth: .infinity)
        .disabled(model.isDrafting)
    }

    private func cleanUpPressureTitle(for bundle: MomentDraftBundle) -> String {
        bundle.lane == .takeMoreCare ? "Make direct" : "Clean up"
    }

    private func actionRail(bundle: MomentDraftBundle) -> some View {
        VStack(spacing: 10) {
            if model.canRestorePreviousDraft {
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 10) {
                        undoRewriteButton(bundle)
                        keepRewriteButton(bundle)
                    }

                    VStack(spacing: 8) {
                        undoRewriteButton(bundle)
                        keepRewriteButton(bundle)
                    }
                }
            }

            if model.canShowDraftHistory {
                draftHistoryButton(bundle)
            }

            if bundle.lane != .takeMoreCare {
                Button {
                    takeMoreCare()
                } label: {
                    Label("Take care", systemImage: "heart.text.square")
                        .lineLimit(1)
                        .minimumScaleFactor(0.78)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.capsule)
                .tint(model.moment.isCarefulMode ? .prosePalCare : .prosePalCoral)
                .controlSize(.large)
                .disabled(model.isDrafting)
            }

            ViewThatFits(in: .horizontal) {
                HStack(spacing: 10) {
                    ForEach(MomentAdjustment.allCases) { adjustment in
                        adjustmentButton(adjustment)
                    }
                }

                VStack(spacing: 8) {
                    ForEach(MomentAdjustment.allCases) { adjustment in
                        adjustmentButton(adjustment)
                    }
                }
            }

            ViewThatFits(in: .horizontal) {
                HStack(spacing: 10) {
                    copyButton(text: bundle.messageText)
                    shareButton(text: bundle.messageText)
                    saveButton(bundle: bundle)
                }

                VStack(spacing: 8) {
                    copyButton(text: bundle.messageText)
                    shareButton(text: bundle.messageText)
                    saveButton(bundle: bundle)
                }
            }
            .controlSize(.large)
        }
    }

    private func undoRewriteButton(_ bundle: MomentDraftBundle) -> some View {
        Button {
            diagnostics.messageAction(
                model.previousDraftActionDiagnosticsName,
                source: "moment_draft",
                messageCharacters: bundle.messageText.count
            )
            model.restorePreviousDraft()
        } label: {
            Label(model.previousDraftActionTitle, systemImage: "arrow.uturn.backward")
                .lineLimit(dynamicTypeSize.isAccessibilitySize ? 2 : 1)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.82)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
        .buttonBorderShape(.capsule)
        .tint(.prosePalNavy)
        .controlSize(.large)
        .frame(maxWidth: .infinity)
    }

    private func keepRewriteButton(_ bundle: MomentDraftBundle) -> some View {
        Button {
            diagnostics.messageAction(
                model.keepCurrentDraftActionDiagnosticsName,
                source: "moment_draft",
                messageCharacters: bundle.messageText.count
            )
            model.keepCurrentDraftChange()
        } label: {
            Label(model.keepCurrentDraftActionTitle, systemImage: "checkmark")
                .lineLimit(dynamicTypeSize.isAccessibilitySize ? 2 : 1)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.82)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .buttonBorderShape(.capsule)
        .tint(model.moment.isCarefulMode ? .prosePalCare : .prosePalCoral)
        .controlSize(.large)
        .frame(maxWidth: .infinity)
    }

    private func draftHistoryButton(_ bundle: MomentDraftBundle) -> some View {
        Button {
            diagnostics.messageAction(
                "open_draft_history",
                source: "moment_draft",
                messageCharacters: bundle.messageText.count
            )
            isShowingDraftHistory = true
        } label: {
            Label("History", systemImage: "clock.arrow.circlepath")
                .lineLimit(1)
                .minimumScaleFactor(0.82)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
        .buttonBorderShape(.capsule)
        .tint(.prosePalNavy)
        .controlSize(.large)
        .frame(maxWidth: .infinity)
    }

    private func adjustmentButton(_ adjustment: MomentAdjustment) -> some View {
        Button {
            model.adjust(adjustment)
        } label: {
            Label(adjustment.displayName, systemImage: adjustment.systemImage)
                .lineLimit(1)
                .minimumScaleFactor(0.74)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
        .buttonBorderShape(.capsule)
        .tint(model.moment.isCarefulMode ? .prosePalCare : .prosePalCoral)
        .controlSize(.small)
        .frame(maxWidth: .infinity)
        .disabled(model.isDrafting)
    }

    private func copyButton(text: String) -> some View {
        Button {
            copy(text)
        } label: {
            Label("Copy", systemImage: "doc.on.doc")
                .lineLimit(1)
                .minimumScaleFactor(0.82)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
        .buttonBorderShape(.capsule)
        .tint(.prosePalNavy)
    }

    private func shareButton(text: String) -> some View {
        Button {
            shareRequest = MomentShareRequest.text(text)
            diagnostics.messageAction("share", source: "moment_draft", messageCharacters: text.count)
        } label: {
            Label("Share", systemImage: "square.and.arrow.up")
                .lineLimit(1)
                .minimumScaleFactor(0.82)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .buttonBorderShape(.capsule)
        .tint(.prosePalCoral)
    }

    private func saveButton(bundle: MomentDraftBundle) -> some View {
        Button {
            save(bundle)
        } label: {
            Label("Save", systemImage: "bookmark")
                .lineLimit(1)
                .minimumScaleFactor(0.82)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
        .buttonBorderShape(.capsule)
        .tint(.prosePalNavy)
    }

    private func takeMoreCare() {
        diagnostics.messageAction(
            "take_more_care",
            source: "moment_draft",
            messageCharacters: model.bundle?.messageText.count ?? 0
        )
        model.takeMoreCare()
    }

    private func copy(_ text: String) {
        #if canImport(UIKit)
        UIPasteboard.general.string = text
        #endif
        diagnostics.messageAction("copy", source: "moment_draft", messageCharacters: text.count)
    }

    private func save(_ bundle: MomentDraftBundle) {
        let record = SavedMomentDraftRecord(
            moment: model.moment,
            messageText: bundle.messageText,
            lane: bundle.lane
        )
        modelContext.insert(record)

        do {
            try modelContext.save()
            diagnostics.messageAction("save", source: "moment_draft", messageCharacters: bundle.messageText.count)
            withAnimation(.easeInOut(duration: 0.18)) {
                saveNotice = "Saved"
            }
        } catch {
            withAnimation(.easeInOut(duration: 0.18)) {
                saveNotice = "Could not save this draft."
            }
        }

        Task { @MainActor in
            try? await Task.sleep(for: .seconds(1.4))
            withAnimation(.easeInOut(duration: 0.18)) {
                saveNotice = nil
            }
        }
    }

    private func addTruthBead() {
        let text = newTruthBeadText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !currentPersonName.isEmpty, !text.isEmpty else { return }

        let record = RelationshipTruthBeadRecord(
            personName: currentPersonName,
            text: text,
            isUserApproved: true
        )
        modelContext.insert(record)

        do {
            try modelContext.save()
            diagnostics.messageAction("truth_bead_added", source: "moment", messageCharacters: 0)
            newTruthBeadText = ""
            isAddingTruthBead = false
            focusedField = nil
            model.resetDraftForMomentChange()
        } catch {
            withAnimation(.easeInOut(duration: 0.18)) {
                saveNotice = "Could not save this detail."
            }
        }
    }

    private func deleteTruthBead(_ bead: RelationshipTruthBeadRecord) {
        modelContext.delete(bead)
        try? modelContext.save()
        diagnostics.messageAction("truth_bead_deleted", source: "moment", messageCharacters: 0)
        model.resetDraftForMomentChange()
    }

    private func addVoiceCard() {
        let summary = newVoiceCardSummary.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !currentPersonName.isEmpty, !summary.isEmpty else { return }

        let record = RelationshipVoiceCardRecord(
            personName: currentPersonName,
            summary: summary,
            isUserApproved: true
        )
        modelContext.insert(record)

        do {
            try modelContext.save()
            diagnostics.messageAction("voice_card_added", source: "moment", messageCharacters: 0)
            newVoiceCardSummary = ""
            isAddingVoiceCard = false
            focusedField = nil
            model.resetDraftForMomentChange()
        } catch {
            withAnimation(.easeInOut(duration: 0.18)) {
                saveNotice = "Could not save this voice card."
            }
        }
    }

    private func deleteVoiceCard(_ voiceCard: RelationshipVoiceCardRecord) {
        modelContext.delete(voiceCard)
        try? modelContext.save()
        diagnostics.messageAction("voice_card_deleted", source: "moment", messageCharacters: 0)
        model.resetDraftForMomentChange()
    }

    private func applyVoiceTranscript(_ transcript: String) {
        let trimmedTranscript = transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTranscript.isEmpty else { return }

        model.trueThing = trimmedTranscript
        diagnostics.messageAction(
            "voice_input_used",
            source: "moment",
            messageCharacters: trimmedTranscript.count
        )
    }
}

private struct MomentSelectionRow: View {
    let title: String
    let value: String
    let detail: String
    let systemImage: String
    var isCareful = false

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            MomentSymbolBadge(systemImage: systemImage, style: isCareful ? .care : .coral, size: 34)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(value)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(2)

                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 10)

            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.prosePalPaper,
                            Color.prosePalCard,
                            accentSurface
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(accentColor.opacity(0.16), lineWidth: 1)
                }
        }
        .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
    }

    private var accentColor: Color {
        isCareful ? .prosePalCare : .prosePalCoral
    }

    private var accentSurface: Color {
        isCareful ? .prosePalCareCard : .prosePalCoralCard
    }
}

private struct MomentCompactSelectionRow: View {
    let title: String
    let value: String
    let detail: String
    let systemImage: String
    var isCondensed = false
    var isCareful = false

    var body: some View {
        Group {
            if isCondensed {
                condensedBody
            } else {
                regularBody
            }
        }
        .background {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.prosePalPaper,
                            Color.prosePalCard,
                            accentSurface
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(accentColor.opacity(0.14), lineWidth: 1)
                }
        }
        .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
    }

    private var regularBody: some View {
        HStack(alignment: .center, spacing: 10) {
            MomentSymbolBadge(systemImage: systemImage, style: isCareful ? .care : .coral, size: 30)

            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)

                HStack(spacing: 6) {
                    Text(value)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    Text(detail)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 8)

            Image(systemName: "chevron.right")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var condensedBody: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(alignment: .center, spacing: 7) {
                MomentSymbolBadge(systemImage: systemImage, style: isCareful ? .care : .coral, size: 22)

                Text(title)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)

                Spacer(minLength: 2)

                Image(systemName: "chevron.right")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }

            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.82)

            Text(detail)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.82)
        }
        .padding(.horizontal, 11)
        .padding(.vertical, 9)
        .frame(maxWidth: .infinity, minHeight: 74, alignment: .leading)
    }

    private var accentColor: Color {
        isCareful ? .prosePalCare : .prosePalCoral
    }

    private var accentSurface: Color {
        isCareful ? .prosePalCareCard : .prosePalCoralCard
    }
}

private struct MomentRelationshipPickerSheet: View {
    @Binding var selection: Relationship
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""

    var body: some View {
        NavigationStack {
            List {
                if isSearching && !hasSearchResults {
                    ContentUnavailableView.search(text: searchText)
                }

                ForEach(RelationshipGroup.allCases) { group in
                    let relationships = filteredRelationships(in: group)
                    if !relationships.isEmpty {
                        Section(group.displayName) {
                            ForEach(relationships) { relationship in
                                Button {
                                    selection = relationship
                                    playMomentSelectionFeedback()
                                    dismiss()
                                } label: {
                                    MomentRelationshipPickerRow(
                                        relationship: relationship,
                                        isSelected: relationship == selection
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search relationships")
            .momentPickerListStyle()
            .contentMargins(.top, 8, for: .scrollContent)
            .navigationTitle("Who they are")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }

    private var isSearching: Bool {
        !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var hasSearchResults: Bool {
        RelationshipGroup.allCases.contains { !filteredRelationships(in: $0).isEmpty }
    }

    private func filteredRelationships(in group: RelationshipGroup) -> [Relationship] {
        let groupRelationships = Relationship.allCases.filter { $0.group == group }
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return groupRelationships }

        return groupRelationships.filter {
            $0.momentSearchText.localizedCaseInsensitiveContains(query)
        }
    }
}

private struct MomentRelationshipPickerRow: View {
    let relationship: Relationship
    let isSelected: Bool

    var body: some View {
        MomentPickerRow(
            systemImage: relationship.symbolName,
            title: relationship.displayName,
            subtitle: relationship.group.displayName,
            isSelected: isSelected
        )
    }
}

private struct MomentOccasionPickerSheet: View {
    @Binding var selection: Occasion
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""

    var body: some View {
        NavigationStack {
            List {
                if !isSearching {
                    Section("Often used") {
                        ForEach(Occasion.featuredCases) { occasion in
                            occasionButton(for: occasion)
                        }
                    }
                } else if !hasSearchResults {
                    ContentUnavailableView.search(text: searchText)
                }

                ForEach(displayedGroups) { group in
                    let occasions = filteredOccasions(in: group)
                    if !occasions.isEmpty {
                        Section(group.displayName) {
                            ForEach(occasions) { occasion in
                                occasionButton(for: occasion)
                            }
                        }
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search moments")
            .momentPickerListStyle()
            .contentMargins(.top, 8, for: .scrollContent)
            .navigationTitle("Moment")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }

    private var isSearching: Bool {
        !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var displayedGroups: [OccasionGroup] {
        if isSearching {
            return OccasionGroup.allCases
        }

        return OccasionGroup.allCases.filter { $0 != .mostUsed }
    }

    private var hasSearchResults: Bool {
        OccasionGroup.allCases.contains { !filteredOccasions(in: $0).isEmpty }
    }

    private func filteredOccasions(in group: OccasionGroup) -> [Occasion] {
        let groupOccasions = Occasion.allCases.filter { $0.group == group }
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return groupOccasions }

        return groupOccasions.filter {
            $0.searchText.localizedCaseInsensitiveContains(query)
        }
    }

    private func occasionButton(for occasion: Occasion) -> some View {
        Button {
            selection = occasion
            playMomentSelectionFeedback()
            dismiss()
        } label: {
            MomentOccasionPickerRow(
                occasion: occasion,
                isSelected: occasion == selection
            )
        }
        .buttonStyle(.plain)
    }
}

private struct MomentOccasionPickerRow: View {
    let occasion: Occasion
    let isSelected: Bool

    var body: some View {
        MomentPickerRow(
            systemImage: occasion.symbolName,
            title: occasion.displayName,
            subtitle: occasion.group.displayName,
            isSelected: isSelected
        )
    }
}

private struct MomentPickerRow: View {
    let systemImage: String
    let title: String
    let subtitle: String
    let isSelected: Bool

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            MomentSymbolBadge(systemImage: systemImage, style: .coral, size: 34)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.body.weight(.medium))
                    .foregroundStyle(.primary)
                    .lineLimit(2)

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 8)

            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.tint)
            }
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }
}

private struct MomentTruthBeadRow: View {
    let bead: RelationshipTruthBeadRecord
    let onEdit: () -> Void
    let onExplain: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            MomentSymbolBadge(systemImage: "checkmark.seal.fill", style: .coral, size: 30)

            Text(bead.text)
                .font(.callout)
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 8)

            Menu {
                Button {
                    onEdit()
                } label: {
                    Label("Edit detail", systemImage: "pencil")
                }

                Button {
                    onExplain()
                } label: {
                    Label("Why this appears", systemImage: "info.circle")
                }

                Button(role: .destructive) {
                    onDelete()
                } label: {
                    Label("Delete detail", systemImage: "trash")
                }
            } label: {
                MomentMemoryManageLabel()
            }
            .accessibilityLabel("Relationship memory actions")
        }
        .padding(12)
        .background(Color.prosePalPaper.opacity(0.74), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.prosePalCoral.opacity(0.12), lineWidth: 1)
        }
    }
}

private struct MomentVoiceCardRow: View {
    let voiceCard: RelationshipVoiceCardRecord
    let onEdit: () -> Void
    let onExplain: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            MomentSymbolBadge(
                systemImage: voiceCard.isUserApproved ? "waveform.circle.fill" : "pause.circle.fill",
                style: .care,
                size: 30
            )

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(voiceCard.isUserApproved ? "Used in drafts" : "Paused")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Spacer(minLength: 0)
                }

                Text(voiceCard.summary)
                    .font(.callout)
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 8)

            Menu {
                Button {
                    onEdit()
                } label: {
                    Label("Edit voice card", systemImage: "pencil")
                }

                Button {
                    onExplain()
                } label: {
                    Label("Why this appears", systemImage: "info.circle")
                }

                Button(role: .destructive) {
                    onDelete()
                } label: {
                    Label("Delete voice card", systemImage: "trash")
                }
            } label: {
                MomentMemoryManageLabel()
            }
            .accessibilityLabel("Voice card actions")
        }
        .padding(12)
        .background(Color.prosePalPaper.opacity(0.74), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.prosePalCare.opacity(0.16), lineWidth: 1)
        }
    }
}

private struct MomentMemoryManageLabel: View {
    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: "ellipsis.circle")
                .font(.caption.weight(.semibold))
                .frame(width: 14, height: 14)
            Text("Manage")
                .font(.caption.weight(.semibold))
        }
        .foregroundStyle(.secondary)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(Color.prosePalPaper.opacity(0.86), in: Capsule())
            .overlay {
                Capsule()
                    .stroke(Color.prosePalCoral.opacity(0.16), lineWidth: 1)
            }
    }
}

private struct MomentSavedEmptyState: View {
    let isSearching: Bool
    var emptyTitle: String?
    var emptyDetail: String?
    var systemImage: String = "bookmark"

    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.prosePalCoral.opacity(0.22),
                                Color.prosePalPaper.opacity(0.88)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                )
                .frame(width: 74, height: 74)

                Image(systemName: isSearching ? "magnifyingglass" : systemImage)
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(Color.prosePalCoralDeep)
                    .symbolRenderingMode(.hierarchical)
            }

            VStack(spacing: 6) {
                Text(resolvedTitle)
                    .font(.title3.weight(.semibold))
                    .multilineTextAlignment(.center)

                Text(resolvedDetail)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if !isSearching {
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 8) {
                        guidancePill("Saved by you", systemImage: "hand.tap")
                        guidancePill("Private here", systemImage: "lock")
                    }

                    VStack(spacing: 8) {
                        guidancePill("Saved by you", systemImage: "hand.tap")
                        guidancePill("Private here", systemImage: "lock")
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 18)
        .padding(.vertical, 24)
        .background {
            MomentCardBackground(isCareful: false, prominence: .standard)
        }
        .accessibilityElement(children: .combine)
    }

    private func guidancePill(_ title: String, systemImage: String) -> some View {
        Label(title, systemImage: systemImage)
            .font(.caption.weight(.semibold))
            .foregroundStyle(Color.prosePalCoralDeep)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(Color.prosePalPaper.opacity(0.86), in: Capsule(style: .continuous))
            .overlay {
                Capsule(style: .continuous)
                    .stroke(Color.prosePalCoral.opacity(0.14), lineWidth: 1)
            }
    }

    private var resolvedTitle: String {
        if let emptyTitle {
            return emptyTitle
        }
        return isSearching ? "No saved drafts found" : "No saved drafts yet"
    }

    private var resolvedDetail: String {
        if let emptyDetail {
            return emptyDetail
        }
        return isSearching ? "Try another person, moment, or phrase." : "When a message feels right, save it here for later."
    }
}

private struct MomentDraftsLibraryEmptyState: View {
    let onWriteFirst: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Image(systemName: "rectangle.stack")
                .font(.system(size: 46, weight: .regular))
                .foregroundStyle(Color.prosePalCoral.opacity(0.55))
                .frame(width: 64, height: 58)
                .accessibilityHidden(true)

            Text("Nothing here yet")
                .font(.system(size: 23, weight: .medium, design: .serif))
                .foregroundStyle(Color.prosePalInk)
                .multilineTextAlignment(.center)
                .padding(.top, 8)

            Text("Every message you shape with ProsePal lands here — ready to revisit, reuse, or refine.")
                .font(.system(size: 15, weight: .regular, design: .default))
                .lineSpacing(6)
                .foregroundStyle(Color.prosePalSlate.opacity(0.78))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: 278)
                .padding(.top, 28)

            Button(action: onWriteFirst) {
                Label("Write your first", systemImage: "pencil.and.scribble")
                    .font(.headline.weight(.semibold))
                    .labelStyle(.titleAndIcon)
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 28)
                    .frame(minWidth: 196, minHeight: 52)
                    .background(Color.prosePalCoral, in: Capsule(style: .continuous))
                    .shadow(color: Color.prosePalCoralDeep.opacity(0.20), radius: 12, x: 0, y: 7)
            }
            .buttonStyle(.plain)
            .padding(.top, 34)
            .accessibilityLabel("Write your first draft")
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }
}

private struct SavedMomentDraftsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \SavedMomentDraftRecord.createdAt, order: .reverse)
    private var drafts: [SavedMomentDraftRecord]
    let onWriteFirst: () -> Void
    @State private var searchText = ""
    @State private var selectedFilter: SavedDraftFilter = .all
    @State private var isShowingSearch = false

    init(onWriteFirst: @escaping () -> Void = {}) {
        self.onWriteFirst = onWriteFirst
    }

    private var filteredDrafts: [SavedMomentDraftRecord] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        return drafts.filter { draft in
            selectedFilter.includes(draft)
                && (
                    query.isEmpty
                        || draft.title.localizedCaseInsensitiveContains(query)
                        || draft.subtitle.localizedCaseInsensitiveContains(query)
                        || draft.messageText.localizedCaseInsensitiveContains(query)
                )
        }
    }

    private var isFirstRunEmptyState: Bool {
        drafts.isEmpty &&
            searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
            selectedFilter == .all
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 11) {
                draftsTopChrome

                if isShowingSearch {
                    draftsSearchField
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }

                if !isFirstRunEmptyState {
                    savedDraftFilterRow
                }

                if filteredDrafts.isEmpty {
                    if isFirstRunEmptyState {
                        MomentDraftsLibraryEmptyState(onWriteFirst: onWriteFirst)
                            .frame(minHeight: 484)
                            .padding(.top, 58)
                    } else {
                        MomentSavedEmptyState(
                            isSearching: !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                            emptyTitle: selectedFilter.emptyTitle,
                            emptyDetail: selectedFilter.emptyDetail
                        )
                        .padding(.top, 10)
                    }
                } else {
                    ForEach(filteredDrafts) { draft in
                        NavigationLink {
                            SavedMomentDraftDetailView(draft: draft)
                        } label: {
                            SavedMomentDraftLibraryCard(draft: draft)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 2)
            .padding(.bottom, 126)
        }
        .scrollIndicators(.hidden)
        .safeAreaInset(edge: .bottom) {
            Color.clear
                .frame(height: 92)
                .accessibilityHidden(true)
        }
        .background {
            MomentAtmosphericBackground(isCareful: false)
        }
        #if os(iOS)
        .toolbar(.hidden, for: .navigationBar)
        #endif
    }

    private var draftsTopChrome: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .center) {
                Image(systemName: "line.3.horizontal")
                    .font(.system(size: 18, weight: .regular))
                    .foregroundStyle(Color.prosePalCoralDeep)
                    .frame(width: 38, height: 38)
                    .accessibilityHidden(true)

                Spacer()

                if !isFirstRunEmptyState || isShowingSearch {
                    Button {
                        withAnimation(.easeInOut(duration: 0.18)) {
                            isShowingSearch.toggle()
                        }
                    } label: {
                        Image(systemName: isShowingSearch ? "xmark" : "magnifyingglass")
                            .font(.system(size: 18, weight: .regular))
                            .frame(width: 38, height: 38)
                            .contentShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(Color.prosePalCoralDeep)
                    .accessibilityLabel(isShowingSearch ? "Close search" : "Search drafts")
                }
            }
            .frame(height: 38)

            Text("Drafts")
                .font(.system(size: 36, design: .serif).weight(.medium))
                .foregroundStyle(Color.prosePalInk)
                .lineLimit(1)
                .minimumScaleFactor(0.84)
        }
        .padding(.top, 2)
    }

    private var draftsSearchField: some View {
        TextField("Search saved drafts", text: $searchText)
            .textFieldStyle(.plain)
            .font(.body)
            .foregroundStyle(Color.prosePalInk)
            .padding(.horizontal, 14)
            .frame(height: 42)
            .background(Color.prosePalPaper.opacity(0.76), in: Capsule(style: .continuous))
            .overlay {
                Capsule(style: .continuous)
                    .stroke(Color.prosePalNavy.opacity(0.10), lineWidth: 1)
            }
            .submitLabel(.search)
    }

    private var savedDraftFilterRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(SavedDraftFilter.allCases) { filter in
                    Button {
                        selectedFilter = filter
                    } label: {
                        Text(filter.title)
                            .font(.subheadline.weight(selectedFilter == filter ? .semibold : .medium))
                            .foregroundStyle(selectedFilter == filter ? Color.prosePalCoralDeep : Color.prosePalSlate)
                            .lineLimit(1)
                            .padding(.horizontal, 15)
                            .frame(height: 36)
                            .background(
                                selectedFilter == filter
                                    ? Color.prosePalCoral.opacity(0.11)
                                    : Color.prosePalPaper.opacity(0.58),
                                in: Capsule(style: .continuous)
                            )
                            .overlay {
                                Capsule(style: .continuous)
                                    .stroke(
                                        selectedFilter == filter
                                            ? Color.prosePalCoral.opacity(0.22)
                                            : Color.prosePalNavy.opacity(0.08),
                                        lineWidth: 1
                                    )
                            }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .scrollClipDisabled()
        .padding(.top, 2)
    }
}

private enum SavedDraftFilter: String, CaseIterable, Identifiable {
    case all
    case kept
    case used
    case drafts

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all: "All"
        case .kept: "Kept"
        case .used: "Used"
        case .drafts: "Drafts"
        }
    }

    func includes(_ draft: SavedMomentDraftRecord) -> Bool {
        switch self {
        case .all, .kept, .drafts:
            return true
        case .used:
            return false
        }
    }

    var emptyTitle: String? {
        switch self {
        case .used:
            return "No used drafts yet"
        default:
            return nil
        }
    }

    var emptyDetail: String? {
        switch self {
        case .used:
            return "Drafts you mark as used will appear here."
        default:
            return nil
        }
    }
}

private struct SavedMomentDraftLibraryCard: View {
    let draft: SavedMomentDraftRecord

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: draft.occasion.symbolName)
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(Color.prosePalCoral)
                .frame(width: 40, height: 40)
                .background(Color.prosePalCoral.opacity(0.12), in: RoundedRectangle(cornerRadius: 12, style: .continuous))

            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(draft.title)
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(Color.prosePalInk)
                            .lineLimit(1)
                            .minimumScaleFactor(0.84)

                        Text(draft.subtitle)
                            .font(.caption)
                            .foregroundStyle(Color.prosePalSlate)
                            .lineLimit(1)
                    }

                    Spacer(minLength: 8)

                    Text("Kept")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.prosePalCare)
                        .padding(.horizontal, 9)
                        .frame(height: 22)
                        .background(Color.prosePalCare.opacity(0.12), in: Capsule(style: .continuous))
                }

                Text(draft.messageText)
                    .font(.system(.callout, design: .serif))
                    .foregroundStyle(Color.prosePalSlate)
                    .lineLimit(1)

                Label(relativeSavedDate, systemImage: "clock")
                    .font(.caption2)
                    .foregroundStyle(Color.prosePalSlate.opacity(0.78))
            }
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity, minHeight: 112, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.prosePalPaper.opacity(0.96))
                .overlay {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.prosePalNavy.opacity(0.10), lineWidth: 1)
                }
                .shadow(color: Color.prosePalCoralDeep.opacity(0.10), radius: 10, x: 0, y: 5)
        }
    }

    private var relativeSavedDate: String {
        let calendar = Calendar.current

        if calendar.isDateInToday(draft.createdAt) {
            return "Just now"
        }
        if calendar.isDateInYesterday(draft.createdAt) {
            return "Yesterday"
        }

        let days = calendar.dateComponents([.day], from: draft.createdAt, to: Date()).day ?? 0
        if days < 7 {
            return draft.createdAt.formatted(.dateTime.weekday(.abbreviated))
        }

        return draft.createdAt.formatted(.dateTime.month(.abbreviated).day())
    }
}

private struct SavedMomentDraftDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    let draft: SavedMomentDraftRecord
    @State private var isEditing = false
    @State private var editedMessageText: String
    @State private var notice: String?
    @State private var shareRequest: MomentShareRequest?
    private let diagnostics = NativeDiagnosticsLogger.shared

    init(draft: SavedMomentDraftRecord) {
        self.draft = draft
        _editedMessageText = State(initialValue: draft.messageText)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                if let notice {
                    Label(notice, systemImage: "checkmark.circle")
                        .font(.callout.weight(.semibold))
                        .foregroundStyle(.secondary)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text(draft.title)
                        .font(.system(.largeTitle, design: .serif).weight(.bold))
                        .fixedSize(horizontal: false, vertical: true)

                    Text(draft.subtitle)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }

                Group {
                    if isEditing {
                        TextField("Draft text", text: $editedMessageText, axis: .vertical)
                            .font(.system(.title3, design: .serif))
                            .lineSpacing(5)
                            .lineLimit(8...18)
                            .textFieldStyle(.plain)
                    } else {
                        Text(draft.messageText)
                            .font(.system(.title3, design: .serif))
                            .lineSpacing(5)
                            .textSelection(.enabled)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(18)
                .background {
                    MomentCardBackground(isCareful: false, prominence: .elevated)
                }

                HStack(spacing: 12) {
                    if isEditing {
                        Button {
                            cancelEditing()
                        } label: {
                            Label("Cancel", systemImage: "xmark")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .buttonBorderShape(.capsule)

                        Button {
                            saveEdits()
                        } label: {
                            Label("Save", systemImage: "checkmark")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .buttonBorderShape(.capsule)
                        .tint(.prosePalCoral)
                        .disabled(!canSaveEdits)
                    } else {
                        Button {
                            copy(draft.messageText)
                        } label: {
                            Label("Copy", systemImage: "doc.on.doc")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .buttonBorderShape(.capsule)

                        Button {
                            shareRequest = MomentShareRequest.text(draft.messageText)
                            diagnostics.messageAction("share", source: "saved_draft", messageCharacters: draft.messageText.count)
                        } label: {
                            Label("Share", systemImage: "square.and.arrow.up")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .buttonBorderShape(.capsule)
                        .tint(.prosePalCoral)
                    }
                }
                .controlSize(.large)
            }
            .padding(20)
        }
        .background {
            MomentAtmosphericBackground(isCareful: false)
        }
        .navigationTitle("Draft")
        .toolbarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(isEditing ? "Save" : "Edit") {
                    if isEditing {
                        saveEdits()
                    } else {
                        beginEditing()
                    }
                }
                .disabled(isEditing && !canSaveEdits)
            }

            ToolbarItem(placement: .destructiveAction) {
                Button("Delete", role: .destructive) {
                    modelContext.delete(draft)
                    try? modelContext.save()
                    dismiss()
                }
            }
        }
        .momentShareSheet($shareRequest)
    }

    private func copy(_ text: String) {
        #if canImport(UIKit)
        UIPasteboard.general.string = text
        #endif
    }

    private var canSaveEdits: Bool {
        !editedMessageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func beginEditing() {
        editedMessageText = draft.messageText
        withAnimation(.easeInOut(duration: 0.18)) {
            notice = nil
            isEditing = true
        }
    }

    private func cancelEditing() {
        editedMessageText = draft.messageText
        withAnimation(.easeInOut(duration: 0.18)) {
            isEditing = false
        }
    }

    private func saveEdits() {
        guard canSaveEdits else { return }
        draft.updateMessageText(editedMessageText)
        try? modelContext.save()
        editedMessageText = draft.messageText

        withAnimation(.easeInOut(duration: 0.18)) {
            isEditing = false
            notice = "Saved"
        }
    }
}

private struct RelationshipMemoryVaultView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \RelationshipTruthBeadRecord.updatedAt, order: .reverse)
    private var beads: [RelationshipTruthBeadRecord]
    @Query(sort: \RelationshipVoiceCardRecord.updatedAt, order: .reverse)
    private var voiceCards: [RelationshipVoiceCardRecord]
    @State private var searchText = ""

    private var filteredItems: [RelationshipMemoryVaultItem] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        let items = (beads.map(RelationshipMemoryVaultItem.detail) + voiceCards.map(RelationshipMemoryVaultItem.voice))
            .sorted { $0.updatedAt > $1.updatedAt }
        guard !query.isEmpty else { return items }

        return items.filter {
            $0.searchText.localizedCaseInsensitiveContains(query)
        }
    }

    var body: some View {
        List {
            MomentScreenIdentityCard(
                eyebrow: "Memory",
                title: "What ProsePal may remember",
                detail: "Approved details and voice notes stay editable, pausable, and local to this relationship memory.",
                systemImage: "checkmark.seal"
            )
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)

            if filteredItems.isEmpty {
                MomentSavedEmptyState(
                    isSearching: !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                    emptyTitle: searchText.isEmpty ? "No relationship memory yet" : "No matching memory",
                    emptyDetail: searchText.isEmpty ? "Save details or voice cards from the Moment screen when they should help future drafts." : "Try another person or phrase.",
                    systemImage: "checkmark.seal"
                )
                .padding(.vertical, 12)
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            } else {
                ForEach(filteredItems) { item in
                    NavigationLink {
                        destination(for: item)
                    } label: {
                        RelationshipMemoryVaultRow(item: item)
                    }
                    .listRowBackground(Color.prosePalPaper.opacity(0.84))
                }
                .onDelete(perform: delete)
            }
        }
        .navigationTitle("Memory")
        .toolbarTitleDisplayMode(.inline)
        .searchable(text: $searchText, prompt: "Search memory")
        .contentMargins(.bottom, 112, for: .scrollContent)
        .safeAreaInset(edge: .bottom) {
            Color.clear
                .frame(height: 86)
                .accessibilityHidden(true)
        }
        .scrollContentBackground(.hidden)
        .background {
            MomentAtmosphericBackground(isCareful: false)
        }
    }

    private func delete(at offsets: IndexSet) {
        for index in offsets {
            switch filteredItems[index] {
            case .detail(let bead):
                modelContext.delete(bead)
            case .voice(let voiceCard):
                modelContext.delete(voiceCard)
            }
        }
        try? modelContext.save()
    }

    @ViewBuilder
    private func destination(for item: RelationshipMemoryVaultItem) -> some View {
        switch item {
        case .detail(let bead):
            RelationshipMemoryDetailView(bead: bead)
        case .voice(let voiceCard):
            RelationshipVoiceCardDetailView(voiceCard: voiceCard)
        }
    }
}

private enum RelationshipMemoryVaultItem: Identifiable {
    case detail(RelationshipTruthBeadRecord)
    case voice(RelationshipVoiceCardRecord)

    var id: String {
        switch self {
        case .detail(let bead):
            "detail-\(bead.id.uuidString)"
        case .voice(let voiceCard):
            "voice-\(voiceCard.id.uuidString)"
        }
    }

    var personName: String {
        switch self {
        case .detail(let bead):
            bead.personName
        case .voice(let voiceCard):
            voiceCard.personName
        }
    }

    var bodyText: String {
        switch self {
        case .detail(let bead):
            bead.text
        case .voice(let voiceCard):
            voiceCard.summary
        }
    }

    var kindLabel: String {
        switch self {
        case .detail:
            "Detail"
        case .voice:
            "Voice"
        }
    }

    var isUserApproved: Bool {
        switch self {
        case .detail(let bead):
            bead.isUserApproved
        case .voice(let voiceCard):
            voiceCard.isUserApproved
        }
    }

    var updatedAt: Date {
        switch self {
        case .detail(let bead):
            bead.updatedAt
        case .voice(let voiceCard):
            voiceCard.updatedAt
        }
    }

    var searchText: String {
        "\(personName) \(kindLabel) \(bodyText)"
    }
}

private struct RelationshipMemoryVaultRow: View {
    let item: RelationshipMemoryVaultItem

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 8) {
                Text(item.personName)
                    .font(.headline)

                Text(item.kindLabel)
                    .font(.caption2.weight(.bold))
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(.tint.opacity(0.14), in: Capsule())
                    .foregroundStyle(.tint)

                if !item.isUserApproved {
                    Text("Paused")
                        .font(.caption2.weight(.bold))
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(.secondary.opacity(0.12), in: Capsule())
                }
            }

            Text(item.bodyText)
                .font(.callout)
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
        .padding(.vertical, 4)
    }
}

private struct RelationshipMemoryDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    let bead: RelationshipTruthBeadRecord
    @State private var personName: String
    @State private var text: String
    @State private var isUserApproved: Bool
    @State private var notice: String?

    init(bead: RelationshipTruthBeadRecord) {
        self.bead = bead
        _personName = State(initialValue: bead.personName)
        _text = State(initialValue: bead.text)
        _isUserApproved = State(initialValue: bead.isUserApproved)
    }

    var body: some View {
        Form {
            if let notice {
                Section {
                    Label(notice, systemImage: "checkmark.circle")
                }
            }

            Section("Person") {
                TextField("Name", text: $personName)
                    .momentNameInputBehavior()
            }

            Section {
                TextField("What should ProsePal remember?", text: $text, axis: .vertical)
                    .lineLimit(3...6)
            } header: {
                Text("Detail")
            } footer: {
                Text("Correct this whenever it becomes stale or wrong.")
            }

            Section {
                Toggle("Use this in drafts", isOn: $isUserApproved)
            } header: {
                Text("Use")
            } footer: {
                Text("Why am I seeing this? You saved this detail for \(bead.personName). ProsePal uses approved details only when drafting for that person, and does not log the text.")
            }

            Section {
                Button("Delete detail", role: .destructive) {
                    modelContext.delete(bead)
                    try? modelContext.save()
                    dismiss()
                }
            }
        }
        .navigationTitle("Memory Detail")
        .toolbarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Done") {
                    dismiss()
                }
            }

            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    save()
                }
                .disabled(!canSave)
            }
        }
    }

    private var canSave: Bool {
        !personName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
            !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func save() {
        bead.update(
            personName: personName,
            text: text,
            isUserApproved: isUserApproved
        )
        try? modelContext.save()

        withAnimation(.easeInOut(duration: 0.18)) {
            notice = "Saved"
        }
    }
}

private struct RelationshipVoiceCardDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    let voiceCard: RelationshipVoiceCardRecord
    @State private var personName: String
    @State private var summary: String
    @State private var isUserApproved: Bool
    @State private var notice: String?

    init(voiceCard: RelationshipVoiceCardRecord) {
        self.voiceCard = voiceCard
        _personName = State(initialValue: voiceCard.personName)
        _summary = State(initialValue: voiceCard.summary)
        _isUserApproved = State(initialValue: voiceCard.isUserApproved)
    }

    var body: some View {
        Form {
            if let notice {
                Section {
                    Label(notice, systemImage: "checkmark.circle")
                }
            }

            Section("Person") {
                TextField("Name", text: $personName)
                    .momentNameInputBehavior()
            }

            Section {
                TextField("How should ProsePal sound with this person?", text: $summary, axis: .vertical)
                    .lineLimit(3...6)
            } header: {
                Text("Voice")
            } footer: {
                Text("Use this for style only, not as a fact to quote.")
            }

            Section {
                Toggle("Use this in drafts", isOn: $isUserApproved)
            } header: {
                Text("Use")
            } footer: {
                Text("Why am I seeing this? You saved this voice card for \(voiceCard.personName). ProsePal uses approved voice cards only when drafting for that person, and does not log the text.")
            }

            Section {
                Button("Delete voice card", role: .destructive) {
                    modelContext.delete(voiceCard)
                    try? modelContext.save()
                    dismiss()
                }
            }
        }
        .navigationTitle("Voice Card")
        .toolbarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Done") {
                    dismiss()
                }
            }

            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    save()
                }
                .disabled(!canSave)
            }
        }
    }

    private var canSave: Bool {
        !personName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
            !summary.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func save() {
        voiceCard.update(
            personName: personName,
            summary: summary,
            isUserApproved: isUserApproved
        )
        try? modelContext.save()

        withAnimation(.easeInOut(duration: 0.18)) {
            notice = "Saved"
        }
    }
}

private struct MomentSettingsView: View {
    @Bindable var account: MomentAccountModel
    let onDone: () -> Void
    @State private var activeSheet: MomentSettingsPresentedSheet?
    @State private var supportNotice: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                settingsTopChrome

                if let notice = account.notice {
                    Label(notice.title, systemImage: notice.systemImage)
                        .font(.callout.weight(.semibold))
                        .foregroundStyle(Color.prosePalSlate)
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.prosePalPaper.opacity(0.92), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                }

                settingsProfileCard

                settingsGroup("Writing") {
                    settingsStaticRow(
                        systemImage: "paintbrush",
                        title: "Default tone",
                        subtitle: "Diplomatic · Warm",
                        trailing: "Edit",
                        showsChevron: true
                    )
                    settingsDivider
                    settingsSwitchRow(
                        systemImage: "person.crop.square",
                        title: "Voice profile",
                        subtitle: "Learns how you write",
                        isOn: account.runtimeReadiness.isRelationshipVaultPersistent
                    )
                    settingsDivider
                    settingsStaticRow(
                        systemImage: "textformat.size",
                        title: "Reading text size",
                        trailing: "Medium",
                        showsChevron: true
                    )
                }

                settingsGroup("Privacy") {
                    settingsSwitchRow(
                        systemImage: "lock",
                        title: "Private mode",
                        subtitle: "Keep drafts on this device",
                        isOn: true
                    )
                    settingsDivider
                    settingsNavigationRow(
                        systemImage: "shield.checkered",
                        title: "Privacy & data"
                    ) {
                        MomentPrivacyDataView(account: account)
                    }
                }

                settingsGroup("Subscription") {
                    settingsButtonRow(
                        systemImage: "checkmark.seal",
                        title: "ProsePal Pro",
                        subtitle: account.isPremiumUnlocked ? "Active" : "Upgrade available",
                        showsChevron: true
                    ) {
                        activeSheet = .paywall
                    }
                    settingsDivider
                    settingsButtonRow(
                        systemImage: "lifepreserver",
                        title: "Help & support",
                        showsChevron: true
                    ) {
                        copySupportEmail()
                    }
                }

                if let supportNotice {
                    Label(supportNotice, systemImage: "checkmark.circle")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.prosePalSlate)
                        .frame(maxWidth: .infinity, alignment: .center)
                }

                settingsGroup("Account & data") {
                    if account.isSignedIn {
                        settingsButtonRow(
                            systemImage: "rectangle.portrait.and.arrow.right",
                            title: "Sign out"
                        ) {
                            Task {
                                await account.signOut()
                            }
                        }
                        settingsDivider
                        settingsButtonRow(
                            systemImage: "trash",
                            title: account.isDeletingAccount ? "Deleting account" : "Delete account",
                            role: .destructive
                        ) {
                            account.requestAccountDeletion()
                        }
                        .disabled(account.isDeletingAccount)
                        settingsDivider
                    } else {
                        MomentAppleSignInControl(account: account, source: "settings")
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                        settingsDivider
                    }

                    settingsButtonRow(
                        systemImage: "arrow.clockwise",
                        title: account.isRestoringPurchases ? "Restoring purchases" : "Restore purchases",
                        subtitle: account.subscriptionErrorMessage
                    ) {
                        Task {
                            await account.restorePurchases(source: "settings")
                        }
                    }
                    .disabled(account.isRestoringPurchases)
                    settingsDivider
                    settingsNavigationRow(
                        systemImage: "checkmark.seal",
                        title: "Relationship memory",
                        subtitle: account.runtimeReadiness.isRelationshipVaultPersistent ? "Stored on device" : "Temporary"
                    ) {
                        RelationshipMemoryVaultView()
                    }
                    settingsDivider
                    settingsStaticRow(
                        systemImage: "lock.doc",
                        title: "Private Draft",
                        trailing: account.runtimeReadiness.isPrivateDraftConfigured ? "Device dependent" : "Unavailable here"
                    )
                    settingsDivider
                    settingsStaticRow(
                        systemImage: "heart.text.square",
                        title: "Take more care",
                        trailing: account.runtimeReadiness.isCarefulGatewayConfigured ? "Ready" : "Needs setup"
                    )
                }

                settingsGroup("Legal") {
                    Link(destination: MomentSettingsExternalLinks.support) {
                        settingsLinkRowBody(systemImage: "envelope", title: "Contact support")
                    }
                    .buttonStyle(.plain)
                    settingsDivider
                    Link(destination: MomentSettingsExternalLinks.terms) {
                        settingsLinkRowBody(systemImage: "doc.text", title: "Terms")
                    }
                    .buttonStyle(.plain)
                    settingsDivider
                    Link(destination: MomentSettingsExternalLinks.privacy) {
                        settingsLinkRowBody(systemImage: "hand.raised", title: "Privacy Policy")
                    }
                    .buttonStyle(.plain)
                }

                settingsGroup("About") {
                    settingsStaticRow(systemImage: "info.circle", title: "Version", trailing: versionText)
                    settingsDivider
                    settingsStaticRow(systemImage: "iphone", title: "Direction", trailing: "Native iOS")
                }
            }
            .padding(.horizontal, 18)
            .padding(.top, 10)
            .padding(.bottom, 42)
        }
        .scrollIndicators(.hidden)
        .background {
            MomentAtmosphericBackground(isCareful: false)
        }
        .tint(.prosePalCoral)
        #if os(iOS)
        .toolbar(.hidden, for: .navigationBar)
        #endif
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .paywall:
                MomentPaywallSheet(account: account)
            }
        }
        .confirmationDialog(
            "Delete account?",
            isPresented: Binding(
                get: { account.isConfirmingAccountDeletion },
                set: { if !$0 { account.cancelAccountDeletion() } }
            ),
            titleVisibility: .visible
        ) {
            Button("Delete account", role: .destructive) {
                Task {
                    await account.confirmAccountDeletion()
                }
            }
            Button("Cancel", role: .cancel) {
                account.cancelAccountDeletion()
            }
        } message: {
            Text("This deletes your ProsePal account and app data connected to it.")
        }
    }

    private var settingsTopChrome: some View {
        VStack(alignment: .leading, spacing: 18) {
            Button("Done") {
                onDone()
            }
            .font(.title3.weight(.regular))
            .foregroundStyle(Color.prosePalCoralDeep)
            .buttonStyle(.plain)
            .frame(minHeight: 36, alignment: .leading)

            Text("Settings")
                .font(.system(size: 38, weight: .medium, design: .serif))
                .foregroundStyle(Color.prosePalInk)
                .lineLimit(1)
                .minimumScaleFactor(0.84)
        }
        .padding(.top, 4)
    }

    private var settingsProfileCard: some View {
        HStack(spacing: 14) {
            Text(profileInitials)
                .font(.system(size: 22, weight: .bold, design: .default))
                .foregroundStyle(Color.prosePalCoralDeep)
                .frame(width: 58, height: 58)
                .background(Color.prosePalCoral.opacity(0.16), in: Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(profileTitle)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Color.prosePalInk)
                    .lineLimit(1)
                    .minimumScaleFactor(0.84)

                Text(profileDetail)
                    .font(.callout)
                    .foregroundStyle(Color.prosePalSlate.opacity(0.78))
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
            }

            Spacer(minLength: 10)

            Text(account.isPremiumUnlocked ? "Pro" : "Free")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.prosePalCoralDeep)
                .padding(.horizontal, 13)
                .frame(height: 32)
                .background(Color.prosePalCoral.opacity(0.12), in: Capsule(style: .continuous))
        }
        .padding(16)
        .frame(maxWidth: .infinity, minHeight: 88, alignment: .leading)
        .background(Color.prosePalPaper.opacity(0.96), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.prosePalNavy.opacity(0.10), lineWidth: 1)
        }
        .shadow(color: Color.prosePalCoralDeep.opacity(0.08), radius: 12, x: 0, y: 6)
        .accessibilityElement(children: .combine)
    }

    private func settingsGroup<Content: View>(
        _ title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption.weight(.semibold))
                .textCase(.uppercase)
                .foregroundStyle(Color.prosePalSlate.opacity(0.72))
                .padding(.leading, 4)

            VStack(spacing: 0) {
                content()
            }
            .background(Color.prosePalPaper.opacity(0.94), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.prosePalNavy.opacity(0.10), lineWidth: 1)
            }
        }
    }

    private var settingsDivider: some View {
        Rectangle()
            .fill(Color.prosePalNavy.opacity(0.11))
            .frame(height: 0.5)
            .padding(.leading, 64)
    }

    private func settingsStaticRow(
        systemImage: String,
        title: String,
        subtitle: String? = nil,
        trailing: String? = nil,
        showsChevron: Bool = false
    ) -> some View {
        settingsRowBody(
            systemImage: systemImage,
            title: title,
            subtitle: subtitle,
            trailing: trailing,
            showsChevron: showsChevron
        )
    }

    private func settingsButtonRow(
        systemImage: String,
        title: String,
        subtitle: String? = nil,
        showsChevron: Bool = false,
        role: ButtonRole? = nil,
        action: @escaping () -> Void
    ) -> some View {
        Button(role: role, action: action) {
            settingsRowBody(
                systemImage: systemImage,
                title: title,
                subtitle: subtitle,
                showsChevron: showsChevron,
                isDestructive: role == .destructive
            )
        }
        .buttonStyle(.plain)
    }

    private func settingsNavigationRow<Destination: View>(
        systemImage: String,
        title: String,
        subtitle: String? = nil,
        @ViewBuilder destination: () -> Destination
    ) -> some View {
        NavigationLink {
            destination()
        } label: {
            settingsRowBody(
                systemImage: systemImage,
                title: title,
                subtitle: subtitle,
                showsChevron: true
            )
        }
        .buttonStyle(.plain)
    }

    private func settingsSwitchRow(
        systemImage: String,
        title: String,
        subtitle: String? = nil,
        isOn: Bool
    ) -> some View {
        HStack(spacing: 12) {
            settingsIcon(systemImage)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(Color.prosePalInk)

                if let subtitle {
                    Text(subtitle)
                        .font(.callout)
                        .foregroundStyle(Color.prosePalSlate.opacity(0.78))
                        .lineLimit(2)
                }
            }

            Spacer(minLength: 10)

            settingsSwitch(isOn: isOn)
        }
        .padding(.horizontal, 16)
        .frame(minHeight: 64)
        .accessibilityElement(children: .combine)
    }

    private func settingsRowBody(
        systemImage: String,
        title: String,
        subtitle: String? = nil,
        trailing: String? = nil,
        showsChevron: Bool = false,
        isDestructive: Bool = false
    ) -> some View {
        HStack(spacing: 12) {
            settingsIcon(systemImage, color: isDestructive ? Color.red.opacity(0.78) : Color.prosePalSlate)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(isDestructive ? Color.red.opacity(0.84) : Color.prosePalInk)
                    .lineLimit(1)
                    .minimumScaleFactor(0.84)

                if let subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.callout)
                        .foregroundStyle(Color.prosePalSlate.opacity(0.78))
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Spacer(minLength: 10)

            if let trailing {
                Text(trailing)
                    .font(.body)
                    .foregroundStyle(Color.prosePalSlate.opacity(0.64))
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)
            }

            if showsChevron {
                Image(systemName: "chevron.right")
                    .font(.body.weight(.medium))
                    .foregroundStyle(Color.prosePalSlate.opacity(0.48))
            }
        }
        .padding(.horizontal, 16)
        .frame(minHeight: 64)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }

    private func settingsLinkRowBody(systemImage: String, title: String) -> some View {
        settingsRowBody(
            systemImage: systemImage,
            title: title,
            showsChevron: true
        )
    }

    private func settingsIcon(_ systemImage: String, color: Color = Color.prosePalSlate) -> some View {
        Image(systemName: systemImage)
            .font(.system(size: 20, weight: .regular))
            .foregroundStyle(color)
            .frame(width: 36)
    }

    private func settingsSwitch(isOn: Bool) -> some View {
        ZStack(alignment: isOn ? .trailing : .leading) {
            Capsule(style: .continuous)
                .fill(isOn ? Color.prosePalCoral : Color.prosePalSlate.opacity(0.18))

            Circle()
                .fill(Color.prosePalPaper)
                .frame(width: 28, height: 28)
                .shadow(color: Color.prosePalNavy.opacity(0.16), radius: 3, x: 0, y: 2)
                .padding(2)
        }
        .frame(width: 56, height: 32)
        .accessibilityLabel(isOn ? "On" : "Off")
    }

    private var profileInitials: String {
        guard let firstCharacter = (account.signedInEmail ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .first
        else {
            return "PP"
        }
        return String(firstCharacter).uppercased()
    }

    private var profileTitle: String {
        account.isSignedIn ? "Apple account" : "ProsePal"
    }

    private var profileDetail: String {
        if account.isSignedIn {
            return account.signedInEmail ?? "Signed in with Apple"
        }
        return "Private on this iPhone"
    }

    private var versionText: String {
        account.appVersionDisplayText
    }

    private func copySupportEmail() {
        #if canImport(UIKit)
        UIPasteboard.general.string = MomentSettingsExternalLinks.supportEmail
        #elseif canImport(AppKit)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(MomentSettingsExternalLinks.supportEmail, forType: .string)
        #endif
        supportNotice = "Copied support email"
    }
}

private struct MomentPrivacyDataView: View {
    let account: MomentAccountModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var notice: String?
    @State private var eraseError: String?
    @State private var isConfirmingErase = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                topChrome
                trustNote

                privacyGroup("Controls") {
                    privacyStatusRow(
                        systemImage: "iphone",
                        title: "On-device drafts",
                        subtitle: "Process without leaving your iPhone",
                        trailing: account.runtimeReadiness.isPrivateDraftConfigured ? "On" : "Unavailable"
                    )
                    privacyDivider
                    privacyStatusRow(
                        systemImage: "chart.line.uptrend.xyaxis",
                        title: "Anonymous diagnostics",
                        subtitle: "Metadata only, no writing text",
                        trailing: "Minimal"
                    )
                }

                privacyGroup("Your data") {
                    NavigationLink {
                        MomentLocalDataExportView()
                    } label: {
                        privacyRowBody(
                            systemImage: "square.and.arrow.up",
                            title: "Export local data",
                            subtitle: "Drafts and approved relationship memory",
                            showsChevron: true
                        )
                    }
                    .buttonStyle(.plain)

                    privacyDivider

                    Button(role: .destructive) {
                        isConfirmingErase = true
                    } label: {
                        privacyRowBody(
                            systemImage: "trash",
                            title: "Delete local data",
                            subtitle: "Erase saved drafts and relationship memory",
                            isDestructive: true
                        )
                    }
                    .buttonStyle(.plain)
                }

                if let notice {
                    Label(notice, systemImage: "checkmark.circle")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.prosePalSlate)
                        .frame(maxWidth: .infinity, alignment: .center)
                }

                if let eraseError {
                    Label(eraseError, systemImage: "exclamationmark.triangle")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.prosePalCoralDeep)
                        .frame(maxWidth: .infinity, alignment: .center)
                }

                privacyFinePrint
            }
            .padding(.horizontal, 18)
            .padding(.top, 8)
            .padding(.bottom, 36)
        }
        .scrollIndicators(.hidden)
        .background {
            MomentAtmosphericBackground(isCareful: false)
        }
        .tint(.prosePalCoral)
        #if os(iOS)
        .toolbar(.hidden, for: .navigationBar)
        #endif
        .confirmationDialog(
            "Delete local data?",
            isPresented: $isConfirmingErase,
            titleVisibility: .visible
        ) {
            Button("Delete local data", role: .destructive) {
                eraseLocalData()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This erases saved drafts, truth beads, and voice cards stored on this device. Your account is not deleted.")
        }
    }

    private var topChrome: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button {
                dismiss()
            } label: {
                Label("Settings", systemImage: "chevron.left")
                    .font(.body.weight(.regular))
                    .labelStyle(.titleAndIcon)
            }
            .buttonStyle(.plain)
            .foregroundStyle(Color.prosePalCoralDeep)
            .frame(minHeight: 36, alignment: .leading)

            Text("Privacy & data")
                .font(.system(.title2, design: .serif).weight(.medium))
                .foregroundStyle(Color.prosePalInk)
                .lineLimit(1)
                .minimumScaleFactor(0.82)
        }
    }

    private var trustNote: some View {
        HStack(alignment: .top, spacing: 13) {
            Image(systemName: "lock")
                .font(.system(size: 20, weight: .regular))
                .foregroundStyle(Color.prosePalCoralDeep)
                .frame(width: 42, height: 42)
                .background(Color.prosePalCoral.opacity(0.12), in: RoundedRectangle(cornerRadius: 14, style: .continuous))

            VStack(alignment: .leading, spacing: 5) {
                Text("Your writing stays yours")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(Color.prosePalInk)

                Text("ProsePal processes drafts privately. Your words are never used to train models, and you can erase them at any time.")
                    .font(.callout)
                    .foregroundStyle(Color.prosePalSlate.opacity(0.78))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
        .background(Color.prosePalPaper.opacity(0.92), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.prosePalNavy.opacity(0.10), lineWidth: 1)
        }
    }

    private func privacyGroup<Content: View>(
        _ title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption.weight(.semibold))
                .textCase(.uppercase)
                .foregroundStyle(Color.prosePalSlate.opacity(0.72))
                .padding(.leading, 4)

            VStack(spacing: 0) {
                content()
            }
            .background(Color.prosePalPaper.opacity(0.94), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.prosePalNavy.opacity(0.10), lineWidth: 1)
            }
        }
    }

    private var privacyDivider: some View {
        Rectangle()
            .fill(Color.prosePalNavy.opacity(0.11))
            .frame(height: 0.5)
            .padding(.leading, 64)
    }

    private func privacyStatusRow(
        systemImage: String,
        title: String,
        subtitle: String,
        trailing: String
    ) -> some View {
        privacyRowBody(
            systemImage: systemImage,
            title: title,
            subtitle: subtitle,
            trailing: trailing
        )
    }

    private func privacyRowBody(
        systemImage: String,
        title: String,
        subtitle: String? = nil,
        trailing: String? = nil,
        showsChevron: Bool = false,
        isDestructive: Bool = false
    ) -> some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: 19, weight: .regular))
                .foregroundStyle(isDestructive ? Color.red.opacity(0.78) : Color.prosePalSlate)
                .frame(width: 36)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(isDestructive ? Color.red.opacity(0.84) : Color.prosePalInk)
                    .lineLimit(1)
                    .minimumScaleFactor(0.84)

                if let subtitle {
                    Text(subtitle)
                        .font(.callout)
                        .foregroundStyle(Color.prosePalSlate.opacity(0.78))
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Spacer(minLength: 10)

            if let trailing {
                Text(trailing)
                    .font(.callout.weight(.medium))
                    .foregroundStyle(Color.prosePalSlate.opacity(0.68))
                    .lineLimit(1)
                    .minimumScaleFactor(0.74)
            }

            if showsChevron {
                Image(systemName: "chevron.right")
                    .font(.body.weight(.medium))
                    .foregroundStyle(Color.prosePalSlate.opacity(0.48))
            }
        }
        .padding(.horizontal, 16)
        .frame(minHeight: 64)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }

    private var privacyFinePrint: some View {
        HStack(spacing: 4) {
            Text("Read our")
            Link("Privacy Policy", destination: MomentSettingsExternalLinks.privacy)
            Text("for the full details.")
        }
        .font(.caption)
        .foregroundStyle(Color.prosePalSlate.opacity(0.68))
        .frame(maxWidth: .infinity)
        .multilineTextAlignment(.center)
    }

    private func eraseLocalData() {
        do {
            try RelationshipVaultLocalDataEraser.eraseAll(in: modelContext)
            eraseError = nil
            notice = "Local data deleted"
        } catch {
            notice = nil
            eraseError = "Could not delete local data. Please try again."
        }
    }
}

private struct MomentLocalDataExportView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var exportState: MomentLocalDataExportState = .loading
    @State private var notice: String?

    var body: some View {
        List {
            switch exportState {
            case .loading:
                Section {
                    ProgressView("Preparing export")
                }
                .momentListRowSurface()

            case .ready(let export):
                Section {
                    Label("Export ready", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.primary)
                    LabeledContent("File", value: export.fileName)
                    LabeledContent("Truth Beads", value: "\(export.snapshot.counts.truthBeads)")
                    LabeledContent("Voice Cards", value: "\(export.snapshot.counts.voiceCards)")
                    LabeledContent("Saved Drafts", value: "\(export.snapshot.counts.savedDrafts)")
                } header: {
                    MomentListSectionHeader("Summary")
                }
                .momentListRowSurface()

                Section {
                    Button {
                        copy(export.jsonString)
                    } label: {
                        Label("Copy JSON", systemImage: "doc.on.doc")
                    }

                    Button {
                        prepareExport()
                    } label: {
                        Label("Refresh export", systemImage: "arrow.clockwise")
                    }
                } header: {
                    MomentListSectionHeader("Actions")
                }
                .momentListRowSurface()

                if let notice {
                    Section {
                        Label(notice, systemImage: "checkmark.circle.fill")
                    }
                    .momentListRowSurface()
                }

                Section {
                    Text(export.preview)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)
                        .fixedSize(horizontal: false, vertical: true)
                } header: {
                    MomentListSectionHeader("Preview")
                }
                .momentListRowSurface()

            case .failed:
                Section {
                    Label("Export failed. Please try again.", systemImage: "exclamationmark.triangle")
                    Button {
                        prepareExport()
                    } label: {
                        Label("Try again", systemImage: "arrow.clockwise")
                    }
                }
                .momentListRowSurface()
            }
        }
        .navigationTitle("Export")
        .toolbarTitleDisplayMode(.inline)
        .contentMargins(.top, 6, for: .scrollContent)
        .scrollContentBackground(.hidden)
        .background {
            MomentAtmosphericBackground(isCareful: false)
        }
        .tint(.prosePalCoral)
        .task {
            if case .loading = exportState {
                prepareExport()
            }
        }
    }

    private func prepareExport() {
        notice = nil

        do {
            let exportedAt = Date()
            let snapshot = try RelationshipVaultExporter.snapshot(
                in: modelContext,
                exportedAt: exportedAt
            )
            let data = try RelationshipVaultExporter.encodedData(for: snapshot)
            guard let jsonString = String(data: data, encoding: .utf8) else {
                throw MomentLocalDataExportError.encodingFailed
            }

            exportState = .ready(MomentLocalDataExport(
                fileName: RelationshipVaultExporter.fileName(exportedAt: exportedAt),
                snapshot: snapshot,
                jsonString: jsonString
            ))
        } catch {
            exportState = .failed
        }
    }

    private func copy(_ jsonString: String) {
        #if canImport(UIKit)
        UIPasteboard.general.string = jsonString
        #elseif canImport(AppKit)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(jsonString, forType: .string)
        #endif
        notice = "Copied JSON"
    }
}

private enum MomentLocalDataExportState {
    case loading
    case ready(MomentLocalDataExport)
    case failed
}

private struct MomentLocalDataExport {
    var fileName: String
    var snapshot: RelationshipVaultExportSnapshot
    var jsonString: String

    var preview: String {
        let maxCharacters = 2_400
        guard jsonString.count > maxCharacters else {
            return jsonString
        }

        return String(jsonString.prefix(maxCharacters)) + "\n..."
    }
}

private enum MomentLocalDataExportError: Error {
    case encodingFailed
}

private enum MomentSettingsPresentedSheet: Identifiable {
    case paywall

    var id: String {
        "paywall"
    }
}

private struct MomentAppleSignInControl: View {
    @Bindable var account: MomentAccountModel
    let source: String

    var body: some View {
        #if canImport(AuthenticationServices)
        if account.isAppleSignInConfigured {
            SignInWithAppleButton(.continue) { request in
                request.requestedScopes = [.email, .fullName]
                request.nonce = account.beginAppleSignInRequest(source: source)
            } onCompletion: { result in
                handle(result)
            }
            .signInWithAppleButtonStyle(.black)
            .frame(maxWidth: .infinity, minHeight: 52, maxHeight: 52)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .disabled(account.isSigningIn)
            .accessibilityLabel("Continue with Apple")
        } else {
            fallbackButton
        }
        #else
        fallbackButton
        #endif
    }

    private var fallbackButton: some View {
        Button {
            _ = account.beginAppleSignInRequest(source: source)
        } label: {
            Label("Continue with Apple", systemImage: "apple.logo")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
        .controlSize(.large)
        .tint(.prosePalNavy)
        .disabled(account.isSigningIn)
    }

    #if canImport(AuthenticationServices)
    private func handle(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            guard
                let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
                let tokenData = credential.identityToken,
                let token = String(data: tokenData, encoding: .utf8)
            else {
                Task { @MainActor in
                    await account.completeAppleSignIn(idToken: nil, source: source)
                }
                return
            }

            Task { @MainActor in
                await account.completeAppleSignIn(idToken: token, source: source)
            }
        case .failure(let error):
            if let authorizationError = error as? ASAuthorizationError,
               authorizationError.code == .canceled {
                account.cancelAppleSignIn(source: source)
            } else {
                account.failAppleSignIn(source: source, category: "authorization_error")
            }
        }
    }
    #endif
}

private struct MomentPaywallSheet: View {
    @Bindable var account: MomentAccountModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    paywallTopChrome
                    paywallHero
                    paywallFeaturePanel
                    productSection
                    purchaseActionSection
                    accountSection
                    paywallFinePrint
                }
                .padding(18)
                .padding(.bottom, 28)
            }
            .scrollIndicators(.hidden)
            .background {
                MomentAtmosphericBackground(isCareful: true)
            }
            .momentNavigationBarColorScheme()
            #if os(iOS)
            .toolbar(.hidden, for: .navigationBar)
            #endif
            .task {
                await account.loadSubscriptionProducts(source: "paywall")
            }
        }
    }

    private var paywallTopChrome: some View {
        HStack(alignment: .center) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .medium))
                    .frame(width: 42, height: 42)
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .foregroundStyle(Color.prosePalCoralDeep)
            .background(Color.prosePalPaper.opacity(0.74), in: Circle())
            .accessibilityLabel("Close")

            Spacer(minLength: 12)

            Button {
                Task {
                    await account.restorePurchases(source: "paywall")
                    if account.isPremiumUnlocked {
                        dismiss()
                    }
                }
            } label: {
                Text(account.isRestoringPurchases ? "Restoring" : "Restore")
                    .font(.body.weight(.medium))
                    .frame(minHeight: 42, alignment: .trailing)
            }
            .buttonStyle(.plain)
            .foregroundStyle(Color.prosePalCoralDeep)
            .disabled(account.isRestoringPurchases)
        }
        .padding(.top, 2)
    }

    private var paywallHero: some View {
        VStack(spacing: 10) {
            Image(systemName: "pencil.and.scribble")
                .font(.system(size: 30, weight: .regular))
                .foregroundStyle(Color.prosePalCoralDeep)
                .frame(width: 64, height: 64)
                .background(
                    LinearGradient(
                        colors: [
                            Color.prosePalCoral.opacity(0.20),
                            Color.prosePalCare.opacity(0.14)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    in: RoundedRectangle(cornerRadius: 18, style: .continuous)
                )

            Text("A room of your own.")
                .font(.system(size: 34, weight: .regular, design: .serif).italic())
                .foregroundStyle(Color.prosePalInk)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.82)

            Text("Unlimited drafts, every register of tone, and a voice profile that remembers how you write.")
                .font(.callout)
                .foregroundStyle(Color.prosePalSlate.opacity(0.78))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }

    private var paywallFeaturePanel: some View {
        VStack(spacing: 0) {
            MomentPremiumFeatureRow(
                systemImage: "infinity",
                title: "Unlimited drafts",
                detail: "Write and revise without counting"
            )
            MomentPaywallDivider()
            MomentPremiumFeatureRow(
                systemImage: "book.closed",
                title: "Your voice profile",
                detail: "ProsePal learns your cadence over time"
            )
            MomentPaywallDivider()
            MomentPremiumFeatureRow(
                systemImage: "lock",
                title: "Kept private",
                detail: "Your pages never train a model"
            )
        }
        .padding(.vertical, 4)
        .background(Color.prosePalPaper.opacity(0.92), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.prosePalNavy.opacity(0.10), lineWidth: 1)
        }
        .shadow(color: Color.prosePalCoralDeep.opacity(0.07), radius: 12, x: 0, y: 6)
    }

    @ViewBuilder
    private var purchaseActionSection: some View {
        if !account.subscriptionProducts.isEmpty {
            VStack(spacing: 9) {
                Button {
                    Task {
                        await account.purchasePremium(source: "paywall")
                        if account.isPremiumUnlocked {
                            dismiss()
                        }
                    }
                } label: {
                    Text(account.isPurchasingPremium ? "Working..." : "Continue")
                        .font(.headline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                }
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.capsule)
                .tint(.prosePalCoral)
                .disabled(account.isPurchasingPremium || account.isLoadingSubscriptions)

                Text(account.premiumRenewalDisclosureText)
                    .font(.caption2)
                    .foregroundStyle(Color.prosePalSlate.opacity(0.72))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var accountSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Account")
                .font(.headline.weight(.semibold))
                .foregroundStyle(Color.prosePalInk)

            Text(account.isSignedIn ? "Purchases are connected to your Apple account." : "Sign in with Apple to connect purchases to you.")
                .font(.callout)
                .foregroundStyle(Color.prosePalSlate.opacity(0.78))
                .fixedSize(horizontal: false, vertical: true)

            if !account.isSignedIn {
                MomentAppleSignInControl(account: account, source: "paywall")
            }
        }
        .padding(16)
        .background(Color.prosePalPaper.opacity(0.92), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.prosePalNavy.opacity(0.10), lineWidth: 1)
        }
    }

    private var paywallFinePrint: some View {
        HStack(spacing: 8) {
            Text("Cancel anytime")
            Text("·")
            Link("Terms", destination: MomentSettingsExternalLinks.terms)
            Text("·")
            Link("Privacy", destination: MomentSettingsExternalLinks.privacy)
        }
        .font(.caption.weight(.medium))
        .foregroundStyle(Color.prosePalSlate.opacity(0.74))
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private var productSection: some View {
        if account.isLoadingSubscriptions {
            MomentPaywallLoadingRow()
        } else if account.subscriptionProducts.isEmpty {
            MomentPaywallUnavailableRow(
                message: account.subscriptionErrorMessage ?? SubscriptionError.notConfigured.userSafeMessage,
                onRetry: {
                    Task {
                        await account.loadSubscriptionProducts(source: "paywall_retry")
                    }
                }
            )
        } else {
            VStack(spacing: 10) {
                ForEach(account.subscriptionProducts) { product in
                    Button {
                        account.selectSubscriptionProduct(product)
                    } label: {
                        MomentPaywallPlanRow(
                            title: product.displayName,
                            subtitle: product.durationLabel ?? "Premium access",
                            price: product.displayPrice,
                            badge: product.isRecommended ? "Best value" : nil,
                            isSelected: account.selectedSubscriptionProductID == product.id
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

private struct MomentPremiumFeatureRow: View {
    let systemImage: String
    let title: String
    let detail: String

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: 18, weight: .regular))
                .foregroundStyle(Color.prosePalCoralDeep)
                .frame(width: 34, height: 34)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(Color.prosePalInk)
                Text(detail)
                    .font(.callout)
                    .foregroundStyle(Color.prosePalSlate.opacity(0.78))
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
        .padding(.vertical, 11)
        .accessibilityElement(children: .combine)
    }
}

private struct MomentPaywallDivider: View {
    var body: some View {
        Rectangle()
            .fill(Color.prosePalNavy.opacity(0.11))
            .frame(height: 0.5)
            .padding(.leading, 62)
    }
}

private struct MomentPaywallPlanRow: View {
    let title: String
    let subtitle: String
    let price: String
    let badge: String?
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 22, weight: .regular))
                .foregroundStyle(isSelected ? Color.prosePalCoral : Color.prosePalSlate.opacity(0.42))

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 8) {
                    Text(title)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(Color.prosePalInk)

                    if let badge {
                        Text(badge)
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(Color.prosePalCoralDeep)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(Color.prosePalCoral.opacity(0.13), in: Capsule())
                    }
                }

                Text(subtitle)
                    .font(.callout)
                    .foregroundStyle(Color.prosePalSlate.opacity(0.78))
            }

            Spacer(minLength: 10)

            Text(price)
                .font(.headline.weight(.semibold))
                .foregroundStyle(Color.prosePalInk)
        }
        .padding(16)
        .background(Color.prosePalPaper.opacity(isSelected ? 0.98 : 0.86), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(isSelected ? Color.prosePalCoral.opacity(0.32) : Color.prosePalNavy.opacity(0.10), lineWidth: 1)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct MomentPaywallLoadingRow: View {
    var body: some View {
        HStack(spacing: 12) {
            ProgressView()
                .tint(.prosePalCoral)

            VStack(alignment: .leading, spacing: 3) {
                Text("Loading subscription options")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(Color.prosePalInk)
                Text("This should only take a moment.")
                    .font(.callout)
                    .foregroundStyle(Color.prosePalSlate.opacity(0.78))
            }

            Spacer(minLength: 0)
        }
        .padding(16)
        .background(Color.prosePalPaper.opacity(0.92), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.prosePalNavy.opacity(0.10), lineWidth: 1)
        }
        .accessibilityElement(children: .combine)
    }
}

private struct MomentPaywallUnavailableRow: View {
    let message: String
    let onRetry: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 12) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 18, weight: .regular))
                    .foregroundStyle(Color.prosePalCoralDeep)
                    .frame(width: 34, height: 34)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Subscription options unavailable")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(Color.prosePalInk)
                    Text(message)
                        .font(.callout)
                        .foregroundStyle(Color.prosePalSlate.opacity(0.78))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Button {
                onRetry()
            } label: {
                Label("Retry", systemImage: "arrow.clockwise")
                    .font(.headline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
            }
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.capsule)
            .tint(.prosePalCoral)
        }
        .padding(16)
        .background(Color.prosePalPaper.opacity(0.92), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.prosePalNavy.opacity(0.10), lineWidth: 1)
        }
        .accessibilityElement(children: .combine)
    }
}

private enum MomentSettingsExternalLinks {
    static let terms = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!
    static let privacy = URL(string: "https://prosepal.app/privacy")!
    static let supportEmail = "support@prosepal.app"
    static let support = URL(string: "mailto:\(supportEmail)")!
}

private extension Relationship {
    var momentSearchText: String {
        "\(displayName) \(group.displayName) \(generationHint)"
    }
}

private extension String {
    var momentNormalizedSearchKey: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
    }
}

private extension MomentAdjustment {
    var systemImage: String {
        switch self {
        case .warmer:
            "sun.max"
        case .shorter:
            "scissors"
        case .moreDirect:
            "arrow.right"
        }
    }
}
