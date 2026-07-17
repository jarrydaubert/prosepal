import Foundation
import ProsePalAPI

public enum MomentDraftUnavailableReason: Equatable, Sendable {
    case offline
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
