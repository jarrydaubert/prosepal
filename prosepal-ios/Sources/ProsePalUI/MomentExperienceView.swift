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

@MainActor
@Observable
public final class MomentModel {
    public var personName: String = ""
    public var relationship: Relationship = .closeFriend
    public var occasion: Occasion = .birthday
    public var register: MomentRegister = .react
    public var trueThing: String = ""
    public var bundle: MomentDraftBundle?
    public var isDrafting = false
    public var errorMessage: String?
    public var draftUnavailableReason: MomentDraftUnavailableReason?

    @ObservationIgnored private let service: any MessageWritingService
    @ObservationIgnored private let diagnostics: NativeDiagnosticsLogger
    @ObservationIgnored private var draftTask: Task<Void, Never>?
    @ObservationIgnored private var draftGeneration = 0

    public init(
        service: any MessageWritingService,
        diagnostics: NativeDiagnosticsLogger = .shared
    ) {
        self.service = service
        self.diagnostics = diagnostics
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

    public func applyLaunchRequest(_ request: MomentLaunchRequest) {
        if let personName = request.personName {
            self.personName = personName
        }
        if let occasion = request.occasion {
            self.occasion = occasion
        }
        alignRegisterForMoment()
        scheduleDraft()
    }

    public func alignRegisterForMoment() {
        if moment.prefersCareRegister && register == .react {
            register = .assemble
        } else if !moment.prefersCareRegister && register == .assemble {
            register = .react
        }
    }

    public func scheduleDraft() {
        draftTask?.cancel()
        let generation = nextDraftGeneration()
        guard canDraft else {
            bundle = nil
            errorMessage = nil
            draftUnavailableReason = nil
            isDrafting = false
            return
        }

        draftTask = Task { [weak self] in
            do {
                try await Task.sleep(for: .milliseconds(450))
                await self?.draftNow(generation: generation)
            } catch {
                self?.clearCancelledDraftingState(generation: generation)
            }
        }
    }

    public func draftNow() async {
        await draftNow(generation: nextDraftGeneration(), trigger: "manual")
    }

    private func draftNow(generation: Int, trigger: String = "automatic") async {
        guard canDraft else { return }
        let input = moment
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
        guard let bundle else { return }
        draftTask?.cancel()
        let generation = nextDraftGeneration()
        draftTask = Task { [weak self, bundle] in
            await self?.adjustNow(bundle, adjustment: adjustment, generation: generation)
        }
    }

    public func takeMoreCare() {
        guard canDraft else { return }
        draftTask?.cancel()
        let generation = nextDraftGeneration()
        let currentBundle = bundle
        draftTask = Task { [weak self, currentBundle] in
            await self?.takeMoreCareNow(currentBundle, generation: generation)
        }
    }

    private func adjustNow(
        _ bundle: MomentDraftBundle,
        adjustment: MomentAdjustment,
        generation: Int
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
            self.bundle = nextBundle
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
        generation: Int
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
            self.bundle = nextBundle
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

    private func clearCancelledDraftingState(generation: Int) {
        if isCurrentGeneration(generation) && isDrafting {
            isDrafting = false
        }
    }

    private static func durationMs(since startedAt: Date) -> Int {
        max(0, Int(Date().timeIntervalSince(startedAt) * 1_000))
    }
}

private struct MomentDraftUnavailableNotice {
    var title: String
    var detail: String
    var systemImage: String
    var canRetry: Bool
}

public struct MomentAppRootView: View {
    @State private var model: MomentModel
    @State private var account: MomentAccountModel
    @State private var welcomeState: MomentWelcomeState
    @State private var selectedTab: MomentRootTab = .moment
    @State private var didLogStartup = false
    @Query(sort: \SavedMomentDraftRecord.createdAt, order: .reverse)
    private var savedDrafts: [SavedMomentDraftRecord]

    private let launchStore: MomentLaunchStore
    private let diagnostics: NativeDiagnosticsLogger

    public init(
        service: any MessageWritingService,
        account: MomentAccountModel,
        welcomeState: @autoclosure @escaping () -> MomentWelcomeState = MomentWelcomeState(),
        launchStore: MomentLaunchStore = MomentLaunchStore(),
        diagnostics: NativeDiagnosticsLogger = .shared
    ) {
        _model = State(initialValue: MomentModel(service: service))
        _account = State(initialValue: account)
        _welcomeState = State(initialValue: welcomeState())
        self.launchStore = launchStore
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
        applyLaunchRequest(deepLink.launchRequest)
    }

    private func applyLaunchRequest(_ request: MomentLaunchRequest) {
        selectedTab = .moment
        diagnostics.momentLaunchConsumed(request)
        model.applyLaunchRequest(request)
    }

    private var tabs: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                MomentSheetView(model: model, account: account)
                    .navigationTitle("ProsePal")
                    .toolbarTitleDisplayMode(.inline)
            }
            .tabItem {
                Label("Moment", systemImage: "square.and.pencil")
            }
            .tag(MomentRootTab.moment)

            NavigationStack {
                SavedMomentDraftsView()
            }
            .tabItem {
                Label("Saved", systemImage: "bookmark")
            }
            .tag(MomentRootTab.saved)

            NavigationStack {
                MomentSettingsView(account: account)
            }
            .tabItem {
                Label("Settings", systemImage: "gearshape")
            }
            .tag(MomentRootTab.settings)
        }
        .tint(.prosePalCoral)
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
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: systemImage)
                .font(.title3)
                .foregroundStyle(.tint)
                .frame(width: 32, height: 32)

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
    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
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
    @State private var editingTruthBead: RelationshipTruthBeadRecord?
    @State private var editingVoiceCard: RelationshipVoiceCardRecord?
    @State private var isShowingMemoryExplanation = false
    @State private var isShowingVoiceCardExplanation = false
    @State private var hasEntered = false

    private let diagnostics = NativeDiagnosticsLogger.shared

    private enum Field: Hashable {
        case person
        case truth
        case memory
        case voice
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header
                personSection
                momentSection
                if shouldReserveFirstViewportRailBreak {
                    Color.clear
                        .frame(height: firstViewportRailBreakHeight)
                        .accessibilityHidden(true)
                }
                truthSection
                if model.safetySignal == .crisisSupport {
                    crisisSupportSection
                } else if !currentPersonName.isEmpty {
                    memorySection
                    if model.moment.isCarefulMode {
                        carefulModeSection
                    }
                    draftSection
                } else {
                    draftSection
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
            .padding(.vertical, 18)
            .opacity(hasEntered ? 1 : 0)
            .offset(y: reduceMotion || hasEntered ? 0 : 12)
        }
        .background {
            MomentAtmosphericBackground(isCareful: model.moment.isCarefulMode)
                .animation(.easeInOut(duration: 0.28), value: model.moment.isCarefulMode)
        }
        .safeAreaInset(edge: .bottom) {
            if let bundle = model.bundle, focusedField == nil {
                actionRail(bundle: bundle)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .momentControlBarSurface()
            } else {
                MomentBottomRailClearance(isCareful: model.moment.isCarefulMode)
                    .frame(height: focusedField == nil ? 76 : 56)
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    focusedField = nil
                }
            }
        }
        .momentTabBarVisibility(isVisible: focusedField == nil)
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
        .sheet(item: $editingTruthBead, onDismiss: {
            model.scheduleDraft()
        }) { bead in
            NavigationStack {
                RelationshipMemoryDetailView(bead: bead)
            }
        }
        .sheet(item: $editingVoiceCard, onDismiss: {
            model.scheduleDraft()
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
        .onChange(of: model.personName) { _, _ in model.scheduleDraft() }
        .onChange(of: model.relationship) { _, newValue in
            diagnostics.selectionChanged(kind: "moment_relationship", value: newValue.rawValue)
            model.scheduleDraft()
        }
        .onChange(of: model.occasion) { _, newValue in
            diagnostics.selectionChanged(kind: "moment", value: newValue.rawValue)
            model.alignRegisterForMoment()
            model.scheduleDraft()
        }
        .onChange(of: model.register) { _, newValue in
            diagnostics.selectionChanged(kind: "moment_register", value: newValue.rawValue)
            model.scheduleDraft()
        }
        .onChange(of: model.trueThing) { _, _ in model.scheduleDraft() }
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

    private var currentPersonName: String {
        model.personName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var shouldReserveFirstViewportRailBreak: Bool {
        focusedField == nil && !currentPersonName.isEmpty
    }

    private var firstViewportRailBreakHeight: CGFloat {
        model.moment.isCarefulMode ? 84 : 96
    }

    private var bottomScrollSpacerHeight: CGFloat {
        if focusedField != nil {
            return 96
        }
        return model.bundle == nil && model.errorMessage == nil ? 132 : 170
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

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(
                model.moment.isCarefulMode ? "Take care active" : "Private by default",
                systemImage: model.moment.isCarefulMode ? "heart.text.square" : "lock.fill"
            )
            .font(.caption.weight(.bold))
            .foregroundStyle(Color.white.opacity(0.86))
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(Color.white.opacity(0.12), in: Capsule(style: .continuous))

            Text(currentPersonName.isEmpty ? "Who are you showing up for?" : "For \(currentPersonName)")
                .font(.system(currentPersonName.isEmpty ? .title : .title2, design: .serif).weight(.bold))
                .foregroundStyle(.white)
                .fixedSize(horizontal: false, vertical: true)

            if currentPersonName.isEmpty {
                Text("Start with the person. ProsePal keeps a private draft ready as you shape what is true.")
                    .font(.callout)
                    .foregroundStyle(.white.opacity(0.74))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(currentPersonName.isEmpty ? 20 : 18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            MomentHeroBackground(isCareful: model.moment.isCarefulMode)
        }
        .animation(.easeInOut(duration: 0.24), value: model.moment.isCarefulMode)
    }

    private var personSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            MomentSectionLabel(title: "Person", systemImage: "person.crop.circle")

            TextField("Name or person", text: $model.personName, prompt: Text("Alex, Mum, my manager"))
                .momentNameInputBehavior()
                .submitLabel(.next)
                .focused($focusedField, equals: .person)
                .font(.title3.weight(.semibold))
                .padding(16)
                .background(Color.momentSecondaryGroupedBackground, in: RoundedRectangle(cornerRadius: 18, style: .continuous))

            Button {
                focusedField = nil
                diagnostics.pickerOpened("relationship")
                isShowingRelationshipPicker = true
            } label: {
                MomentSelectionRow(
                    title: "Who they are to you",
                    value: model.relationship.displayName,
                    detail: model.relationship.group.displayName,
                    systemImage: model.relationship.symbolName
                )
            }
            .buttonStyle(.plain)
        }
        .prosePalMomentCard()
    }

    private var momentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            MomentSectionLabel(
                title: "Moment",
                systemImage: model.moment.isCarefulMode ? "heart.text.square" : "calendar",
                isCareful: model.moment.isCarefulMode
            )

            Button {
                focusedField = nil
                diagnostics.pickerOpened("moment")
                isShowingMomentPicker = true
            } label: {
                MomentSelectionRow(
                    title: "What is the moment?",
                    value: model.occasion.displayName,
                    detail: model.moment.prefersCareRegister ? "Handled with extra care" : model.occasion.group.displayName,
                    systemImage: model.occasion.symbolName
                )
            }
            .buttonStyle(.plain)

            MomentRegisterSelector(
                selection: $model.register,
                registers: availableRegisters,
                isCareful: model.moment.isCarefulMode
            )
        }
        .prosePalMomentCard(isCareful: model.moment.isCarefulMode)
    }

    private var availableRegisters: [MomentRegister] {
        if model.moment.prefersCareRegister {
            return MomentRegister.allCases.filter { $0 != .react }
        }
        return MomentRegister.allCases
    }

    private var truthSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            MomentSectionLabel(
                title: "What is true?",
                systemImage: "quote.bubble",
                isCareful: model.moment.isCarefulMode
            )

            TextField("One honest detail", text: $model.trueThing, prompt: Text("I miss our Sunday calls."))
                .focused($focusedField, equals: .truth)
                .submitLabel(.done)
                .padding(16)
                .momentInputSurface(isCareful: model.moment.isCarefulMode, cornerRadius: 18)

            Text("Optional for easy moments. Essential for harder ones.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .prosePalMomentCard(isCareful: model.moment.isCarefulMode)
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

            if approvedBeadsForCurrentPerson.isEmpty {
                Text("No saved details yet.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
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
                }
            }

            Divider()
                .padding(.vertical, 2)

            voiceCardControls
        }
        .prosePalMomentCard(prominence: approvedBeadsForCurrentPerson.isEmpty && voiceCardForCurrentPerson == nil ? .standard : .elevated)
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
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "heart.text.square")
                .font(.headline)
                .foregroundStyle(Color.prosePalCare)
                .frame(width: 28, height: 28)

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
                draftBody(bundle.messageText)

                if bundle.pressureCheck.hasFindings {
                    pressureCheck(bundle.pressureCheck)
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

    private func draftUnavailableView(_ notice: MomentDraftUnavailableNotice) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: notice.systemImage)
                    .font(.headline)
                    .foregroundStyle(.tint)
                    .frame(width: 24)

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

    private func draftBody(_ text: String) -> some View {
        Text(text)
            .font(.system(.title3, design: .serif))
            .lineSpacing(5)
            .textSelection(.enabled)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(20)
            .background {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.prosePalPaper,
                                Color.prosePalPaper.opacity(0.92),
                                Color.prosePalCoral.opacity(0.035)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(Color.prosePalCoral.opacity(0.18), lineWidth: 1)
                    }
            }
    }

    private func pressureCheck(_ check: PressureCheck) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Pressure check", systemImage: "checkmark.seal")
                .font(.subheadline.weight(.semibold))

            ForEach(check.userVisibleNotes, id: \.self) { note in
                Text(note)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(14)
        .background(Color.prosePalCare.opacity(0.10), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.prosePalCare.opacity(0.20), lineWidth: 1)
        }
    }

    private func actionRail(bundle: MomentDraftBundle) -> some View {
        VStack(spacing: 10) {
            if bundle.lane != .takeMoreCare {
                Button {
                    takeMoreCare()
                } label: {
                    Label("Take more care", systemImage: "heart.text.square")
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

    private func adjustmentButton(_ adjustment: MomentAdjustment) -> some View {
        Button {
            model.adjust(adjustment)
        } label: {
            Label(adjustment.displayName, systemImage: adjustment.systemImage)
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
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
        .buttonBorderShape(.capsule)
        .tint(.prosePalNavy)
    }

    private func shareButton(text: String) -> some View {
        ShareLink(item: text) {
            Label("Share", systemImage: "square.and.arrow.up")
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
            focusedField = nil
            model.scheduleDraft()
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
        model.scheduleDraft()
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
            focusedField = nil
            model.scheduleDraft()
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
        model.scheduleDraft()
    }
}

private struct MomentSelectionRow: View {
    let title: String
    let value: String
    let detail: String
    let systemImage: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.headline)
                .symbolRenderingMode(.hierarchical)
                .frame(width: 30, height: 30)
                .foregroundStyle(.tint)

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
                            Color.prosePalPaper.opacity(0.86),
                            Color.momentSecondaryGroupedBackground.opacity(0.82)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.prosePalCoral.opacity(0.16), lineWidth: 1)
                }
        }
        .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
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
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.headline)
                .symbolRenderingMode(.hierarchical)
                .frame(width: 28, height: 28)
                .foregroundStyle(.tint)

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
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "checkmark.seal.fill")
                .font(.subheadline)
                .foregroundStyle(.tint)
                .padding(.top, 2)

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
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: voiceCard.isUserApproved ? "waveform.circle.fill" : "pause.circle.fill")
                .font(.subheadline)
                .foregroundStyle(.tint)
                .padding(.top, 2)

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
        Label("Manage", systemImage: "ellipsis.circle")
            .font(.caption.weight(.semibold))
            .labelStyle(.titleAndIcon)
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
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 18)
        .padding(.vertical, 28)
        .background {
            MomentCardBackground(isCareful: false, prominence: .standard)
        }
        .accessibilityElement(children: .combine)
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

