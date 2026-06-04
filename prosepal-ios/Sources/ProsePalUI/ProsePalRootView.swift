import ProsePalAPI
import ProsePalDomain
import SwiftUI

#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

@MainActor
public final class ProsePalAppModel: ObservableObject {
    @Published var draft = MessageDraft()
    @Published var generatedMessages: [GeneratedMessage] = []
    @Published var savedMessages: [SavedMessage] = []
    @Published var notice: AppNotice?
    @Published var isShowingResults = false
    @Published var isShowingPaywall = false
    @Published var isGenerating = false
    @Published var errorMessage: String?
    @Published var fallbackStatus: FallbackStatus = .none
    @Published var laneUsed: GenerationLane?
    @Published var usageStatus: UsageStatus
    @Published var hasCompletedOnboarding: Bool
    @Published var selectedTab: AppTab = .compose

    public nonisolated static let defaultSavedMessagesKey = "prosepal.native.savedMessages.v1"
    public nonisolated static let defaultOnboardingCompletionKey = "prosepal.native.onboardingCompleted.v1"
    private let client: MessageWritingClient
    private let clientContext: ClientContext
    private let savedMessagesStore: UserDefaults
    private let savedMessagesKey: String
    private let onboardingStore: UserDefaults
    private let onboardingCompletionKey: String
    private let diagnostics: NativeDiagnosticsLogger

    public init(
        client: MessageWritingClient,
        clientContext: ClientContext,
        usageStatus: UsageStatus = UsageStatus(),
        savedMessagesStore: UserDefaults = .standard,
        savedMessagesKey: String = ProsePalAppModel.defaultSavedMessagesKey,
        onboardingStore: UserDefaults = .standard,
        onboardingCompletionKey: String = ProsePalAppModel.defaultOnboardingCompletionKey,
        diagnostics: NativeDiagnosticsLogger = .shared
    ) {
        self.client = client
        self.clientContext = clientContext
        self.usageStatus = usageStatus
        self.savedMessagesStore = savedMessagesStore
        self.savedMessagesKey = savedMessagesKey
        self.onboardingStore = onboardingStore
        self.onboardingCompletionKey = onboardingCompletionKey
        self.diagnostics = diagnostics
        self.savedMessages = Self.loadSavedMessages(from: savedMessagesStore, key: savedMessagesKey)
        self.hasCompletedOnboarding = onboardingStore.bool(forKey: onboardingCompletionKey)
        diagnostics.appStarted(
            hasCompletedOnboarding: self.hasCompletedOnboarding,
            savedMessageCount: self.savedMessages.count
        )
    }

    func generate() async {
        if isGenerating { return }
        guard prepareForGeneration() else { return }

        isGenerating = true
        errorMessage = nil
        let requestedLane = draft.requestedLane
        let startedAt = Date()

        let request = CardRequest(
            intent: draft.intent,
            requestedLane: requestedLane,
            clientContext: clientContext
        )
        diagnostics.generationStarted(requestID: request.idempotencyKey, draft: draft)

        do {
            let response = try await client.generateCard(request: request)
            generatedMessages = response.messages
            fallbackStatus = response.fallbackStatus
            laneUsed = response.laneUsed
            usageStatus.recordSuccessfulGeneration(requestedLane: requestedLane, laneUsed: response.laneUsed)
            diagnostics.generationSucceeded(
                requestID: request.idempotencyKey,
                laneUsed: response.laneUsed,
                fallbackStatus: response.fallbackStatus,
                messageCount: response.messages.count,
                totalMessageCharacters: response.messages.reduce(0) { $0 + $1.text.count },
                durationMs: startedAt.elapsedMilliseconds
            )
            isShowingResults = true
        } catch let error as GenerationError {
            diagnostics.generationFailed(
                requestID: request.idempotencyKey,
                category: error.diagnosticsCategory,
                durationMs: startedAt.elapsedMilliseconds
            )
            errorMessage = error.userSafeMessage
        } catch {
            diagnostics.generationFailed(
                requestID: request.idempotencyKey,
                category: "unexpected_error",
                durationMs: startedAt.elapsedMilliseconds
            )
            errorMessage = "Message generation failed. Please try again."
        }

        isGenerating = false
    }

    func selectLane(_ lane: GenerationLane) {
        if usageStatus.isPremiumLocked(lane) {
            diagnostics.paywallShown(
                trigger: "premium_lane_selected",
                requestedLane: lane,
                standardRemaining: usageStatus.standardRemaining
            )
            isShowingPaywall = true
            showNotice("Premium is locked", systemImage: "lock")
            return
        }

        draft.requestedLane = lane
        diagnostics.selectionChanged(kind: "generation_lane", value: lane.rawValue)
    }

    func useStandardLaneFromPaywall() {
        draft.requestedLane = .standard
        isShowingPaywall = false
        diagnostics.selectionChanged(kind: "generation_lane", value: GenerationLane.standard.rawValue)
        showNotice("Standard selected", systemImage: "checkmark.circle.fill")
    }

    func restorePurchasesPlaceholder() {
        diagnostics.messageAction("restore_purchases", source: "settings_or_paywall", messageCharacters: 0)
        showNotice("Nothing to restore yet", systemImage: "arrow.clockwise")
    }

    func completeOnboarding() {
        hasCompletedOnboarding = true
        onboardingStore.set(true, forKey: onboardingCompletionKey)
        diagnostics.onboardingCompleted()
    }

    private func prepareForGeneration() -> Bool {
        if usageStatus.isPremiumLocked(draft.requestedLane) {
            diagnostics.paywallShown(
                trigger: "premium_lane_generate",
                requestedLane: draft.requestedLane,
                standardRemaining: usageStatus.standardRemaining
            )
            isShowingPaywall = true
            return false
        }

        if usageStatus.isStandardLimitReached(for: draft.requestedLane) {
            errorMessage = "You've used your Standard drafts for today."
            diagnostics.paywallShown(
                trigger: "standard_limit_reached",
                requestedLane: draft.requestedLane,
                standardRemaining: usageStatus.standardRemaining
            )
            isShowingPaywall = true
            return false
        }

        return true
    }

    @discardableResult
    func save(_ message: GeneratedMessage) -> Bool {
        saveText(message.text)
    }

    @discardableResult
    func saveText(_ text: String) -> Bool {
        let trimmedText = text.trimmedForSaving
        guard !trimmedText.isEmpty else {
            showNotice("Nothing to save", systemImage: "exclamationmark.circle")
            return false
        }

        guard !savedMessages.contains(where: { $0.text == trimmedText }) else {
            showNotice("Already saved", systemImage: "bookmark.fill")
            return false
        }

        savedMessages.insert(
            SavedMessage(
                text: trimmedText,
                occasion: draft.occasion,
                relationship: draft.relationship,
                tone: draft.tone,
                length: draft.length,
                recipientName: draft.recipientName.nilIfBlank,
                savedAt: .now
            ),
            at: 0
        )
        persistSavedMessages()
        diagnostics.messageAction("save", source: "generated_or_editor", messageCharacters: trimmedText.count)
        showNotice("Saved", systemImage: "bookmark.fill")
        playSuccessFeedback()
        return true
    }

    @discardableResult
    func updateSaved(_ message: SavedMessage, text: String) -> Bool {
        let trimmedText = text.trimmedForSaving
        guard !trimmedText.isEmpty else {
            showNotice("Nothing to save", systemImage: "exclamationmark.circle")
            return false
        }

        guard let index = savedMessages.firstIndex(where: { $0.id == message.id }) else {
            showNotice("Message not found", systemImage: "exclamationmark.circle")
            return false
        }

        guard !savedMessages.contains(where: { $0.id != message.id && $0.text == trimmedText }) else {
            showNotice("Already saved", systemImage: "bookmark.fill")
            return false
        }

        savedMessages[index].text = trimmedText
        persistSavedMessages()
        diagnostics.messageAction("update_saved", source: "saved_editor", messageCharacters: trimmedText.count)
        showNotice("Updated", systemImage: "checkmark.circle.fill")
        playSuccessFeedback()
        return true
    }

