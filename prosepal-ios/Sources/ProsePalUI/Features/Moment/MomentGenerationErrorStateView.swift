import SwiftUI

struct MomentGenerationErrorStateView: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    let presentation: MomentGenerationErrorPresentation
    let canDraft: Bool
    let isDrafting: Bool
    let isCareful: Bool
    let minHeight: CGFloat
    let onRetry: () -> Void
    let onBack: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: dynamicTypeSize.isAccessibilitySize ? 28 : 26)

            VStack(spacing: 11) {
                Image(systemName: presentation.systemImage)
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(Color.prosePalWarning)
                    .frame(width: 60, height: 60)
                    .background(
                        Color.prosePalWarning.opacity(0.14),
                        in: RoundedRectangle(cornerRadius: 18, style: .continuous)
                    )
                    .accessibilityHidden(true)

                Text(presentation.title)
                    .font(.system(size: 23, weight: .medium, design: .serif))
                    .foregroundStyle(Color.prosePalInk)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                Text(presentation.detail)
                    .font(.callout)
                    .lineSpacing(3)
                    .foregroundStyle(Color.prosePalSlate)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 285)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity)
            .accessibilityElement(children: .combine)

            Spacer(minLength: dynamicTypeSize.isAccessibilitySize ? 28 : 54)

            VStack(spacing: 10) {
                Button(action: onRetry) {
                    Label(presentation.actionTitle, systemImage: presentation.actionSystemImage)
                        .font(.headline.weight(.semibold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.82)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                }
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.capsule)
                .tint(isCareful ? .prosePalCare : .prosePalCoral)
                .disabled(!canDraft || isDrafting)
                .accessibilityIdentifier(presentation.actionAccessibilityIdentifier)

                Button("Back to your note", action: onBack)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.prosePalCoralDeep)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .buttonStyle(.plain)
            }
        }
        .frame(minHeight: minHeight, alignment: .center)
    }
}

#Preview("Online writing required") {
    MomentGenerationErrorStateView(
        presentation: MomentGenerationErrorPresentation(
            reason: .onlineWritingPermissionRequired,
            errorMessage: "Allow online writing to continue. Your Moment and current draft are still here."
        ),
        canDraft: true,
        isDrafting: false,
        isCareful: false,
        minHeight: 500,
        onRetry: {},
        onBack: {}
    )
    .padding()
}
