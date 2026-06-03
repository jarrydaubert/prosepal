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
    @Published var isGenerating = false
    @Published var errorMessage: String?
    @Published var fallbackStatus: FallbackStatus = .none
    @Published var laneUsed: GenerationLane?
    @Published var selectedTab: AppTab = .compose

    private static let savedMessagesKey = "prosepal.native.savedMessages.v1"
    private let client: MessageWritingClient
    private let clientContext: ClientContext

    public init(client: MessageWritingClient, clientContext: ClientContext) {
        self.client = client
        self.clientContext = clientContext
        self.savedMessages = Self.loadSavedMessages()
    }

    func generate() async {
        if isGenerating { return }

        isGenerating = true
        errorMessage = nil

        let request = CardRequest(
            intent: draft.intent,
            requestedLane: draft.requestedLane,
            clientContext: clientContext
        )

        do {
            let response = try await client.generateCard(request: request)
            generatedMessages = response.messages
            fallbackStatus = response.fallbackStatus
            laneUsed = response.laneUsed
            selectedTab = .results
        } catch let error as GenerationError {
            errorMessage = error.userSafeMessage
        } catch {
            errorMessage = "Message generation failed. Please try again."
        }

        isGenerating = false
    }

    func save(_ message: GeneratedMessage) {
        guard !savedMessages.contains(where: { $0.text == message.text }) else { return }
        savedMessages.insert(
            SavedMessage(text: message.text, occasion: draft.occasion, savedAt: .now),
            at: 0
        )
        persistSavedMessages()
    }

    func deleteSaved(_ message: SavedMessage) {
        savedMessages.removeAll { $0.id == message.id }
        persistSavedMessages()
    }

    private static func loadSavedMessages() -> [SavedMessage] {
        guard let data = UserDefaults.standard.data(forKey: savedMessagesKey) else {
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
        UserDefaults.standard.set(data, forKey: Self.savedMessagesKey)
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

public struct SavedMessage: Codable, Identifiable, Equatable, Sendable {
    public var id = UUID()
    public var text: String
    public var occasion: Occasion
    public var savedAt: Date
}

enum AppTab: Hashable {
    case compose
    case results
    case saved
    case settings
}

public struct ProsePalRootView: View {
    @StateObject private var model: ProsePalAppModel

    public init(model: @autoclosure @escaping () -> ProsePalAppModel) {
        _model = StateObject(wrappedValue: model())
    }

    public var body: some View {
        TabView(selection: $model.selectedTab) {
            ComposeView()
                .tabItem { Label("Create", systemImage: "square.and.pencil") }
                .tag(AppTab.compose)

            ResultsView()
                .tabItem { Label("Drafts", systemImage: "text.page") }
                .tag(AppTab.results)

            SavedMessagesView()
                .tabItem { Label("Saved", systemImage: "bookmark") }
                .tag(AppTab.saved)

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape") }
                .tag(AppTab.settings)
        }
        .tint(.indigo)
        .environmentObject(model)
    }
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
                    Spacer()
                    Button("Done") { focusedField = nil }
                }
            }
            .safeAreaInset(edge: .bottom) {
                generateButton
            }
            .sheet(isPresented: $isShowingOccasionPicker) {
                OccasionPickerSheet(selection: $model.draft.occasion)
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

            Picker("Lane", selection: $model.draft.requestedLane) {
                Text("Auto").tag(GenerationLane.automatic)
                Text("Standard").tag(GenerationLane.standard)
                Text("Premium").tag(GenerationLane.premium)
            }
            .pickerStyle(.segmented)

            Label("Standard drafts available. Premium unlocks enhanced drafts later.", systemImage: "gauge")
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
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
                Label(errorMessage, systemImage: "exclamationmark.triangle")
                    .font(.footnote)
                    .foregroundStyle(.red)
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
                ForEach(OccasionGroup.allCases) { group in
                    let occasions = filteredOccasions(in: group)
                    if !occasions.isEmpty {
                        Section(group.displayName) {
                            ForEach(occasions) { occasion in
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

    private func filteredOccasions(in group: OccasionGroup) -> [Occasion] {
        let groupOccasions = Occasion.allCases.filter { $0.group == group }
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return groupOccasions }

        return groupOccasions.filter {
            $0.searchText.localizedCaseInsensitiveContains(query)
        }
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

struct ResultsView: View {
    @EnvironmentObject private var model: ProsePalAppModel

    var body: some View {
        NavigationStack {
            VStack {
                if model.generatedMessages.isEmpty {
                    EmptyStateView(
                        title: "No Drafts",
                        systemImage: "text.page",
                        detail: "Create a message to see drafts here."
                    )
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            generationStatus
                            ForEach(model.generatedMessages) { message in
                                ResultCard(message: message)
                            }
                        }
                        .padding(20)
                    }
                    .background(Color.prosePalGroupedBackground)
                }
            }
            .navigationTitle("Drafts")
        }
    }

    @ViewBuilder
    private var generationStatus: some View {
        if model.fallbackStatus != .none {
            Label("Simple draft used this time. You can retry shortly.", systemImage: "wand.and.stars.inverse")
                .font(.footnote.weight(.medium))
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
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

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(message.text)
                .font(.body)
                .lineSpacing(4)
                .textSelection(.enabled)

            HStack {
                Button {
                    copyToPasteboard(message.text)
                } label: {
                    Label("Copy", systemImage: "doc.on.doc")
                }

                ShareLink(item: message.text) {
                    Label("Share", systemImage: "square.and.arrow.up")
                }

                Spacer()

                Button {
                    model.save(message)
                } label: {
                    Image(systemName: "bookmark")
                        .accessibilityLabel("Save")
                }
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
        .padding(18)
        .background(Color.prosePalSecondaryGroupedBackground, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
}

struct SavedMessagesView: View {
    @EnvironmentObject private var model: ProsePalAppModel

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
                        ForEach(model.savedMessages) { saved in
                            VStack(alignment: .leading, spacing: 8) {
                                Label(saved.occasion.displayName, systemImage: saved.occasion.symbolName)
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.secondary)
                                Text(saved.text)
                                    .font(.body)
                                    .textSelection(.enabled)
                            }
                            .padding(.vertical, 8)
                        }
                        .onDelete { offsets in
                            offsets.map { model.savedMessages[$0] }.forEach(model.deleteSaved)
                        }
                    }
                }
            }
            .navigationTitle("Saved")
        }
    }
}

struct SettingsView: View {
    @EnvironmentObject private var model: ProsePalAppModel

    var body: some View {
        NavigationStack {
            List {
                Section("Writing") {
                    Picker("Spelling", selection: $model.draft.spellingPreference) {
                        ForEach(SpellingPreference.allCases) { preference in
                            Text(preference.displayName).tag(preference)
                        }
                    }
                    Picker("Default Lane", selection: $model.draft.requestedLane) {
                        Text("Auto").tag(GenerationLane.automatic)
                        Text("Standard").tag(GenerationLane.standard)
                        Text("Premium").tag(GenerationLane.premium)
                    }
                }

                Section("Account") {
                    Label("Sign in with Apple", systemImage: "apple.logo")
                    Label("Subscription restore", systemImage: "arrow.clockwise")
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
}

private func copyToPasteboard(_ text: String) {
    #if os(iOS)
    UIPasteboard.general.string = text
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
