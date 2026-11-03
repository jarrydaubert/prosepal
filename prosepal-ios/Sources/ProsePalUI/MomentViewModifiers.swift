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

    func momentInputSurface(isCareful: Bool = false, cornerRadius: CGFloat = ProsePalRadius.field) -> some View {
        self
            .background {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.prosePalPaper,
                                Color.prosePalSurfaceSunken
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
                                        Color.prosePalGlassStroke,
                                        (isCareful ? Color.prosePalCare : Color.prosePalCoral).opacity(0.22),
                                        Color.prosePalBorder.opacity(0.70)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 0.5
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
                        Color.prosePalSurface2,
                        isCareful ? Color.prosePalCareCard : Color.prosePalAccentSoft
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
            .textContentType(.name)
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
                    RoundedRectangle(cornerRadius: ProsePalRadius.capsule, style: .continuous)
                        .fill(Color.prosePalPaper)
                        .overlay {
                            RoundedRectangle(cornerRadius: ProsePalRadius.capsule, style: .continuous)
                                .stroke(Color.prosePalBorder, lineWidth: 0.5)
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
                    .regular.tint(Color.prosePalGlassFill).interactive(),
                    in: .rect(cornerRadius: ProsePalRadius.capsule)
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
