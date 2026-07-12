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
    case timedOut(lane: GenerationTimeoutLane)
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
        case .timedOut(let lane):
            self = .timedOut(lane: lane)
        case .rateLimited:
            self = .rateLimited
        case .requestNeedsFreshKey:
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
    public var tone: Tone
    public var length: MessageLength
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
        tone: Tone = .heartfelt,
        length: MessageLength = .standard,
        trueThing: String,
        bundle: MomentDraftBundle,
        draftSnapshots: [MomentDraftSnapshot],
        savedAt: Date = Date()
    ) {
        self.schemaVersion = schemaVersion
        self.personName = ProsePalTextInput.personName(personName)
        self.relationship = relationship
        self.occasion = occasion
        self.register = register
        self.tone = tone
        self.length = length
        self.trueThing = ProsePalTextInput.momentDetail(trueThing)
        self.bundle = bundle
        self.draftSnapshots = Array(draftSnapshots.suffix(12))
        self.savedAt = savedAt
    }

    public var hasRecoverableDraft: Bool {
        !personName.isEmpty && !bundle.messageText.isEmpty
    }

    private enum CodingKeys: String, CodingKey {
        case schemaVersion
        case personName
        case relationship
        case occasion
        case register
        case tone
        case length
        case trueThing
        case bundle
        case draftSnapshots
        case savedAt
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        schemaVersion = try container.decode(Int.self, forKey: .schemaVersion)
        personName = ProsePalTextInput.personName(
            try container.decode(String.self, forKey: .personName)
        )
        relationship = try container.decode(Relationship.self, forKey: .relationship)
        occasion = try container.decode(Occasion.self, forKey: .occasion)
        register = try container.decode(MomentRegister.self, forKey: .register)
        tone = try container.decodeIfPresent(Tone.self, forKey: .tone) ?? .heartfelt
        length = try container.decodeIfPresent(MessageLength.self, forKey: .length) ?? .standard
        trueThing = ProsePalTextInput.momentDetail(
            try container.decode(String.self, forKey: .trueThing)
        )
        bundle = try container.decode(MomentDraftBundle.self, forKey: .bundle)
        draftSnapshots = Array((try container.decode([MomentDraftSnapshot].self, forKey: .draftSnapshots)).suffix(12))
        savedAt = try container.decode(Date.self, forKey: .savedAt)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(schemaVersion, forKey: .schemaVersion)
        try container.encode(personName, forKey: .personName)
        try container.encode(relationship, forKey: .relationship)
        try container.encode(occasion, forKey: .occasion)
        try container.encode(register, forKey: .register)
        try container.encode(tone, forKey: .tone)
        try container.encode(length, forKey: .length)
        try container.encode(trueThing, forKey: .trueThing)
        try container.encode(bundle, forKey: .bundle)
        try container.encode(draftSnapshots, forKey: .draftSnapshots)
        try container.encode(savedAt, forKey: .savedAt)
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
    public var tone: Tone = .heartfelt
    public var length: MessageLength = .standard
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
    @ObservationIgnored private let draftRecoveryStore: any MomentDraftRecoveryStoring
    @ObservationIgnored private var draftTask: Task<Void, Never>?
    @ObservationIgnored private var draftGeneration = 0

    public init(
        service: any MessageWritingService,
        diagnostics: NativeDiagnosticsLogger = .shared,
        draftRecoveryStore: any MomentDraftRecoveryStoring = MomentDraftRecoveryNoopStore()
    ) {
        self.service = service
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
        if bundle.lane == .takeMoreCare {
            adjust(.moreDirect, acknowledgePressureResult: true)
        } else {
            takeMoreCare(acknowledgePressureResult: true)
        }
    }

    public func applyLaunchRequest(_ request: MomentLaunchRequest) {
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
        tone = .heartfelt
        length = .standard
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

    public func startDraft() {
        guard canDraft, !isDrafting else { return }
        isDrafting = true
        draftTask?.cancel()
        let generation = nextDraftGeneration()
        draftTask = Task { [weak self] in
            await self?.draftNow(generation: generation, trigger: "manual")
        }
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

        currentBundle.messageText = ProsePalTextInput.draft(messageText)
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
            let nextBundle = try await service.draft(for: input)
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
            let nextBundle = try await service.adjust(bundle, with: adjustment, moment: input)
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
            let nextBundle = try await service.takeMoreCare(bundle, moment: input)
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
        tone = state.tone
        length = state.length
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

struct MomentShareRequest: Identifiable {
    let id = UUID()
    let activityItems: [Any]

    static func text(_ text: String) -> MomentShareRequest {
        MomentShareRequest(activityItems: [text])
    }
}

private struct MomentDraftUseSheetRequest: Identifiable {
    let id = UUID()
    let bundle: MomentDraftBundle
    let toneLabel: String

    var previewText: String {
        let trimmed = bundle.messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        let maximumPreviewCharacters = 86
        guard trimmed.count > maximumPreviewCharacters else { return trimmed }

        let prefix = String(trimmed.prefix(maximumPreviewCharacters))
        let boundary = prefix.lastIndex(where: { $0.isWhitespace }) ?? prefix.endIndex
        let wordBoundedPrefix = prefix[..<boundary].trimmingCharacters(in: .whitespacesAndNewlines)
        return "\(wordBoundedPrefix)…"
    }
}

private struct MomentTransientToast: Identifiable, Equatable {
    let id = UUID()
    var message: String
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

private struct MomentDraftUseSheet: View {
    let request: MomentDraftUseSheetRequest
    let onCopy: () -> Void
    let onSave: () -> Void
    let onShareDestination: (String) -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private let destinations = [
        MomentDraftShareDestination(id: "messages", title: "Messages", systemImage: "message.fill", tint: Color.prosePalCare),
        MomentDraftShareDestination(id: "mail", title: "Mail", systemImage: "envelope.fill", tint: Color.blue.opacity(0.82)),
        MomentDraftShareDestination(id: "notes", title: "Notes", systemImage: "note.text", tint: Color.prosePalWarning),
        MomentDraftShareDestination(id: "more", title: "More", systemImage: "ellipsis.circle.fill", tint: Color.prosePalSlate.opacity(0.82))
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            grabber

            Text("Send draft")
                .font(.headline.weight(.semibold))
                .foregroundStyle(Color.prosePalInk)
                .frame(maxWidth: .infinity, alignment: .center)

            previewCard

            destinationRow

            actionRows

            Button {
                dismiss()
            } label: {
                Text("Cancel")
                    .font(.headline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
            }
            .buttonStyle(.plain)
            .foregroundStyle(Color.prosePalInk)
            .background(Color.prosePalPaper.opacity(0.78), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .padding(.horizontal, 18)
        .padding(.top, 8)
        .padding(.bottom, 20)
        .background {
            MomentAtmosphericBackground(isCareful: request.bundle.lane == .takeMoreCare)
                .opacity(0.36)
                .ignoresSafeArea()
        }
    }

    private var grabber: some View {
        Capsule(style: .continuous)
            .fill(Color.prosePalSlate.opacity(0.38))
            .frame(width: 38, height: 5)
            .frame(maxWidth: .infinity)
            .padding(.top, 3)
            .padding(.bottom, 2)
            .accessibilityHidden(true)
    }

    private var previewCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label("\(request.toneLabel) · your voice kept", systemImage: "checkmark.seal")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.prosePalCare)
                .labelStyle(.titleAndIcon)
                .lineLimit(1)
                .minimumScaleFactor(0.78)

            Text("\"\(request.previewText)\"")
                .font(.system(.callout, design: .serif))
                .lineSpacing(3)
                .foregroundStyle(Color.prosePalSlate)
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.prosePalPaper.opacity(0.94), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.prosePalNavy.opacity(0.10), lineWidth: 1)
        }
        .accessibilityElement(children: .combine)
    }

    private var destinationRow: some View {
        LazyVGrid(columns: destinationColumns, spacing: 8) {
            ForEach(destinations) { destination in
                destinationButton(destination)
                .simultaneousGesture(TapGesture().onEnded {
                    onShareDestination(destination.id)
                })
            }
        }
    }

    private var destinationColumns: [GridItem] {
        if dynamicTypeSize.isAccessibilitySize {
            return [GridItem(.flexible(), spacing: 8)]
        }
        return [
            GridItem(.flexible(), spacing: 8),
            GridItem(.flexible(), spacing: 8)
        ]
    }

    private func destinationButton(_ destination: MomentDraftShareDestination) -> some View {
        ShareLink(item: request.bundle.messageText) {
            HStack(spacing: 10) {
                Image(systemName: destination.systemImage)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(destination.tint)
                    .frame(width: 34, height: 34)
                    .background(Color.prosePalPaper.opacity(0.94), in: Circle())
                    .shadow(color: Color.prosePalNavy.opacity(0.08), radius: 6, x: 0, y: 3)

                Text(destination.title)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Color.prosePalSlate)
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity)
            .frame(height: 58)
            .background(Color.prosePalPaper.opacity(0.46), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.prosePalNavy.opacity(0.08), lineWidth: 1)
            }
        }
    }

    private var actionRows: some View {
        VStack(spacing: 0) {
            sheetActionRow(systemImage: "doc.on.doc", title: "Copy to clipboard") {
                dismiss()
                onCopy()
            }

            Divider()
                .padding(.leading, 52)

            sheetActionRow(systemImage: "bookmark", title: "Save to drafts") {
                dismiss()
                onSave()
            }
        }
        .background(Color.prosePalPaper.opacity(0.94), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.prosePalNavy.opacity(0.10), lineWidth: 1)
        }
    }

    private func sheetActionRow(
        systemImage: String,
        title: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: systemImage)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(Color.prosePalCoralDeep)
                    .frame(width: 28)
                    .accessibilityHidden(true)

                Text(title)
                    .font(.body.weight(.medium))
                    .foregroundStyle(Color.prosePalInk)

                Spacer(minLength: 8)

                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Color.prosePalSlate.opacity(0.48))
                    .accessibilityHidden(true)
            }
            .padding(.horizontal, 14)
            .frame(height: 54)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private struct MomentDraftShareDestination: Identifiable {
        var id: String
        var title: String
        var systemImage: String
        var tint: Color
    }
}

private struct MomentCopiedToast: View {
    let message: String

    var body: some View {
        Label(message, systemImage: "checkmark.circle.fill")
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(Color.prosePalInk)
            .padding(.horizontal, 18)
            .frame(minHeight: 48)
            .background(.regularMaterial, in: Capsule(style: .continuous))
            .overlay {
                Capsule(style: .continuous)
                    .stroke(Color.prosePalNavy.opacity(0.10), lineWidth: 1)
            }
            .shadow(color: Color.prosePalCoralDeep.opacity(0.14), radius: 16, x: 0, y: 8)
            .accessibilityElement(children: .combine)
    }
}

extension View {
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

private enum MemoryDeletionRequest {
    case truthBead(RelationshipTruthBeadRecord)
    case voiceCard(RelationshipVoiceCardRecord)

    var actionTitle: String {
        switch self {
        case .truthBead:
            "Delete detail"
        case .voiceCard:
            "Delete voice card"
        }
    }

    var message: String {
        switch self {
        case .truthBead:
            "This removes the saved detail from this device. This cannot be undone."
        case .voiceCard:
            "This removes the saved voice card from this device. This cannot be undone."
        }
    }
}

private struct MemoryDeletionConfirmationModifier: ViewModifier {
    @Binding var request: MemoryDeletionRequest?
    let onConfirm: (MemoryDeletionRequest) -> Void

