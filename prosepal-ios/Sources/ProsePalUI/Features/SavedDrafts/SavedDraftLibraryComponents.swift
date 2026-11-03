import ProsePalAPI
import SwiftUI

enum SavedDraftRelativeDateLabel {
    static func text(
        createdAt: Date,
        relativeTo referenceDate: Date,
        calendar: Calendar
    ) -> String {
        if calendar.isDate(createdAt, inSameDayAs: referenceDate) {
            return String(localized: "Just now")
        }

        guard let yesterday = calendar.date(byAdding: .day, value: -1, to: referenceDate) else {
            return createdAt.formatted(.dateTime.month(.abbreviated).day())
        }
        if calendar.isDate(createdAt, inSameDayAs: yesterday) {
            return String(localized: "Yesterday")
        }

        let days = calendar.dateComponents([.day], from: createdAt, to: referenceDate).day ?? 0
        if days >= 0, days < 7 {
            return createdAt.formatted(.dateTime.weekday(.abbreviated))
        }

        return createdAt.formatted(.dateTime.month(.abbreviated).day())
    }
}

struct SavedDraftsLibraryEmptyState: View {
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

struct SavedMomentDraftLibraryCard: View {
    let draft: SavedMomentDraftRecord
    let referenceDate: Date
    let calendar: Calendar

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: draft.occasion.symbolName)
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(Color.prosePalCoral)
                .frame(width: 40, height: 40)
                .background(
                    Color.prosePalCoral.opacity(0.12),
                    in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                )

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

                    Text("Saved")
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
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("savedDraft.card")
    }

    private var relativeSavedDate: String {
        SavedDraftRelativeDateLabel.text(
            createdAt: draft.createdAt,
            relativeTo: referenceDate,
            calendar: calendar
        )
    }
}