private struct SavedMomentDraftsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \SavedMomentDraftRecord.createdAt, order: .reverse)
    private var drafts: [SavedMomentDraftRecord]
    @State private var searchText = ""

    private var filteredDrafts: [SavedMomentDraftRecord] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return drafts }
        return drafts.filter { draft in
            draft.title.localizedCaseInsensitiveContains(query)
                || draft.subtitle.localizedCaseInsensitiveContains(query)
                || draft.messageText.localizedCaseInsensitiveContains(query)
        }
    }

    var body: some View {
        List {
            MomentScreenIdentityCard(
                eyebrow: "Saved",
                title: "Drafts worth keeping",
                detail: "Messages you choose to save stay close, searchable, and ready when the moment returns.",
                systemImage: "bookmark"
            )
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)

            if filteredDrafts.isEmpty {
                MomentSavedEmptyState(isSearching: !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .padding(.vertical, 26)
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            } else {
                ForEach(filteredDrafts) { draft in
                    NavigationLink {
                        SavedMomentDraftDetailView(draft: draft)
                    } label: {
                        SavedMomentDraftRow(draft: draft)
                    }
                    .listRowBackground(Color.prosePalPaper.opacity(0.84))
                }
                .onDelete(perform: delete)
            }
        }
        .navigationTitle("Saved")
        .searchable(text: $searchText, prompt: "Search saved drafts")
        .scrollContentBackground(.hidden)
        .background {
            MomentAtmosphericBackground(isCareful: false)
        }
    }

    private func delete(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(filteredDrafts[index])
        }
        try? modelContext.save()
    }
}

