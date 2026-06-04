import ProsePalAPI
import ProsePalDomain
import SwiftUI

#if os(iOS)
import UIKit
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

    public init(
        client: MessageWritingClient,
        clientContext: ClientContext,
        usageStatus: UsageStatus = UsageStatus(),
        savedMessagesStore: UserDefaults = .standard,
        savedMessagesKey: String = ProsePalAppModel.defaultSavedMessagesKey,
        onboardingStore: UserDefaults = .standard,
        onboardingCompletionKey: String = ProsePalAppModel.defaultOnboardingCompletionKey
    ) {
        self.client = client
        self.clientContext = clientContext
        self.usageStatus = usageStatus
        self.savedMessagesStore = savedMessagesStore
        self.savedMessagesKey = savedMessagesKey
        self.onboardingStore = onboardingStore
        self.onboardingCompletionKey = onboardingCompletionKey
        self.savedMessages = Self.loadSavedMessages(from: savedMessagesStore, key: savedMessagesKey)
        self.hasCompletedOnboarding = onboardingStore.bool(forKey: onboardingCompletionKey)
    }

    func generate() async {
        if isGenerating { return }
        guard prepareForGeneration() else { return }

        isGenerating = true
        errorMessage = nil
        let requestedLane = draft.requestedLane

        let request = CardRequest(
            intent: draft.intent,
            requestedLane: requestedLane,
            clientContext: clientContext
        )

        do {
            let response = try await client.generateCard(request: request)
            generatedMessages = response.messages
            fallbackStatus = response.fallbackStatus
            laneUsed = response.laneUsed
            usageStatus.recordSuccessfulGeneration(requestedLane: requestedLane, laneUsed: response.laneUsed)
            isShowingResults = true
        } catch let error as GenerationError {
            errorMessage = error.userSafeMessage
        } catch {
            errorMessage = "Message generation failed. Please try again."
        }

        isGenerating = false
    }

    func selectLane(_ lane: GenerationLane) {
        if usageStatus.isPremiumLocked(lane) {
            isShowingPaywall = true
            showNotice("Premium is locked", systemImage: "lock")
            return
        }

        draft.requestedLane = lane
    }

    func useStandardLaneFromPaywall() {
        draft.requestedLane = .standard
        isShowingPaywall = false
        showNotice("Standard selected", systemImage: "checkmark.circle.fill")
    }

    func restorePurchasesPlaceholder() {
        showNotice("Restore is not connected yet", systemImage: "arrow.clockwise")
    }

    func completeOnboarding() {
        hasCompletedOnboarding = true
        onboardingStore.set(true, forKey: onboardingCompletionKey)
    }

    private func prepareForGeneration() -> Bool {
        if usageStatus.isPremiumLocked(draft.requestedLane) {
            isShowingPaywall = true
            return false
        }

        if usageStatus.isStandardLimitReached(for: draft.requestedLane) {
            errorMessage = "You've used your Standard drafts for today."
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
        showNotice("Updated", systemImage: "checkmark.circle.fill")
        playSuccessFeedback()
        return true
    }

    func deleteSaved(_ message: SavedMessage) {
        savedMessages.removeAll { $0.id == message.id }
        persistSavedMessages()
        showNotice("Deleted", systemImage: "trash")
    }

    func deleteSaved(at offsets: IndexSet) {
        let ids = Set(offsets.map { savedMessages[$0].id })
        savedMessages.removeAll { ids.contains($0.id) }
        persistSavedMessages()
        showNotice("Deleted", systemImage: "trash")
    }

    func isSaved(_ message: GeneratedMessage) -> Bool {
        savedMessages.contains { $0.text == message.text.trimmedForSaving }
    }

    func copyText(_ text: String) {
        copyToPasteboard(text)
        showNotice("Copied", systemImage: "doc.on.doc")
        playSelectionFeedback()
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
    public var requestedLane: GenerationLane = .automatic
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

        return "Premium unlocks enhanced drafts and higher limits later."
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
        case .automatic, .standard, .template:
            true
        case .premium, .local:
            false
        }
    }
}

