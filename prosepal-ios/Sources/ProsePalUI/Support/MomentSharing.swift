import Foundation

enum MomentTextShareAction: String, CaseIterable, Equatable, Sendable {
    case copy
    case share

    var title: String {
        switch self {
        case .copy:
            String(localized: "Copy")
        case .share:
            String(localized: "Share")
        }
    }

    var systemImage: String {
        switch self {
        case .copy:
            "doc.on.doc"
        case .share:
            "square.and.arrow.up"
        }
    }
}

enum MomentTextShareSurface: String, Equatable, Sendable {
    case activeDraft
    case savedDraft

    func accessibilityIdentifier(for action: MomentTextShareAction) -> String {
        "\(rawValue).\(action.rawValue)"
    }
}

struct MomentTextSharePresentation: Equatable, Sendable {
    let text: String
    let surface: MomentTextShareSurface

    static let actions = MomentTextShareAction.allCases

    func accessibilityIdentifier(for action: MomentTextShareAction) -> String {
        surface.accessibilityIdentifier(for: action)
    }

    @discardableResult
    func copy(using writeToClipboard: (String) -> Void) -> MomentShareInteraction {
        writeToClipboard(text)
        return .copyCompleted
    }
}

enum MomentShareInteraction: Equatable, Sendable {
    case copyCompleted
    case sharePresented
    case shareCancelled
}

enum MomentShareTelemetryPolicy {
    static func diagnosticsAction(for interaction: MomentShareInteraction) -> String? {
        switch interaction {
        case .copyCompleted:
            "copy"
        case .sharePresented, .shareCancelled:
            nil
        }
    }
}
