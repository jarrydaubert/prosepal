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

    public func scheduleDraft() {
        draftTask?.cancel()
        let generation = nextDraftGeneration()
        guard canDraft else {
            bundle = nil
            errorMessage = nil
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
            diagnostics.momentDraftFailed(
                requestID: requestID,
                category: error.diagnosticsCategory,
                durationMs: Self.durationMs(since: startedAt)
            )
        } catch {
            guard isCurrentGeneration(generation) else { return }
            errorMessage = "ProsePal could not write this yet."
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
            diagnostics.momentDraftFailed(
                requestID: requestID,
                category: error.diagnosticsCategory,
                durationMs: Self.durationMs(since: startedAt)
            )
        } catch {
            guard isCurrentGeneration(generation) else { return }
            errorMessage = "ProsePal could not reshape this yet."
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
            diagnostics.momentDraftFailed(
                requestID: requestID,
                category: error.diagnosticsCategory,
                durationMs: Self.durationMs(since: startedAt)
            )
        } catch {
            guard isCurrentGeneration(generation) else { return }
            errorMessage = "ProsePal could not take more care with this yet."
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

public struct MomentAppRootView: View {
    @State private var model: MomentModel
    @State private var account: MomentAccountModel
    @State private var welcomeState: MomentWelcomeState
    @State private var selectedTab: MomentRootTab = .moment

    public init(
        service: any MessageWritingService,
        account: MomentAccountModel,
        welcomeState: @autoclosure @escaping () -> MomentWelcomeState = MomentWelcomeState()
    ) {
        _model = State(initialValue: MomentModel(service: service))
        _account = State(initialValue: account)
        _welcomeState = State(initialValue: welcomeState())
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
        .task {
            await account.loadInitialState()
        }
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

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                Spacer(minLength: 44)

                VStack(alignment: .leading, spacing: 14) {
                    Text("Words for the moment.")
                        .font(.system(.largeTitle, design: .serif).weight(.bold))
                        .fixedSize(horizontal: false, vertical: true)

                    Text("Start with who this is for. ProsePal keeps a private draft nearby, then helps you take more care when the moment needs it.")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
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
        }
        .background(Color.momentGroupedBackground)
        .safeAreaInset(edge: .bottom) {
            Button {
                onStart()
            } label: {
                Label("Start with someone", systemImage: "arrow.right")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
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
        .background(Color.prosePalCard, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .accessibilityElement(children: .combine)
    }
}

private struct MomentSheetView: View {
    @Bindable var model: MomentModel
    @Bindable var account: MomentAccountModel
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \RelationshipTruthBeadRecord.updatedAt, order: .reverse)
    private var truthBeads: [RelationshipTruthBeadRecord]
    @FocusState private var focusedField: Field?
    @State private var saveNotice: String?
    @State private var isShowingRelationshipPicker = false
    @State private var isShowingMomentPicker = false
    @State private var isShowingPaywall = false
    @State private var newTruthBeadText = ""

    private let diagnostics = NativeDiagnosticsLogger.shared

    private enum Field: Hashable {
        case person
        case truth
        case memory
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                header
                personSection
                momentSection
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
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 22)
        }
        .background(Color.momentGroupedBackground)
        .safeAreaInset(edge: .bottom) {
            if let bundle = model.bundle {
                actionRail(bundle: bundle)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .momentControlBarSurface()
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
        .onChange(of: model.personName) { _, _ in model.scheduleDraft() }
        .onChange(of: model.relationship) { _, newValue in
            diagnostics.selectionChanged(kind: "moment_relationship", value: newValue.rawValue)
            model.scheduleDraft()
        }
        .onChange(of: model.occasion) { _, newValue in
            diagnostics.selectionChanged(kind: "moment", value: newValue.rawValue)
            model.scheduleDraft()
        }
        .onChange(of: model.register) { _, newValue in
            diagnostics.selectionChanged(kind: "moment_register", value: newValue.rawValue)
            model.scheduleDraft()
        }
        .onChange(of: model.trueThing) { _, _ in model.scheduleDraft() }
    }

    private var currentPersonName: String {
        model.personName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var approvedBeadsForCurrentPerson: [RelationshipTruthBeadRecord] {
        let normalizedName = currentPersonName.momentNormalizedSearchKey
        guard !normalizedName.isEmpty else { return [] }
        return truthBeads.filter {
            $0.isUserApproved && $0.personName.momentNormalizedSearchKey == normalizedName
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Who are you showing up for?")
                .font(.largeTitle.weight(.bold))
                .fixedSize(horizontal: false, vertical: true)

            Text("Start with the person. ProsePal will find the moment and keep a private draft ready as you shape what is true.")
                .font(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.top, 12)
    }

    private var personSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Person")
                .font(.headline)

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
            Text("Moment")
                .font(.headline)

            Button {
                focusedField = nil
                diagnostics.pickerOpened("moment")
                isShowingMomentPicker = true
            } label: {
                MomentSelectionRow(
                    title: "What is the moment?",
                    value: model.occasion.displayName,
                    detail: model.occasion.group.displayName,
                    systemImage: model.occasion.symbolName
                )
            }
            .buttonStyle(.plain)

            Picker("Care", selection: $model.register) {
                ForEach(MomentRegister.allCases) { register in
                    Text(register.displayName).tag(register)
                }
            }
            .pickerStyle(.segmented)

            Text(model.register.userSafeDescription)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .prosePalMomentCard()
    }

    private var truthSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("What is true?")
                .font(.headline)

            TextField("One honest detail", text: $model.trueThing, prompt: Text("I miss our Sunday calls."))
                .focused($focusedField, equals: .truth)
                .submitLabel(.done)
                .padding(16)
                .background(Color.momentSecondaryGroupedBackground, in: RoundedRectangle(cornerRadius: 18, style: .continuous))

            Text("Optional for easy moments. Essential for harder ones.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .prosePalMomentCard()
    }

    private var memorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Label("Relationship memory", systemImage: "checkmark.seal")
                    .font(.headline)

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
                    .background(Color.momentSecondaryGroupedBackground, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
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
                        MomentTruthBeadRow(bead: bead) {
                            deleteTruthBead(bead)
                        }
                    }
                }
            }
        }
        .prosePalMomentCard()
    }

    private var crisisSupportSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("This needs immediate support", systemImage: "exclamationmark.triangle.fill")
                .font(.headline)

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
        .prosePalMomentCard()
    }

    private var carefulModeSection: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "heart.text.square")
                .font(.headline)
                .foregroundStyle(.tint)
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
        .prosePalMomentCard()
    }

    @ViewBuilder
    private var draftSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label("Private draft", systemImage: "lock")
                    .font(.headline)
                Spacer()
                if model.isDrafting {
                    ProgressView()
                        .controlSize(.small)
                }
            }

            if let errorMessage = model.errorMessage {
                Text(errorMessage)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
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
        .prosePalMomentCard()
    }

    private func draftBody(_ text: String) -> some View {
        Text(text)
            .font(.system(.title3, design: .serif))
            .lineSpacing(5)
            .textSelection(.enabled)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(18)
            .background(Color.prosePalPaper, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private func pressureCheck(_ check: PressureCheck) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Pressure check", systemImage: "checkmark.seal")
                .font(.subheadline.weight(.semibold))

            ForEach(check.notes, id: \.self) { note in
                Text(note)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(14)
        .background(Color.momentSecondaryGroupedBackground, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
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
                .controlSize(.large)
                .disabled(model.isDrafting)
            }

            HStack(spacing: 10) {
                ForEach(MomentAdjustment.allCases) { adjustment in
                    Button(adjustment.displayName) {
                        model.adjust(adjustment)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .disabled(model.isDrafting)
                }
            }

            HStack(spacing: 10) {
                Button {
                    copy(bundle.messageText)
                } label: {
                    Label("Copy", systemImage: "doc.on.doc")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)

                ShareLink(item: bundle.messageText) {
                    Label("Share", systemImage: "square.and.arrow.up")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)

                Button {
                    save(bundle)
                } label: {
                    Label("Save", systemImage: "bookmark")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
            .controlSize(.large)
        }
    }

    private func takeMoreCare() {
        if account.isPremiumUnlocked {
            diagnostics.messageAction(
                "take_more_care",
                source: "moment_draft",
                messageCharacters: model.bundle?.messageText.count ?? 0
            )
            model.takeMoreCare()
        } else {
            diagnostics.messageAction(
                "take_more_care_locked",
                source: "moment_draft",
                messageCharacters: model.bundle?.messageText.count ?? 0
            )
            isShowingPaywall = true
        }
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
        .background(Color.momentSecondaryGroupedBackground, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
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
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }
}

private struct MomentTruthBeadRow: View {
    let bead: RelationshipTruthBeadRecord
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

            Button(role: .destructive) {
                onDelete()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.body)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
            .accessibilityLabel("Delete relationship memory")
        }
        .padding(12)
        .background(Color.momentSecondaryGroupedBackground, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
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
            if filteredDrafts.isEmpty {
                ContentUnavailableView(
                    searchText.isEmpty ? "No saved drafts yet" : "No saved drafts found",
                    systemImage: "bookmark",
                    description: Text(searchText.isEmpty ? "When a message feels right, save it here for later." : "Try another person, moment, or phrase.")
                )
                .listRowBackground(Color.clear)
            } else {
                ForEach(filteredDrafts) { draft in
                    NavigationLink {
                        SavedMomentDraftDetailView(draft: draft)
                    } label: {
                        SavedMomentDraftRow(draft: draft)
                    }
                }
                .onDelete(perform: delete)
            }
        }
        .navigationTitle("Saved")
        .searchable(text: $searchText, prompt: "Search saved drafts")
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
                        .font(.largeTitle.weight(.bold))
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
                    .background(Color.prosePalPaper, in: RoundedRectangle(cornerRadius: 20, style: .continuous))

                HStack(spacing: 12) {
                    Button {
                        copy(draft.messageText)
                    } label: {
                        Label("Copy", systemImage: "doc.on.doc")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)

                    ShareLink(item: draft.messageText) {
                        Label("Share", systemImage: "square.and.arrow.up")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                }
                .controlSize(.large)
            }
            .padding(20)
        }
        .background(Color.momentGroupedBackground)
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
    @State private var searchText = ""

    private var filteredBeads: [RelationshipTruthBeadRecord] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return beads }

        return beads.filter {
            $0.personName.localizedCaseInsensitiveContains(query)
                || $0.text.localizedCaseInsensitiveContains(query)
        }
    }

    var body: some View {
        List {
            if filteredBeads.isEmpty {
                ContentUnavailableView(
                    searchText.isEmpty ? "No relationship memory yet" : "No matching details",
                    systemImage: "checkmark.seal",
                    description: Text(searchText.isEmpty ? "Save details from the Moment screen when they should help future drafts." : "Try another person or phrase.")
                )
                .listRowBackground(Color.clear)
            } else {
                ForEach(filteredBeads) { bead in
                    NavigationLink {
                        RelationshipMemoryDetailView(bead: bead)
                    } label: {
                        RelationshipMemoryRow(bead: bead)
                    }
                }
                .onDelete(perform: delete)
            }
        }
        .navigationTitle("Memory")
        .searchable(text: $searchText, prompt: "Search memory")
    }

    private func delete(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(filteredBeads[index])
        }
        try? modelContext.save()
    }
}