    func deleteSaved(_ message: SavedMessage) {
        savedMessages.removeAll { $0.id == message.id }
        persistSavedMessages()
        diagnostics.messageAction("delete_saved", source: "saved_detail", messageCharacters: message.text.count)
        showNotice("Deleted", systemImage: "trash")
    }

    func deleteSaved(at offsets: IndexSet) {
        let deletedCharacterCount = offsets.reduce(0) { total, offset in
            total + savedMessages[offset].text.count
        }
        let ids = Set(offsets.map { savedMessages[$0].id })
        savedMessages.removeAll { ids.contains($0.id) }
        persistSavedMessages()
        diagnostics.messageAction("delete_saved", source: "saved_list", messageCharacters: deletedCharacterCount)
        showNotice("Deleted", systemImage: "trash")
    }

    func isSaved(_ message: GeneratedMessage) -> Bool {
        savedMessages.contains { $0.text == message.text.trimmedForSaving }
    }

    func copyText(_ text: String) {
        diagnostics.messageAction("copy", source: "message", messageCharacters: text.count)
        copyToPasteboard(text)
        showNotice("Copied", systemImage: "doc.on.doc")
        playSelectionFeedback()
    }

    func logTabSelected(_ tab: AppTab) {
        diagnostics.tabSelected(tab.rawValue)
    }

    func logComposeFieldFocused(_ field: ComposeField?) {
        diagnostics.composeFieldFocused(field?.rawValue)
    }

    func logOccasionPickerOpened() {
        diagnostics.pickerOpened("occasion")
    }

    func logSelectionChanged(kind: String, value: String) {
        diagnostics.selectionChanged(kind: kind, value: value)
    }

    func logPaywallOpened(trigger: String) {
        diagnostics.paywallShown(
            trigger: trigger,
            requestedLane: draft.requestedLane,
            standardRemaining: usageStatus.standardRemaining
        )
    }

    func logEditStarted(_ text: String, source: String) {
        diagnostics.messageAction("edit_started", source: source, messageCharacters: text.count)
    }

    func logShareText(_ text: String, source: String) {
        diagnostics.messageAction("share", source: source, messageCharacters: text.count)
    }

    func showNotice(_ title: String, systemImage: String) {
        let notice = AppNotice(title: title, systemImage: systemImage)
        self.notice = notice

        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 1_700_000_000)
            if self.notice?.id == notice.id {
                self.notice = nil
            }
        }
    }

    private static func loadSavedMessages(from store: UserDefaults, key: String) -> [SavedMessage] {
        guard let data = store.data(forKey: key) else {
            return []
        }

        do {
            return try JSONDecoder().decode([SavedMessage].self, from: data)
        } catch {
            return []
        }
    }

    private func persistSavedMessages() {
        guard let data = try? JSONEncoder().encode(savedMessages) else { return }
        savedMessagesStore.set(data, forKey: savedMessagesKey)
    }
}

public struct MessageDraft: Equatable, Sendable {
    public var occasion: Occasion = .birthday
    public var relationship: Relationship = .parent
    public var tone: Tone = .heartfelt
    public var length: MessageLength = .standard
    public var spellingPreference: SpellingPreference = .automatic
    public var requestedLane: GenerationLane = .standard
    public var recipientName = ""
    public var thingsToInclude = ""
    public var thingsToAvoid = ""
    public var personalContext = ""

    var intent: CardIntent {
        CardIntent(
            occasion: occasion,
            relationship: relationship,
            tone: tone,
            length: length,
            spellingPreference: spellingPreference,
            localeIdentifier: spellingPreference.localeIdentifier,
            recipientName: recipientName.nilIfBlank,
            thingsToInclude: thingsToInclude.commaSeparatedValues,
            thingsToAvoid: thingsToAvoid.commaSeparatedValues,
            userContext: personalContext.nilIfBlank
        )
    }
}

public struct SavedMessage: Codable, Identifiable, Equatable, Hashable, Sendable {
    public var id: UUID
    public var text: String
    public var occasion: Occasion
    public var relationship: Relationship
    public var tone: Tone
    public var length: MessageLength
    public var recipientName: String?
    public var savedAt: Date

    public init(
        id: UUID = UUID(),
        text: String,
        occasion: Occasion,
        relationship: Relationship,
        tone: Tone,
        length: MessageLength,
        recipientName: String? = nil,
        savedAt: Date = .now
    ) {
        self.id = id
        self.text = text
        self.occasion = occasion
        self.relationship = relationship
        self.tone = tone
        self.length = length
        self.recipientName = recipientName
        self.savedAt = savedAt
    }

    public var title: String {
        guard let recipientName = recipientName?.trimmedForSaving, !recipientName.isEmpty else {
            return occasion.displayName
        }
        return recipientName
    }

    public var subtitle: String {
        "\(occasion.displayName) / \(relationship.displayName) / \(tone.displayName)"
    }
}

public struct AppNotice: Identifiable, Equatable, Sendable {
    public var id: UUID
    public var title: String
    public var systemImage: String

    public init(id: UUID = UUID(), title: String, systemImage: String) {
        self.id = id
        self.title = title
        self.systemImage = systemImage
    }
}

public struct UsageStatus: Equatable, Sendable {
    public var standardLimit: Int
    public var standardRemaining: Int
    public var isPremiumUnlocked: Bool
    public var resetDescription: String

    public init(
        standardLimit: Int = 3,
        standardRemaining: Int = 2,
        isPremiumUnlocked: Bool = false,
        resetDescription: String = "today"
    ) {
        self.standardLimit = max(0, standardLimit)
        self.standardRemaining = max(0, min(standardRemaining, standardLimit))
        self.isPremiumUnlocked = isPremiumUnlocked
        self.resetDescription = resetDescription
    }

    public var usageText: String {
        if isPremiumUnlocked {
            return "Premium generation active"
        }

        return "\(standardRemaining) of \(standardLimit) Standard drafts left \(resetDescription)"
    }

    public var detailText: String {
        if isPremiumUnlocked {
            return "Enhanced drafts and higher limits are available."
        }

        if standardRemaining == 0 {
            return "Premium will unlock enhanced drafts and higher limits."
        }

        return "Premium unlocks enhanced drafts and higher limits."
    }

    public func isPremiumLocked(_ lane: GenerationLane) -> Bool {
        lane == .premium && !isPremiumUnlocked
    }

    public func isStandardLimitReached(for lane: GenerationLane) -> Bool {
        !isPremiumUnlocked && isStandardLike(lane) && standardRemaining <= 0
    }

    public mutating func recordSuccessfulGeneration(requestedLane: GenerationLane, laneUsed: GenerationLane) {
        guard !isPremiumUnlocked, isStandardLike(requestedLane) || isStandardLike(laneUsed) else {
            return
        }

        standardRemaining = max(0, standardRemaining - 1)
    }

    private func isStandardLike(_ lane: GenerationLane) -> Bool {
        switch lane {
        case .automatic, .standard:
            true
        case .premium, .local:
            false
        }
    }
}

enum AppTab: String, Hashable {
    case compose
    case saved
    case settings
}

public struct ProsePalRootView: View {
    @StateObject private var model: ProsePalAppModel

    public init(model: @autoclosure @escaping () -> ProsePalAppModel) {
        _model = StateObject(wrappedValue: model())
    }