    func body(content: Content) -> some View {
        content.confirmationDialog(
            "Delete saved memory?",
            isPresented: Binding(
                get: { request != nil },
                set: { isPresented in
                    if !isPresented {
                        request = nil
                    }
                }
            ),
            titleVisibility: .visible,
            presenting: request
        ) { request in
            Button(request.actionTitle, role: .destructive) {
                onConfirm(request)
            }
            Button("Cancel", role: .cancel) {
                self.request = nil
            }
        } message: { request in
            Text(request.message)
        }
    }
}

struct MomentSheetView: View {
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
    @State private var useDraftRequest: MomentDraftUseSheetRequest?
    @State private var transientToast: MomentTransientToast?
    @State private var isShowingDraftSource = false
    @State private var isShowingReviseMode = false
    @State private var selectedDraftRevisionTab: DraftRevisionTab = .draft
    @State private var pendingMemoryDeletion: MemoryDeletionRequest?

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
        case original

        var id: String { rawValue }

        var title: String {
            switch self {
            case .draft:
                return "Draft"
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
        .sheet(item: $useDraftRequest) { request in
            MomentDraftUseSheet(
                request: request,
                onCopy: {
                    copy(request.bundle.messageText, source: "draft_use_sheet")
                },
                onSave: {
                    save(request.bundle)
                },
                onShareDestination: { destination in
                    diagnostics.messageAction(
                        "send_handoff_\(destination)",
                        source: "draft_send_sheet",
                        messageCharacters: request.bundle.messageText.count
                    )
                }
            )
            #if os(iOS)
            .presentationDetents([.height(dynamicTypeSize.isAccessibilitySize ? 620 : 520)])
            .presentationDragIndicator(.hidden)
            .presentationBackground(.regularMaterial)
            #endif
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
        .modifier(
            MemoryDeletionConfirmationModifier(
                request: $pendingMemoryDeletion,
                onConfirm: confirmMemoryDeletion
            )
        )
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
        .onChange(of: model.tone) { _, newValue in
            diagnostics.selectionChanged(kind: "moment_tone", value: newValue.rawValue)
            model.resetDraftForMomentChange()
        }
        .onChange(of: model.length) { _, newValue in
            diagnostics.selectionChanged(kind: "moment_length", value: newValue.rawValue)
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
            if isShowingInitialGenerationState {
                generatingContent
            } else if let bundle = model.bundle, isShowingReviseMode {
                draftReviseContent(bundle)
            } else if let bundle = model.bundle, !isShowingDraftSource {
                draftResultContent(bundle)
            } else if isShowingOfflineDraftState {
                offlineDraftStateContent
            } else if isShowingQuotaReachedState {
                quotaReachedStateContent(viewportHeight: viewportHeight)
            } else if isShowingGenerationErrorState {
                generationErrorStateContent(viewportHeight: viewportHeight)
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

    private var toastBottomPadding: CGFloat {
        if focusedField != nil {
            return 24
        }
        if model.bundle != nil && !isShowingDraftSource {
            return dynamicTypeSize.isAccessibilitySize ? 34 : 96
        }
        if model.bundle != nil {
            return dynamicTypeSize.isAccessibilitySize ? 34 : 118
        }
        return 92
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

    private var isShowingInitialGenerationState: Bool {
        model.isDrafting &&
            model.bundle == nil &&
            model.errorMessage == nil &&
            shouldUseActiveMomentLayout
    }

    private var isShowingOfflineDraftState: Bool {
        model.draftUnavailableReason == .offline &&
            model.errorMessage != nil &&
            (model.bundle == nil || isShowingDraftSource) &&
            !model.isDrafting &&
            shouldUseActiveMomentLayout
    }

    private var isShowingGenerationErrorState: Bool {
        guard
            model.errorMessage != nil,
            (model.bundle == nil || isShowingDraftSource),
            !model.isDrafting,
            shouldUseActiveMomentLayout
        else {
            return false
        }

        switch model.draftUnavailableReason {
        case .timedOut, .rateLimited, .serviceUnavailable, .unexpectedResponse, .unexpected:
            return true
        case .offline, .usageLimitReached, .contentBlocked, .none:
            return false
        }
    }

    private var isShowingQuotaReachedState: Bool {
        model.draftUnavailableReason == .usageLimitReached &&
            model.errorMessage != nil &&
            (model.bundle == nil || isShowingDraftSource) &&
            !model.isDrafting &&
            shouldUseActiveMomentLayout
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

    private var shouldShowFloatingDraftActionRail: Bool {
        !dynamicTypeSize.isAccessibilitySize && !isShowingDraftSource
    }

    @ViewBuilder
    private var bottomInsetContent: some View {
        ZStack(alignment: .bottom) {
            bottomInsetRailContent
            transientToastOverlay
        }
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private var bottomInsetRailContent: some View {
        if isShowingInitialGenerationState {
            Color.clear
                .frame(height: 8)
                .accessibilityHidden(true)
        } else if let bundle = model.bundle, isShowingReviseMode, focusedField == nil {
            draftRevisionKeepButton(bundle: bundle)
                .padding(.horizontal, 18)
                .padding(.top, 10)
                .padding(.bottom, 12)
        } else if let bundle = model.bundle, !isShowingBlockingDraftState, focusedField == nil, shouldShowFloatingDraftActionRail {
            draftFloatingControls(bundle: bundle)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .momentControlBarSurface()
        } else {
            MomentBottomRailClearance(isCareful: model.moment.isCarefulMode)
                .frame(height: focusedField == nil ? 76 : 56)
        }
    }

    private var isShowingBlockingDraftState: Bool {
        isShowingOfflineDraftState || isShowingGenerationErrorState || isShowingQuotaReachedState
    }

    @ViewBuilder
    private var transientToastOverlay: some View {
        if let transientToast {
            MomentCopiedToast(message: transientToast.message)
                .padding(.horizontal, 24)
                .padding(.bottom, toastBottomPadding)
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .allowsHitTesting(false)
                .zIndex(10)
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
        if isShowingInitialGenerationState {
            return 18
        }
        return model.bundle != nil && !isShowingDraftSource ? 18 : 20
    }

    private var topChromeBottomPadding: CGFloat {
        if isShowingInitialGenerationState {
            return dynamicTypeSize.isAccessibilitySize ? 12 : 6
        }
        if model.bundle != nil && (isShowingReviseMode || !isShowingDraftSource) {
            return dynamicTypeSize.isAccessibilitySize ? 12 : 5
        }
        if isShowingGenerationErrorState {
            return dynamicTypeSize.isAccessibilitySize ? 12 : 18
        }
        return 8
    }

    @ViewBuilder
    private var topChrome: some View {
        if isShowingInitialGenerationState {
            generatingTopChrome
        } else if isShowingQuotaReachedState {
            quotaReachedTopChrome
        } else if isShowingGenerationErrorState {
            generationErrorTopChrome
        } else if model.bundle != nil && isShowingReviseMode {
            draftReviseTopChrome
        } else if model.bundle != nil && !isShowingDraftSource {
            draftResultTopChrome
        } else {
            momentTopChrome
        }
    }

    private var momentTopChrome: some View {
        ZStack {
            Text("Write")
                .font(.headline.weight(.semibold))
                .foregroundStyle(Color.prosePalInk)
                .lineLimit(1)

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
        }
        .frame(height: 42)
        .frame(maxWidth: .infinity)
    }

    private var generatingTopChrome: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: 6) {
                    generatingBackButton
                    detailChromeTitle("Writing…")
                }
            } else {
                ZStack {
                    Text("Writing…")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(Color.prosePalInk)
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .center)

                    HStack {
                        generatingBackButton

                        Spacer(minLength: 8)
                    }
                }
                .frame(height: 48)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var generatingBackButton: some View {
        Button {
            model.resetDraftForMomentChange()
            isShowingDraftSource = true
            isShowingReviseMode = false
        } label: {
            Label("Today", systemImage: "chevron.left")
                .font(.system(.body, design: .default).weight(.regular))
                .labelStyle(.titleAndIcon)
                .lineLimit(1)
                .minimumScaleFactor(0.88)
                .frame(minWidth: dynamicTypeSize.isAccessibilitySize ? nil : 76, alignment: .leading)
        }
        .buttonStyle(.plain)
        .foregroundStyle(Color.prosePalCoralDeep)
        .accessibilityLabel("Back to today")
    }

    private func detailChromeTitle(_ title: String) -> some View {
        Text(title)
            .font(dynamicTypeSize.isAccessibilitySize ? .system(.title2, design: .default).weight(.semibold) : .headline.weight(.semibold))
            .foregroundStyle(Color.prosePalInk)
            .lineLimit(2)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: dynamicTypeSize.isAccessibilitySize ? .leading : .center)
            .accessibilityAddTraits(.isHeader)
    }

    private var draftResultTopChrome: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .center, spacing: 12) {
                        draftResultBackButton

                        Spacer(minLength: 12)

                        draftResultSaveButton
                    }

                    detailChromeTitle("A draft")
                }
            } else {
                HStack(alignment: .center) {
                    draftResultBackButton

                    Spacer(minLength: 8)

                    Text("A draft")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(Color.prosePalInk)
                        .lineLimit(1)

                    Spacer(minLength: 8)

                    draftResultSaveButton
                }
                .frame(height: 48)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var draftResultBackButton: some View {
        Button {
            isShowingReviseMode = false
            isShowingDraftSource = true
        } label: {
            Label("Today", systemImage: "chevron.left")
                .font(.system(.body, design: .default).weight(.regular))
                .labelStyle(.titleAndIcon)
                .lineLimit(1)
                .minimumScaleFactor(0.88)
                .frame(minWidth: dynamicTypeSize.isAccessibilitySize ? nil : 76, alignment: .leading)
        }
        .buttonStyle(.plain)
        .foregroundStyle(Color.prosePalCoralDeep)
        .accessibilityLabel("Back to today")
    }

    private var draftResultSaveButton: some View {
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

    private var generationErrorTopChrome: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: 6) {
                    generationErrorBackButton
                    detailChromeTitle("A draft")
                }
            } else {
                ZStack {
                    Text("A draft")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(Color.prosePalInk)
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .center)

                    HStack {
                        generationErrorBackButton

                        Spacer(minLength: 8)
                    }
                }
                .frame(height: 48)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var generationErrorBackButton: some View {
        Button {
            returnToNoteAfterDraftFailure()
        } label: {
            Label("Today", systemImage: "chevron.left")
                .font(.system(.body, design: .default).weight(.regular))
                .labelStyle(.titleAndIcon)
                .lineLimit(1)
                .minimumScaleFactor(0.88)
                .frame(minWidth: dynamicTypeSize.isAccessibilitySize ? nil : 76, alignment: .leading)
        }
        .buttonStyle(.plain)
        .foregroundStyle(Color.prosePalCoralDeep)
        .accessibilityLabel("Back to today")
    }

    private var quotaReachedTopChrome: some View {
        HStack {
            Button {
                returnToNoteAfterDraftFailure()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .semibold))
                    .frame(width: 44, height: 44)
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .foregroundStyle(Color.prosePalCoralDeep)
            .accessibilityLabel("Back to your note")

            Spacer(minLength: 8)
        }
        .frame(height: 48)
        .frame(maxWidth: .infinity)
    }

    private var draftReviseTopChrome: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .center, spacing: 12) {
                        Button {
                            endFocusedEditing()
                            isShowingReviseMode = false
                        } label: {
                            Label("Draft", systemImage: "chevron.left")
                                .font(.system(.body, design: .default).weight(.regular))
                                .labelStyle(.titleAndIcon)
                                .lineLimit(1)
                                .minimumScaleFactor(0.88)
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(Color.prosePalCoralDeep)
                        .accessibilityLabel("Back to draft")

                        Spacer(minLength: 12)

                        Button {
                            endFocusedEditing()
                            isShowingReviseMode = false
                        } label: {
                            Text("Done")
                                .font(.body.weight(.semibold))
                                .foregroundStyle(Color.prosePalCoralDeep)
                                .frame(minHeight: 44, alignment: .trailing)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Done revising")
                    }

                    detailChromeTitle("Revise")
                }
            } else {
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
            }
        }
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
        guidedComposerContent
    }

