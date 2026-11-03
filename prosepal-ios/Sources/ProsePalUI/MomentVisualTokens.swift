import SwiftUI
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

private struct ProsePalReduceTransparencyOverrideKey: EnvironmentKey {
    static let defaultValue = false
}

public extension EnvironmentValues {
    var prosePalReduceTransparencyOverride: Bool {
        get { self[ProsePalReduceTransparencyOverrideKey.self] }
        set { self[ProsePalReduceTransparencyOverrideKey.self] = newValue }
    }
}

enum ProsePalRadius {
    static let xs: CGFloat = 6
    static let small: CGFloat = 10
    static let medium: CGFloat = 14
    static let large: CGFloat = 18
    static let extraLarge: CGFloat = 22
    static let twoExtraLarge: CGFloat = 28
    static let threeExtraLarge: CGFloat = 36
    static let capsule: CGFloat = 999

    static let button = capsule
    static let chip = capsule
    static let field: CGFloat = 16
    static let card = extraLarge
    static let sheet = twoExtraLarge
    static let canvas: CGFloat = 20
}

enum ProsePalElevation {
    case extraSmall
    case small
    case medium
    case large
    case glass
    case accent(Color)
}

extension View {
    func prosePalElevation(_ elevation: ProsePalElevation) -> some View {
        modifier(ProsePalElevationModifier(elevation: elevation))
    }
}

private struct ProsePalElevationModifier: ViewModifier {
    let elevation: ProsePalElevation

    func body(content: Content) -> some View {
        switch elevation {
        case .extraSmall:
            content
                .shadow(color: Color.prosePalShadow.opacity(0.05), radius: 1.5, x: 0, y: 1)
        case .small:
            content
                .shadow(color: Color.prosePalShadow.opacity(0.06), radius: 2, x: 0, y: 1)
                .shadow(color: Color.prosePalShadow.opacity(0.05), radius: 6, x: 0, y: 2)
        case .medium:
            content
                .shadow(color: Color.prosePalShadow.opacity(0.06), radius: 4, x: 0, y: 2)
                .shadow(color: Color.prosePalShadow.opacity(0.08), radius: 20, x: 0, y: 8)
        case .large:
            content
                .shadow(color: Color.prosePalShadow.opacity(0.06), radius: 8, x: 0, y: 4)
                .shadow(color: Color.prosePalShadow.opacity(0.12), radius: 40, x: 0, y: 16)
        case .glass:
            content
                .shadow(color: Color.prosePalGlassShadow.opacity(0.16), radius: 44, x: 0, y: 14)
        case let .accent(color):
            content
                .shadow(color: color.opacity(0.22), radius: 24, x: 0, y: 6)
        }
    }
}

extension Color {
    static var momentGroupedBackground: Color {
        Color(red: 0.970, green: 0.940, blue: 0.893)
    }

    static var momentSecondaryGroupedBackground: Color {
        Color(red: 0.958, green: 0.924, blue: 0.872)
    }

    static var prosePalPaper: Color {
        prosePalSurface
    }

    static var prosePalCard: Color {
        prosePalSurface2
    }

    static var prosePalSurface: Color {
        Color(red: 0.997, green: 0.978, blue: 0.946)
    }

    static var prosePalSurface2: Color {
        Color(red: 0.982, green: 0.960, blue: 0.922)
    }

    static var prosePalSurfaceSunken: Color {
        Color(red: 0.960, green: 0.930, blue: 0.883)
    }

    static var prosePalSeparator: Color {
        Color(red: 0.880, green: 0.847, blue: 0.803)
    }

    static var prosePalBorder: Color {
        Color(red: 0.846, green: 0.808, blue: 0.760)
    }

    static var prosePalBorderStrong: Color {
        Color(red: 0.780, green: 0.736, blue: 0.685)
    }

    static var prosePalCoralCard: Color {
        prosePalAccentSoft2
    }

    static var prosePalCareCard: Color {
        Color(red: 0.930, green: 0.966, blue: 0.935)
    }

    static var prosePalWarningCard: Color {
        Color(red: 0.897, green: 0.709, blue: 0.408).opacity(0.22)
    }

    static var prosePalNavy: Color {
        prosePalInk
    }

    static var prosePalSlate: Color {
        Color(red: 0.334, green: 0.307, blue: 0.285)
    }

    static var prosePalInk: Color {
        Color(red: 0.145, green: 0.122, blue: 0.103)
    }

    static var prosePalCoral: Color {
        Color(red: 0.615, green: 0.314, blue: 0.207)
    }

    static var prosePalCoralDeep: Color {
        Color(red: 0.465, green: 0.221, blue: 0.151)
    }

    static var prosePalAccentText: Color {
        Color(red: 0.539, green: 0.258, blue: 0.171)
    }

    static var prosePalAccentHover: Color {
        Color(red: 0.544, green: 0.263, blue: 0.175)
    }

    static var prosePalAccentSoft: Color {
        Color(red: 0.972, green: 0.889, blue: 0.833)
    }

    static var prosePalAccentSoft2: Color {
        Color(red: 0.959, green: 0.827, blue: 0.751)
    }

    static var prosePalTextOnAccent: Color {
        Color(red: 0.984, green: 0.965, blue: 0.933)
    }

    static var prosePalCare: Color {
        Color(red: 0.306, green: 0.424, blue: 0.350)
    }

    static var prosePalCareSurface: Color {
        Color.prosePalCare.opacity(0.14)
    }

    static var prosePalWarning: Color {
        Color(red: 0.615, green: 0.403, blue: 0.182)
    }

    static var prosePalDanger: Color {
        Color(red: 0.739, green: 0.289, blue: 0.249)
    }

    static var prosePalInfo: Color {
        Color(red: 0.243, green: 0.374, blue: 0.520)
    }

    static var prosePalGlassFill: Color {
        Color(red: 1.000, green: 0.980, blue: 0.937).opacity(0.60)
    }

    static var prosePalGlassFill2: Color {
        Color(red: 1.000, green: 0.980, blue: 0.937).opacity(0.42)
    }

    static var prosePalGlassStroke: Color {
        Color.white.opacity(0.60)
    }

    static var prosePalGlassStrokeSoft: Color {
        Color.white.opacity(0.32)
    }

    static var prosePalShadow: Color {
        Color(red: 0.213, green: 0.169, blue: 0.145)
    }

    static var prosePalGlassShadow: Color {
        Color(red: 0.413, green: 0.257, blue: 0.203)
    }
}

func playMomentSelectionFeedback() {
    #if canImport(UIKit)
    UISelectionFeedbackGenerator().selectionChanged()
    #endif
}