    public var body: some View {
        Group {
            if model.hasCompletedOnboarding {
                AppTabsView()
            } else {
                OnboardingView(onStart: model.completeOnboarding)
            }
        }
        .tint(Color.prosePalCoral)
        .environmentObject(model)
        .sheet(isPresented: $model.isShowingPaywall) {
            PaywallPlaceholderSheet(
                usageStatus: model.usageStatus,
                onUseStandard: model.useStandardLaneFromPaywall,
                onRestore: model.restorePurchasesPlaceholder
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .overlay(alignment: .top) {
            if let notice = model.notice {
                NoticeBanner(notice: notice)
                    .padding(.top, 8)
                    .padding(.horizontal, 18)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .overlay {
            if model.isGenerating {
                WritingProgressOverlay()
                    .transition(.opacity)
            }
        }
        .animation(.spring(response: 0.34, dampingFraction: 0.86), value: model.notice?.id)
        .animation(.easeInOut(duration: 0.18), value: model.isGenerating)
    }
}

struct AppTabsView: View {
    @EnvironmentObject private var model: ProsePalAppModel

    var body: some View {
        TabView(selection: $model.selectedTab) {
            ComposeView()
                .tabItem { Label("Create", systemImage: "square.and.pencil") }
                .tag(AppTab.compose)

            SavedMessagesView()
                .tabItem { Label("Saved", systemImage: "bookmark") }
                .tag(AppTab.saved)

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape") }
                .tag(AppTab.settings)
        }
        .onChange(of: model.selectedTab) { _, tab in
            model.logTabSelected(tab)
        }
    }
}

struct OnboardingView: View {
    var onStart: () -> Void
    @State private var selectedStep = 0

    private let steps = OnboardingStep.all

    var body: some View {
        NavigationStack {
            onboardingPages
                .background(ProsePalBrandBackdrop())
                .navigationTitle("")
                .prosePalOnboardingToolbarStyle()
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Button("Skip", action: onStart)
                            .foregroundStyle(.white)
                    }
                }
                .safeAreaInset(edge: .bottom) {
                    VStack(spacing: 12) {
                        OnboardingPageDots(count: steps.count, selectedIndex: selectedStep)

                        Button {
                            if selectedStep == steps.count - 1 {
                                onStart()
                            } else {
                                withAnimation(.spring(response: 0.32, dampingFraction: 0.86)) {
                                    selectedStep += 1
                                }
                            }
                        } label: {
                            Label(selectedStep == steps.count - 1 ? "Start writing" : "Continue", systemImage: "arrow.right")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)

                        Text("No account required to try Standard drafts.")
                            .font(.caption)
                            .foregroundStyle(Color.prosePalTextSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, 22)
                    .padding(.top, 12)
                    .padding(.bottom, 10)
                    .background(.ultraThinMaterial)
                }
        }
        .preferredColorScheme(.dark)
    }

    @ViewBuilder
    private var onboardingPages: some View {
        #if os(iOS)
        onboardingPageContent
            .tabViewStyle(.page(indexDisplayMode: .never))
        #else
        onboardingPageContent
        #endif
    }

    private var onboardingPageContent: some View {
        TabView(selection: $selectedStep) {
            ForEach(Array(steps.enumerated()), id: \.element.id) { index, step in
                onboardingPage(step)
                    .tag(index)
            }
        }
    }

    private func onboardingPage(_ step: OnboardingStep) -> some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(spacing: 14) {
                    PackageResourceImage(name: step.imageName)
                        .scaledToFit()
                        .frame(maxWidth: 292, maxHeight: 360)
                        .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: 30, style: .continuous)
                                .strokeBorder(Color.white.opacity(0.20), lineWidth: 1)
                        }
                        .shadow(color: .black.opacity(0.22), radius: 26, x: 0, y: 14)
                }

                VStack(spacing: 10) {
                    Text(step.title)
                        .font(.largeTitle.weight(.bold))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .minimumScaleFactor(0.82)

                    Text(step.detail)
                        .font(.body)
                        .foregroundStyle(Color.prosePalTextSecondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(3)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 28)
            .padding(.top, 18)
            .padding(.bottom, 118)
        }
    }
}

private struct OnboardingPageDots: View {
    let count: Int
    let selectedIndex: Int

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<count, id: \.self) { index in
                Circle()
                    .fill(index == selectedIndex ? Color.white : Color.prosePalTextSecondary.opacity(0.48))
                    .frame(width: index == selectedIndex ? 8 : 7, height: index == selectedIndex ? 8 : 7)
            }
        }
        .accessibilityLabel("Onboarding step \(selectedIndex + 1) of \(count)")
    }
}

private struct OnboardingStep: Identifiable {
    let id: String
    let title: String
    let detail: String
    let imageName: String

    static let all: [OnboardingStep] = [
        OnboardingStep(
            id: "real-moments",
            title: "Find the right words",
            detail: "For cards, texts, notes, and the moments where a blank box feels bigger than it should.",
            imageName: "slide_1"
        ),
        OnboardingStep(
            id: "give-context",
            title: "Add the human details",
            detail: "Say who it is for, what the moment is, how close you are, and how it should feel.",
            imageName: "slide_2"
        ),
        OnboardingStep(
            id: "standard-premium",
            title: "Start simple",
            detail: "Standard helps with everyday messages. Premium is there for harder moments and higher limits.",
            imageName: "slide_3"
        )
    ]
}

