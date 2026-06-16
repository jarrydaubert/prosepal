import ProsePalAPI
import ProsePalDomain
import SwiftUI
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
    @ObservationIgnored private var draftTask: Task<Void, Never>?
    @ObservationIgnored private var draftGeneration = 0

    public init(service: any MessageWritingService) {
        self.service = service
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
        moment.hasEnoughContextForDraft
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
        await draftNow(generation: nextDraftGeneration())
    }

    private func draftNow(generation: Int) async {
        guard canDraft else { return }
        let input = moment
        isDrafting = true
        errorMessage = nil
        defer {
            finishDrafting(generation: generation)
        }

        do {
            let nextBundle = try await service.draft(for: input)
            guard isCurrentGeneration(generation) else { return }
            bundle = nextBundle
        } catch is CancellationError {
            return
        } catch let error as GenerationError {
            guard isCurrentGeneration(generation) else { return }
            errorMessage = error.userSafeMessage
        } catch {
            guard isCurrentGeneration(generation) else { return }
            errorMessage = "ProsePal could not write this yet."
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

    private func adjustNow(
        _ bundle: MomentDraftBundle,
        adjustment: MomentAdjustment,
        generation: Int
    ) async {
        let input = moment
        isDrafting = true
        errorMessage = nil
        defer {
            finishDrafting(generation: generation)
        }

        do {
            let nextBundle = try await service.adjust(bundle, with: adjustment, moment: input)
            guard isCurrentGeneration(generation) else { return }
            self.bundle = nextBundle
        } catch is CancellationError {
            return
        } catch let error as GenerationError {
            guard isCurrentGeneration(generation) else { return }
            errorMessage = error.userSafeMessage
        } catch {
            guard isCurrentGeneration(generation) else { return }
            errorMessage = "ProsePal could not reshape this yet."
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
}

public struct MomentAppRootView: View {
    @State private var model: MomentModel

    public init(service: any MessageWritingService) {
        _model = State(initialValue: MomentModel(service: service))
    }

    public var body: some View {
        NavigationStack {
            MomentSheetView(model: model)
                .navigationTitle("ProsePal")
                .toolbarTitleDisplayMode(.inline)
        }
    }
}

private struct MomentSheetView: View {
    @Bindable var model: MomentModel
    @FocusState private var focusedField: Field?

    private enum Field: Hashable {
        case person
        case truth
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                header
                personSection
                momentSection
                truthSection
                draftSection
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
        .onChange(of: model.personName) { _, _ in model.scheduleDraft() }
        .onChange(of: model.relationship) { _, _ in model.scheduleDraft() }
        .onChange(of: model.occasion) { _, _ in model.scheduleDraft() }
        .onChange(of: model.register) { _, _ in model.scheduleDraft() }
        .onChange(of: model.trueThing) { _, _ in model.scheduleDraft() }
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

            Picker("Relationship", selection: $model.relationship) {
                ForEach(Relationship.allCases) { relationship in
                    Text(relationship.displayName).tag(relationship)
                }
            }
            .pickerStyle(.menu)
        }
        .prosePalMomentCard()
    }

    private var momentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Moment")
                .font(.headline)

            Picker("Moment", selection: $model.occasion) {
                ForEach(Occasion.allCases) { occasion in
                    Text(occasion.displayName).tag(occasion)
                }
            }
            .pickerStyle(.menu)

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

                ShareLink(item: bundle.messageText) {
                    Label("Send", systemImage: "paperplane")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
            .controlSize(.large)
        }
    }

    private func copy(_ text: String) {
        #if canImport(UIKit)
        UIPasteboard.general.string = text
        #endif
    }
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