    private var activePrimaryContent: some View {
        guidedComposerContent
    }

    private var guidedComposerContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            composerIntro

            VStack(alignment: .leading, spacing: 10) {
                composerStep(number: 1, title: "Who", detail: "Name the person.") {
                    TextField(
                        "Name or person",
                        text: $model.personName.prosePalLimited(to: ProsePalTextLimit.personName),
                        prompt: Text("Alex, Mum, my manager")
                    )
                        .momentNameInputBehavior()
                        .submitLabel(.next)
                        .onSubmit {
                            submitPersonEntry(focusNote: true)
                        }
                        .focused($focusedField, equals: .person)
                        .font(.system(.title3, design: .serif))
                        .foregroundStyle(Color.prosePalInk)
                        .textFieldStyle(.plain)
                        .padding(.horizontal, 13)
                        .frame(minHeight: 44, alignment: .leading)
                        .momentInputSurface(isCareful: model.moment.isCarefulMode, cornerRadius: 15)
                        .accessibilityLabel("Name or person")
                        .accessibilityValue("\(model.personName.count) of \(ProsePalTextLimit.personName) characters")
                }

                composerDivider

                composerStep(number: 2, title: "What's the occasion?", detail: "Pick the moment.") {
                    occasionComposerButton
                }

                composerDivider

                composerStep(number: 3, title: "Tone", detail: "Choose how it should feel.") {
                    toneComposerMenu
                }

                composerDivider

                composerStep(number: 4, title: "Length", detail: model.length.generationHint) {
                    lengthComposerPicker
                }

                composerDivider

                composerStep(number: 5, title: "Generate", detail: "Create the draft.") {
                    generateComposerButton
                }

                composerDivider

                relationshipComposerButton

                composerDivider

                composerOptionalDetailSection
            }
        }
        .padding(14)
        .background {
            MomentCardBackground(
                isCareful: model.moment.isCarefulMode,
                prominence: .standard
            )
        }
    }

    private var composerIntro: some View {
        HStack(alignment: .center, spacing: 10) {
            MomentSymbolBadge(
                systemImage: model.moment.isCarefulMode ? "heart.text.square" : "sparkles",
                style: model.moment.isCarefulMode ? .care : .coral,
                size: 32
            )

            VStack(alignment: .leading, spacing: 3) {
                Text("Write a message")
                    .font(.system(.title3, design: .serif).weight(.semibold))
                    .foregroundStyle(Color.prosePalInk)

                Text("Who, occasion, tone, length, then Generate.")
                    .font(.footnote)
                    .foregroundStyle(Color.prosePalSlate)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 8)
        }
        .accessibilityElement(children: .combine)
    }

    private func composerStep<Content: View>(
        number: Int,
        title: String,
        detail: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(number)")
                .font(.caption.weight(.bold))
                .foregroundStyle(.white)
                .frame(width: 26, height: 26)
                .background(composerAccentColor, in: Circle())
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 7) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.prosePalInk)

                    Text(detail)
                        .font(.caption)
                        .foregroundStyle(Color.prosePalSlate.opacity(0.74))
                        .fixedSize(horizontal: false, vertical: true)
                }

                content()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var composerDivider: some View {
        Rectangle()
            .fill(Color.prosePalNavy.opacity(0.08))
            .frame(height: 1)
            .padding(.leading, 38)
            .accessibilityHidden(true)
    }

    private var relationshipComposerButton: some View {
        Button {
            endFocusedEditing()
            diagnostics.pickerOpened("relationship")
            isShowingRelationshipPicker = true
        } label: {
            composerChoiceLabel(
                title: "Relationship",
                value: model.relationship.displayName,
                detail: model.relationship.group.displayName,
                systemImage: model.relationship.symbolName,
                showsChevron: true
            )
        }
        .buttonStyle(.plain)
    }

    private var occasionComposerButton: some View {
        Button {
            endFocusedEditing()
            diagnostics.pickerOpened("moment")
            isShowingMomentPicker = true
        } label: {
            composerChoiceLabel(
                title: "Occasion",
                value: model.occasion.displayName,
                detail: model.moment.prefersCareRegister ? "Handled with extra care" : model.occasion.group.displayName,
                systemImage: model.occasion.symbolName,
                showsChevron: true
            )
        }
        .buttonStyle(.plain)
    }

    private var toneComposerMenu: some View {
        Menu {
            ForEach(Tone.allCases) { tone in
                Button {
                    model.tone = tone
                    playMomentSelectionFeedback()
                } label: {
                    Label(tone.displayName, systemImage: tone.symbolName)
                }
            }
        } label: {
            composerChoiceLabel(
                title: "Tone",
                value: model.tone.displayName,
                detail: model.tone.description,
                systemImage: model.tone.symbolName,
                showsChevron: true
            )
        }
        .buttonStyle(.plain)
    }

    private var lengthComposerPicker: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(spacing: 8) {
                    lengthComposerButtons
                }
            } else {
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 8) {
                        lengthComposerButtons
                    }

                    VStack(spacing: 8) {
                        lengthComposerButtons
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var lengthComposerButtons: some View {
        ForEach(MessageLength.allCases) { length in
            Button {
                model.length = length
                playMomentSelectionFeedback()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: length.symbolName)
                        .font(.caption.weight(.semibold))
                        .accessibilityHidden(true)

                    Text(length.displayName)
                        .font(.caption.weight(.semibold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.78)
                }
                .foregroundStyle(model.length == length ? Color.prosePalTextOnAccent : Color.prosePalSlate)
                .frame(maxWidth: .infinity)
                .frame(minHeight: 34)
                .background {
                    Capsule(style: .continuous)
                        .fill(model.length == length ? composerAccentColor : Color.prosePalGlassFill2)
                }
                .overlay {
                    Capsule(style: .continuous)
                        .stroke(Color.prosePalGlassStrokeSoft, lineWidth: 0.5)
                }
            }
            .buttonStyle(.plain)
            .accessibilityAddTraits(model.length == length ? [.isSelected] : [])
        }
    }

    private var composerOptionalDetailSection: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "text.quote")
                .font(.caption.weight(.semibold))
                .foregroundStyle(composerAccentColor)
                .frame(width: 26, height: 26)
                .background(composerAccentColor.opacity(0.12), in: Circle())
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 9) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Optional detail")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.prosePalInk)

                    Text("Add one thing to include, or leave it blank.")
                        .font(.caption)
                        .foregroundStyle(Color.prosePalSlate.opacity(0.74))
                        .fixedSize(horizontal: false, vertical: true)
                }

                TextField(
                    "Anything to mention?",
                    text: $model.trueThing.prosePalLimited(to: ProsePalTextLimit.momentDetail),
                    prompt: Text("A memory, apology, detail, or feeling"),
                    axis: .vertical
                )
                .font(.system(.body, design: .serif))
                .lineSpacing(4)
                .foregroundStyle(Color.prosePalInk)
                .textFieldStyle(.plain)
                .lineLimit(dynamicTypeSize.isAccessibilitySize ? 4...10 : 2...6)
                .focused($focusedField, equals: .truth)
                .submitLabel(.done)
                .onSubmit {
                    endFocusedEditing()
                }
                .padding(13)
                .frame(minHeight: dynamicTypeSize.isAccessibilitySize ? 96 : 72, alignment: .topLeading)
                .momentInputSurface(isCareful: model.moment.isCarefulMode, cornerRadius: 15)
                .accessibilityLabel("Optional detail to include")
                .accessibilityValue("\(model.trueThing.count) of \(ProsePalTextLimit.momentDetail) characters")

                MomentCharacterLimitStatus(
                    text: model.trueThing,
                    limit: ProsePalTextLimit.momentDetail
                )

                noteTools
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var generateComposerButton: some View {
        Button {
            generateDraftFromComposer()
        } label: {
            Label(composerGenerateButtonTitle, systemImage: model.isDrafting ? "hourglass" : "sparkles")
                .font(.headline.weight(.semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.82)
                .frame(maxWidth: .infinity)
                .frame(minHeight: 46)
        }
        .buttonStyle(.borderedProminent)
        .buttonBorderShape(.capsule)
        .tint(composerAccentColor)
        .disabled(!model.canDraft || model.isDrafting)
    }

    private var composerGenerateButtonTitle: String {
        if model.isDrafting {
            return "Generating"
        }
        if model.errorMessage != nil {
            return "Try again"
        }
        if model.bundle != nil {
            return "Regenerate"
        }
        if model.safetySignal == .crisisSupport {
            return "Draft unavailable"
        }
        return "Generate"
    }

    private var composerAccentColor: Color {
        model.moment.isCarefulMode ? .prosePalCare : .prosePalCoral
    }

    private func composerChoiceLabel(
        title: String,
        value: String,
        detail: String,
        systemImage: String,
        showsChevron: Bool
    ) -> some View {
        HStack(alignment: .center, spacing: 10) {
            MomentSymbolBadge(
                systemImage: systemImage,
                style: model.moment.isCarefulMode ? .care : .coral,
                size: 26
            )

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(Color.prosePalSlate.opacity(0.70))

                Text(value)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.prosePalInk)
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)

                Text(detail)
                    .font(.caption2)
                    .foregroundStyle(Color.prosePalSlate.opacity(0.72))
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
            }

            Spacer(minLength: 8)

            if showsChevron {
                Image(systemName: "chevron.down")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(Color.prosePalSlate.opacity(0.55))
                    .accessibilityHidden(true)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 15, style: .continuous)
                .fill(Color.prosePalGlassFill2)
                .overlay {
                    RoundedRectangle(cornerRadius: 15, style: .continuous)
                        .stroke(Color.prosePalGlassStrokeSoft, lineWidth: 0.5)
                }
        }
        .contentShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
        .accessibilityElement(children: .combine)
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

    private var generatingContent: some View {
        MomentGeneratingView(
            noteText: model.trueThing,
            isCareful: model.moment.isCarefulMode
        )
    }

    private func draftReviseContent(_ bundle: MomentDraftBundle) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            draftRevisionSegmentedControl
            draftRevisionPage(bundle)
            draftRevisionSuggestionCard(bundle)
            draftRevisionToneRow(bundle)
        }
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

    private func generateDraftFromComposer() {
        guard !currentPersonName.isEmpty else {
            focusedField = .person
            return
        }

        hasCommittedPersonEntry = true
        focusedField = nil
        Task {
            await model.draftNow()
        }
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

    private var offlineDraftStateContent: some View {
        VStack(alignment: .leading, spacing: 14) {
            offlineConnectionBanner
            offlineNotePage
        }
    }

    private var offlineConnectionBanner: some View {
        HStack(alignment: .center, spacing: 10) {
            Image(systemName: "wifi.slash")
                .font(.system(size: 19, weight: .semibold))
                .foregroundStyle(Color.prosePalWarning)
                .frame(width: 24)
                .accessibilityHidden(true)

            Text("You're offline — your note is still here on this device")
                .font(.subheadline.weight(.medium))
                .lineSpacing(2)
                .foregroundStyle(Color.prosePalSlate)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.prosePalNavy.opacity(0.10), lineWidth: 1)
        }
        .shadow(color: Color.prosePalCoralDeep.opacity(0.08), radius: 8, x: 0, y: 3)
        .accessibilityElement(children: .combine)
    }

    private var offlineNotePage: some View {
        MomentWritingPageSurface(
            prompt: "The note",
            isCareful: model.moment.isCarefulMode,
            minHeight: dynamicTypeSize.isAccessibilitySize ? 230 : 150
        ) {
            Text(offlineNoteText)
                .font(.system(.title3, design: .serif))
                .lineSpacing(5)
                .foregroundStyle(Color.prosePalInk)
                .fixedSize(horizontal: false, vertical: true)
        } footer: {
            offlineNoteFooter
        }
    }

    private var offlineNoteText: String {
        let trimmed = model.trueThing.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "Your note is saved here." : trimmed
    }

    @ViewBuilder
    private var offlineNoteFooter: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 12) {
                savedLocallyLabel
                Spacer(minLength: 8)
                offlineRetryButton
            }

            VStack(alignment: .leading, spacing: 12) {
                savedLocallyLabel
                offlineRetryButton
            }
        }
    }

    private var savedLocallyLabel: some View {
        Text("Saved locally")
            .font(.caption.weight(.medium))
            .foregroundStyle(Color.prosePalSlate.opacity(0.76))
            .lineLimit(1)
    }

    private var offlineRetryButton: some View {
        Button {
            model.startDraft()
        } label: {
            Label("Try again", systemImage: "arrow.clockwise")
                .font(.subheadline.weight(.semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .buttonStyle(.bordered)
        .buttonBorderShape(.capsule)
        .controlSize(.regular)
        .tint(.prosePalNavy)
        .disabled(!model.canDraft || model.isDrafting)
        .accessibilityIdentifier("moment.offline.retry")
    }

    private func generationErrorStateContent(viewportHeight: CGFloat) -> some View {
        VStack(spacing: 0) {
            Spacer(minLength: dynamicTypeSize.isAccessibilitySize ? 28 : 26)

            VStack(spacing: 11) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(Color.prosePalWarning)
                    .frame(width: 60, height: 60)
                    .background(
                        Color.prosePalWarning.opacity(0.14),
                        in: RoundedRectangle(cornerRadius: 18, style: .continuous)
                    )
                    .accessibilityHidden(true)

                Text("That didn't go through")
                    .font(.system(size: 23, weight: .medium, design: .serif))
                    .foregroundStyle(Color.prosePalInk)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                Text("We couldn't finish your draft just now. Your note is safe — nothing was lost.")
                    .font(.callout)
                    .lineSpacing(3)
                    .foregroundStyle(Color.prosePalSlate)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 285)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity)
            .accessibilityElement(children: .combine)

            Spacer(minLength: dynamicTypeSize.isAccessibilitySize ? 28 : 54)

            generationErrorActions
        }
        .frame(minHeight: blockingStateContentHeight(for: viewportHeight), alignment: .center)
    }

    private func quotaReachedStateContent(viewportHeight: CGFloat) -> some View {
        VStack(spacing: 0) {
            Spacer(minLength: dynamicTypeSize.isAccessibilitySize ? 28 : 24)

            VStack(spacing: 8) {
                Image(systemName: "hourglass")
                    .font(.system(size: 28, weight: .medium))
                    .foregroundStyle(Color.prosePalCoralDeep)
                    .frame(width: 60, height: 60)
                    .background(
                        Color.prosePalCoralCard.opacity(0.62),
                        in: RoundedRectangle(cornerRadius: 18, style: .continuous)
                    )
                    .accessibilityHidden(true)

                Text("Draft limit reached")
                    .font(.system(size: 26, weight: .medium, design: .serif))
                    .foregroundStyle(Color.prosePalInk)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 340)
                    .padding(.top, 12)
                    .lineLimit(2)
                    .minimumScaleFactor(0.84)

                Text(model.errorMessage ?? "No more drafts are available for this account right now.")
                    .font(.callout)
                    .lineSpacing(3)
                    .foregroundStyle(Color.prosePalSlate)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 300)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity)
            .accessibilityElement(children: .combine)

            Spacer(minLength: dynamicTypeSize.isAccessibilitySize ? 28 : 50)

            quotaReachedActions
        }
        .frame(minHeight: blockingStateContentHeight(for: viewportHeight), alignment: .center)
    }

    private func blockingStateContentHeight(for viewportHeight: CGFloat) -> CGFloat {
        if dynamicTypeSize.isAccessibilitySize {
            return max(viewportHeight - 156, 520)
        }
        return max(viewportHeight - 218, 500)
    }

    private var quotaReachedActions: some View {
        VStack(spacing: 10) {
            Button {
                isShowingPaywall = true
            } label: {
                Label("View Pro options", systemImage: "feather")
                    .font(.headline.weight(.semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
            }
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.capsule)
            .tint(model.moment.isCarefulMode ? .prosePalCare : .prosePalCoral)

            Button {
                returnToNoteAfterDraftFailure()
            } label: {
                Text("Back to your note")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.prosePalCoralDeep)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
            }
            .buttonStyle(.plain)
        }
    }

    private var generationErrorActions: some View {
        VStack(spacing: 10) {
            Button {
                Task {
                    await model.draftNow()
                }
            } label: {
                Label("Try again", systemImage: "arrow.clockwise")
                    .font(.headline.weight(.semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
            }
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.capsule)
            .tint(model.moment.isCarefulMode ? .prosePalCare : .prosePalCoral)
            .disabled(!model.canDraft || model.isDrafting)

            Button {
                returnToNoteAfterDraftFailure()
            } label: {
                Text("Back to your note")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.prosePalCoralDeep)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
            }
            .buttonStyle(.plain)
        }
    }

    private func returnToNoteAfterDraftFailure() {
        model.resetDraftForMomentChange()
        isShowingDraftSource = true
        isShowingReviseMode = false
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
                                pendingMemoryDeletion = .truthBead(bead)
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
            TextField(
                "A detail to remember",
                text: $newTruthBeadText.prosePalLimited(to: ProsePalTextLimit.relationshipMemory),
                prompt: Text("Loves Sunday walks")
            )
                .focused($focusedField, equals: .memory)
                .submitLabel(.done)
                .padding(14)
                .momentInputSurface(cornerRadius: 16)
                .onSubmit {
                    addTruthBead()
                }
                .accessibilityValue("\(newTruthBeadText.count) of \(ProsePalTextLimit.relationshipMemory) characters")

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
                        pendingMemoryDeletion = .voiceCard(voiceCard)
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
            TextField(
                "Warm, short, no fuss",
                text: $newVoiceCardSummary.prosePalLimited(to: ProsePalTextLimit.voiceCard),
                prompt: Text("Warm, short, no fuss")
            )
                .focused($focusedField, equals: .voice)
                .submitLabel(.done)
                .padding(14)
                .momentInputSurface(cornerRadius: 16)
                .onSubmit {
                    addVoiceCard()
                }
                .accessibilityValue("\(newVoiceCardSummary.count) of \(ProsePalTextLimit.voiceCard) characters")

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
        case .timedOut(let lane):
            return MomentDraftUnavailableNotice(
                title: lane == .onDevice
                    ? String(localized: "On-device writing took too long")
                    : String(localized: "Drafting took too long"),
                detail: errorMessage,
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
                    .accessibilityValue("\(bundle.messageText.count) of \(ProsePalTextLimit.draft) characters")
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                Text(draftRevisionDisplayText(for: bundle))
                    .font(.system(.title3, design: .serif))
                    .lineSpacing(7)
                    .foregroundStyle(Color.prosePalInk)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityLabel("Original text")
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
                .accessibilityValue("\(bundle.messageText.count) of \(ProsePalTextLimit.draft) characters")
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

            draftResultFooter(bundle)
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

    @ViewBuilder
    private func draftResultFooter(_ bundle: MomentDraftBundle) -> some View {
        if dynamicTypeSize.isAccessibilitySize {
            VStack(alignment: .center, spacing: 8) {
                draftResultFooterButton(title: "Copy", systemImage: "doc.on.doc") {
                    copy(bundle.messageText)
                }

                draftResultFooterButton(title: "Send", systemImage: "paperplane.fill") {
                    openDraftSendSheet(bundle, source: "moment_result_card")
                }

                draftResultFooterButton(title: "Keep this", systemImage: "checkmark", isAccent: true) {
                    save(bundle)
                }
            }
        } else {
            HStack(alignment: .center, spacing: 4) {
                draftResultFooterButton(title: "Copy", systemImage: "doc.on.doc") {
                    copy(bundle.messageText)
                }

                draftResultFooterButton(title: "Send", systemImage: "paperplane.fill") {
                    openDraftSendSheet(bundle, source: "moment_result_card")
                }

                Spacer(minLength: 4)

                draftResultFooterButton(title: "Keep this", systemImage: "checkmark", isAccent: true) {
                    save(bundle)
                }
            }
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
                    .font(dynamicTypeSize.isAccessibilitySize ? .body.weight(isAccent ? .semibold : .medium) : .subheadline.weight(isAccent ? .semibold : .medium))
            } icon: {
                Image(systemName: systemImage)
                    .font(dynamicTypeSize.isAccessibilitySize ? .body.weight(.medium) : .caption.weight(.medium))
            }
            .labelStyle(.titleAndIcon)
            .lineLimit(dynamicTypeSize.isAccessibilitySize ? 2 : 1)
            .minimumScaleFactor(0.78)
            .frame(
                maxWidth: dynamicTypeSize.isAccessibilitySize ? .infinity : nil,
                minHeight: dynamicTypeSize.isAccessibilitySize ? 52 : 36
            )
            .padding(.horizontal, dynamicTypeSize.isAccessibilitySize ? 14 : 8)
            .foregroundStyle(isAccent ? Color.prosePalCoralDeep : Color.prosePalSlate)
            .background {
                if dynamicTypeSize.isAccessibilitySize {
                    Capsule(style: .continuous)
                        .fill(isAccent ? Color.prosePalAccentSoft : Color.prosePalSurface2.opacity(0.72))
                }
            }
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
                    draftRefineChip(title: "Another", systemImage: "arrow.clockwise") {
                        focusedField = nil
                        Task {
                            await model.draftNow()
                        }
                    }
                    .disabled(!model.canDraft)

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
            model.updateActiveDraftMessage(ProsePalTextInput.limited(
                nextText,
                to: ProsePalTextLimit.draft
            ))
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
                    sendButton(bundle: bundle)
                    saveButton(bundle: bundle)
                }

                VStack(spacing: 8) {
                    copyButton(text: bundle.messageText)
                    sendButton(bundle: bundle)
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

    private func sendButton(bundle: MomentDraftBundle) -> some View {
        Button {
            openDraftSendSheet(bundle, source: "moment_draft")
        } label: {
            Label("Send", systemImage: "paperplane.fill")
                .lineLimit(1)
                .minimumScaleFactor(0.82)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .buttonBorderShape(.capsule)
        .tint(model.moment.isCarefulMode ? .prosePalCare : .prosePalCoral)
    }

    private func openDraftSendSheet(_ bundle: MomentDraftBundle, source: String) {
        useDraftRequest = MomentDraftUseSheetRequest(
            bundle: bundle,
            toneLabel: draftResultToneLabel(for: bundle)
        )
        diagnostics.messageAction(
            "open_draft_send_handoff",
            source: source,
            messageCharacters: bundle.messageText.count
        )
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

    private func copy(_ text: String, source: String = "moment_draft") {
        #if canImport(UIKit)
        UIPasteboard.general.string = text
        #endif
        diagnostics.messageAction("copy", source: source, messageCharacters: text.count)
        showToast("Copied — your voice and all")
    }

    private func showToast(_ message: String) {
        let toast = MomentTransientToast(message: message)
        withAnimation(.easeInOut(duration: 0.18)) {
            transientToast = toast
        }

        Task { @MainActor in
            try? await Task.sleep(for: .seconds(5))
            guard transientToast == toast else { return }
            withAnimation(.easeInOut(duration: 0.18)) {
                transientToast = nil
            }
        }
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
        do {
            try performConfirmedMemoryDeletion(
                delete: { modelContext.delete(bead) },
                save: { try modelContext.save() },
                rollback: { modelContext.rollback() }
            )
            diagnostics.messageAction("truth_bead_deleted", source: "moment", messageCharacters: 0)
            model.resetDraftForMomentChange()
        } catch {
            saveNotice = "Could not delete this detail."
        }
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
        do {
            try performConfirmedMemoryDeletion(
                delete: { modelContext.delete(voiceCard) },
                save: { try modelContext.save() },
                rollback: { modelContext.rollback() }
            )
            diagnostics.messageAction("voice_card_deleted", source: "moment", messageCharacters: 0)
            model.resetDraftForMomentChange()
        } catch {
            saveNotice = "Could not delete this voice card."
        }
    }

    private func confirmMemoryDeletion(_ request: MemoryDeletionRequest) {
        pendingMemoryDeletion = nil
        switch request {
        case .truthBead(let bead):
            deleteTruthBead(bead)
        case .voiceCard(let voiceCard):
            deleteVoiceCard(voiceCard)
        }
    }

    private func applyVoiceTranscript(_ transcript: String) {
        let trimmedTranscript = transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTranscript.isEmpty else { return }

        model.trueThing = ProsePalTextInput.momentDetail(trimmedTranscript)
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

struct SavedMomentDraftsView: View {
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

struct MomentDetailTopChrome<Trailing: View>: View {
    let title: String
    let backAction: () -> Void
    private let trailing: Trailing

    init(
        title: String,
        backAction: @escaping () -> Void,
        @ViewBuilder trailing: () -> Trailing
    ) {
        self.title = title
        self.backAction = backAction
        self.trailing = trailing()
    }

    var body: some View {
        HStack(alignment: .center) {
            Button {
                backAction()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 17, weight: .semibold))
                    .frame(width: 42, height: 42)
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .foregroundStyle(Color.prosePalCoralDeep)
            .background(Color.prosePalPaper.opacity(0.74), in: Circle())
            .accessibilityLabel("Back")

            Spacer(minLength: 12)

            Text(title)
                .font(.headline.weight(.semibold))
                .foregroundStyle(Color.prosePalInk)
                .lineLimit(1)

            Spacer(minLength: 12)

            trailing
                .frame(minWidth: 54, alignment: .trailing)
        }
        .frame(height: 46)
    }
}

struct MomentDetailHero: View {
    let systemImage: String
    let title: String
    let detail: String
    var accent: Color = .prosePalCoralDeep

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: 24, weight: .regular))
                .foregroundStyle(accent)
                .frame(width: 52, height: 52)
                .background(accent.opacity(0.12), in: RoundedRectangle(cornerRadius: 17, style: .continuous))
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 7) {
                Text(title)
                    .font(.system(size: 30, weight: .regular, design: .serif))
                    .foregroundStyle(Color.prosePalInk)
                    .fixedSize(horizontal: false, vertical: true)

                Text(detail)
                    .font(.callout)
                    .foregroundStyle(Color.prosePalSlate.opacity(0.78))
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct MomentDetailNotice: View {
    let text: String

    var body: some View {
        Label(text, systemImage: "checkmark.circle")
            .font(.callout.weight(.semibold))
            .foregroundStyle(Color.prosePalCare)
            .padding(.horizontal, 14)
            .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
            .background(Color.prosePalCare.opacity(0.10), in: RoundedRectangle(cornerRadius: 15, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 15, style: .continuous)
                    .stroke(Color.prosePalCare.opacity(0.16), lineWidth: 1)
            }
    }
}

struct MomentDetailCard<Content: View>: View {
    let title: String
    let systemImage: String
    let footer: String?
    private let content: Content

    init(
        title: String,
        systemImage: String,
        footer: String? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.systemImage = systemImage
        self.footer = footer
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 9) {
                Image(systemName: systemImage)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.prosePalCoralDeep)
                    .frame(width: 26, height: 26)
                    .background(Color.prosePalCoral.opacity(0.12), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .accessibilityHidden(true)

                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.prosePalInk)
            }

            content

            if let footer {
                Text(footer)
                    .font(.footnote)
                    .lineSpacing(2)
                    .foregroundStyle(Color.prosePalSlate.opacity(0.72))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.prosePalPaper.opacity(0.94), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.prosePalNavy.opacity(0.10), lineWidth: 1)
        }
        .shadow(color: Color.prosePalCoralDeep.opacity(0.06), radius: 10, x: 0, y: 5)
    }
}

private struct RelationshipMemoryVaultView: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \RelationshipTruthBeadRecord.updatedAt, order: .reverse)
    private var beads: [RelationshipTruthBeadRecord]
    @Query(sort: \RelationshipVoiceCardRecord.updatedAt, order: .reverse)
    private var voiceCards: [RelationshipVoiceCardRecord]
    @State private var searchText = ""

    private var allItems: [RelationshipMemoryVaultItem] {
        (beads.map(RelationshipMemoryVaultItem.detail) + voiceCards.map(RelationshipMemoryVaultItem.voice))
            .sorted { $0.updatedAt > $1.updatedAt }
    }

    private var trimmedSearchText: String {
        searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var isSearching: Bool {
        !trimmedSearchText.isEmpty
    }

    private var filteredItems: [RelationshipMemoryVaultItem] {
        let query = trimmedSearchText
        let items = allItems
        guard !query.isEmpty else { return items }

        return items.filter {
            $0.searchText.localizedCaseInsensitiveContains(query)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            vaultTopChrome
                .padding(.horizontal, 20)
                .padding(.top, 10)
                .padding(.bottom, 8)

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    memoryHero

                    if !allItems.isEmpty || isSearching {
                        memorySearchField
                    }

                    if filteredItems.isEmpty {
                        MomentSavedEmptyState(
                            isSearching: isSearching,
                            emptyTitle: isSearching ? "No matching memory" : "No relationship memory yet",
                            emptyDetail: isSearching ? "Try another person or phrase." : "Save details or voice cards from the Moment screen when they should help future drafts.",
                            systemImage: "checkmark.seal"
                        )
                        .padding(.top, 4)
                    } else {
                        memoryList(filteredItems)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 44)
            }
            .scrollIndicators(.hidden)
        }
        .background {
            MomentAtmosphericBackground(isCareful: false)
        }
        .tint(.prosePalCoral)
        #if os(iOS)
        .toolbar(.hidden, for: .navigationBar)
        #endif
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

    private var vaultTopChrome: some View {
        HStack(alignment: .center) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 17, weight: .semibold))
                    .frame(width: 42, height: 42)
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .foregroundStyle(Color.prosePalCoralDeep)
            .background(Color.prosePalPaper.opacity(0.74), in: Circle())
            .accessibilityLabel("Back")

            Spacer(minLength: 12)

            Text("Memory")
                .font(.headline.weight(.semibold))
                .foregroundStyle(Color.prosePalInk)

            Spacer(minLength: 54)
        }
    }

    private var memoryHero: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: "checkmark.seal")
                .font(.system(size: 24, weight: .regular))
                .foregroundStyle(Color.prosePalCoralDeep)
                .frame(width: 52, height: 52)
                .background(Color.prosePalCoral.opacity(0.12), in: RoundedRectangle(cornerRadius: 17, style: .continuous))

            VStack(alignment: .leading, spacing: 7) {
                Text("What ProsePal may remember")
                    .font(.system(size: 30, weight: .regular, design: .serif))
                    .foregroundStyle(Color.prosePalInk)
                    .fixedSize(horizontal: false, vertical: true)

                Text("Approved details and voice notes stay editable, pausable, and local to this relationship memory.")
                    .font(.callout)
                    .foregroundStyle(Color.prosePalSlate.opacity(0.78))
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var memorySearchField: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(Color.prosePalSlate.opacity(0.70))

            TextField("Search memory", text: $searchText)
                .textFieldStyle(.plain)
                .font(.body)
                .foregroundStyle(Color.prosePalInk)
                .submitLabel(.search)

            if isSearching {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 17, weight: .semibold))
                }
                .buttonStyle(.plain)
                .foregroundStyle(Color.prosePalSlate.opacity(0.55))
                .accessibilityLabel("Clear search")
            }
        }
        .padding(.horizontal, 15)
        .frame(height: 46)
        .background(Color.prosePalPaper.opacity(0.80), in: Capsule(style: .continuous))
        .overlay {
            Capsule(style: .continuous)
                .stroke(Color.prosePalNavy.opacity(0.10), lineWidth: 1)
        }
    }

    private func memoryList(_ items: [RelationshipMemoryVaultItem]) -> some View {
        memoryGroup("Saved memory") {
            ForEach(items.indices, id: \.self) { index in
                let item = items[index]

                NavigationLink {
                    destination(for: item)
                } label: {
                    RelationshipMemoryVaultRow(item: item)
                }
                .buttonStyle(.plain)

                if index != items.index(before: items.endIndex) {
                    memoryDivider
                }
            }
        }
    }

    private func memoryGroup<Content: View>(
        _ title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.caption.weight(.semibold))
                .textCase(.uppercase)
                .foregroundStyle(Color.prosePalSlate.opacity(0.62))
                .padding(.horizontal, 2)

            VStack(spacing: 0) {
                content()
            }
            .background(Color.prosePalPaper.opacity(0.94), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(Color.prosePalNavy.opacity(0.10), lineWidth: 1)
            }
            .shadow(color: Color.prosePalCoralDeep.opacity(0.06), radius: 10, x: 0, y: 5)
        }
    }

    private var memoryDivider: some View {
        Rectangle()
            .fill(Color.prosePalNavy.opacity(0.08))
            .frame(height: 1)
            .padding(.leading, 70)
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

    var systemImage: String {
        switch self {
        case .detail:
            "text.badge.checkmark"
        case .voice:
            "person.crop.square"
        }
    }

    var updatedAtLabel: String {
        let calendar = Calendar.current

        if calendar.isDateInToday(updatedAt) {
            return "Updated today"
        }
        if calendar.isDateInYesterday(updatedAt) {
            return "Updated yesterday"
        }

        let days = calendar.dateComponents([.day], from: updatedAt, to: Date()).day ?? 0
        if days < 7 {
            return "Updated \(updatedAt.formatted(.dateTime.weekday(.abbreviated)))"
        }

        return "Updated \(updatedAt.formatted(.dateTime.month(.abbreviated).day()))"
    }

    var searchText: String {
        "\(personName) \(kindLabel) \(bodyText)"
    }
}