struct ComposeView: View {
    @EnvironmentObject private var model: ProsePalAppModel
    @FocusState private var focusedField: ComposeField?
    @State private var isShowingOccasionPicker = false
    @State private var isShowingRelationshipPicker = false
    @State private var isShowingTonePicker = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    intentHeader
                    recipientFields
                    occasionSelector
                    relationshipSection
                    toneSection
                    detailFields
                    styleControls
                    generationControls
                }
                .padding(.horizontal, 20)
                .padding(.top, 18)
                .padding(.bottom, focusedField == nil ? 118 : 34)
            }
            .background(Color.prosePalGroupedBackground)
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("Create")
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Button {
                        focusedField = nil
                        Task { await model.generate() }
                    } label: {
                        Text(model.isGenerating ? "Writing" : "Write")
                            .fontWeight(.semibold)
                    }
                    .disabled(model.isGenerating)

                    Spacer(minLength: 16)

                    Button("Done") { focusedField = nil }
                }
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                if focusedField == nil {
                    generateButton
                }
            }
            .sheet(isPresented: $isShowingOccasionPicker) {
                OccasionPickerSheet(selection: $model.draft.occasion)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $isShowingRelationshipPicker) {
                RelationshipPickerSheet(selection: $model.draft.relationship)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $isShowingTonePicker) {
                TonePickerSheet(selection: $model.draft.tone)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
            .navigationDestination(isPresented: $model.isShowingResults) {
                ResultsView()
            }
            .onChange(of: focusedField) { _, field in
                model.logComposeFieldFocused(field)
            }
            .onChange(of: model.draft.occasion) { _, occasion in
                model.logSelectionChanged(kind: "occasion", value: occasion.rawValue)
            }
            .onChange(of: model.draft.relationship) { _, relationship in
                model.logSelectionChanged(kind: "relationship", value: relationship.rawValue)
            }
            .onChange(of: model.draft.tone) { _, tone in
                model.logSelectionChanged(kind: "tone", value: tone.rawValue)
            }
            .onChange(of: model.draft.length) { _, length in
                model.logSelectionChanged(kind: "length", value: length.rawValue)
            }
        }
    }

    private var intentHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Find the right words")
                .font(.system(.title, design: .rounded, weight: .bold))
                .foregroundStyle(.primary)
            Text("For a card, text, note, or the message you have not quite found yet.")
                .font(.callout)
                .foregroundStyle(.secondary)
            Text(summaryText)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Color.prosePalCoral)
                .padding(.top, 2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.linearGradient(
                    colors: [Color.prosePalCoral.opacity(0.18), Color.prosePalNavy.opacity(0.10), Color.prosePalSecondaryGroupedBackground],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(.white.opacity(0.72), lineWidth: 1)
        )
    }

    private var summaryText: String {
        let length = model.draft.length == .standard ? "" : "\(model.draft.length.displayName.lowercased()) "
        let base = "\(model.draft.tone.displayName) \(length)message"
        guard let recipient = model.draft.recipientName.nilIfBlank else {
            return base
        }
        return "\(base) for \(recipient)"
    }

    private var occasionSelector: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("What is the occasion?")
                    .font(.headline)
                Spacer()
                Button("Browse") {
                    model.logOccasionPickerOpened()
                    isShowingOccasionPicker = true
                }
                .font(.callout.weight(.semibold))
            }

            Button {
                model.logOccasionPickerOpened()
                isShowingOccasionPicker = true
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: model.draft.occasion.symbolName)
                        .font(.title2)
                        .frame(width: 34, height: 34)
                        .foregroundStyle(Color.prosePalCoral)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(model.draft.occasion.displayName)
                            .font(.headline)
                            .foregroundStyle(.primary)
                        Text(model.draft.occasion.group.displayName)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
                .padding(16)
                .background(Color.prosePalSecondaryGroupedBackground, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            }
            .buttonStyle(.plain)
        }
    }

    private var recipientFields: some View {
        ModernPanel {
            VStack(alignment: .leading, spacing: 8) {
                Text("Who is it for?")
                    .font(.headline)
                TextField("Name or person", text: $model.draft.recipientName, prompt: Text("Alex, Mum, my manager"))
                    .focused($focusedField, equals: ComposeField.recipient)
            }
        }
    }

    private var relationshipSection: some View {
        ModernPanel {
            SelectionSummaryButton(
                title: "Who are they to you?",
                value: model.draft.relationship.displayName,
                detail: model.draft.relationship.pickerDescription,
                systemImage: model.draft.relationship.symbolName
            ) {
                isShowingRelationshipPicker = true
            }
        }
    }

    private var toneSection: some View {
        ModernPanel {
            SelectionSummaryButton(
                title: "How should it feel?",
                value: model.draft.tone.displayName,
                detail: model.draft.tone.description,
                systemImage: model.draft.tone.symbolName
            ) {
                isShowingTonePicker = true
            }
        }
    }

    private var styleControls: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Length")
                .font(.headline)

            Picker("Length", selection: $model.draft.length) {
                ForEach(MessageLength.allCases) { length in
                    Text(length.displayName).tag(length)
                }
            }
            .pickerStyle(.segmented)

            GenerationModeSelector(
                selectedLane: model.draft.requestedLane,
                usageStatus: model.usageStatus,
                onSelect: model.selectLane
            )

            UsageStatusRow(usageStatus: model.usageStatus)
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private var detailFields: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Personal touches")
                .font(.headline)

            TextField("Anything to include?", text: $model.draft.thingsToInclude, prompt: Text("quiet cup of tea, old photos"))
                .focused($focusedField, equals: .include)

            Divider()

            TextField("Anything to avoid?", text: $model.draft.thingsToAvoid, prompt: Text("age jokes, formal wording"))
                .focused($focusedField, equals: .avoid)

            Divider()

            TextField("Extra context", text: $model.draft.personalContext, axis: .vertical)
                .lineLimit(3...6)
                .focused($focusedField, equals: .context)
        }
        .padding(16)
        .background(Color.prosePalSecondaryGroupedBackground, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private var generationControls: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let errorMessage = model.errorMessage {
                VStack(alignment: .leading, spacing: 10) {
                    Label(errorMessage, systemImage: "exclamationmark.triangle")
                        .font(.footnote)
                        .foregroundStyle(.red)

                    HStack {
                        Button {
                            Task { await model.generate() }
                        } label: {
                            Label("Try again", systemImage: "arrow.clockwise")
                        }
                        .disabled(model.isGenerating)

                        if model.usageStatus.isStandardLimitReached(for: model.draft.requestedLane) {
                            Button {
                                model.logPaywallOpened(trigger: "create_error_view_premium")
                                model.isShowingPaywall = true
                            } label: {
                                Label("View Premium", systemImage: "star")
                            }
                        }
                    }
                    .font(.footnote.weight(.semibold))
                }
                .padding(12)
                .background(Color.red.opacity(0.08), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
        }
    }

    private var generateButton: some View {
        Button {
            Task { await model.generate() }
        } label: {
            HStack {
                if model.isGenerating {
                    ProgressView()
                        .tint(.white)
                }
                Text(model.isGenerating ? "Writing" : "Write message")
                    .font(.headline)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .disabled(model.isGenerating)
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .padding(.bottom, 12)
        .background(Color.prosePalGroupedBackground)
        .overlay(alignment: .top) {
            Divider()
        }
    }
}

private struct SelectionSummaryButton: View {
    let title: String
    let value: String
    let detail: String
    let systemImage: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: systemImage)
                    .font(.headline)
                    .foregroundStyle(Color.prosePalCoral)
                    .frame(width: 28, height: 28)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Text(value)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.86)
                    Text(detail)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                Spacer(minLength: 8)

                Image(systemName: "chevron.up.chevron.down")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(title), \(value)")
    }
}

struct OccasionPickerSheet: View {
    @Binding var selection: Occasion
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""

    var body: some View {
        NavigationStack {
            List {
                if searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Section("Most Used") {
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
            .searchable(text: $searchText, prompt: "Search occasions")
            .navigationTitle("Occasion")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }

    private var displayedGroups: [OccasionGroup] {
        if searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return OccasionGroup.allCases.filter { $0 != .mostUsed }
        }

        return OccasionGroup.allCases
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
            dismiss()
        } label: {
            OccasionPickerRow(
                occasion: occasion,
                isSelected: occasion == selection
            )
        }
        .buttonStyle(.plain)
    }
}

struct OccasionPickerRow: View {
    let occasion: Occasion
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: occasion.symbolName)
                .font(.headline)
                .frame(width: 28, height: 28)
                .foregroundStyle(Color.prosePalCoral)

            VStack(alignment: .leading, spacing: 3) {
                Text(occasion.displayName)
                    .font(.body.weight(.medium))
                    .foregroundStyle(.primary)
                Text(occasion.pickerDescription)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer()

            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(Color.prosePalCoral)
            }
        }
        .contentShape(Rectangle())
        .padding(.vertical, 4)
    }
}

private extension Occasion {
    var pickerDescription: String {
        switch self {
        case .birthday: "Birthday wishes for their day."
        case .thankYou: "A thoughtful note of thanks."
        case .sympathy: "Warm support and condolences."
        case .wedding: "Wishes for a couple's big day."
        case .christmas: "Warm festive wishes."
        case .getWell: "Encouragement while they recover."
        case .congrats: "Celebrate a win or achievement."
        case .mothersDay: "Appreciation for Mother's Day."
        case .fathersDay: "Appreciation for Father's Day."
        case .baby: "Welcome a new baby."
        case .graduation: "Celebrate graduation."
        case .anniversary: "Mark a special anniversary."
        case .valentinesDay: "A romantic or affectionate note."
        case .thinkingOfYou: "Let someone know you care."
        case .newYear: "Good wishes for the year ahead."
        case .engagement: "Celebrate an engagement."
        case .kidsBirthday: "A fun birthday note for a child."
        case .justBecause: "A warm note for no special reason."
        case .housewarming: "Congratulate someone on a new home."
        case .retirement: "Celebrate a new chapter."
        case .newJob: "Wish them well in a new role."
        case .encouragement: "Support them through a challenge."
        case .easter: "Spring and Easter wishes."
        case .thanksgiving: "Gratitude and holiday warmth."
        case .halloween: "A playful Halloween greeting."
        case .apology: "Say sorry with care."
        case .farewell: "A goodbye or leaving message."
        case .goodLuck: "Wish them luck for what's next."
        case .promotion: "Celebrate a promotion."
        case .thankYouTeacher: "Thank a teacher."
        case .thankYouHealthcare: "Thank someone for care."
        case .thankYouService: "Thank someone for service."
        case .hanukkah: "Warm Hanukkah wishes."
        case .diwali: "Bright Diwali wishes."
        case .eid: "Warm Eid wishes."
        case .lunarNewYear: "Lunar New Year wishes."
        case .kwanzaa: "Warm Kwanzaa wishes."
        case .petBirthday: "Celebrate a beloved pet."
        case .newPet: "Welcome a new pet."
        case .petSympathy: "Comfort after pet loss."
        }
    }
}

