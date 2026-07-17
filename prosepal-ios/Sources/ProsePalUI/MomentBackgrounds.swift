import SwiftUI

struct MomentAtmosphericBackground: View {
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.prosePalReduceTransparencyOverride) private var reduceTransparencyOverride

    let isCareful: Bool

    var body: some View {
        Group {
            if shouldReduceTransparency {
                Color.momentGroupedBackground
            } else {
                atmosphericGradient
            }
        }
        .ignoresSafeArea()
    }

    private var atmosphericGradient: some View {
        ZStack {
            Color.momentGroupedBackground

            LinearGradient(
                colors: [
                    Color.momentGroupedBackground,
                    Color.momentSecondaryGroupedBackground
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            RadialGradient(
                colors: [
                    Color.prosePalCoral.opacity(0.16),
                    Color.clear
                ],
                center: .topLeading,
                startRadius: 24,
                endRadius: 300
            )

            RadialGradient(
                colors: [
                    Color.prosePalCare.opacity(isCareful ? 0.18 : 0.10),
                    Color.clear
                ],
                center: .bottomTrailing,
                startRadius: 20,
                endRadius: 330
            )

            LinearGradient(
                colors: [
                    Color.white.opacity(0.34),
                    Color.clear,
                    Color.prosePalCoralDeep.opacity(0.08)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }

    private var shouldReduceTransparency: Bool {
        reduceTransparency || reduceTransparencyOverride
    }
}

struct MomentHeroBackground: View {
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.prosePalReduceTransparencyOverride) private var reduceTransparencyOverride

    let isCareful: Bool

    var body: some View {
        RoundedRectangle(cornerRadius: ProsePalRadius.sheet, style: .continuous)
            .fill(fill)
            .overlay {
                RoundedRectangle(cornerRadius: ProsePalRadius.sheet, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.prosePalGlassStroke,
                                Color.prosePalAccentSoft.opacity(0.54),
                                accentColor.opacity(0.24)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.5
                    )
            }
            .prosePalElevation(.medium)
    }

    private var fill: LinearGradient {
        if shouldReduceTransparency {
            return LinearGradient(
                colors: [Color.prosePalPaper, Color.prosePalPaper],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }

        return LinearGradient(
            colors: isCareful
                ? [
                    Color.prosePalPaper,
                    Color.prosePalCareCard.opacity(0.88),
                    Color.prosePalSurface2
                ]
                : [
                    Color.prosePalPaper,
                    Color.prosePalAccentSoft.opacity(0.82),
                    Color.prosePalSurface2
                ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var accentColor: Color {
        isCareful ? Color.prosePalCare : Color.prosePalCoral
    }

    private var shouldReduceTransparency: Bool {
        reduceTransparency || reduceTransparencyOverride
    }
}

struct MomentCardBackground: View {
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.prosePalReduceTransparencyOverride) private var reduceTransparencyOverride

    let isCareful: Bool
    let prominence: MomentSurfaceProminence

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: ProsePalRadius.card, style: .continuous)

        let surface = shape
            .fill(cardFill)
            .overlay {
                shape.stroke(borderFill, lineWidth: borderWidth)
            }

        if shouldReduceTransparency {
            surface
        } else {
            surface.prosePalElevation(prominence == .elevated ? .medium : .small)
        }
    }

    private var cardFill: LinearGradient {
        if shouldReduceTransparency {
            return LinearGradient(
                colors: [reduceTransparencyFill, reduceTransparencyFill],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }

        switch prominence {
        case .accent:
            return LinearGradient(
                colors: [
                    Color.prosePalPaper,
                    Color.prosePalAccentSoft.opacity(0.76),
                    Color.prosePalSurface2
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .warning:
            return LinearGradient(
                colors: [
                    Color.prosePalPaper,
                    Color.prosePalWarningCard,
                    Color.prosePalCard
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .standard, .elevated:
            return LinearGradient(
                colors: isCareful
                    ? [
                        Color.prosePalPaper,
                        Color.prosePalCareCard.opacity(0.84),
                        Color.prosePalSurface2
                    ]
                    : [
                        Color.prosePalPaper,
                        Color.prosePalSurface2,
                        Color.prosePalAccentSoft.opacity(0.54)
                    ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    private var borderFill: LinearGradient {
        if shouldReduceTransparency {
            return LinearGradient(
                colors: [accentColor, accentColor],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }

        return LinearGradient(
            colors: [
                Color.prosePalGlassStroke,
                Color.prosePalBorder.opacity(prominence == .standard ? 0.62 : 0.78),
                accentColor.opacity(prominence == .standard ? 0.18 : 0.30)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var accentColor: Color {
        switch prominence {
        case .warning:
            Color.prosePalWarning
        default:
            isCareful ? Color.prosePalCare : Color.prosePalCoral
        }
    }

    private var reduceTransparencyFill: Color {
        switch prominence {
        case .warning:
            Color.prosePalWarningCard
        case .accent:
            isCareful ? Color.prosePalCareCard : Color.prosePalCoralCard
        case .standard, .elevated:
            Color.prosePalPaper
        }
    }

    private var borderWidth: CGFloat {
        prominence == .standard ? 0.5 : 1
    }

    private var shouldReduceTransparency: Bool {
        reduceTransparency || reduceTransparencyOverride
    }
}