private struct RelationshipMemoryVaultRow: View {
    let item: RelationshipMemoryVaultItem

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: item.systemImage)
                .font(.system(size: 18, weight: .regular))
                .foregroundStyle(Color.prosePalCoralDeep)
                .frame(width: 42, height: 42)
                .background(Color.prosePalCoral.opacity(0.12), in: RoundedRectangle(cornerRadius: 14, style: .continuous))

            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(item.personName)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(Color.prosePalInk)
                        .lineLimit(1)
                        .minimumScaleFactor(0.84)

                    Spacer(minLength: 8)

                    HStack(spacing: 6) {
                        memoryBadge(item.kindLabel, color: .prosePalCoralDeep)

                        if !item.isUserApproved {
                            memoryBadge("Paused", color: .prosePalSlate)
                        }
                    }
                }

                Text(item.bodyText)
                    .font(.callout)
                    .foregroundStyle(Color.prosePalSlate.opacity(0.82))
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                Label(item.updatedAtLabel, systemImage: "clock")
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(Color.prosePalSlate.opacity(0.66))
            }

            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color.prosePalSlate.opacity(0.40))
                .padding(.top, 14)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity, minHeight: 104, alignment: .leading)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }

    private func memoryBadge(_ title: String, color: Color) -> some View {
        Text(title)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(color)
            .padding(.horizontal, 8)
            .frame(height: 24)
            .background(color.opacity(0.12), in: Capsule(style: .continuous))
    }
}