struct RelationshipPickerSheet: View {
    @Binding var selection: Relationship
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""

    var body: some View {
        NavigationStack {
            List {
                if !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                   !hasSearchResults {
                    ContentUnavailableView.search(text: searchText)
                }

                ForEach(RelationshipGroup.allCases) { group in
                    let relationships = filteredRelationships(in: group)
                    if !relationships.isEmpty {
                        Section(group.displayName) {
                            ForEach(relationships) { relationship in
                                Button {
                                    selection = relationship
                                    playSelectionFeedback()
                                    dismiss()
                                } label: {
                                    RelationshipPickerRow(
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
            .navigationTitle("Relationship")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }

    private var hasSearchResults: Bool {
        RelationshipGroup.allCases.contains { !filteredRelationships(in: $0).isEmpty }
    }

    private func filteredRelationships(in group: RelationshipGroup) -> [Relationship] {
        let groupRelationships = Relationship.allCases.filter { $0.group == group }
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return groupRelationships }

        return groupRelationships.filter {
            $0.searchText.localizedCaseInsensitiveContains(query)
        }
    }
}

private extension Relationship {
    var searchText: String {
        "\(displayName) \(pickerDescription) \(generationHint)"
    }
}

private struct RelationshipPickerRow: View {
    let relationship: Relationship
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: relationship.symbolName)
                .font(.headline)
                .frame(width: 28, height: 28)
                .foregroundStyle(Color.prosePalCoral)

            VStack(alignment: .leading, spacing: 3) {
                Text(relationship.displayName)
                    .font(.body.weight(.medium))
                    .foregroundStyle(.primary)
                Text(relationship.pickerDescription)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer(minLength: 8)

            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(Color.prosePalCoral)
            }
        }
        .contentShape(Rectangle())
        .padding(.vertical, 4)
    }
}

private extension Relationship {
    var pickerDescription: String {
        switch self {
        case .closeFriend: "Close, familiar, and easygoing."
        case .family: "Warm and familiar."
        case .parent: "Loving, grateful, and respectful."
        case .child: "Proud, encouraging, and affectionate."
        case .sibling: "Familiar, loyal, and lightly teasing when it fits."
        case .grandparent: "Respectful, warm, and appreciative."
        case .grandchild: "Affectionate, proud, and encouraging."
        case .romantic: "Loving, personal, and intimate."
        case .colleague: "Friendly and work-appropriate."
        case .boss: "Respectful and professional."
        case .mentor: "Grateful and appreciative."
        case .teacher: "Thankful, respectful, and specific."
        case .neighbor: "Friendly and neighbourly."
        case .acquaintance: "Polite and not too familiar."
        }
    }
}

struct TonePickerSheet: View {
    @Binding var selection: Tone
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""

    var body: some View {
        NavigationStack {
            List {
                if !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                   filteredTones.isEmpty {
                    ContentUnavailableView.search(text: searchText)
                }

                Section("Tone") {
                    ForEach(filteredTones) { tone in
                        Button {
                            selection = tone
                            playSelectionFeedback()
                            dismiss()
                        } label: {
                            TonePickerRow(tone: tone, isSelected: tone == selection)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search tones")
            .navigationTitle("Tone")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }

    private var filteredTones: [Tone] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return Tone.allCases }

        return Tone.allCases.filter {
            $0.searchText.localizedCaseInsensitiveContains(query)
        }
    }
}

private extension Tone {
    var searchText: String {
        "\(displayName) \(description) \(generationHint)"
    }
}

private struct TonePickerRow: View {
    let tone: Tone
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: tone.symbolName)
                .font(.headline)
                .frame(width: 28, height: 28)
                .foregroundStyle(Color.prosePalCoral)

            VStack(alignment: .leading, spacing: 3) {
                Text(tone.displayName)
                    .font(.body.weight(.medium))
                    .foregroundStyle(.primary)
                Text(tone.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer(minLength: 8)

            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(Color.prosePalCoral)
            }
        }
        .contentShape(Rectangle())
        .padding(.vertical, 4)
    }
}
struct GenerationModeSelector: View {
    let selectedLane: GenerationLane
    let usageStatus: UsageStatus
    let onSelect: (GenerationLane) -> Void

    private let lanes: [GenerationLane] = [.standard, .premium]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Generation")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text(usageStatus.isPremiumUnlocked ? "Premium is active. Standard remains available." : "Standard is included. Premium is locked until you upgrade.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(lanes, id: \.rawValue) { lane in
                        GenerationLaneButton(
                            lane: lane,
                            symbolName: symbolName(for: lane),
                            subtitle: subtitle(for: lane),
                            isSelected: lane == selectedLane,
                            isLocked: usageStatus.isPremiumLocked(lane)
                        ) {
                            onSelect(lane)
                        }
                    }
                }
                .padding(.vertical, 2)
            }
            .scrollBounceBehavior(.basedOnSize, axes: .horizontal)
        }
    }

    private func symbolName(for lane: GenerationLane) -> String {
        switch lane {
        case .automatic: "wand.and.stars"
        case .standard: "sparkles"
        case .premium: "star.fill"
        case .local: "iphone"
        }
    }

    private func subtitle(for lane: GenerationLane) -> String {
        switch lane {
        case .automatic: "Best fit"
        case .standard: "Included"
        case .premium:
            usageStatus.isPremiumUnlocked ? "Active" : "Locked"
        case .local: "On device"
        }
    }
}

private struct GenerationLaneButton: View {
    let lane: GenerationLane
    let symbolName: String
    let subtitle: String
    let isSelected: Bool
    let isLocked: Bool
    var onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 6) {
                Image(systemName: symbolName)
                    .font(.headline)
                Text(lane.displayName)
                    .font(.caption.weight(.semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.86)
                Text(subtitle)
                    .font(.caption2)
                    .foregroundStyle(isSelected ? .white.opacity(0.82) : .secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
            }
            .frame(width: 116)
            .frame(minHeight: 68)
            .padding(.horizontal, 6)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(isSelected ? Color.prosePalCoral : Color.prosePalSecondaryGroupedBackground)
            )
            .foregroundStyle(isSelected ? .white : .primary)
            .overlay(alignment: .topTrailing) {
                if isLocked {
                    Image(systemName: "lock.fill")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(isSelected ? .white : .secondary)
                        .padding(8)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(lane.displayName), \(subtitle)")
    }
}

struct UsageStatusRow: View {
    let usageStatus: UsageStatus

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: usageStatus.isPremiumUnlocked ? "checkmark.seal.fill" : "gauge")
                .font(.callout.weight(.semibold))
                .foregroundStyle(Color.prosePalCoral)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 3) {
                Text(usageStatus.usageText)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.primary)
                Text(usageStatus.detailText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)
        }
        .padding(12)
        .background(Color.prosePalSecondaryGroupedBackground, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .accessibilityElement(children: .combine)
    }
}