private struct SavedMomentDraftRow: View {
    let draft: SavedMomentDraftRecord

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(draft.title)
                    .font(.headline)
                Spacer(minLength: 12)
                Text(draft.createdAt, style: .date)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Text(draft.subtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text(draft.messageText)
                .font(.callout)
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
        .padding(.vertical, 4)
    }
}

private struct SavedMomentDraftDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    let draft: SavedMomentDraftRecord

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(draft.title)
                        .font(.system(.largeTitle, design: .serif).weight(.bold))
                        .fixedSize(horizontal: false, vertical: true)

                    Text(draft.subtitle)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }

                Text(draft.messageText)
                    .font(.system(.title3, design: .serif))
                    .lineSpacing(5)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(18)
                    .background {
                        MomentCardBackground(isCareful: false, prominence: .elevated)
                    }

                HStack(spacing: 12) {
                    Button {
                        copy(draft.messageText)
                    } label: {
                        Label("Copy", systemImage: "doc.on.doc")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .buttonBorderShape(.capsule)

                    ShareLink(item: draft.messageText) {
                        Label("Share", systemImage: "square.and.arrow.up")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .buttonBorderShape(.capsule)
                    .tint(.prosePalCoral)
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
            ToolbarItem(placement: .destructiveAction) {
                Button("Delete", role: .destructive) {
                    modelContext.delete(draft)
                    try? modelContext.save()
                    dismiss()
                }
            }
        }
    }

    private func copy(_ text: String) {
        #if canImport(UIKit)
        UIPasteboard.general.string = text
        #endif
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
                .padding(.vertical, 26)
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
        .searchable(text: $searchText, prompt: "Search memory")
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
    @State private var isShowingPaywall = false

    var body: some View {
        List {
            MomentScreenIdentityCard(
                eyebrow: "Settings",
                title: "Your ProsePal",
                detail: "Account, privacy, writing readiness, and the memory you approve.",
                systemImage: "gearshape",
                style: .quiet
            )
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)

            if let notice = account.notice {
                Section {
                    Label(notice.title, systemImage: notice.systemImage)
                        .font(.callout.weight(.semibold))
                }
                .momentListRowSurface()
            }

            Section("Account") {
                if account.isSignedIn {
                    LabeledContent("Signed in", value: account.signedInEmail ?? "Apple account")

                    Button {
                        Task {
                            await account.signOut()
                        }
                    } label: {
                        Label("Sign out", systemImage: "rectangle.portrait.and.arrow.right")
                    }

                    Button(role: .destructive) {
                        account.requestAccountDeletion()
                    } label: {
                        Label(
                            account.isDeletingAccount ? "Deleting..." : "Delete account",
                            systemImage: "trash"
                        )
                    }
                    .disabled(account.isDeletingAccount)
                } else {
                    MomentAppleSignInControl(account: account, source: "settings")
                    Text("Sign in when you want purchase restore, account deletion, or data export.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .momentListRowSurface()

            Section("Premium") {
                LabeledContent("Status", value: account.isPremiumUnlocked ? "Active" : "Not active")

                Button {
                    isShowingPaywall = true
                } label: {
                    Label("View Premium", systemImage: "star")
                }

                Button {
                    Task {
                        await account.restorePurchases(source: "settings")
                    }
                } label: {
                    Label(account.isRestoringPurchases ? "Restoring..." : "Restore purchases", systemImage: "arrow.clockwise")
                }
                .disabled(account.isRestoringPurchases)

                if let subscriptionErrorMessage = account.subscriptionErrorMessage {
                    Label(subscriptionErrorMessage, systemImage: "exclamationmark.triangle")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .momentListRowSurface()

            Section("Writing") {
                LabeledContent(
                    "Private Draft",
                    value: account.runtimeReadiness.isPrivateDraftConfigured ? "Device dependent" : "Unavailable here"
                )
                LabeledContent(
                    "Take more care",
                    value: account.runtimeReadiness.isCarefulGatewayConfigured ? "Ready" : "Needs setup"
                )
                Label("Private drafts depend on this device's runtime state", systemImage: "lock")
                Label("Take more care is used for harder moments", systemImage: "heart.text.square")
            }
            .momentListRowSurface()

            Section("Privacy") {
                Label("Saved drafts are only created when you tap Save", systemImage: "bookmark")
                NavigationLink {
                    RelationshipMemoryVaultView()
                } label: {
                    Label("Relationship memory", systemImage: "checkmark.seal")
                }
                LabeledContent("Export data", value: account.isSignedIn ? "Contact support" : "Sign in required")
                LabeledContent("Delete account", value: account.isSignedIn ? "Available above" : "Sign in required")
            }
            .momentListRowSurface()

            Section("Support") {
                Link(destination: MomentSettingsExternalLinks.support) {
                    Label("Contact support", systemImage: "envelope")
                }
            }
            .momentListRowSurface()

            Section("Legal") {
                Link(destination: MomentSettingsExternalLinks.terms) {
                    Label("Terms", systemImage: "doc.text")
                }
                Link(destination: MomentSettingsExternalLinks.privacy) {
                    Label("Privacy Policy", systemImage: "hand.raised")
                }
            }
            .momentListRowSurface()

            Section("About") {
                LabeledContent("Version", value: versionText)
                LabeledContent("Direction", value: "Native iOS")
            }
            .momentListRowSurface()
        }
        .navigationTitle("Settings")
        .scrollContentBackground(.hidden)
        .background {
            MomentAtmosphericBackground(isCareful: false)
        }
        .tint(.prosePalCoral)
        .sheet(isPresented: $isShowingPaywall) {
            MomentPaywallSheet(account: account)
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

    private var versionText: String {
        account.appVersionDisplayText
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
                VStack(alignment: .leading, spacing: 20) {
                    MomentScreenIdentityCard(
                        eyebrow: "Premium",
                        title: "Take more care",
                        detail: "Extra support for harder moments, higher limits, and more room to reshape a draft.",
                        systemImage: "star.fill",
                        isCareful: true
                    )

                    VStack(spacing: 12) {
                        MomentPremiumFeatureRow(
                            systemImage: "heart.text.square",
                            title: "Harder moments",
                            detail: "More support for nuanced, sensitive, or high-stakes messages."
                        )
                        MomentPremiumFeatureRow(
                            systemImage: "arrow.triangle.2.circlepath",
                            title: "More rewrites",
                            detail: "Try warmer, shorter, or clearer versions when the first draft is not quite right."
                        )
                        MomentPremiumFeatureRow(
                            systemImage: "infinity",
                            title: "Higher limits",
                            detail: "More room for everyday messages."
                        )
                    }

                    productSection

                    VStack(spacing: 10) {
                    Button {
                        Task {
                            await account.purchasePremium(source: "paywall")
                                if account.isPremiumUnlocked {
                                    dismiss()
                                }
                            }
                        } label: {
                            Label(account.isPurchasingPremium ? "Working..." : "Continue with Premium", systemImage: "star.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .buttonBorderShape(.capsule)
                        .tint(.prosePalCoral)
                        .controlSize(.large)
                        .disabled(account.isPurchasingPremium || account.isLoadingSubscriptions || account.subscriptionProducts.isEmpty)

                        Text(account.premiumRenewalDisclosureText)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)

                        Button {
                            Task {
                                await account.restorePurchases(source: "paywall")
                                if account.isPremiumUnlocked {
                                    dismiss()
                                }
                            }
                        } label: {
                            Label(account.isRestoringPurchases ? "Restoring..." : "Restore purchases", systemImage: "arrow.clockwise")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .buttonBorderShape(.capsule)
                        .controlSize(.large)
                        .disabled(account.isRestoringPurchases)

                        if let subscriptionErrorMessage = account.subscriptionErrorMessage {
                            Label(subscriptionErrorMessage, systemImage: "exclamationmark.triangle")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Account")
                            .font(.headline)

                        Text(account.isSignedIn ? "Purchases are connected to your Apple account." : "Sign in with Apple to connect purchases to you.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)

                        if !account.isSignedIn {
                            MomentAppleSignInControl(account: account, source: "paywall")
                        }
                    }
                    .padding(14)
                    .background {
                        MomentCardBackground(isCareful: false, prominence: .standard)
                    }

                    HStack(spacing: 8) {
                        Link("Terms", destination: MomentSettingsExternalLinks.terms)
                        Text("/")
                        Link("Privacy Policy", destination: MomentSettingsExternalLinks.privacy)
                    }
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                }
                .padding(22)
            }
            .background {
                MomentAtmosphericBackground(isCareful: true)
            }
            .navigationTitle("Premium")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .task {
                await account.loadSubscriptionProducts(source: "paywall")
            }
        }
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
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: systemImage)
                .font(.headline)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.headline)
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color.prosePalPaper.opacity(0.78), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.prosePalCare.opacity(0.18), lineWidth: 1)
        }
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
                .font(.title3)
                .foregroundStyle(isSelected ? Color.prosePalCoral : Color.secondary)

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 8) {
                    Text(title)
                        .font(.headline)

                    if let badge {
                        Text(badge)
                            .font(.caption2.weight(.bold))
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(.tint.opacity(0.14), in: Capsule())
                    }
                }

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 10)

            Text(price)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
        }
        .padding(14)
        .background {
            MomentCardBackground(
                isCareful: false,
                prominence: isSelected ? .accent : .standard
            )
        }
        .frame(maxWidth: .infinity)
    }
}

private struct MomentPaywallLoadingRow: View {
    var body: some View {
        HStack(spacing: 12) {
            ProgressView()

            VStack(alignment: .leading, spacing: 3) {
                Text("Loading subscription options")
                    .font(.headline)
                Text("This should only take a moment.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)
        }
        .padding(14)
        .background {
            MomentCardBackground(isCareful: false, prominence: .standard)
        }
        .accessibilityElement(children: .combine)
    }
}

private struct MomentPaywallUnavailableRow: View {
    let message: String
    let onRetry: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.body.weight(.semibold))
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Subscription options unavailable")
                        .font(.headline)
                    Text(message)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Button {
                onRetry()
            } label: {
                Label("Retry", systemImage: "arrow.clockwise")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .buttonBorderShape(.capsule)
        }
        .padding(14)
        .background {
            MomentCardBackground(isCareful: false, prominence: .warning)
        }
        .accessibilityElement(children: .combine)
    }
}

private enum MomentSettingsExternalLinks {
    static let terms = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!
    static let privacy = URL(string: "https://prosepal.app/privacy")!
    static let support = URL(string: "mailto:support@prosepal.app")!
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

private func playMomentSelectionFeedback() {
    #if canImport(UIKit)
    UISelectionFeedbackGenerator().selectionChanged()
    #endif
}

private enum MomentSurfaceProminence {
    case standard
    case elevated
    case accent
    case warning
}

private enum MomentIdentityCardStyle {
    case hero
    case quiet
}

private struct MomentScreenIdentityCard: View {
    @Environment(\.colorScheme) private var colorScheme

    let eyebrow: String
    let title: String
    let detail: String
    let systemImage: String
    var isCareful: Bool = false
    var style: MomentIdentityCardStyle = .hero

    var body: some View {
        Group {
            switch style {
            case .hero:
                heroCard
            case .quiet:
                quietCard
            }
        }
        .accessibilityElement(children: .combine)
    }

    private var heroCard: some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.white.opacity(0.12))
                    .frame(width: 52, height: 52)

                Image(systemName: systemImage)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.white)
                    .symbolRenderingMode(.hierarchical)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(eyebrow.uppercased())
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.white.opacity(0.72))

                Text(title)
                    .font(.system(.title2, design: .serif).weight(.bold))
                    .foregroundStyle(.white)
                    .fixedSize(horizontal: false, vertical: true)

                Text(detail)
                    .font(.callout)
                    .foregroundStyle(.white.opacity(0.74))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            MomentHeroBackground(isCareful: isCareful)
        }
    }

    private var quietCard: some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                accentColor.opacity(colorScheme == .dark ? 0.32 : 0.16),
                                Color.prosePalPaper.opacity(colorScheme == .dark ? 0.18 : 0.74)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 50, height: 50)

                Image(systemName: systemImage)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(accentColor)
                    .symbolRenderingMode(.hierarchical)
            }

            VStack(alignment: .leading, spacing: 5) {
                Text(eyebrow.uppercased())
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(accentColor)

                Text(title)
                    .font(.system(.title3, design: .serif).weight(.bold))
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)

                Text(detail)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.prosePalPaper.opacity(colorScheme == .dark ? 0.20 : 0.82))
                .overlay {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(colorScheme == .dark ? 0.18 : 0.52),
                                    Color.prosePalNavy.opacity(colorScheme == .dark ? 0.24 : 0.10),
                                    accentColor.opacity(colorScheme == .dark ? 0.18 : 0.10)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                }
                .shadow(color: Color.prosePalNavy.opacity(colorScheme == .dark ? 0.16 : 0.08), radius: 14, x: 0, y: 8)
        }
    }

    private var accentColor: Color {
        isCareful ? Color.prosePalCare : Color.prosePalCoral
    }
}

