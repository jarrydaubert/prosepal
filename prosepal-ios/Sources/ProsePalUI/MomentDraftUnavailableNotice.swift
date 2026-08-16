import Foundation
import ProsePalAPI

public enum MomentDraftUnavailableReason: Equatable, Sendable {
    case offline
    case onlineWritingPermissionRequired
    case timedOut(lane: GenerationTimeoutLane)
    case rateLimited
    case usageLimitReached
    case contentBlocked
    case serviceUnavailable
    case unexpectedResponse
    case unexpected

    init(_ error: GenerationError) {
        switch error {
        case .offline:
            self = .offline
        case .onlineWritingPermissionRequired:
            self = .onlineWritingPermissionRequired
        case .timedOut(let lane):
            self = .timedOut(lane: lane)
        case .rateLimited, .requestNeedsFreshKey:
            self = .rateLimited
        case .usageLimitReached:
            self = .usageLimitReached
        case .contentBlocked:
            self = .contentBlocked
        case .serviceUnavailable:
            self = .serviceUnavailable
        case .unexpectedResponse:
            self = .unexpectedResponse
        }
    }
}

struct MomentDraftUnavailableNotice {
    var title: String
    var detail: String
    var systemImage: String
    var canRetry: Bool

    static let offline = MomentDraftUnavailableNotice(
        title: String(localized: "Connection needed"),
        detail: String(localized: "Private Draft could not finish offline on this device. Check your connection and try again."),
        systemImage: "wifi.slash",
        canRetry: true
    )
}

struct MomentGenerationErrorPresentation {
    let title: String
    let detail: String
    let systemImage: String
    let actionTitle: String
    let actionSystemImage: String
    let actionAccessibilityIdentifier: String

    init(reason: MomentDraftUnavailableReason?, errorMessage: String?) {
        if reason == .onlineWritingPermissionRequired {
            title = "Online writing is off"
            detail = errorMessage ?? "Allow online writing to continue. Your Moment is still here."
            systemImage = "network.slash"
            actionTitle = "Review Online Writing"
            actionSystemImage = "hand.raised"
            actionAccessibilityIdentifier = "onlineWriting.permission.retry"
        } else {
            title = "That didn't go through"
            detail = "We couldn't finish your draft just now. Your note is safe — nothing was lost."
            systemImage = "exclamationmark.triangle.fill"
            actionTitle = "Try again"
            actionSystemImage = "arrow.clockwise"
            actionAccessibilityIdentifier = "moment.generation.retry"
        }
    }
}