struct ResultsView: View {
    @EnvironmentObject private var model: ProsePalAppModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Group {
            if model.generatedMessages.isEmpty {
                EmptyStateView(
                    title: "No Messages",
                    systemImage: "text.page",
                    detail: "Write a message to see options here."
                )
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Pick one to copy, edit, save, or share.")
                                .font(.callout)
                                .foregroundStyle(.secondary)
                            Text(resultContextText)
                                .font(.caption.weight(.medium))
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        generationStatus

                        ForEach(Array(model.generatedMessages.enumerated()), id: \.element.id) { index, message in
                            ResultCard(message: message, draftNumber: index + 1)
                        }

                        Button {
                            dismiss()
                        } label: {
                            Label("Start over", systemImage: "arrow.uturn.backward")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.large)
                        .padding(.top, 4)
                    }
                    .padding(20)
                }
                .background(Color.prosePalGroupedBackground)
            }
        }
        .navigationTitle(resultsTitle)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    Task { await model.generate() }
                } label: {
                    Label("Regenerate", systemImage: "arrow.clockwise")
                }
                .disabled(model.isGenerating)
            }
        }
    }

    @ViewBuilder
    private var generationStatus: some View {
        if model.fallbackStatus != .none {
            VStack(alignment: .leading, spacing: 10) {
                Label("Generation used a backup route. You can retry shortly.", systemImage: "wand.and.stars.inverse")
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Button {
                    Task { await model.generate() }
                } label: {
                    Label("Retry generation", systemImage: "arrow.clockwise")
                }
                .font(.footnote.weight(.semibold))
                .disabled(model.isGenerating)
            }
            .padding(12)
            .background(Color.prosePalProGold.opacity(0.14), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        } else if let lane = model.laneUsed {
            Label("\(lane.displayName) generation", systemImage: "checkmark.seal")
                .font(.footnote.weight(.medium))
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var resultsTitle: String {
        guard let recipient = model.draft.recipientName.nilIfBlank else {
            return "Your messages"
        }
        return "Messages for \(recipient)"
    }

    private var resultContextText: String {
        "\(model.draft.occasion.displayName) / \(model.draft.relationship.displayName) / \(model.draft.tone.displayName) / \(model.draft.length.displayName)"
    }
}

struct ResultCard: View {
    @EnvironmentObject private var model: ProsePalAppModel
    let message: GeneratedMessage
    let draftNumber: Int
    @State private var editedText = ""
    @State private var isEditing = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label("Option \(draftNumber)", systemImage: "text.page")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                if model.isSaved(message) {
                    Label("Saved", systemImage: "bookmark.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.prosePalCoral)
                }
            }

            Text(message.text)
                .font(.body)
                .lineSpacing(4)
                .textSelection(.enabled)

            resultActions
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
        .padding(18)
        .background(Color.prosePalSecondaryGroupedBackground, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .contextMenu {
            Button {
                model.copyText(message.text)
            } label: {
                Label("Copy", systemImage: "doc.on.doc")
            }

                    Button {
                        model.logEditStarted(message.text, source: "result_context_menu")
                        editedText = message.text
                        isEditing = true
                    } label: {
                Label("Edit", systemImage: "square.and.pencil")
            }

            Button {
                model.save(message)
            } label: {
                Label("Save", systemImage: "bookmark")
            }
            .disabled(model.isSaved(message))
        }
        .sheet(isPresented: $isEditing) {
            DraftEditorSheet(
                title: "Edit Option \(draftNumber)",
                text: $editedText,
                onCopy: { model.copyText(editedText) },
                onShare: { model.logShareText(editedText, source: "result_editor") },
                onSave: {
                    if model.saveText(editedText) {
                        isEditing = false
                    }
                }
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .onAppear {
            editedText = message.text
        }
    }

    @ViewBuilder
    private var resultActions: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 10) {
                copyButton
                shareLink
                editButton
                Spacer(minLength: 0)
                saveButton
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 10) {
                    copyButton
                    shareLink
                    editButton
                }
                saveButton
            }
        }
    }

    private var copyButton: some View {
        Button {
            model.copyText(message.text)
        } label: {
            Label("Copy", systemImage: "doc.on.doc")
        }
    }

    private var shareLink: some View {
        ShareLink(item: message.text) {
            Label("Share", systemImage: "square.and.arrow.up")
        }
        .simultaneousGesture(TapGesture().onEnded {
            model.logShareText(message.text, source: "result_card")
        })
    }

    private var editButton: some View {
        Button {
            model.logEditStarted(message.text, source: "result_card")
            editedText = message.text
            isEditing = true
        } label: {
            Label("Edit", systemImage: "square.and.pencil")
        }
    }

    private var saveButton: some View {
        Button {
            model.save(message)
        } label: {
            Label(model.isSaved(message) ? "Saved" : "Save", systemImage: model.isSaved(message) ? "bookmark.fill" : "bookmark")
        }
        .disabled(model.isSaved(message))
    }
}

struct DraftEditorSheet: View {
    var title: String
    @Binding var text: String
    var onCopy: () -> Void
    var onShare: () -> Void = {}
    var onSave: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                TextEditor(text: $text)
                    .font(.body)
                    .lineSpacing(4)
                    .padding(12)
                    .frame(minHeight: 220)
                    .background(Color.prosePalSecondaryGroupedBackground, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
            .padding(20)
            .padding(.bottom, 68)
            .background(Color.prosePalGroupedBackground)
            .navigationTitle(title)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                editorActions
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    .padding(.bottom, 12)
                    .background(.bar)
                    .overlay(alignment: .top) {
                        Divider()
                    }
            }
        }
    }

    private var editorActions: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 10) {
                Button {
                    onCopy()
                } label: {
                    Label("Copy", systemImage: "doc.on.doc")
                }

                ShareLink(item: text) {
                    Label("Share", systemImage: "square.and.arrow.up")
                }
                .simultaneousGesture(TapGesture().onEnded(onShare))

                Spacer(minLength: 8)

                Button {
                    onSave()
                } label: {
                    Label("Save", systemImage: "bookmark")
                }
                .buttonStyle(.borderedProminent)
            }
            .buttonStyle(.bordered)

            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 10) {
                    Button {
                        onCopy()
                    } label: {
                        Label("Copy", systemImage: "doc.on.doc")
                    }

                    ShareLink(item: text) {
                        Label("Share", systemImage: "square.and.arrow.up")
                    }
                    .simultaneousGesture(TapGesture().onEnded(onShare))
                }

                Button {
                    onSave()
                } label: {
                    Label("Save", systemImage: "bookmark")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            }
            .buttonStyle(.bordered)
        }
    }
}

struct PaywallPlaceholderSheet: View {
    let usageStatus: UsageStatus
    let onUseStandard: () -> Void
    let onRestore: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    VStack(alignment: .leading, spacing: 10) {
                        Image(systemName: "star.circle.fill")
                            .font(.system(size: 50, weight: .semibold))
                            .foregroundStyle(Color.prosePalCoral)

                        Text("Premium generation")
                            .font(.largeTitle.weight(.bold))
                            .minimumScaleFactor(0.75)

                        Text("Better drafts for harder moments, higher limits, and priority generation when available.")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }

                    VStack(spacing: 12) {
                        PremiumFeatureRow(systemImage: "heart.text.square", title: "Enhanced drafts", detail: "More help for nuanced or sensitive messages.")
                        PremiumFeatureRow(systemImage: "gauge", title: "Higher limits", detail: "More writing room for Standard and Premium drafts.")
                        PremiumFeatureRow(systemImage: "arrow.clockwise.circle", title: "Regenerate more", detail: "Try another angle without losing your draft.")
                    }

                    UsageStatusRow(usageStatus: usageStatus)