private struct RelationshipMemoryRow: View {
    let bead: RelationshipTruthBeadRecord

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 8) {
                Text(bead.personName)
                    .font(.headline)

                if !bead.isUserApproved {
                    Text("Paused")
                        .font(.caption2.weight(.bold))
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(.secondary.opacity(0.12), in: Capsule())
                }
            }

            Text(bead.text)
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
        bead.personName = personName.trimmingCharacters(in: .whitespacesAndNewlines)
        bead.text = text.trimmingCharacters(in: .whitespacesAndNewlines)
        bead.isUserApproved = isUserApproved
        bead.updatedAt = Date()
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
            if let notice = account.notice {
                Section {
                    Label(notice.title, systemImage: notice.systemImage)
                        .font(.callout.weight(.semibold))
                }
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
                }
            }

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
            }

            Section("Writing") {
                Label("Private draft starts on device when available", systemImage: "lock")
                Label("Take more care is used for harder moments", systemImage: "heart.text.square")
            }

            Section("Privacy") {
                Label("Saved drafts are only created when you tap Save", systemImage: "bookmark")
                NavigationLink {
                    RelationshipMemoryVaultView()
                } label: {
                    Label("Relationship memory", systemImage: "checkmark.seal")
                }
            }

            Section("About") {
                LabeledContent("Version", value: versionText)
                LabeledContent("Direction", value: "Native iOS")
            }
        }
        .navigationTitle("Settings")
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
                    VStack(alignment: .leading, spacing: 10) {
                        Label("Premium", systemImage: "star.fill")
                            .font(.headline.weight(.semibold))

                        Text("Take more care")
                            .font(.largeTitle.weight(.bold))

                        Text("Extra support for harder moments, higher limits, and more room to reshape a draft.")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

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
                        .controlSize(.large)
                        .disabled(account.isRestoringPurchases)
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
                    .background(Color.momentSecondaryGroupedBackground, in: RoundedRectangle(cornerRadius: 18, style: .continuous))

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
            .background(Color.momentGroupedBackground)
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
                    .buttonStyle(.bordered)
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
        .background(Color.momentSecondaryGroupedBackground, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
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
                .foregroundStyle(isSelected ? Color.accentColor : Color.secondary)

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
        .background(Color.momentSecondaryGroupedBackground, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(isSelected ? Color.accentColor.opacity(0.55) : Color.clear, lineWidth: 1.4)
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
        .background(Color.momentSecondaryGroupedBackground, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
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
        }
        .padding(14)
        .background(Color.momentSecondaryGroupedBackground, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .accessibilityElement(children: .combine)
    }
}

private enum MomentSettingsExternalLinks {
    static let terms = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!
    static let privacy = URL(string: "https://prosepal.app/privacy")!
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

private extension View {
    func prosePalMomentCard() -> some View {
        self
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.prosePalCard, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
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
    func momentControlBarSurface() -> some View {
        #if os(iOS) || os(macOS) || os(tvOS) || os(watchOS)
        if #available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, *) {
            self.background(.clear)
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

private extension Color {
    static var momentGroupedBackground: Color {
        #if canImport(UIKit)
        Color(uiColor: .systemGroupedBackground)
        #elseif canImport(AppKit)
        Color(nsColor: .windowBackgroundColor)
        #else
        Color.gray.opacity(0.08)
        #endif
    }

    static var momentSecondaryGroupedBackground: Color {
        #if canImport(UIKit)
        Color(uiColor: .secondarySystemGroupedBackground)
        #elseif canImport(AppKit)
        Color(nsColor: .controlBackgroundColor)
        #else
        Color.gray.opacity(0.12)
        #endif
    }

    static var prosePalPaper: Color {
        #if canImport(UIKit)
        Color(uiColor: .systemBackground)
        #elseif canImport(AppKit)
        Color(nsColor: .textBackgroundColor)
        #else
        Color.white
        #endif
    }

    static var prosePalCard: Color {
        #if canImport(UIKit)
        Color(uiColor: .secondarySystemGroupedBackground)
        #elseif canImport(AppKit)
        Color(nsColor: .controlBackgroundColor)
        #else
        Color.gray.opacity(0.12)
        #endif
    }
}
