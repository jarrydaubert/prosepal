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

extension Color {
    static var momentGroupedBackground: Color {
        Color(red: 0.957, green: 0.925, blue: 0.850)
    }

    static var momentSecondaryGroupedBackground: Color {
        Color(red: 0.945, green: 0.890, blue: 0.800)
    }

    static var prosePalPaper: Color {
        Color(red: 0.985, green: 0.956, blue: 0.890)
    }

    static var prosePalCard: Color {
        Color(red: 0.971, green: 0.925, blue: 0.830)
    }

    static var prosePalCoralCard: Color {
        Color(red: 0.930, green: 0.850, blue: 0.750)
    }

    static var prosePalCareCard: Color {
        Color(red: 0.900, green: 0.930, blue: 0.865)
    }

    static var prosePalWarningCard: Color {
        Color(red: 0.965, green: 0.890, blue: 0.760)
    }

    static var prosePalNavy: Color {
        Color(red: 0.225, green: 0.195, blue: 0.165)
    }

    static var prosePalSlate: Color {
        Color(red: 0.400, green: 0.360, blue: 0.315)
    }

    static var prosePalInk: Color {
        Color(red: 0.170, green: 0.145, blue: 0.120)
    }

    static var prosePalCoral: Color {
        Color(red: 0.560, green: 0.310, blue: 0.220)
    }

    static var prosePalCoralDeep: Color {
        Color(red: 0.400, green: 0.220, blue: 0.160)
    }

    static var prosePalCare: Color {
        Color(red: 0.390, green: 0.540, blue: 0.410)
    }

    static var prosePalCareSurface: Color {
        Color.prosePalCare.opacity(0.14)
    }

    static var prosePalWarning: Color {
        Color(red: 0.620, green: 0.420, blue: 0.150)
    }
}

func playMomentSelectionFeedback() {
    #if canImport(UIKit)
    UISelectionFeedbackGenerator().selectionChanged()
    #endif
}