                    VStack(spacing: 10) {
                        Button {
                            onUseStandard()
                            dismiss()
                        } label: {
                            Label("Use Standard", systemImage: "sparkles")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)

                        Button {
                            onRestore()
                        } label: {
                            Label("Restore purchases", systemImage: "arrow.clockwise")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.large)

                        Button("Not now") {
                            dismiss()
                        }
                        .font(.callout.weight(.semibold))
                    }
                }
                .padding(22)
            }
            .background(Color.prosePalGroupedBackground)
            .navigationTitle("Premium")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}

struct PremiumFeatureRow: View {
    let systemImage: String
    let title: String
    let detail: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: systemImage)
                .font(.headline)
                .foregroundStyle(Color.prosePalCoral)
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
        .background(Color.prosePalSecondaryGroupedBackground, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

struct SavedMessagesView: View {
    @EnvironmentObject private var model: ProsePalAppModel
    @State private var searchText = ""

    private var filteredSavedMessages: [SavedMessage] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return model.savedMessages }

        return model.savedMessages.filter { saved in
            saved.title.localizedCaseInsensitiveContains(query) ||
            saved.subtitle.localizedCaseInsensitiveContains(query) ||
            saved.text.localizedCaseInsensitiveContains(query)
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if model.savedMessages.isEmpty {
                    EmptyStateView(
                        title: "No Saved Messages",
                        systemImage: "bookmark",
                        detail: "Saved drafts appear here."
                    )
                } else {
                    List {
                        if filteredSavedMessages.isEmpty {
                            ContentUnavailableView.search(text: searchText)
                        } else {
                            ForEach(filteredSavedMessages) { saved in
                                NavigationLink {
                                    SavedMessageDetailView(saved: saved)
                                } label: {
                                    SavedMessageRow(saved: saved)
                                }
                            }
                            .onDelete { offsets in
                                offsets
                                    .map { filteredSavedMessages[$0] }
                                    .forEach(model.deleteSaved)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Saved")
            .searchable(text: $searchText, prompt: "Search saved messages")
        }
    }
}

struct SavedMessageRow: View {
    let saved: SavedMessage

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack {
                Label(saved.title, systemImage: saved.occasion.symbolName)
                    .font(.headline)
                    .lineLimit(1)
                Spacer()
                Text(saved.savedAt.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Text(saved.text)
                .font(.callout)
                .foregroundStyle(.secondary)
                .lineLimit(2)

            Text(saved.subtitle)
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .padding(.vertical, 6)
    }
}

struct SavedMessageDetailView: View {
    @EnvironmentObject private var model: ProsePalAppModel
    @Environment(\.dismiss) private var dismiss
    let saved: SavedMessage
    @State private var editedText: String
    @State private var isEditing = false
    @State private var isConfirmingDelete = false

    init(saved: SavedMessage) {
        self.saved = saved
        _editedText = State(initialValue: saved.text)
    }

    private var currentSaved: SavedMessage {
        model.savedMessages.first { $0.id == saved.id } ?? saved
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 12) {
                    Label(currentSaved.occasion.displayName, systemImage: currentSaved.occasion.symbolName)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)

                    Text(currentSaved.text)
                        .font(.body)
                        .lineSpacing(5)
                        .textSelection(.enabled)
                }
                .padding(18)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.prosePalSecondaryGroupedBackground, in: RoundedRectangle(cornerRadius: 22, style: .continuous))

                ModernPanel {
                    LabeledContent("Recipient", value: currentSaved.recipientName ?? "Not specified")
                    LabeledContent("Occasion", value: currentSaved.occasion.displayName)
                    LabeledContent("Relationship", value: currentSaved.relationship.displayName)
                    LabeledContent("Tone", value: currentSaved.tone.displayName)
                    LabeledContent("Length", value: currentSaved.length.displayName)
                    LabeledContent("Saved", value: currentSaved.savedAt.formatted(date: .abbreviated, time: .shortened))
                }

                HStack(spacing: 10) {
                    Button {
                        model.copyText(currentSaved.text)
                    } label: {
                        Label("Copy", systemImage: "doc.on.doc")
                    }

                    ShareLink(item: currentSaved.text) {
                        Label("Share", systemImage: "square.and.arrow.up")
                    }
                    .simultaneousGesture(TapGesture().onEnded {
                        model.logShareText(currentSaved.text, source: "saved_detail")
                    })

                    Button {
                        model.logEditStarted(currentSaved.text, source: "saved_detail")
                        editedText = currentSaved.text
                        isEditing = true
                    } label: {
                        Label("Edit", systemImage: "square.and.pencil")
                    }
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
            }
            .padding(20)
        }
        .background(Color.prosePalGroupedBackground)
        .navigationTitle(currentSaved.title)
        .toolbar {
            ToolbarItem(placement: .destructiveAction) {
                Button(role: .destructive) {
                    isConfirmingDelete = true
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
        }
        .confirmationDialog("Delete saved message?", isPresented: $isConfirmingDelete, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                model.deleteSaved(currentSaved)
                dismiss()
            }
        }
        .sheet(isPresented: $isEditing) {
            DraftEditorSheet(
                title: "Edit Saved Message",
                text: $editedText,
                onCopy: { model.copyText(editedText) },
                onShare: { model.logShareText(editedText, source: "saved_editor") },
                onSave: {
                    if model.updateSaved(currentSaved, text: editedText) {
                        isEditing = false
                    }
                }
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
    }
}

struct SettingsView: View {
    @EnvironmentObject private var model: ProsePalAppModel

    var body: some View {
        NavigationStack {
            List {
                Section("Account") {
                    Button {
                        model.showNotice("Sign in is unavailable in this preview", systemImage: "apple.logo")
                    } label: {
                        Label("Sign in with Apple", systemImage: "apple.logo")
                    }

                    Button {
                        model.logPaywallOpened(trigger: "settings_subscription")
                        model.isShowingPaywall = true
                    } label: {
                        Label("Subscription", systemImage: "star")
                    }

                    Button {
                        model.restorePurchasesPlaceholder()
                    } label: {
                        Label("Restore purchases", systemImage: "arrow.clockwise")
                    }
                }

                Section("Writing") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Spelling")
                            .font(.headline)

                        Picker("Spelling", selection: $model.draft.spellingPreference) {
                            ForEach(SpellingPreference.allCases) { preference in
                                Text(preference.displayName).tag(preference)
                            }
                        }
                        .pickerStyle(.segmented)

                        Text(model.draft.spellingPreference.exampleText)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Picker("Default tone", selection: $model.draft.tone) {
                        ForEach(Tone.allCases) { tone in
                            Text(tone.displayName).tag(tone)
                        }
                    }
                }

                Section("Generation") {
                    ForEach([GenerationLane.standard, .premium], id: \.rawValue) { lane in
                        Button {
                            model.selectLane(lane)
                        } label: {
                            HStack {
                                Label(lane.displayName, systemImage: lane == .premium ? "star" : "sparkles")
                                Spacer()
                                if model.draft.requestedLane == lane {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(Color.prosePalCoral)
                                } else if model.usageStatus.isPremiumLocked(lane) {
                                    Image(systemName: "lock.fill")
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }

                    UsageStatusRow(usageStatus: model.usageStatus)
                }

                Section("Privacy") {
                    Button {
                        model.showNotice("Export is unavailable in this preview", systemImage: "square.and.arrow.up")
                    } label: {
                        Label("Export data", systemImage: "square.and.arrow.up")
                    }

                    Button(role: .destructive) {
                        model.showNotice("Account deletion requires sign-in", systemImage: "trash")
                    } label: {
                        Label("Delete account", systemImage: "trash")
                    }
                }

                Section("Support") {
                    Button {
                        model.showNotice("Feedback is unavailable in this preview", systemImage: "envelope")
                    } label: {
                        Label("Send feedback", systemImage: "envelope")
                    }

                    Label("Terms", systemImage: "doc.text")
                    Label("Privacy Policy", systemImage: "hand.raised")
                }

                Section("About") {
                    LabeledContent("Writing", value: "Online generation")
                    LabeledContent("Version", value: "Native preview")
                }
            }
            .navigationTitle("Settings")
            .onChange(of: model.draft.spellingPreference) { _, preference in
                model.logSelectionChanged(kind: "spelling", value: preference.rawValue)
            }
            .onChange(of: model.draft.tone) { _, tone in
                model.logSelectionChanged(kind: "tone", value: tone.rawValue)
            }
        }
    }
}

struct ModernPanel<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        VStack(spacing: 12) {
            content
        }
        .padding(16)
        .background(Color.prosePalSecondaryGroupedBackground, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}

struct NoticeBanner: View {
    let notice: AppNotice

    var body: some View {
        Label(notice.title, systemImage: notice.systemImage)
            .font(.callout.weight(.semibold))
            .foregroundStyle(.primary)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(.regularMaterial, in: Capsule(style: .continuous))
            .shadow(color: .black.opacity(0.12), radius: 18, x: 0, y: 8)
    }
}

private struct WritingProgressOverlay: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var messageIndex = 0

    private let messages = [
        "Finding the right words...",
        "Shaping the tone...",
        "Adding the details...",
        "Almost ready..."
    ]

    var body: some View {
        ZStack {
            ProsePalBrandBackdrop()

            VStack(spacing: 22) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.14))
                        .frame(width: 96, height: 96)
                    Circle()
                        .strokeBorder(Color.white.opacity(0.22), lineWidth: 1)
                        .frame(width: 96, height: 96)
                    Image(systemName: "sparkles")
                        .font(.system(size: 34, weight: .semibold))
                        .foregroundStyle(.white)
                        .scaleEffect(reduceMotion ? 1 : (messageIndex.isMultiple(of: 2) ? 1 : 1.05))
                        .animation(.easeInOut(duration: 0.22), value: messageIndex)
                }

                VStack(spacing: 8) {
                    Text("Writing")
                        .font(.title.weight(.bold))
                        .foregroundStyle(.white)
                    Text(messages[messageIndex])
                        .font(.callout)
                        .foregroundStyle(Color.prosePalTextSecondary)
                        .contentTransition(.opacity)
                }

                ProgressView()
                    .tint(.white)
                    .controlSize(.large)
            }
            .padding(28)
        }
        .ignoresSafeArea()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Writing message. Please wait.")
        .task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 1_900_000_000)
                guard !Task.isCancelled else { return }
                withAnimation(.easeInOut(duration: reduceMotion ? 0 : 0.22)) {
                    messageIndex = (messageIndex + 1) % messages.count
                }
            }
        }
    }
}

