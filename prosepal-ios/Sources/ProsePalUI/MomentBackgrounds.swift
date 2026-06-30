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
                    Color(red: 0.966, green: 0.925, blue: 0.830),
                    Color(red: 0.944, green: 0.880, blue: 0.765)
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
        RoundedRectangle(cornerRadius: 28, style: .continuous)
            .fill(fill)
            .overlay {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.78),
                                Color.prosePalCoral.opacity(0.16),
                                (isCareful ? Color.prosePalCare : Color.prosePalCoral).opacity(0.26)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
            .shadow(color: Color.prosePalCoralDeep.opacity(0.12), radius: 18, x: 0, y: 10)
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
                    Color.prosePalCareCard,
                    Color.prosePalCard
                ]
                : [
                    Color.prosePalPaper,
                    Color.prosePalCoralCard,
                    Color.prosePalCard
                ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
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
        let shape = RoundedRectangle(cornerRadius: 22, style: .continuous)

        shape
            .fill(cardFill)
            .overlay {
                shape.stroke(borderFill, lineWidth: borderWidth)
            }
            .shadow(
                color: shadowColor,
                radius: prominence == .elevated ? 18 : 10,
                x: 0,
                y: prominence == .elevated ? 10 : 5
            )
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
                    Color.prosePalCoralCard,
                    Color.prosePalPaper,
                    Color.prosePalCard
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .warning:
            return LinearGradient(
                colors: [
                    Color.prosePalWarningCard,
                    Color.prosePalPaper,
                    Color.prosePalCard
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .standard, .elevated:
            return LinearGradient(
                colors: isCareful
                    ? [
                        Color.prosePalCareCard,
                        Color.prosePalPaper,
                        Color.prosePalCard
                    ]
                    : [
                        Color.prosePalCard,
                        Color.prosePalPaper,
                        Color.prosePalCoralCard
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
                Color.white.opacity(0.64),
                Color.prosePalNavy.opacity(prominence == .standard ? 0.18 : 0.28),
                accentColor.opacity(prominence == .standard ? 0.18 : 0.32)
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
        prominence == .standard ? 0.8 : 1
    }

    private var shadowColor: Color {
        if shouldReduceTransparency {
            return Color.clear
        }

        switch prominence {
        case .warning:
            return Color.prosePalWarning.opacity(0.12)
        default:
            return Color.black.opacity(prominence == .elevated ? 0.18 : 0.10)
        }
    }

    private var shouldReduceTransparency: Bool {
        reduceTransparency || reduceTransparencyOverride
    }
}
