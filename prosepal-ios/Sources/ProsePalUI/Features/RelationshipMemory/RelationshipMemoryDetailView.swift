import ProsePalAPI
import ProsePalDomain
import SwiftData
import SwiftUI

struct RelationshipMemoryDetailView: View {
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
            MomentDetailTopChrome(
                title: "Memory detail",
                backAccessibilityIdentifier: "memory.detail.back",
                backAction: { dismiss() }
            ) {
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

                    memoryDetailUseCard(
                        isOn: $isUserApproved,
                        footer: "Why am I seeing this? You saved this detail for \(bead.personName). ProsePal uses approved details only when drafting for that person, and does not log the text."
                    )

                    memoryDetailDeleteButton(
                        title: "Delete detail",
                        accessibilityIdentifier: "memory.detail.delete.request"
                    ) {
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
            .accessibilityIdentifier("memory.detail.delete.confirm")
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
}

struct RelationshipVoiceCardDetailView: View {
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
            MomentDetailTopChrome(
                title: "Voice card",
                backAccessibilityIdentifier: "voiceCard.detail.back",
                backAction: { dismiss() }
            ) {
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

                    memoryDetailUseCard(
                        isOn: $isUserApproved,
                        footer: "Why am I seeing this? You saved this voice card for \(voiceCard.personName). ProsePal uses approved voice cards only when drafting for that person, and does not log the text."
                    )

                    memoryDetailDeleteButton(
                        title: "Delete voice card",
                        accessibilityIdentifier: "voiceCard.detail.delete.request"
                    ) {
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
            .accessibilityIdentifier("voiceCard.detail.delete.confirm")
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
}

@MainActor
private func memoryDetailUseCard(isOn: Binding<Bool>, footer: String) -> some View {
    MomentDetailCard(title: "Use", systemImage: "checkmark.seal", footer: footer) {
        Toggle("Use this in drafts", isOn: isOn)
            .font(.body.weight(.medium))
            .foregroundStyle(Color.prosePalInk)
            .tint(.prosePalCare)
    }
}

@MainActor
private func memoryDetailDeleteButton(
    title: String,
    accessibilityIdentifier: String,
    action: @escaping () -> Void
) -> some View {
    Button(role: .destructive, action: action) {
        Label(title, systemImage: "trash")
            .font(.subheadline.weight(.semibold))
            .frame(maxWidth: .infinity)
            .frame(height: 48)
    }
    .buttonStyle(.plain)
    .foregroundStyle(Color.red.opacity(0.86))
    .background(Color.red.opacity(0.08), in: Capsule(style: .continuous))
    .accessibilityIdentifier(accessibilityIdentifier)
}

private struct MomentDetailTopChrome<Trailing: View>: View {
    let title: String
    let backAccessibilityIdentifier: String
    let backAction: () -> Void
    private let trailing: Trailing

    init(
        title: String,
        backAccessibilityIdentifier: String,
        backAction: @escaping () -> Void,
        @ViewBuilder trailing: () -> Trailing
    ) {
        self.title = title
        self.backAccessibilityIdentifier = backAccessibilityIdentifier
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
            .accessibilityIdentifier(backAccessibilityIdentifier)

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

private struct MomentDetailNotice: View {
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

#Preview("Memory detail") {
    RelationshipMemoryDetailPreview()
}

#Preview("Voice card detail") {
    RelationshipVoiceCardDetailPreview()
}

private struct RelationshipMemoryDetailPreview: View {
    private let container: ModelContainer
    private let bead: RelationshipTruthBeadRecord

    init() {
        container = try! RelationshipVaultContainerFactory.makeEphemeral()
        bead = RelationshipTruthBeadRecord(
            personName: "Mira",
            text: "Loves the Sunday morning calls and long walks by the river."
        )
        container.mainContext.insert(bead)
    }

    var body: some View {
        NavigationStack {
            RelationshipMemoryDetailView(bead: bead)
        }
        .modelContainer(container)
    }
}

private struct RelationshipVoiceCardDetailPreview: View {
    private let container: ModelContainer
    private let voiceCard: RelationshipVoiceCardRecord

    init() {
        container = try! RelationshipVaultContainerFactory.makeEphemeral()
        voiceCard = RelationshipVoiceCardRecord(
            personName: "Mira",
            summary: "Warm, short, no fuss."
        )
        container.mainContext.insert(voiceCard)
    }

    var body: some View {
        NavigationStack {
            RelationshipVoiceCardDetailView(voiceCard: voiceCard)
        }
        .modelContainer(container)
    }
}