private struct MomentAtmosphericBackground: View {
    @Environment(\.colorScheme) private var colorScheme

    let isCareful: Bool

    var body: some View {
        ZStack {
            Color.momentGroupedBackground

            LinearGradient(
                colors: isCareful
                    ? [
                        Color.prosePalCare.opacity(colorScheme == .dark ? 0.22 : 0.14),
                        Color.momentGroupedBackground,
                        Color.prosePalNavy.opacity(colorScheme == .dark ? 0.20 : 0.12)
                    ]
                    : [
                        Color.prosePalCoral.opacity(colorScheme == .dark ? 0.14 : 0.09),
                        Color.momentGroupedBackground,
                        Color.prosePalNavy.opacity(colorScheme == .dark ? 0.18 : 0.10)
                    ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            LinearGradient(
                colors: [
                    Color.prosePalPaper.opacity(colorScheme == .dark ? (isCareful ? 0.08 : 0.12) : 0.08),
                    Color.clear,
                    Color.prosePalNavy.opacity(colorScheme == .dark ? 0.06 : 0.035)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
        .ignoresSafeArea()
    }
}

private struct MomentHeroBackground: View {
    let isCareful: Bool

    var body: some View {
        RoundedRectangle(cornerRadius: 28, style: .continuous)
            .fill(
                LinearGradient(
                    colors: isCareful
                        ? [
                            Color.prosePalNavy,
                            Color.prosePalCare.opacity(0.82),
                            Color.prosePalNavy.opacity(0.92)
                        ]
                        : [
                            Color.prosePalNavy,
                            Color.prosePalCoralDeep.opacity(0.82),
                            Color.prosePalNavy.opacity(0.90)
                        ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.36),
                                Color.white.opacity(0.10),
                                Color.prosePalCoral.opacity(isCareful ? 0.12 : 0.32)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
            .shadow(color: Color.prosePalNavy.opacity(0.18), radius: 24, x: 0, y: 14)
    }
}

private struct MomentCardBackground: View {
    let isCareful: Bool
    let prominence: MomentSurfaceProminence

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 22, style: .continuous)

        shape
            .fill(cardFill)
            .overlay {
                shape.stroke(borderFill, lineWidth: borderWidth)
            }
            .shadow(
                color: shadowColor,
                radius: prominence == .elevated ? 18 : 10,
                x: 0,
                y: prominence == .elevated ? 10 : 5
            )
    }

    private var cardFill: LinearGradient {
        switch prominence {
        case .accent:
            LinearGradient(
                colors: [
                    Color.prosePalCoral.opacity(0.20),
                    Color.prosePalCard,
                    Color.prosePalPaper.opacity(0.88),
                    Color.prosePalNavy.opacity(0.035)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .warning:
            LinearGradient(
                colors: [
                    Color.prosePalWarning.opacity(0.18),
                    Color.prosePalCard,
                    Color.prosePalPaper.opacity(0.88),
                    Color.prosePalNavy.opacity(0.035)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .standard, .elevated:
            LinearGradient(
                colors: isCareful
                    ? [
                        Color.prosePalCareSurface,
                        Color.prosePalCard,
                        Color.prosePalPaper.opacity(0.84),
                        Color.prosePalNavy.opacity(0.04)
                    ]
                    : [
                        Color.prosePalCard,
                        Color.prosePalPaper.opacity(0.90),
                        Color.prosePalCoral.opacity(0.06),
                        Color.prosePalNavy.opacity(0.035)
                    ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    private var borderFill: LinearGradient {
        LinearGradient(
            colors: [
                Color.white.opacity(0.52),
                accentColor.opacity(prominence == .standard ? 0.20 : 0.38),
                Color.prosePalNavy.opacity(prominence == .standard ? 0.14 : 0.22)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var accentColor: Color {
        switch prominence {
        case .warning:
            Color.prosePalWarning
        default:
            isCareful ? Color.prosePalCare : Color.prosePalCoral
        }
    }

    private var borderWidth: CGFloat {
        prominence == .standard ? 0.8 : 1
    }

    private var shadowColor: Color {
        switch prominence {
        case .warning:
            Color.prosePalWarning.opacity(0.10)
        default:
            Color.prosePalNavy.opacity(prominence == .elevated ? 0.16 : 0.08)
        }
    }
}

private struct MomentRegisterSelector: View {
    @Binding var selection: MomentRegister
    let registers: [MomentRegister]
    let isCareful: Bool

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 8) {
                registerButtons
            }

            VStack(spacing: 8) {
                registerButtons
            }
        }
        .animation(.spring(response: 0.34, dampingFraction: 0.82), value: selection)
        .animation(.spring(response: 0.34, dampingFraction: 0.82), value: registers.map(\.rawValue).joined())
    }

    @ViewBuilder
    private var registerButtons: some View {
        ForEach(registers) { register in
            Button {
                selection = register
                playMomentSelectionFeedback()
            } label: {
                MomentRegisterOption(
                    register: register,
                    isSelected: selection == register,
                    isCareful: isCareful
                )
            }
            .buttonStyle(.plain)
        }
    }
}

private struct MomentRegisterOption: View {
    let register: MomentRegister
    let isSelected: Bool
    let isCareful: Bool

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: register.systemImage)
                .font(.caption.weight(.bold))
                .symbolRenderingMode(.hierarchical)

            Text(register.displayName)
                .font(.footnote.weight(.semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.82)
        }
        .foregroundStyle(isSelected ? Color.white : Color.primary)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity)
        .background {
            Capsule(style: .continuous)
                .fill(backgroundFill)
        }
        .overlay {
            Capsule(style: .continuous)
                .stroke(
                    isSelected ? Color.white.opacity(0.24) : accentColor.opacity(0.20),
                    lineWidth: 1
                )
        }
        .scaleEffect(isSelected ? 1 : 0.98)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }

    private var accentColor: Color {
        isCareful ? .prosePalCare : .prosePalCoral
    }

    private var backgroundFill: LinearGradient {
        if isSelected {
            return LinearGradient(
                colors: isCareful
                    ? [Color.prosePalCare, Color.prosePalNavy.opacity(0.92)]
                    : [Color.prosePalCoral, Color.prosePalCoralDeep],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }

        return LinearGradient(
            colors: [
                Color.prosePalPaper.opacity(0.82),
                Color.momentSecondaryGroupedBackground.opacity(0.88)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

private struct MomentBottomRailClearance: View {
    let isCareful: Bool

    var body: some View {
        LinearGradient(
            stops: [
                .init(color: Color.momentGroupedBackground.opacity(0), location: 0),
                .init(color: Color.momentGroupedBackground.opacity(0.06), location: 0.48),
                .init(color: Color.momentGroupedBackground.opacity(0.24), location: 1)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .overlay(alignment: .bottom) {
            (isCareful ? Color.prosePalCare : Color.prosePalCoral)
                .opacity(0.035)
                .frame(height: 34)
                .blur(radius: 12)
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

private struct MomentSectionLabel: View {
    let title: String
    let systemImage: String
    var isCareful: Bool = false

    var body: some View {
        Label(title, systemImage: systemImage)
            .font(.headline)
            .symbolRenderingMode(.hierarchical)
            .foregroundStyle(isCareful ? Color.prosePalCare : Color.primary)
    }
}

private extension View {
    func prosePalMomentCard(
        isCareful: Bool = false,
        prominence: MomentSurfaceProminence = .standard
    ) -> some View {
        self
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                MomentCardBackground(isCareful: isCareful, prominence: prominence)
            }
    }

    func momentInputSurface(isCareful: Bool = false, cornerRadius: CGFloat = 16) -> some View {
        self
            .background {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.prosePalPaper.opacity(0.98),
                                Color.momentSecondaryGroupedBackground.opacity(0.92)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .stroke(
                                (isCareful ? Color.prosePalCare : Color.prosePalCoral).opacity(0.16),
                                lineWidth: 1
                            )
                    }
            }
    }

    func momentListRowSurface(isCareful: Bool = false) -> some View {
        self
            .listRowBackground(
                LinearGradient(
                    colors: [
                        Color.prosePalPaper.opacity(0.92),
                        Color.prosePalCard.opacity(0.88),
                        (isCareful ? Color.prosePalCare : Color.prosePalCoral).opacity(0.045)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
    }

    @ViewBuilder
    func momentPickerListStyle() -> some View {
        #if os(iOS)
        self.listStyle(.insetGrouped)
        #else
        self
        #endif
    }

    @ViewBuilder
    func momentNameInputBehavior() -> some View {
        #if os(iOS)
        self.textInputAutocapitalization(.words)
        #else
        self
        #endif
    }

    @ViewBuilder
    func momentTabBarVisibility(isVisible: Bool) -> some View {
        #if os(iOS)
        self.toolbar(isVisible ? .visible : .hidden, for: .tabBar)
        #else
        self
        #endif
    }

    @ViewBuilder
    func momentControlBarSurface() -> some View {
        #if os(iOS) || os(macOS) || os(tvOS) || os(watchOS)
        if #available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, *) {
            self
                .padding(8)
                .glassEffect(
                    .regular.tint(Color.prosePalNavy.opacity(0.10)).interactive(),
                    in: .rect(cornerRadius: 30)
                )
        } else {
            self
                .background(.bar)
                .overlay(alignment: .top) {
                    Divider()
                }
        }
        #else
        self
            .background(.bar)
            .overlay(alignment: .top) {
                Divider()
            }
        #endif
    }
}

private extension MomentRegister {
    var systemImage: String {
        switch self {
        case .react:
            "bolt.fill"
        case .confess:
            "pencil"
        case .assemble:
            "heart.text.square"
        }
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

private extension Color {
    static var momentGroupedBackground: Color {
        #if canImport(UIKit)
        Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(red: 0.055, green: 0.066, blue: 0.082, alpha: 1)
                : UIColor(red: 0.974, green: 0.958, blue: 0.925, alpha: 1)
        })
        #elseif canImport(AppKit)
        Color(nsColor: .windowBackgroundColor)
        #else
        Color.gray.opacity(0.08)
        #endif
    }

    static var momentSecondaryGroupedBackground: Color {
        #if canImport(UIKit)
        Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(red: 0.108, green: 0.125, blue: 0.152, alpha: 1)
                : UIColor(red: 0.946, green: 0.918, blue: 0.870, alpha: 1)
        })
        #elseif canImport(AppKit)
        Color(nsColor: .controlBackgroundColor)
        #else
        Color.gray.opacity(0.12)
        #endif
    }

    static var prosePalPaper: Color {
        #if canImport(UIKit)
        Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(red: 0.100, green: 0.108, blue: 0.126, alpha: 1)
                : UIColor(red: 1.000, green: 0.992, blue: 0.966, alpha: 1)
        })
        #elseif canImport(AppKit)
        Color(nsColor: .textBackgroundColor)
        #else
        Color.white
        #endif
    }

    static var prosePalCard: Color {
        #if canImport(UIKit)
        Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(red: 0.082, green: 0.096, blue: 0.118, alpha: 1)
                : UIColor(red: 0.992, green: 0.978, blue: 0.948, alpha: 1)
        })
        #elseif canImport(AppKit)
        Color(nsColor: .controlBackgroundColor)
        #else
        Color.gray.opacity(0.12)
        #endif
    }

    static var prosePalNavy: Color {
        Color(red: 0.10, green: 0.14, blue: 0.20)
    }

    static var prosePalCoral: Color {
        Color(red: 0.83, green: 0.39, blue: 0.35)
    }

    static var prosePalCoralDeep: Color {
        Color(red: 0.64, green: 0.25, blue: 0.23)
    }

    static var prosePalCare: Color {
        Color(red: 0.38, green: 0.53, blue: 0.70)
    }

    static var prosePalCareSurface: Color {
        Color.prosePalCare.opacity(0.14)
    }

    static var prosePalWarning: Color {
        Color(red: 0.78, green: 0.48, blue: 0.22)
    }
}
