import SwiftUI

struct MomentSavedEmptyState: View {
    let isSearching: Bool
    var emptyTitle: String? = nil
    var emptyDetail: String? = nil
    var systemImage: String = "bookmark"

    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.prosePalCoral.opacity(0.22),
                                Color.prosePalPaper.opacity(0.88),
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

    private var resolvedTitle: String {
        if let emptyTitle {
            return emptyTitle
        }
        return isSearching
            ? String(localized: "No saved drafts found")
            : String(localized: "No saved drafts yet")
    }

    private var resolvedDetail: String {
        if let emptyDetail {
            return emptyDetail
        }
        return isSearching
            ? String(localized: "Try another person, moment, or phrase.")
            : String(localized: "When a message feels right, save it here for later.")
    }

    private func guidancePill(_ title: LocalizedStringKey, systemImage: String) -> some View {
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
}
