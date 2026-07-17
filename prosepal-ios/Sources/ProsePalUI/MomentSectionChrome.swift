import SwiftUI

struct MomentBottomRailClearance: View {
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.prosePalReduceTransparencyOverride) private var reduceTransparencyOverride

    let isCareful: Bool

    var body: some View {
        Group {
            if shouldReduceTransparency {
                Color.momentGroupedBackground
            } else {
                clearanceGradient
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private var clearanceGradient: some View {
        LinearGradient(
            stops: [
                .init(color: Color.momentGroupedBackground.opacity(0), location: 0),
                .init(color: Color.momentGroupedBackground.opacity(0.06), location: 0.48),
                .init(color: Color.momentGroupedBackground.opacity(0.24), location: 1)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .overlay(alignment: .bottom) {
            (isCareful ? Color.prosePalCare : Color.prosePalCoral)
                .opacity(0.035)
                .frame(height: 34)
                .blur(radius: 12)
        }
    }

    private var shouldReduceTransparency: Bool {
        reduceTransparency || reduceTransparencyOverride
    }
}

struct MomentSectionLabel: View {
    let title: String
    let systemImage: String
    var isCareful: Bool = false

    var body: some View {
        HStack(alignment: .center, spacing: 9) {
            MomentSymbolBadge(
                systemImage: systemImage,
                style: isCareful ? .care : .subtle,
                size: 28
            )

            Text(title)
        }
            .font(.headline)
            .foregroundStyle(isCareful ? Color.prosePalCare : Color.primary)
            .accessibilityElement(children: .combine)
    }
}

struct MomentListSectionHeader: View {
    let title: String

    init(_ title: String) {
        self.title = title
    }

    var body: some View {
        Text(title.uppercased())
            .font(.caption2.weight(.bold))
            .tracking(0.7)
            .foregroundStyle(Color.white.opacity(0.66))
            .padding(.leading, 2)
            .padding(.bottom, 2)
    }
}