enum AppTab: Hashable {
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
        .tint(.indigo)
        .environmentObject(model)
        .sheet(isPresented: $model.isShowingPaywall) {
            PaywallPlaceholderSheet(
                usageStatus: model.usageStatus,
                onUseStandard: model.useStandardLaneFromPaywall,
                onRestore: model.restorePurchasesPlaceholder
            )
        }
        .overlay(alignment: .top) {
            if let notice = model.notice {
                NoticeBanner(notice: notice)
                    .padding(.top, 8)
                    .padding(.horizontal, 18)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.34, dampingFraction: 0.86), value: model.notice?.id)
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
    }
}

struct OnboardingView: View {
    var onStart: () -> Void
    @State private var selectedStep = 0

    private let steps = OnboardingStep.all

    var body: some View {
        NavigationStack {
            onboardingPages
                .background(Color.prosePalGroupedBackground)
                .navigationTitle("ProsePal")
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Button("Skip", action: onStart)
                    }
                }
                .safeAreaInset(edge: .bottom) {
                    VStack(spacing: 10) {
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

                        Text("No account or subscription required to try Standard drafts.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, 22)
                    .padding(.top, 12)
                    .padding(.bottom, 10)
                    .background(.ultraThinMaterial)
                }
        }
    }

    @ViewBuilder
    private var onboardingPages: some View {
        #if os(iOS)
        onboardingPageContent
            .tabViewStyle(.page(indexDisplayMode: .always))
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
        VStack(spacing: 22) {
            Image(systemName: step.systemImage)
                .font(.system(size: 52, weight: .semibold))
                .foregroundStyle(.indigo)
                .frame(width: 82, height: 82)
                .background(.regularMaterial, in: Circle())

            VStack(spacing: 10) {
                Text(step.title)
                    .font(.largeTitle.weight(.bold))
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.82)

                Text(step.detail)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
            }
        }
        .padding(.horizontal, 28)
    }
}

private struct OnboardingStep: Identifiable {
    let id: String
    let title: String
    let detail: String
    let systemImage: String

    static let all: [OnboardingStep] = [
        OnboardingStep(
            id: "real-moments",
            title: "Write better messages for real moments",
            detail: "Birthdays, thank-yous, apologies, sympathy, and the awkward ones too.",
            systemImage: "heart.text.square"
        ),
        OnboardingStep(
            id: "give-context",
            title: "Give it the context",
            detail: "Choose the occasion, relationship, tone, and details. ProsePal turns that into drafts you can edit.",
            systemImage: "text.bubble"
        ),
        OnboardingStep(
            id: "standard-premium",
            title: "Start simple, unlock more later",
            detail: "Standard drafts help you get started. Premium will add enhanced drafts and higher limits when subscriptions are connected.",
            systemImage: "sparkles"
        )
    ]
}

