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

                Text("Choose one")
                    .font(.caption)
                    .foregroundStyle(Color.prosePalSlate)
            }

            ViewThatFits(in: .horizontal) {
                HStack(spacing: 9) {
                    registerButtons
                }

                VStack(spacing: 9) {
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
        HStack(spacing: 7) {
            Image(systemName: register.systemImage)
                .font(.caption2.weight(.semibold))
                .symbolRenderingMode(.hierarchical)

            Text(register.displayName)
                .font(.caption.weight(.semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.76)
        }
        .foregroundStyle(isSelected ? Color.prosePalTextOnAccent : Color.prosePalSlate)
        .padding(.horizontal, 13)
        .frame(height: 36)
        .frame(maxWidth: .infinity)
        .background {
            Capsule(style: .continuous)
                .fill(backgroundFill)
        }
        .overlay {
            Capsule(style: .continuous)
                .stroke(Color.prosePalGlassStrokeSoft, lineWidth: 0.5)
        }
        .prosePalElevation(isSelected ? .accent(accentColor) : .extraSmall)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }

    private var accentColor: Color {
        isCareful ? .prosePalCare : .prosePalCoral
    }

    private var backgroundFill: LinearGradient {
        if isSelected {
            return LinearGradient(
                colors: isCareful
                    ? [Color.prosePalCare, Color.prosePalCare.opacity(0.94)]
                    : [Color.prosePalCoral, Color.prosePalAccentHover],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }

        return LinearGradient(
            colors: [
                Color.prosePalGlassFill2,
                Color.prosePalPaper.opacity(0.36)
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