func performConfirmedMemoryDeletion(
    delete: () -> Void,
    save: () throws -> Void,
    rollback: () -> Void
) throws {
    delete()
    do {
        try save()
    } catch {
        rollback()
        throw error
    }
}

func performRelationshipMemorySave(
    update: () -> Void,
    save: () throws -> Void,
    rollback: () -> Void
) throws {
    update()
    do {
        try save()
    } catch {
        rollback()
        throw error
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
    @State private var isConfirmingDeletion = false

    init(bead: RelationshipTruthBeadRecord) {
        self.bead = bead
        _personName = State(initialValue: bead.personName)
        _text = State(initialValue: bead.text)
        _isUserApproved = State(initialValue: bead.isUserApproved)
    }

    var body: some View {
        VStack(spacing: 0) {
            MomentDetailTopChrome(title: "Memory detail", backAction: { dismiss() }) {
                Button("Save") {
                    save()
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(canSave ? Color.prosePalCoralDeep : Color.prosePalSlate.opacity(0.45))
                .frame(minHeight: 42)
                .disabled(!canSave)
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
            .padding(.bottom, 8)

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if let notice {
                        MomentDetailNotice(text: notice)
                    }

                    MomentDetailHero(
                        systemImage: "text.badge.checkmark",
                        title: "Saved detail",
                        detail: "Keep only details that should help future drafts for this person."
                    )

                    MomentDetailCard(title: "Person", systemImage: "person") {
                        TextField(
                            "Name",
                            text: $personName.prosePalLimited(to: ProsePalTextLimit.personName)
                        )
                            .momentNameInputBehavior()
                            .font(.body.weight(.medium))
                            .textFieldStyle(.plain)
                            .foregroundStyle(Color.prosePalInk)
                            .accessibilityValue("\(personName.count) of \(ProsePalTextLimit.personName) characters")
                    }

                    MomentDetailCard(
                        title: "Detail",
                        systemImage: "quote.bubble",
                        footer: "Correct this whenever it becomes stale or wrong."
                    ) {
                        TextField(
                            "What should ProsePal remember?",
                            text: $text.prosePalLimited(to: ProsePalTextLimit.relationshipMemory),
                            axis: .vertical
                        )
                            .font(.system(.body, design: .serif))
                            .lineSpacing(4)
                            .lineLimit(3...7)
                            .textFieldStyle(.plain)
                            .foregroundStyle(Color.prosePalInk)
                            .accessibilityValue("\(text.count) of \(ProsePalTextLimit.relationshipMemory) characters")
                    }

                    memoryUseCard(
                        isOn: $isUserApproved,
                        footer: "Why am I seeing this? You saved this detail for \(bead.personName). ProsePal uses approved details only when drafting for that person, and does not log the text."
                    )

                    detailDeleteButton(title: "Delete detail") {
                        isConfirmingDeletion = true
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 44)
            }
            .scrollIndicators(.hidden)
        }
        .background {
            MomentAtmosphericBackground(isCareful: false)
        }
        #if os(iOS)
        .toolbar(.hidden, for: .navigationBar)
        #endif
        .confirmationDialog(
            "Delete saved detail?",
            isPresented: $isConfirmingDeletion,
            titleVisibility: .visible
        ) {
            Button("Delete detail", role: .destructive) {
                deleteRecord()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This removes the detail from future drafts for this person.")
        }
    }

    private var canSave: Bool {
        !personName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
            !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func save() {
        do {
            try performRelationshipMemorySave(
                update: {
                    bead.update(
                        personName: personName,
                        text: text,
                        isUserApproved: isUserApproved
                    )
                },
                save: { try modelContext.save() },
                rollback: { modelContext.rollback() }
            )
            withAnimation(.easeInOut(duration: 0.18)) {
                notice = "Saved"
            }
        } catch {
            notice = "Could not save this detail. Your previous version is still saved."
        }
    }

    private func deleteRecord() {
        do {
            try performConfirmedMemoryDeletion(
                delete: { modelContext.delete(bead) },
                save: { try modelContext.save() },
                rollback: { modelContext.rollback() }
            )
            dismiss()
        } catch {
            notice = "Could not delete this detail. It is still saved."
        }
    }

    private func memoryUseCard(isOn: Binding<Bool>, footer: String) -> some View {
        MomentDetailCard(title: "Use", systemImage: "checkmark.seal", footer: footer) {
            Toggle("Use this in drafts", isOn: isOn)
                .font(.body.weight(.medium))
                .foregroundStyle(Color.prosePalInk)
                .tint(.prosePalCare)
        }
    }

    private func detailDeleteButton(title: String, action: @escaping () -> Void) -> some View {
        Button(role: .destructive, action: action) {
            Label(title, systemImage: "trash")
                .font(.subheadline.weight(.semibold))
                .frame(maxWidth: .infinity)
                .frame(height: 48)
        }
        .buttonStyle(.plain)
        .foregroundStyle(Color.red.opacity(0.86))
        .background(Color.red.opacity(0.08), in: Capsule(style: .continuous))
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
    @State private var isConfirmingDeletion = false

    init(voiceCard: RelationshipVoiceCardRecord) {
        self.voiceCard = voiceCard
        _personName = State(initialValue: voiceCard.personName)
        _summary = State(initialValue: voiceCard.summary)
        _isUserApproved = State(initialValue: voiceCard.isUserApproved)
    }

    var body: some View {
        VStack(spacing: 0) {
            MomentDetailTopChrome(title: "Voice card", backAction: { dismiss() }) {
                Button("Save") {
                    save()
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(canSave ? Color.prosePalCoralDeep : Color.prosePalSlate.opacity(0.45))
                .frame(minHeight: 42)
                .disabled(!canSave)
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
            .padding(.bottom, 8)

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if let notice {
                        MomentDetailNotice(text: notice)
                    }

                    MomentDetailHero(
                        systemImage: "person.crop.square",
                        title: "Voice card",
                        detail: "A style note for how drafts should sound with this person."
                    )

                    MomentDetailCard(title: "Person", systemImage: "person") {
                        TextField(
                            "Name",
                            text: $personName.prosePalLimited(to: ProsePalTextLimit.personName)
                        )
                            .momentNameInputBehavior()
                            .font(.body.weight(.medium))
                            .textFieldStyle(.plain)
                            .foregroundStyle(Color.prosePalInk)
                            .accessibilityValue("\(summary.count) of \(ProsePalTextLimit.voiceCard) characters")
                    }

                    MomentDetailCard(
                        title: "Voice",
                        systemImage: "textformat.size",
                        footer: "Use this for style only, not as a fact to quote."
                    ) {
                        TextField(
                            "How should ProsePal sound with this person?",
                            text: $summary.prosePalLimited(to: ProsePalTextLimit.voiceCard),
                            axis: .vertical
                        )
                            .font(.system(.body, design: .serif))
                            .lineSpacing(4)
                            .lineLimit(3...7)
                            .textFieldStyle(.plain)
                            .foregroundStyle(Color.prosePalInk)
                    }

                    memoryUseCard(
                        isOn: $isUserApproved,
                        footer: "Why am I seeing this? You saved this voice card for \(voiceCard.personName). ProsePal uses approved voice cards only when drafting for that person, and does not log the text."
                    )

                    detailDeleteButton(title: "Delete voice card") {
                        isConfirmingDeletion = true
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 44)
            }
            .scrollIndicators(.hidden)
        }
        .background {
            MomentAtmosphericBackground(isCareful: false)
        }
        #if os(iOS)
        .toolbar(.hidden, for: .navigationBar)
        #endif
        .confirmationDialog(
            "Delete saved voice card?",
            isPresented: $isConfirmingDeletion,
            titleVisibility: .visible
        ) {
            Button("Delete voice card", role: .destructive) {
                deleteRecord()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This removes the voice guidance from future drafts for this person.")
        }
    }

    private var canSave: Bool {
        !personName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
            !summary.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func save() {
        do {
            try performRelationshipMemorySave(
                update: {
                    voiceCard.update(
                        personName: personName,
                        summary: summary,
                        isUserApproved: isUserApproved
                    )
                },
                save: { try modelContext.save() },
                rollback: { modelContext.rollback() }
            )
            withAnimation(.easeInOut(duration: 0.18)) {
                notice = "Saved"
            }
        } catch {
            notice = "Could not save this voice card. Your previous version is still saved."
        }
    }

    private func deleteRecord() {
        do {
            try performConfirmedMemoryDeletion(
                delete: { modelContext.delete(voiceCard) },
                save: { try modelContext.save() },
                rollback: { modelContext.rollback() }
            )
            dismiss()
        } catch {
            notice = "Could not delete this voice card. It is still saved."
        }
    }

    private func memoryUseCard(isOn: Binding<Bool>, footer: String) -> some View {
        MomentDetailCard(title: "Use", systemImage: "checkmark.seal", footer: footer) {
            Toggle("Use this in drafts", isOn: isOn)
                .font(.body.weight(.medium))
                .foregroundStyle(Color.prosePalInk)
                .tint(.prosePalCare)
        }
    }

    private func detailDeleteButton(title: String, action: @escaping () -> Void) -> some View {
        Button(role: .destructive, action: action) {
            Label(title, systemImage: "trash")
                .font(.subheadline.weight(.semibold))
                .frame(maxWidth: .infinity)
                .frame(height: 48)
        }
        .buttonStyle(.plain)
        .foregroundStyle(Color.red.opacity(0.86))
        .background(Color.red.opacity(0.08), in: Capsule(style: .continuous))
    }
}

struct MomentSettingsView: View {
    @Bindable var account: MomentAccountModel
    let onDone: () -> Void
    @State private var supportNotice: String?
    @State private var isStatusWashVisible = false

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
                        title: "Tone options",
                        subtitle: "Choose a tone for each moment",
                        trailing: "Per draft"
                    )
                    settingsDivider
                    settingsStaticRow(
                        systemImage: "person.crop.square",
                        title: "Voice profile",
                        subtitle: "Relationship memory stays on this device",
                        trailing: account.runtimeReadiness.isRelationshipVaultPersistent ? "Available" : "Temporary"
                    )
                    settingsDivider
                    settingsStaticRow(
                        systemImage: "textformat.size",
                        title: "Text size",
                        subtitle: "Follows your device setting",
                        trailing: "System"
                    )
                }

                settingsGroup("Privacy") {
                    settingsStaticRow(
                        systemImage: "lock",
                        title: "Private Draft",
                        subtitle: "Uses on-device writing when available",
                        trailing: account.runtimeReadiness.isPrivateDraftConfigured ? "Automatic" : "Unavailable"
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
                    settingsNavigationRow(
                        systemImage: "checkmark.seal",
                        title: "ProsePal Pro",
                        subtitle: account.isPremiumUnlocked ? "Active" : "Upgrade available"
                    ) {
                        MomentPlanDetailView(account: account)
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
        .onScrollGeometryChange(for: Bool.self) { geometry in
            geometry.contentOffset.y > 8
        } action: { _, isScrolled in
            isStatusWashVisible = isScrolled
        }
        .background {
            MomentAtmosphericBackground(isCareful: false)
        }
        .overlay(alignment: .top) {
            settingsStatusWash
                .opacity(isStatusWashVisible ? 1 : 0)
                .animation(.easeInOut(duration: 0.16), value: isStatusWashVisible)
        }
        .tint(.prosePalCoral)
        #if os(iOS)
        .toolbar(.hidden, for: .navigationBar)
        #endif
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

    private var settingsStatusWash: some View {
        LinearGradient(
            stops: [
                Gradient.Stop(color: Color.prosePalPaper, location: 0.0),
                Gradient.Stop(color: Color.prosePalPaper, location: 0.78),
                Gradient.Stop(color: Color.prosePalPaper.opacity(0.0), location: 1.0)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .frame(height: 106)
        .ignoresSafeArea(edges: .top)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
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

private struct MomentPlanDetailView: View {
    @Bindable var account: MomentAccountModel
    @Environment(\.dismiss) private var dismiss
    @State private var isShowingPaywall = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                topChrome

                if let notice = account.notice {
                    planNotice(notice)
                }

                if account.isPremiumUnlocked {
                    proPlanContent
                } else {
                    freePlanContent
                }
            }
            .padding(.horizontal, 18)
            .padding(.top, 10)
            .padding(.bottom, 42)
        }
        .scrollIndicators(.hidden)
        .background {
            MomentAtmosphericBackground(isCareful: account.isPremiumUnlocked)
        }
        .tint(.prosePalCoral)
        #if os(iOS)
        .toolbar(.hidden, for: .navigationBar)
        #endif
        .sheet(isPresented: $isShowingPaywall) {
            MomentPaywallSheet(account: account)
        }
        .task {
            if account.isPremiumUnlocked &&
                account.subscriptionProducts.isEmpty &&
                account.isSubscriptionConfigured {
                await account.loadSubscriptionProducts(source: "plan_detail")
            }
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

            Text("Your plan")
                .font(.system(.title2, design: .serif).weight(.medium))
                .foregroundStyle(Color.prosePalInk)
                .lineLimit(1)
                .minimumScaleFactor(0.82)
        }
    }

    private var freePlanContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            freeUsageCard
            freeUpsellCard
        }
    }

    private var freeUsageCard: some View {
        VStack(alignment: .leading, spacing: 13) {
            HStack(alignment: .center, spacing: 10) {
                HStack(spacing: 8) {
                    Text("Free plan")
                        .font(.callout.weight(.semibold))
                        .foregroundStyle(Color.prosePalInk)

                    MomentPlanBadge(text: "Free", style: .outline)
                }

                Spacer(minLength: 10)

                Text("this week")
                    .font(.footnote)
                    .foregroundStyle(Color.prosePalSlate.opacity(0.68))
            }

            VStack(alignment: .leading, spacing: 9) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text("Starter refines")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.prosePalInk)

                    Spacer(minLength: 8)

                    Text("service-managed")
                        .font(.caption2.monospaced().weight(.medium))
                        .foregroundStyle(Color.prosePalSlate.opacity(0.64))
                        .lineLimit(1)
                        .minimumScaleFactor(0.78)
                }

                MomentPlanMeter(progress: nil, tint: .prosePalWarning)

                Text("Usage updates after ProsePal syncs your allowance.")
                    .font(.caption)
                    .foregroundStyle(Color.prosePalSlate.opacity(0.70))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
        .planCardSurface(cornerRadius: 18, shadow: true)
        .accessibilityElement(children: .combine)
    }

    private var freeUpsellCard: some View {
        VStack(alignment: .leading, spacing: 13) {
            HStack(alignment: .center, spacing: 12) {
                MomentPlanCrest(systemImage: "pencil.and.scribble", size: 44, cornerRadius: 14)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Go further with Pro")
                        .font(.callout.weight(.semibold))
                        .foregroundStyle(Color.prosePalInk)

                    Text("For the messages that matter most")
                        .font(.footnote)
                        .foregroundStyle(Color.prosePalSlate.opacity(0.72))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            VStack(alignment: .leading, spacing: 9) {
                MomentPlanFeatureLine(systemImage: "infinity", title: "Unlimited refines & drafts")
                MomentPlanFeatureLine(systemImage: "book.closed", title: "A voice profile that's yours")
                MomentPlanFeatureLine(systemImage: "slider.horizontal.3", title: "Every tone & length")
            }

            Button {
                isShowingPaywall = true
            } label: {
                Label("See Pro", systemImage: "pencil.and.scribble")
                    .font(.headline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
            }
            .buttonStyle(.plain)
            .foregroundStyle(Color.prosePalPaper)
            .background(Color.prosePalCoral, in: Capsule(style: .continuous))
            .shadow(color: Color.prosePalCoralDeep.opacity(0.18), radius: 10, x: 0, y: 5)
            .accessibilityLabel("See Pro")
        }
        .padding(16)
        .planCardSurface(cornerRadius: 18, shadow: true)
    }

    private var proPlanContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            proStatusCard
            includedGroup
            manageGroup
        }
    }

    private var proStatusCard: some View {
        VStack(spacing: 5) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 24, weight: .regular))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(Color.prosePalPaper)
                .frame(width: 46, height: 46)
                .background(Color.prosePalPaper.opacity(0.18), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .padding(.bottom, 6)

            Text("ProsePal Pro")
                .font(.system(size: 24, weight: .medium, design: .serif))
                .foregroundStyle(Color.prosePalPaper)
                .lineLimit(1)
                .minimumScaleFactor(0.84)

            Text(proPlanSubtitle)
                .font(.footnote)
                .foregroundStyle(Color.prosePalPaper.opacity(0.84))
                .lineLimit(2)
                .multilineTextAlignment(.center)

            Text(proPlanPrice)
                .font(.title3.weight(.semibold))
                .foregroundStyle(Color.prosePalPaper)
                .padding(.top, 8)
                .lineLimit(1)
                .minimumScaleFactor(0.78)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.prosePalCoral,
                            Color.prosePalCoralDeep
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        }
        .shadow(color: Color.prosePalCoralDeep.opacity(0.18), radius: 18, x: 0, y: 10)
        .accessibilityElement(children: .combine)
    }

    private var includedGroup: some View {
        planGroup("Included") {
            MomentPlanListRow(
                systemImage: "infinity",
                title: "Unlimited refines",
                tint: .prosePalCare,
                trailingSystemImage: "checkmark"
            )
            MomentPlanDivider()
            MomentPlanListRow(
                systemImage: "person.crop.square",
                title: "Voice profile",
                subtitle: account.runtimeReadiness.isRelationshipVaultPersistent ? "Active & learning" : "Available with local vault",
                tint: .prosePalCare,
                trailingSystemImage: "checkmark"
            )
        }
    }

    private var manageGroup: some View {
        VStack(spacing: 0) {
            Link(destination: MomentSettingsExternalLinks.manageSubscriptions) {
                MomentPlanListRow(
                    systemImage: "receipt",
                    title: "Manage subscription",
                    showsChevron: true
                )
            }
            .buttonStyle(.plain)
        }
        .planCardSurface(cornerRadius: 18)
    }

    private func planNotice(_ notice: MomentAccountNotice) -> some View {
        Label(notice.title, systemImage: notice.systemImage)
            .font(.callout.weight(.semibold))
            .foregroundStyle(Color.prosePalSlate)
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.prosePalPaper.opacity(0.92), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .accessibilityElement(children: .combine)
    }

    private func planGroup<Content: View>(
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
            .planCardSurface(cornerRadius: 18)
        }
    }

    private var activeDisplayedProduct: SubscriptionProduct? {
        account.activeSubscriptionProduct ?? account.selectedSubscriptionProduct
    }

    private var proPlanSubtitle: String {
        if let expiresAt = account.subscriptionEntitlement.expiresAt {
            if let duration = activeDisplayedProduct?.durationLabel, !duration.isEmpty {
                return "\(displayDurationLabel(duration)) · renews \(expiresAt.formatted(.dateTime.month(.abbreviated).day().year()))"
            }

            return "Renews \(expiresAt.formatted(.dateTime.month(.abbreviated).day().year()))"
        }

        if let duration = activeDisplayedProduct?.durationLabel, !duration.isEmpty {
            return "\(displayDurationLabel(duration)) · active"
        }

        return "Active subscription"
    }

    private var proPlanPrice: String {
        guard let product = activeDisplayedProduct else {
            return "Unlocked"
        }

        if let duration = product.durationLabel?.lowercased(), !duration.isEmpty {
            return "\(product.displayPrice)\(priceSuffix(for: duration))"
        }

        return product.displayPrice
    }

    private func displayDurationLabel(_ duration: String) -> String {
        let normalized = duration.lowercased()
        if normalized.contains("year") {
            return "Yearly"
        }
        if normalized.contains("month") {
            return "Monthly"
        }
        if normalized.contains("week") {
            return "Weekly"
        }
        return duration
    }

    private func priceSuffix(for duration: String) -> String {
        if duration.contains("year") {
            return "/yr"
        }
        if duration.contains("month") {
            return "/mo"
        }
        if duration.contains("week") {
            return "/wk"
        }
        return " / \(duration)"
    }
}

private struct MomentPlanBadge: View {
    enum Style {
        case outline
        case accent
    }

    let text: String
    var style: Style = .accent

    var body: some View {
        Text(text)
            .font(.caption2.weight(.bold))
            .foregroundStyle(style == .accent ? Color.prosePalPaper : Color.prosePalCoralDeep)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background {
                Capsule(style: .continuous)
                    .fill(style == .accent ? Color.prosePalCoral : Color.prosePalCoral.opacity(0.10))
                    .overlay {
                        Capsule(style: .continuous)
                            .stroke(Color.prosePalCoral.opacity(style == .accent ? 0 : 0.20), lineWidth: 1)
                    }
            }
    }
}

private struct MomentPlanCrest: View {
    let systemImage: String
    var size: CGFloat
    var cornerRadius: CGFloat

    var body: some View {
        Image(systemName: systemImage)
            .font(.system(size: size * 0.48, weight: .regular))
            .foregroundStyle(Color.prosePalCoralDeep)
            .frame(width: size, height: size)
            .background(
                LinearGradient(
                    colors: [
                        Color.prosePalCoral.opacity(0.18),
                        Color.prosePalPaper.opacity(0.92)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(Color.prosePalNavy.opacity(0.08), lineWidth: 0.8)
            }
            .accessibilityHidden(true)
    }
}

private struct MomentPlanFeatureLine: View {
    let systemImage: String
    let title: String

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            Image(systemName: systemImage)
                .font(.system(size: 17, weight: .regular))
                .foregroundStyle(Color.prosePalCoralDeep)
                .frame(width: 22)
                .accessibilityHidden(true)

            Text(title)
                .font(.subheadline)
                .foregroundStyle(Color.prosePalSlate.opacity(0.82))
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

private struct MomentPlanMeter: View {
    let progress: CGFloat?
    var tint: Color

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule(style: .continuous)
                    .fill(Color.prosePalNavy.opacity(0.10))

                if let progress {
                    Capsule(style: .continuous)
                        .fill(tint)
                        .frame(width: max(0, min(proxy.size.width, proxy.size.width * progress)))
                } else {
                    Capsule(style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    tint.opacity(0.26),
                                    tint.opacity(0.12)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: min(proxy.size.width * 0.38, 132))
                }
            }
        }
        .frame(height: 8)
        .accessibilityHidden(true)
    }
}

private struct MomentPlanListRow: View {
    let systemImage: String
    let title: String
    var subtitle: String?
    var tint: Color = .prosePalSlate
    var trailingSystemImage: String?
    var showsChevron = false

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: 20, weight: .regular))
                .foregroundStyle(tint)
                .frame(width: 36)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(Color.prosePalInk)
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

            if let trailingSystemImage {
                Image(systemName: trailingSystemImage)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(tint)
                    .accessibilityHidden(true)
            }

            if showsChevron {
                Image(systemName: "chevron.right")
                    .font(.body.weight(.medium))
                    .foregroundStyle(Color.prosePalSlate.opacity(0.48))
                    .accessibilityHidden(true)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
        .frame(minHeight: subtitle == nil ? 58 : 70)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }
}

private struct MomentPlanDivider: View {
    var body: some View {
        Rectangle()
            .fill(Color.prosePalNavy.opacity(0.11))
            .frame(height: 0.5)
            .padding(.leading, 64)
    }
}

private extension View {
    func planCardSurface(cornerRadius: CGFloat, shadow: Bool = false) -> some View {
        self
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.prosePalPaper.opacity(0.94), in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(Color.prosePalNavy.opacity(0.10), lineWidth: 1)
            }
            .shadow(color: shadow ? Color.prosePalCoralDeep.opacity(0.08) : Color.clear, radius: shadow ? 12 : 0, x: 0, y: shadow ? 6 : 0)
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
            VStack(alignment: .leading, spacing: 20) {
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
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: "lock")
                .font(.system(size: 20, weight: .regular))
                .foregroundStyle(Color.prosePalCoralDeep)
                .frame(width: 44, height: 44)
                .background(Color.prosePalCoral.opacity(0.12), in: RoundedRectangle(cornerRadius: 14, style: .continuous))

            VStack(alignment: .leading, spacing: 7) {
                Text("Your writing stays yours")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(Color.prosePalInk)

                Text("ProsePal processes drafts privately. Your words are never used to train models, and you can erase them at any time.")
                    .font(.callout)
                    .foregroundStyle(Color.prosePalSlate.opacity(0.78))
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(18)
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
        VStack(alignment: .leading, spacing: 10) {
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
                .frame(width: 38)

            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(isDestructive ? Color.red.opacity(0.84) : Color.prosePalInk)
                    .lineLimit(1)
                    .minimumScaleFactor(0.84)

                if let subtitle {
                    Text(subtitle)
                        .font(.callout)
                        .foregroundStyle(Color.prosePalSlate.opacity(0.78))
                        .lineSpacing(2)
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
        .padding(.vertical, 13)
        .frame(minHeight: 82)
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
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var exportState: MomentLocalDataExportState = .loading
    @State private var notice: String?

    var body: some View {
        VStack(spacing: 0) {
            topChrome
                .padding(.horizontal, 20)
                .padding(.top, 10)
                .padding(.bottom, 8)

            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    switch exportState {
                    case .loading:
                        loadingState
                    case .ready(let export):
                        readyState(export)
                    case .failed:
                        failedState
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 44)
            }
            .scrollIndicators(.hidden)
        }
        .background {
            MomentAtmosphericBackground(isCareful: false)
        }
        .tint(.prosePalCoral)
        #if os(iOS)
        .toolbar(.hidden, for: .navigationBar)
        #endif
        .task {
            if case .loading = exportState {
                prepareExport()
            }
        }
    }

    private var topChrome: some View {
        HStack(alignment: .center) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 17, weight: .semibold))
                    .frame(width: 42, height: 42)
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .foregroundStyle(Color.prosePalCoralDeep)
            .background(Color.prosePalPaper.opacity(0.74), in: Circle())
            .accessibilityLabel("Back")

            Spacer(minLength: 12)

            Text("Export")
                .font(.headline.weight(.semibold))
                .foregroundStyle(Color.prosePalInk)

            Spacer(minLength: 54)
        }
    }

    private var loadingState: some View {
        VStack(alignment: .leading, spacing: 18) {
            exportHero(
                systemImage: "square.and.arrow.up",
                title: "Preparing your export",
                detail: "Gathering saved drafts and approved relationship memory into one readable JSON file."
            )

            HStack(spacing: 12) {
                ProgressView()
                    .tint(.prosePalCoral)

                Text("Finding your local records...")
                    .font(.callout)
                    .foregroundStyle(Color.prosePalSlate.opacity(0.78))
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.prosePalPaper.opacity(0.94), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(Color.prosePalNavy.opacity(0.10), lineWidth: 1)
            }
        }
    }

    private func readyState(_ export: MomentLocalDataExport) -> some View {
        VStack(alignment: .leading, spacing: 22) {
            exportHero(
                systemImage: "checkmark.seal",
                title: "Your export is ready",
                detail: "This is a private snapshot of the local records ProsePal can use when helping you write."
            )

            exportGroup("Summary") {
                exportMetricRow(
                    systemImage: "doc.text",
                    title: "File",
                    value: export.fileName
                )
                exportDivider
                exportMetricRow(
                    systemImage: "calendar",
                    title: "Created",
                    value: formattedExportDate(export.snapshot.exportedAt)
                )
                exportDivider
                exportMetricRow(
                    systemImage: "text.badge.checkmark",
                    title: "Truth beads",
                    value: "\(export.snapshot.counts.truthBeads)"
                )
                exportDivider
                exportMetricRow(
                    systemImage: "person.crop.square",
                    title: "Voice cards",
                    value: "\(export.snapshot.counts.voiceCards)"
                )
                exportDivider
                exportMetricRow(
                    systemImage: "tray.full",
                    title: "Saved drafts",
                    value: "\(export.snapshot.counts.savedDrafts)"
                )
            }

            exportActions(export)

            if let notice {
                Label(notice, systemImage: "checkmark.circle.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.prosePalCare)
                    .frame(maxWidth: .infinity, alignment: .center)
            }

            exportPreview(export)
        }
    }

    private var failedState: some View {
        VStack(alignment: .leading, spacing: 18) {
            exportHero(
                systemImage: "exclamationmark.triangle",
                title: "Export failed",
                detail: "ProsePal could not prepare the local data export. You can try again without changing your records."
            )

            Button {
                prepareExport()
            } label: {
                Label("Try again", systemImage: "arrow.clockwise")
                    .font(.body.weight(.semibold))
                    .frame(maxWidth: .infinity, minHeight: 52)
            }
            .buttonStyle(.plain)
            .foregroundStyle(Color.prosePalPaper)
            .background(Color.prosePalCoral, in: Capsule(style: .continuous))
            .shadow(color: Color.prosePalCoralDeep.opacity(0.18), radius: 10, x: 0, y: 5)
        }
    }

    private func exportHero(systemImage: String, title: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: systemImage)
                .font(.system(size: 24, weight: .regular))
                .foregroundStyle(Color.prosePalCoralDeep)
                .frame(width: 52, height: 52)
                .background(Color.prosePalCoral.opacity(0.12), in: RoundedRectangle(cornerRadius: 17, style: .continuous))

            VStack(alignment: .leading, spacing: 7) {
                Text(title)
                    .font(.system(size: 30, weight: .regular, design: .serif))
                    .foregroundStyle(Color.prosePalInk)
                    .fixedSize(horizontal: false, vertical: true)

                Text(detail)
                    .font(.callout)
                    .foregroundStyle(Color.prosePalSlate.opacity(0.78))
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func exportGroup<Content: View>(
        _ title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.caption.weight(.semibold))
                .textCase(.uppercase)
                .foregroundStyle(Color.prosePalSlate.opacity(0.62))
                .padding(.horizontal, 2)

            VStack(spacing: 0) {
                content()
            }
            .background(Color.prosePalPaper.opacity(0.94), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(Color.prosePalNavy.opacity(0.10), lineWidth: 1)
            }
            .shadow(color: Color.prosePalCoralDeep.opacity(0.06), radius: 10, x: 0, y: 5)
        }
    }

    private func exportMetricRow(systemImage: String, title: String, value: String) -> some View {
        HStack(alignment: .center, spacing: 14) {
            Image(systemName: systemImage)
                .font(.system(size: 18, weight: .regular))
                .foregroundStyle(Color.prosePalSlate)
                .frame(width: 34)

            Text(title)
                .font(.callout.weight(.medium))
                .foregroundStyle(Color.prosePalInk)

            Spacer(minLength: 12)

            Text(value)
                .font(.callout.weight(.semibold))
                .foregroundStyle(Color.prosePalSlate.opacity(0.86))
                .multilineTextAlignment(.trailing)
                .lineLimit(2)
                .minimumScaleFactor(0.82)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .frame(minHeight: 58)
        .accessibilityElement(children: .combine)
    }

    private var exportDivider: some View {
        Rectangle()
            .fill(Color.prosePalNavy.opacity(0.08))
            .frame(height: 1)
            .padding(.leading, 64)
    }

    private func exportActions(_ export: MomentLocalDataExport) -> some View {
        VStack(spacing: 10) {
            Button {
                copy(export.jsonString)
            } label: {
                Label("Copy JSON", systemImage: "doc.on.doc")
                    .font(.body.weight(.semibold))
                    .frame(maxWidth: .infinity, minHeight: 52)
            }
            .buttonStyle(.plain)
            .foregroundStyle(Color.prosePalPaper)
            .background(Color.prosePalCoral, in: Capsule(style: .continuous))
            .shadow(color: Color.prosePalCoralDeep.opacity(0.18), radius: 10, x: 0, y: 5)

            Button {
                prepareExport()
            } label: {
                Label("Refresh export", systemImage: "arrow.clockwise")
                    .font(.body.weight(.semibold))
                    .frame(maxWidth: .infinity, minHeight: 48)
            }
            .buttonStyle(.plain)
            .foregroundStyle(Color.prosePalCoralDeep)
            .background(Color.prosePalCoral.opacity(0.12), in: Capsule(style: .continuous))
        }
    }

    private func exportPreview(_ export: MomentLocalDataExport) -> some View {
        exportGroup("Preview") {
            VStack(alignment: .leading, spacing: 12) {
                Text("Readable JSON")
                    .font(.callout.weight(.semibold))
                    .foregroundStyle(Color.prosePalInk)

                ScrollView {
                    Text(export.preview)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(Color.prosePalSlate.opacity(0.82))
                        .lineSpacing(3)
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(16)
                }
                .frame(maxHeight: 320, alignment: .top)
                .background(Color.momentGroupedBackground.opacity(0.42), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.prosePalNavy.opacity(0.08), lineWidth: 1)
                }
            }
            .padding(18)
        }
    }

    private func formattedExportDate(_ date: Date) -> String {
        date.formatted(.dateTime.year().month(.abbreviated).day().hour().minute())
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

struct MomentAppleSignInControl: View {
    @Bindable var account: MomentAccountModel
    let source: String
    var height: CGFloat = 52

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
            .frame(maxWidth: .infinity, minHeight: height, maxHeight: height)
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
        .frame(maxWidth: .infinity, minHeight: height, maxHeight: height)
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
                VStack(alignment: .leading, spacing: 14) {
                    paywallTopChrome
                    paywallHero
                    paywallFeaturePanel
                    productSection
                    purchaseActionSection
                    paywallFinePrint
                    accountSection
                }
                .padding(.horizontal, 18)
                .padding(.top, 14)
                .padding(.bottom, 30)
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
        .padding(.top, 0)
    }

    private var paywallHero: some View {
        VStack(spacing: 8) {
            Image(systemName: "pencil.and.scribble")
                .font(.system(size: 30, weight: .regular))
                .foregroundStyle(Color.prosePalCoralDeep)
                .frame(width: 58, height: 58)
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
                .font(.system(size: 32, weight: .regular, design: .serif).italic())
                .foregroundStyle(Color.prosePalInk)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.82)

            Text("Unlimited drafts, every register of tone, and a voice profile that remembers how you write.")
                .font(.subheadline)
                .foregroundStyle(Color.prosePalSlate.opacity(0.78))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: 312)
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
        .padding(.vertical, 2)
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
        VStack(alignment: .leading, spacing: 11) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "person.crop.circle")
                    .font(.system(size: 18, weight: .regular))
                    .foregroundStyle(Color.prosePalCoralDeep)
                    .frame(width: 32, height: 32)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Account")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(Color.prosePalInk)

                    Text(account.isSignedIn ? "Purchases are connected to your Apple account." : "Sign in with Apple to connect purchases to you.")
                        .font(.subheadline)
                        .foregroundStyle(Color.prosePalSlate.opacity(0.78))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            if !account.isSignedIn {
                MomentAppleSignInControl(account: account, source: "paywall", height: 48)
            }
        }
        .padding(13)
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
                .frame(width: 32, height: 32)

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
        .padding(.vertical, 10)
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
        VStack(alignment: .leading, spacing: 11) {
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
                    .frame(height: 46)
            }
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.capsule)
            .tint(.prosePalCoral)
        }
        .padding(14)
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
    static let manageSubscriptions = URL(string: "https://apps.apple.com/account/subscriptions")!
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
