import SwiftUI

extension View {
    func prosePalMomentCard(
        isCareful: Bool = false,
        prominence: MomentSurfaceProminence = .standard
    ) -> some View {
        self
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                MomentCardBackground(isCareful: isCareful, prominence: prominence)
            }
    }

    func momentInputSurface(isCareful: Bool = false, cornerRadius: CGFloat = 16) -> some View {
        self
            .background {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.prosePalPaper,
                                Color.prosePalCard
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.62),
                                        (isCareful ? Color.prosePalCare : Color.prosePalCoral).opacity(0.22),
                                        Color.prosePalNavy.opacity(0.12)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    }
            }
    }

    func momentListRowSurface(isCareful: Bool = false) -> some View {
        self
            .listRowBackground(
                LinearGradient(
                    colors: [
                        Color.prosePalPaper,
                        Color.prosePalCard,
                        isCareful ? Color.prosePalCareCard : Color.prosePalCoralCard
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
    }

    @ViewBuilder
    func momentPickerListStyle() -> some View {
        #if os(iOS)
        self.listStyle(.insetGrouped)
        #else
        self
        #endif
    }

    @ViewBuilder
    func momentNameInputBehavior() -> some View {
        #if os(iOS)
        self.textInputAutocapitalization(.words)
        #else
        self
        #endif
    }

    @ViewBuilder
    func momentTabBarVisibility(isVisible: Bool) -> some View {
        #if os(iOS)
        self.toolbar(isVisible ? .visible : .hidden, for: .tabBar)
        #else
        self
        #endif
    }

    @ViewBuilder
    func momentNavigationBarColorScheme() -> some View {
        #if os(iOS)
        self.toolbarColorScheme(.light, for: .navigationBar)
        #else
        self
        #endif
    }

    @ViewBuilder
    func momentControlBarSurface() -> some View {
        self.modifier(MomentControlBarSurfaceModifier())
    }
}

private struct MomentControlBarSurfaceModifier: ViewModifier {
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.prosePalReduceTransparencyOverride) private var reduceTransparencyOverride

    func body(content: Content) -> some View {
        if reduceTransparency || reduceTransparencyOverride {
            content
                .padding(8)
                .background {
                    RoundedRectangle(cornerRadius: 30, style: .continuous)
                        .fill(Color.prosePalPaper)
                        .overlay {
                            RoundedRectangle(cornerRadius: 30, style: .continuous)
                                .stroke(Color.prosePalNavy.opacity(0.18), lineWidth: 1)
                        }
                }
        } else {
            defaultSurface(content: content)
        }
    }

    @ViewBuilder
    private func defaultSurface(content: Content) -> some View {
        #if os(iOS) || os(macOS) || os(tvOS) || os(watchOS)
        if #available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, *) {
            content
                .padding(8)
                .glassEffect(
                    .regular.tint(Color.prosePalPaper.opacity(0.44)).interactive(),
                    in: .rect(cornerRadius: 30)
                )
        } else {
            barSurface(content: content)
        }
        #else
        barSurface(content: content)
        #endif
    }

    private func barSurface(content: Content) -> some View {
        content
            .background(.bar)
            .overlay(alignment: .top) {
                Divider()
            }
    }
}
