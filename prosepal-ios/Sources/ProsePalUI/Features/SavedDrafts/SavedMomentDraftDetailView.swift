import Foundation
import ProsePalAPI
import ProsePalDomain
import SwiftUI
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

struct SavedMomentDraftDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let draft: SavedMomentDraftRecord

    @State private var isEditing = false
    @State private var editedMessageText: String
    @State private var notice: SavedDraftNotice?
    @State private var isConfirmingDeletion = false

    private let diagnostics = NativeDiagnosticsLogger.shared

    init(draft: SavedMomentDraftRecord) {
        self.draft = draft
        _editedMessageText = State(initialValue: draft.messageText)
    }

    private var canSaveEdits: Bool {
        !editedMessageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var sharePresentation: MomentTextSharePresentation {
        MomentTextSharePresentation(text: draft.messageText, surface: .savedDraft)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                if let notice {
                    SavedDraftNoticeView(notice: notice)
                }

                MomentDetailHero(
                    systemImage: draft.occasion.symbolName,
                    title: draft.title,
                    detail: draft.subtitle
                )

                MomentDetailCard(
                    title: isEditing ? "Edit draft" : "Saved draft",
                    systemImage: "bookmark"
                ) {
                    if isEditing {
                        TextField(
                            "Draft text",
                            text: $editedMessageText.prosePalLimited(to: ProsePalTextLimit.draft),
                            axis: .vertical
                        )
                        .font(.system(.title3, design: .serif))
                        .lineSpacing(5)
                        .lineLimit(8...18)
                        .textFieldStyle(.plain)
                        .foregroundStyle(Color.prosePalInk)
                        .accessibilityValue(
                            "\(editedMessageText.count) of \(ProsePalTextLimit.draft) characters"
                        )
                    } else {
                        Text(draft.messageText)
                            .font(.system(.title3, design: .serif))
                            .lineSpacing(5)
                            .foregroundStyle(Color.prosePalInk)
                            .textSelection(.enabled)
                    }
                }

                savedDraftActionRow
                savedDraftDeleteButton
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 44)
        }
        .scrollIndicators(.hidden)
        .background {
            MomentAtmosphericBackground(isCareful: false)
        }
        .navigationTitle(String(localized: "Draft"))
        .toolbar {
            #if os(iOS)
            ToolbarItem(placement: .topBarTrailing) {
                editOrSaveButton
            }
            #else
            ToolbarItem {
                editOrSaveButton
            }
            #endif
        }
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .accessibilityIdentifier("savedDraft.detail")
        .confirmationDialog(
            String(localized: "Delete saved draft?"),
            isPresented: $isConfirmingDeletion,
            titleVisibility: .visible
        ) {
            Button(String(localized: "Delete draft"), role: .destructive) {
                deleteDraft(confirmed: true)
            }
            .accessibilityIdentifier("savedDraft.delete.confirm")
            Button(String(localized: "Cancel"), role: .cancel) {}
        } message: {
            Text(String(localized: "This removes the draft from this device. This cannot be undone."))
        }
    }

    private var editOrSaveButton: some View {
        Button(isEditing ? "Save" : "Edit", action: toggleEditing)
            .font(.subheadline.weight(.semibold))
            .disabled(isEditing && !canSaveEdits)
            .accessibilityIdentifier("savedDraft.editOrSave")
    }

    @ViewBuilder
    private var savedDraftActionRow: some View {
        HStack(spacing: 12) {
            if isEditing {
                Button(action: cancelEditing) {
                    Label("Cancel", systemImage: "xmark")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .buttonBorderShape(.capsule)
                .tint(.prosePalCoralDeep)
                .accessibilityIdentifier("savedDraft.edit.cancel")

                Button(action: saveEdits) {
                    Label("Save", systemImage: "checkmark")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.capsule)
                .tint(.prosePalCoral)
                .disabled(!canSaveEdits)
                .accessibilityIdentifier("savedDraft.edit.save")
            } else {
                Button {
                    copyDraft()
                } label: {
                    Label(
                        MomentTextShareAction.copy.title,
                        systemImage: MomentTextShareAction.copy.systemImage
                    )
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .buttonBorderShape(.capsule)
                .tint(.prosePalCoralDeep)
                .accessibilityLabel(MomentTextShareAction.copy.title)
                .accessibilityHint(String(localized: "Copies this draft to the clipboard."))
                .accessibilityIdentifier(
                    sharePresentation.accessibilityIdentifier(for: .copy)
                )

                ShareLink(
                    item: sharePresentation.text,
                    preview: SharePreview(String(localized: "Saved ProsePal draft"))
                ) {
                    Label(
                        MomentTextShareAction.share.title,
                        systemImage: MomentTextShareAction.share.systemImage
                    )
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.capsule)
                .tint(.prosePalCoral)
                .accessibilityLabel(MomentTextShareAction.share.title)
                .accessibilityHint(
                    String(localized: "Opens the system share sheet so you can choose where the draft goes.")
                )
                .accessibilityIdentifier(
                    sharePresentation.accessibilityIdentifier(for: .share)
                )
            }
        }
        .controlSize(.large)
    }

    private var savedDraftDeleteButton: some View {
        Button(role: .destructive) {
            isConfirmingDeletion = true
        } label: {
            Label("Delete draft", systemImage: "trash")
                .font(.subheadline.weight(.semibold))
                .frame(maxWidth: .infinity)
                .frame(height: 48)
        }
        .buttonStyle(.plain)
        .foregroundStyle(Color.red.opacity(0.86))
        .background(Color.red.opacity(0.08), in: Capsule(style: .continuous))
        .accessibilityIdentifier("savedDraft.delete.request")
    }

    private func toggleEditing() {
        if isEditing {
            saveEdits()
        } else {
            beginEditing()
        }
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
            notice = nil
        }
    }

    private func saveEdits() {
        guard canSaveEdits else { return }

        do {
            try persistSavedDraftEdit(
                update: { draft.updateMessageText(editedMessageText) },
                save: { try modelContext.save() },
                rollback: { modelContext.rollback() }
            )
            editedMessageText = draft.messageText
            withAnimation(.easeInOut(duration: 0.18)) {
                isEditing = false
                notice = .success(String(localized: "Saved"))
            }
        } catch {
            editedMessageText = draft.messageText
            withAnimation(.easeInOut(duration: 0.18)) {
                notice = .failure(
                    String(localized: "Could not save this draft. Your previous version is still saved.")
                )
            }
        }
    }

    private func deleteDraft(confirmed: Bool) {
        do {
            let didDelete = try persistSavedDraftDeletion(
                confirmed: confirmed,
                delete: { modelContext.delete(draft) },
                save: { try modelContext.save() },
                rollback: { modelContext.rollback() }
            )
            if didDelete {
                dismiss()
            }
        } catch {
            notice = .failure(String(localized: "Could not delete this draft. It is still saved."))
        }
    }

    private func copyDraft() {
        let interaction = sharePresentation.copy { text in
        #if canImport(UIKit)
            UIPasteboard.general.string = text
        #elseif canImport(AppKit)
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(text, forType: .string)
        #endif
        }
        if let action = MomentShareTelemetryPolicy.diagnosticsAction(for: interaction) {
            diagnostics.messageAction(
                action,
                source: "saved_draft",
                messageCharacters: draft.messageText.count
            )
        }
    }
}

private enum SavedDraftNotice {
    case success(String)
    case failure(String)

    var text: String {
        switch self {
        case let .success(text), let .failure(text):
            text
        }
    }

    var isFailure: Bool {
        if case .failure = self { return true }
        return false
    }
}

private struct SavedDraftNoticeView: View {
    let notice: SavedDraftNotice

    var body: some View {
        Label(
            notice.text,
            systemImage: notice.isFailure ? "exclamationmark.triangle" : "checkmark.circle"
        )
        .font(.callout.weight(.semibold))
        .foregroundStyle(notice.isFailure ? Color.red : Color.prosePalCare)
        .padding(.horizontal, 14)
        .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
        .background(noticeColor.opacity(0.10), in: RoundedRectangle(cornerRadius: 15, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 15, style: .continuous)
                .stroke(noticeColor.opacity(0.16), lineWidth: 1)
        }
    }

    private var noticeColor: Color {
        notice.isFailure ? .red : .prosePalCare
    }
}
