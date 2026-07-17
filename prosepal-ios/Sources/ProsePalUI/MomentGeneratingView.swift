import SwiftUI

struct MomentGeneratingView: View {
    let noteText: String
    let isCareful: Bool
    let onStop: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var isBreathing = false

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            notePreview
            generatingPage
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("moment.generating")
        .task {
            guard !reduceMotion else {
                isBreathing = true
                return
            }

            withAnimation(.easeInOut(duration: 1.25).repeatForever(autoreverses: true)) {
                isBreathing = true
            }
        }
    }

    private var notePreview: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Your note")
                .font(.caption2.weight(.bold))
                .tracking(0.7)
                .foregroundStyle(Color.prosePalSlate.opacity(0.72))

            Text(previewText)
                .font(.system(.body, design: .serif))
                .lineSpacing(4)
                .foregroundStyle(Color.prosePalSlate.opacity(0.78))
                .lineLimit(dynamicTypeSize.isAccessibilitySize ? 6 : 4)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 15)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: ProsePalRadius.field, style: .continuous)
                .fill(Color.prosePalPaper.opacity(0.70))
                .overlay {
                    RoundedRectangle(cornerRadius: ProsePalRadius.field, style: .continuous)
                        .stroke(Color.prosePalSeparator, lineWidth: 0.5)
                }
        }
        .accessibilityElement(children: .combine)
    }

    private var generatingPage: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .center, spacing: 10) {
                breathingOrb

                Text("Finding the right words…")
                    .font(.system(.callout, weight: .semibold))
                    .foregroundStyle(Color.prosePalInk)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityLabel(String(localized: "Writing in progress"))
                    .accessibilityValue(String(localized: "In progress"))
                    .accessibilityIdentifier("moment.generation.progress")
            }

            MomentGeneratingSkeleton()
                .accessibilityHidden(true)

            HStack(alignment: .center, spacing: 7) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 15, weight: .medium))
                    .symbolRenderingMode(.hierarchical)
                    .accessibilityHidden(true)

                Text("Keeping your voice")
                    .font(.footnote)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .foregroundStyle(Color.prosePalCare)

            Button(role: .cancel, action: onStop) {
                Label(String(localized: "Stop writing"), systemImage: "stop.circle")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .accessibilityIdentifier("moment.generation.stop")
        }
        .padding(.top, 20)
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: ProsePalRadius.canvas, style: .continuous)
                .fill(Color.prosePalPaper)
                .overlay {
                    RoundedRectangle(cornerRadius: ProsePalRadius.canvas, style: .continuous)
                        .stroke(Color.prosePalSeparator, lineWidth: 0.5)
                }
                .overlay(alignment: .leading) {
                    Rectangle()
                        .fill((isCareful ? Color.prosePalCare : Color.prosePalCoral).opacity(0.18))
                        .frame(width: 3)
                        .padding(.vertical, 18)
                }
                .prosePalElevation(.small)
        }
        .accessibilityElement(children: .contain)
    }

    private var breathingOrb: some View {
        Circle()
            .fill(isCareful ? Color.prosePalCare : Color.prosePalCoral)
            .frame(width: 11, height: 11)
            .scaleEffect(isBreathing && !reduceMotion ? 1.18 : 0.86)
            .opacity(isBreathing && !reduceMotion ? 0.72 : 1)
            .shadow(
                color: (isCareful ? Color.prosePalCare : Color.prosePalCoral).opacity(0.22),
                radius: isBreathing && !reduceMotion ? 10 : 4,
                x: 0,
                y: 0
            )
            .accessibilityHidden(true)
    }

    private var previewText: String {
        let trimmed = noteText.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "Your rough note will stay here while ProsePal drafts." : trimmed
    }
}

private struct MomentGeneratingSkeleton: View {
    var body: some View {
        GeometryReader { proxy in
            VStack(alignment: .leading, spacing: 11) {
                skeletonLine(width: proxy.size.width * 0.54, height: 18)
                    .padding(.bottom, 2)
                skeletonLine(width: proxy.size.width, height: 13)
                skeletonLine(width: proxy.size.width * 0.96, height: 13)
                skeletonLine(width: proxy.size.width, height: 13)
                skeletonLine(width: proxy.size.width * 0.58, height: 13)
            }
        }
        .frame(height: 106)
    }

    private func skeletonLine(width: CGFloat, height: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: height / 2, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [
                        Color.prosePalCoral.opacity(0.10),
                        Color.prosePalCoral.opacity(0.055)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(width: width, height: height)
    }
}

#Preview("Generating") {
    MomentGeneratingView(
        noteText: "telling my landlord were not renewing the lease. weve been here six years, want to be kind but clear about it.",
        isCareful: false,
        onStop: {}
    )
    .padding(20)
    .background {
        MomentAtmosphericBackground(isCareful: false)
    }
}