private struct ProsePalBrandBackdrop: View {
    var body: some View {
        LinearGradient(
            colors: [
                Color.prosePalDeepNavy,
                Color.prosePalNavy,
                Color.prosePalSurface
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .overlay {
            LinearGradient(
                colors: [
                    Color.prosePalCoral.opacity(0.16),
                    Color.clear,
                    Color.prosePalNavy.opacity(0.26)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
        .ignoresSafeArea()
    }
}

private struct PackageResourceImage: View {
    let name: String
    var fileExtension = "png"
    var subdirectory: String?

    var body: some View {
        content
            .accessibilityHidden(true)
    }

    @ViewBuilder
    private var content: some View {
        #if os(iOS)
        if let url = Bundle.module.url(forResource: name, withExtension: fileExtension, subdirectory: subdirectory),
           let image = UIImage(contentsOfFile: url.path) {
            Image(uiImage: image)
                .resizable()
        } else {
            fallback
        }
        #elseif os(macOS)
        if let url = Bundle.module.url(forResource: name, withExtension: fileExtension, subdirectory: subdirectory),
           let image = NSImage(contentsOf: url) {
            Image(nsImage: image)
                .resizable()
        } else {
            fallback
        }
        #else
        fallback
        #endif
    }

    private var fallback: some View {
        Image(systemName: "photo")
            .resizable()
            .scaledToFit()
            .foregroundStyle(Color.prosePalTextSecondary)
    }
}

private extension View {
    @ViewBuilder
    func prosePalOnboardingToolbarStyle() -> some View {
        #if os(iOS)
        self.toolbarColorScheme(.dark, for: .navigationBar)
        #else
        self
        #endif
    }
}

enum ComposeField: String, Hashable {
    case recipient
    case include
    case avoid
    case context
}

private extension String {
    var nilIfBlank: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    var commaSeparatedValues: [String] {
        split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    var trimmedForSaving: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

private func copyToPasteboard(_ text: String) {
    #if os(iOS)
    UIPasteboard.general.string = text
    #endif
}

private extension Date {
    var elapsedMilliseconds: Int {
        max(0, Int(Date().timeIntervalSince(self) * 1000))
    }
}

private extension GenerationError {
    var diagnosticsCategory: String {
        switch self {
        case .offline:
            "offline"
        case .timedOut:
            "timeout"
        case .rateLimited:
            "rate_limited"
        case .usageLimitReached:
            "usage_limit"
        case .contentBlocked:
            "content_blocked"
        case .serviceUnavailable:
            "service_unavailable"
        case .unexpectedResponse:
            "unexpected_response"
        }
    }
}

private func playSuccessFeedback() {
    #if os(iOS)
    UINotificationFeedbackGenerator().notificationOccurred(.success)
    #endif
}

private func playSelectionFeedback() {
    #if os(iOS)
    UISelectionFeedbackGenerator().selectionChanged()
    #endif
}

private extension Color {
    static var prosePalDeepNavy: Color {
        prosePalHex(0x151C26)
    }

    static var prosePalNavy: Color {
        prosePalHex(0x1D2633)
    }

    static var prosePalSurface: Color {
        prosePalHex(0x222E3D)
    }

    static var prosePalSurfaceElevated: Color {
        prosePalHex(0x283648)
    }

    static var prosePalCoral: Color {
        prosePalHex(0xD4736B)
    }

    static var prosePalCoralLight: Color {
        prosePalHex(0xFCE9E7)
    }

    static var prosePalCoralDark: Color {
        prosePalHex(0xA5564F)
    }

    static var prosePalProGold: Color {
        prosePalHex(0xFBBF24)
    }

    static var prosePalTextSecondary: Color {
        prosePalHex(0xB1BBC8)
    }

    static var prosePalGroupedBackground: Color {
        #if os(iOS)
        Color(uiColor: .systemGroupedBackground)
        #else
        Color.gray.opacity(0.08)
        #endif
    }

    static var prosePalSecondaryGroupedBackground: Color {
        #if os(iOS)
        Color(uiColor: .secondarySystemGroupedBackground)
        #else
        Color.white.opacity(0.72)
        #endif
    }

    private static func prosePalHex(_ value: Int, opacity: Double = 1) -> Color {
        Color(
            red: Double((value >> 16) & 0xFF) / 255,
            green: Double((value >> 8) & 0xFF) / 255,
            blue: Double(value & 0xFF) / 255,
            opacity: opacity
        )
    }
}

struct EmptyStateView: View {
    var title: String
    var systemImage: String
    var detail: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: 44, weight: .semibold))
                .foregroundStyle(.secondary)
            Text(title)
                .font(.title3.weight(.semibold))
            Text(detail)
                .font(.callout)
                .foregroundStyle(.secondary)
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(32)
    }
}

#Preview {
    ProsePalRootView(
        model: ProsePalAppModel(
            client: MockMessageWritingClient(
                response: CardResponse(
                    messages: [
                        GeneratedMessage(text: "A preview draft from ProsePal.")
                    ],
                    laneUsed: .standard
                )
            ),
            clientContext: ClientContext(appVersion: "0.0.0", buildNumber: "1")
        )
    )
}
