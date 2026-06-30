import SwiftUI

enum MomentIdentityCardStyle {
    case hero
    case quiet
}

struct MomentScreenIdentityCard: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.prosePalReduceTransparencyOverride) private var reduceTransparencyOverride

    let eyebrow: String
    let title: String
    let detail: String
    let systemImage: String
    var isCareful: Bool = false
    var style: MomentIdentityCardStyle = .hero

    var body: some View {
        Group {
            switch style {
            case .hero:
                heroCard
            case .quiet:
                quietCard
            }
        }
        .accessibilityElement(children: .combine)
    }

    private var heroCard: some View {
        HStack(alignment: .center, spacing: 16) {
            MomentSymbolBadge(
                systemImage: systemImage,
                style: isCareful ? .heroCare : .hero,
                size: 54
            )

            VStack(alignment: .leading, spacing: 6) {
                Text(eyebrow.uppercased())
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(accentColor)

                Text(title)
                    .font(.system(.title2, design: .serif).weight(.bold))
                    .foregroundStyle(Color.prosePalInk)
                    .fixedSize(horizontal: false, vertical: true)

                Text(detail)
                    .font(.callout)
                    .foregroundStyle(Color.prosePalSlate)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            MomentHeroBackground(isCareful: isCareful)
        }
    }

    private var quietCard: some View {
        HStack(alignment: .center, spacing: 14) {
            MomentSymbolBadge(
                systemImage: systemImage,
                style: isCareful ? .care : .coral,
                size: 50
            )

            VStack(alignment: .leading, spacing: 5) {
                Text(eyebrow.uppercased())
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(accentColor)

                Text(title)
                    .font(.system(.title3, design: .serif).weight(.bold))
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)

                Text(detail)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(quietCardFill)
                .overlay {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(colorScheme == .dark ? 0.18 : 0.52),
                                    Color.prosePalNavy.opacity(colorScheme == .dark ? 0.24 : 0.10),
                                    accentColor.opacity(colorScheme == .dark ? 0.18 : 0.10)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                }
                .shadow(color: Color.prosePalNavy.opacity(colorScheme == .dark ? 0.16 : 0.08), radius: 14, x: 0, y: 8)
        }
    }

    private var quietCardFill: Color {
        if shouldReduceTransparency {
            return Color.prosePalPaper
        }

        return Color.prosePalPaper.opacity(0.86)
    }

    private var shouldReduceTransparency: Bool {
        reduceTransparency || reduceTransparencyOverride
    }

    private var accentColor: Color {
        isCareful ? Color.prosePalCare : Color.prosePalCoral
    }
}