struct ComposeView: View {
    @EnvironmentObject private var model: ProsePalAppModel
    @FocusState private var focusedField: ComposeField?
    @State private var isShowingOccasionPicker = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    intentHeader
                    occasionSelector
                    recipientFields
                    styleControls
                    detailFields
                    generationControls
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 18)
            }
            .background(Color.prosePalGroupedBackground)
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("What are you writing?")
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Button {
                        focusedField = nil
                        Task { await model.generate() }
                    } label: {
                        Label("Generate", systemImage: "sparkles")
                    }
                    .disabled(model.isGenerating)

                    Spacer()

                    Button("Done") { focusedField = nil }
                }
            }
            .safeAreaInset(edge: .bottom) {
                if focusedField == nil {
                    generateButton
                }
            }
            .sheet(isPresented: $isShowingOccasionPicker) {
                OccasionPickerSheet(selection: $model.draft.occasion)
            }
            .navigationDestination(isPresented: $model.isShowingResults) {
                ResultsView()
            }
        }
    }

    private var intentHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(model.draft.occasion.displayName, systemImage: model.draft.occasion.symbolName)
                .font(.system(.title, design: .rounded, weight: .bold))
                .foregroundStyle(.primary)
            Text(summaryText)
                .font(.callout)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.linearGradient(
                    colors: [Color.indigo.opacity(0.14), Color.teal.opacity(0.12), Color.prosePalSecondaryGroupedBackground],
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
        let recipient = model.draft.recipientName.nilIfBlank ?? "someone"
        return "\(model.draft.tone.displayName) \(model.draft.length.displayName.lowercased()) note for \(recipient)"
    }

    private var occasionSelector: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Occasion")
                    .font(.headline)
                Spacer()
                Button("Browse") {
                    isShowingOccasionPicker = true
                }
                .font(.callout.weight(.semibold))
            }

            Button {
                isShowingOccasionPicker = true
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: model.draft.occasion.symbolName)
                        .font(.title2)
                        .frame(width: 34, height: 34)
                        .foregroundStyle(.indigo)
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

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(Occasion.featuredCases) { occasion in
                        Button {
                            model.draft.occasion = occasion
                        } label: {
                            let isSelected = model.draft.occasion == occasion
                            Label(occasion.displayName, systemImage: occasion.symbolName)
                                .font(.callout.weight(.semibold))
                                .labelStyle(.titleAndIcon)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 10)
                                .background(
                                    Capsule(style: .continuous)
                                        .fill(isSelected ? Color.indigo : Color.prosePalSecondaryGroupedBackground)
                                )
                                .foregroundStyle(isSelected ? .white : .primary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 2)
            }
        }
    }

    private var recipientFields: some View {
        ModernPanel {
            TextField("Recipient", text: $model.draft.recipientName)
                .focused($focusedField, equals: ComposeField.recipient)

            Divider()

            Picker("Relationship", selection: $model.draft.relationship) {
                ForEach(Relationship.allCases) { relationship in
                    Label(relationship.displayName, systemImage: relationship.symbolName)
                        .tag(relationship)
                }
            }
        }
    }

    private var styleControls: some View {
        VStack(spacing: 14) {
            Picker("Tone", selection: $model.draft.tone) {
                ForEach(Tone.allCases) { tone in
                    Label(tone.displayName, systemImage: tone.symbolName)
                        .tag(tone)
                }
            }
            .pickerStyle(.menu)
            .frame(maxWidth: .infinity, alignment: .leading)

            Text(model.draft.tone.description)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

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
            TextField("Include", text: $model.draft.thingsToInclude, prompt: Text("quiet cup of tea, old photos"))
                .focused($focusedField, equals: .include)

            Divider()

            TextField("Avoid", text: $model.draft.thingsToAvoid, prompt: Text("inside jokes, formal wording"))
                .focused($focusedField, equals: .avoid)

            Divider()

            TextField("Context", text: $model.draft.personalContext, axis: .vertical)
                .lineLimit(3...6)
                .focused($focusedField, equals: .context)

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
                Text(model.isGenerating ? "Writing" : "Generate")
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
        .background(.ultraThinMaterial)
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
                .foregroundStyle(.indigo)

            VStack(alignment: .leading, spacing: 3) {
                Text(occasion.displayName)
                    .font(.body.weight(.medium))
                    .foregroundStyle(.primary)
                Text(occasion.generationHint)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer()

            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.indigo)
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

    private let lanes: [GenerationLane] = [.automatic, .standard, .premium]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Generation")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 8) {
                ForEach(lanes, id: \.rawValue) { lane in
                    Button {
                        onSelect(lane)
                    } label: {
                        VStack(spacing: 6) {
                            Image(systemName: symbolName(for: lane))
                                .font(.headline)
                            Text(lane.displayName)
                                .font(.caption.weight(.semibold))
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                            Text(subtitle(for: lane))
                                .font(.caption2)
                                .foregroundStyle(lane == selectedLane ? .white.opacity(0.82) : .secondary)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                        }
                        .frame(maxWidth: .infinity, minHeight: 64)
                        .padding(.horizontal, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(lane == selectedLane ? Color.indigo : Color.prosePalSecondaryGroupedBackground)
                        )
                        .foregroundStyle(lane == selectedLane ? .white : .primary)
                        .overlay(alignment: .topTrailing) {
                            if usageStatus.isPremiumLocked(lane) {
                                Image(systemName: "lock.fill")
                                    .font(.caption2.weight(.bold))
                                    .foregroundStyle(lane == selectedLane ? .white : .secondary)
                                    .padding(8)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func symbolName(for lane: GenerationLane) -> String {
        switch lane {
        case .automatic: "wand.and.stars"
        case .standard: "sparkles"
        case .premium: "star.fill"
        case .local: "iphone"
        case .template: "doc.text"
        }
    }

    private func subtitle(for lane: GenerationLane) -> String {
        switch lane {
        case .automatic: "Choose"
        case .standard: "Included"
        case .premium:
            usageStatus.isPremiumUnlocked ? "Active" : "Locked"
        case .local: "On device"
        case .template: "Fallback"
        }
    }
}

struct UsageStatusRow: View {
    let usageStatus: UsageStatus

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: usageStatus.isPremiumUnlocked ? "checkmark.seal.fill" : "gauge")
                .font(.callout.weight(.semibold))
                .foregroundStyle(.indigo)
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
                    title: "No Drafts",
                    systemImage: "text.page",
                    detail: "Create a message to see drafts here."
                )
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Pick one to copy, edit, save, or share.")
                                .font(.callout)
                                .foregroundStyle(.secondary)
                            Text("\(model.draft.occasion.displayName) / \(model.draft.tone.displayName) / \(model.draft.length.displayName)")
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
        .navigationTitle("Drafts")
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
                Label("Simple draft used this time. You can retry shortly.", systemImage: "wand.and.stars.inverse")
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
            .background(Color.orange.opacity(0.12), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        } else if let lane = model.laneUsed {
            Label("\(lane.displayName) generation", systemImage: "checkmark.seal")
                .font(.footnote.weight(.medium))
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
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
                Label("Draft \(draftNumber)", systemImage: "text.page")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                if model.isSaved(message) {
                    Label("Saved", systemImage: "bookmark.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.indigo)
                }
            }

            Text(message.text)
                .font(.body)
                .lineSpacing(4)
                .textSelection(.enabled)

            HStack(spacing: 10) {
                Button {
                    model.copyText(message.text)
                } label: {
                    Label("Copy", systemImage: "doc.on.doc")
                }

                ShareLink(item: message.text) {
                    Label("Share", systemImage: "square.and.arrow.up")
                }

                Button {
                    editedText = message.text
                    isEditing = true
                } label: {
                    Label("Edit", systemImage: "square.and.pencil")
                }

                Spacer(minLength: 0)

                Button {
                    model.save(message)
                } label: {
                    Label(model.isSaved(message) ? "Saved" : "Save", systemImage: model.isSaved(message) ? "bookmark.fill" : "bookmark")
                        .labelStyle(.iconOnly)
                }
                .accessibilityLabel(model.isSaved(message) ? "Saved" : "Save")
                .disabled(model.isSaved(message))
            }
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
                title: "Edit Draft \(draftNumber)",
                text: $editedText,
                onCopy: { model.copyText(editedText) },
                onSave: {
                    if model.saveText(editedText) {
                        isEditing = false
                    }
                }
            )
        }
        .onAppear {
            editedText = message.text
        }
    }
}

struct DraftEditorSheet: View {
    var title: String
    @Binding var text: String
    var onCopy: () -> Void
    var onSave: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                TextEditor(text: $text)
                    .font(.body)
                    .lineSpacing(4)
                    .padding(12)
                    .frame(minHeight: 240)
                    .background(Color.prosePalSecondaryGroupedBackground, in: RoundedRectangle(cornerRadius: 18, style: .continuous))

                HStack {
                    Button {
                        onCopy()
                    } label: {
                        Label("Copy", systemImage: "doc.on.doc")
                    }

                    ShareLink(item: text) {
                        Label("Share", systemImage: "square.and.arrow.up")
                    }

                    Spacer()

                    Button {
                        onSave()
                    } label: {
                        Label("Save", systemImage: "bookmark")
                    }
                    .buttonStyle(.borderedProminent)
                }
                .buttonStyle(.bordered)
            }
            .padding(20)
            .background(Color.prosePalGroupedBackground)
            .navigationTitle(title)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
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
            VStack(alignment: .leading, spacing: 22) {
                VStack(alignment: .leading, spacing: 10) {
                    Image(systemName: "star.circle.fill")
                        .font(.system(size: 50, weight: .semibold))
                        .foregroundStyle(.indigo)

                    Text("Premium generation")
                        .font(.largeTitle.weight(.bold))
                        .minimumScaleFactor(0.75)

                    Text("Better drafts for harder moments, higher limits, and priority generation when it is available.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }

                VStack(spacing: 12) {
                    PremiumFeatureRow(systemImage: "heart.text.square", title: "Enhanced drafts", detail: "More help for nuanced or sensitive messages.")
                    PremiumFeatureRow(systemImage: "gauge", title: "Higher limits", detail: "More writing room once subscriptions are connected.")
                    PremiumFeatureRow(systemImage: "arrow.clockwise.circle", title: "Regenerate more", detail: "Try another angle without losing your draft.")
                }

                UsageStatusRow(usageStatus: usageStatus)

                Spacer(minLength: 0)

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
                .foregroundStyle(.indigo)
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
                    LabeledContent("Recipient", value: currentSaved.recipientName ?? "Not set")
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

                    Button {
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
                onSave: {
                    if model.updateSaved(currentSaved, text: editedText) {
                        isEditing = false
                    }
                }
            )
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
                        model.showNotice("Sign in is not connected yet", systemImage: "apple.logo")
                    } label: {
                        Label("Sign in with Apple", systemImage: "apple.logo")
                    }

                    Button {
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
                    Picker("Spelling", selection: $model.draft.spellingPreference) {
                        ForEach(SpellingPreference.allCases) { preference in
                            Text(preference.displayName).tag(preference)
                        }
                    }

                    Picker("Default tone", selection: $model.draft.tone) {
                        ForEach(Tone.allCases) { tone in
                            Text(tone.displayName).tag(tone)
                        }
                    }
                }

                Section("Generation") {
                    ForEach([GenerationLane.automatic, .standard, .premium], id: \.rawValue) { lane in
                        Button {
                            model.selectLane(lane)
                        } label: {
                            HStack {
                                Label(lane.displayName, systemImage: lane == .premium ? "star" : "sparkles")
                                Spacer()
                                if model.draft.requestedLane == lane {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.indigo)
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
                        model.showNotice("Export is not connected yet", systemImage: "square.and.arrow.up")
                    } label: {
                        Label("Export data", systemImage: "square.and.arrow.up")
                    }

                    Button(role: .destructive) {
                        model.showNotice("Account deletion is not connected yet", systemImage: "trash")
                    } label: {
                        Label("Delete account", systemImage: "trash")
                    }
                }

                Section("Support") {
                    Button {
                        model.showNotice("Feedback is not connected yet", systemImage: "envelope")
                    } label: {
                        Label("Send feedback", systemImage: "envelope")
                    }

                    Label("Terms", systemImage: "doc.text")
                    Label("Privacy Policy", systemImage: "hand.raised")
                }

                Section("Runtime") {
                    LabeledContent("Generation", value: "Gateway contract v1")
                    LabeledContent("Build", value: "Native R&D")
                }
            }
            .navigationTitle("Settings")
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

enum ComposeField: Hashable {
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
            client: TemplateMessageWritingClient(),
            clientContext: ClientContext(appVersion: "0.0.0", buildNumber: "1")
        )
    )
}
