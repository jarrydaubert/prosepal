import SwiftUI

enum MomentSymbolBadgeStyle {
    case hero
    case heroCare
    case coral
    case navy
    case care
    case subtle
    case warning
}

struct MomentSymbolBadge: View {
    let systemImage: String
    var style: MomentSymbolBadgeStyle = .coral
    var size: CGFloat = 32

    var body: some View {
        RoundedRectangle(cornerRadius: max(10, size * 0.34), style: .continuous)
            .fill(fill)
            .overlay {
                RoundedRectangle(cornerRadius: max(10, size * 0.34), style: .continuous)
                    .stroke(strokeColor, lineWidth: 1)
            }
            .overlay {
                Image(systemName: systemImage)
                    .font(.system(size: max(12, size * 0.42), weight: .semibold))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(foregroundColor)
                    .frame(width: size, height: size)
            }
            .frame(width: size, height: size)
            .accessibilityHidden(true)
    }

    private var fill: LinearGradient {
        switch style {
        case .hero:
            LinearGradient(
                colors: [
                    Color.prosePalCoral,
                    Color.prosePalCoralDeep
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .heroCare:
            LinearGradient(
                colors: [
                    Color.prosePalCare,
                    Color.prosePalCoralDeep.opacity(0.86)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .coral:
            LinearGradient(
                colors: [
                    Color.prosePalCoral.opacity(0.20),
                    Color.prosePalPaper.opacity(0.92)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .navy:
            LinearGradient(
                colors: [
                    Color.prosePalPaper,
                    Color.prosePalCard
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .care:
            LinearGradient(
                colors: [
                    Color.prosePalCare.opacity(0.22),
                    Color.prosePalPaper.opacity(0.90)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .subtle:
            LinearGradient(
                colors: [
                    Color.prosePalPaper.opacity(0.92),
                    Color.prosePalCard.opacity(0.80)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .warning:
            LinearGradient(
                colors: [
                    Color.prosePalWarning.opacity(0.22),
                    Color.prosePalPaper.opacity(0.90)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    private var foregroundColor: Color {
        switch style {
        case .hero, .heroCare:
            .white
        case .navy:
            .prosePalInk
        case .care:
            .prosePalCare
        case .warning:
            .prosePalWarning
        case .coral, .subtle:
            .prosePalCoralDeep
        }
    }

    private var strokeColor: Color {
        switch style {
        case .hero, .heroCare:
            Color.white.opacity(0.34)
        case .navy:
            Color.prosePalNavy.opacity(0.12)
        case .care:
            Color.prosePalCare.opacity(0.20)
        case .warning:
            Color.prosePalWarning.opacity(0.22)
        case .coral:
            Color.prosePalCoral.opacity(0.20)
        case .subtle:
            Color.prosePalNavy.opacity(0.10)
        }
    }
}
