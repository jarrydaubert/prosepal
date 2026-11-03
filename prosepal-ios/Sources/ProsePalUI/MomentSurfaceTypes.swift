import SwiftUI

enum MomentSurfaceProminence {
    case standard
    case elevated
    case accent
    case warning
}

enum MomentDraftRevisionTab: String, CaseIterable, Identifiable, Sendable {
    case draft
    case original

    var id: String { rawValue }

    var title: String {
        switch self {
        case .draft:
            String(localized: "Draft")
        case .original:
            String(localized: "Original")
        }
    }
}
