import ProsePalDomain
import SwiftUI

struct MomentRegisterSelector: View {
    @Binding var selection: MomentRegister
    let registers: [MomentRegister]
    let isCareful: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text("How should it read?")
                    .font(.system(.title3, design: .serif).weight(.medium))
                    .foregroundStyle(Color.prosePalInk)

                Spacer(minLength: 12)

                Text("Pick one")
                    .font(.caption)
                    .foregroundStyle(Color.prosePalSlate)
            }

            ViewThatFits(in: .horizontal) {
                HStack(spacing: 8) {
                    registerButtons
                }

                VStack(spacing: 8) {
                    registerButtons
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityHint(selection.userSafeDescription)
        .animation(.spring(response: 0.34, dampingFraction: 0.82), value: selection)
        .animation(.spring(response: 0.34, dampingFraction: 0.82), value: registers.map(\.rawValue).joined())
    }

    @ViewBuilder
    private var registerButtons: some View {
        ForEach(registers) { register in
            Button {
                selection = register
                playMomentSelectionFeedback()
            } label: {
                MomentRegisterOption(
                    register: register,
                    isSelected: selection == register,
                    isCareful: isCareful
                )
            }
            .buttonStyle(.plain)
        }
    }
}

private struct MomentRegisterOption: View {
    let register: MomentRegister
    let isSelected: Bool
    let isCareful: Bool

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: register.systemImage)
                .font(.caption.weight(.bold))
                .symbolRenderingMode(.hierarchical)

            Text(register.displayName)
                .font(.footnote.weight(.semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.72)
        }
        .foregroundStyle(isSelected ? Color.white : Color.primary)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity)
        .background {
            Capsule(style: .continuous)
                .fill(backgroundFill)
        }
        .overlay {
            Capsule(style: .continuous)
                .stroke(
                    isSelected ? Color.white.opacity(0.24) : accentColor.opacity(0.20),
                    lineWidth: 1
                )
        }
        .scaleEffect(isSelected ? 1 : 0.98)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }

    private var accentColor: Color {
        isCareful ? .prosePalCare : .prosePalCoral
    }

    private var backgroundFill: LinearGradient {
        if isSelected {
            return LinearGradient(
                colors: isCareful
                    ? [Color.prosePalCare, Color.prosePalNavy.opacity(0.92)]
                    : [Color.prosePalCoral, Color.prosePalCoralDeep],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }

        return LinearGradient(
            colors: [
                Color.prosePalPaper.opacity(0.82),
                Color.momentSecondaryGroupedBackground.opacity(0.88)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

extension MomentRegister {
    var systemImage: String {
        switch self {
        case .react:
            "bolt.fill"
        case .confess:
            "pencil"
        case .assemble:
            "heart.text.square"
        }
    }
}
