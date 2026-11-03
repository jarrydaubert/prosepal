import Foundation

public enum GenerationTimeoutLane: Equatable, Sendable {
    case onDevice
    case gateway
    case total
}

public enum GenerationError: Error, Equatable, Sendable {
    case offline
    case onlineWritingPermissionRequired
    case timedOut(lane: GenerationTimeoutLane)
    case rateLimited(message: String)
    case requestNeedsFreshKey(message: String)
    case usageLimitReached(message: String)
    case contentBlocked(message: String)
    case serviceUnavailable(message: String)
    case unexpectedResponse(message: String)
}

public extension GenerationError {
    var userSafeMessage: String {
        switch self {
        case .offline:
            "You appear to be offline. Please check your connection and try again."
        case .onlineWritingPermissionRequired:
            String(localized: "Allow online writing to continue. Your Moment and current draft are still here.")
        case .timedOut(let lane):
            switch lane {
            case .onDevice:
                String(localized: "On-device writing took too long. Your note is still here, so you can try again.")
            case .gateway:
                String(localized: "ProsePal could not finish this draft in time. Your note is still here, so you can try again.")
            case .total:
                String(localized: "This draft took too long to finish. Your note is still here, so you can try again.")
            }
        case .rateLimited(let message),
             .requestNeedsFreshKey(let message),
             .usageLimitReached(let message),
             .contentBlocked(let message),
             .serviceUnavailable(let message),
             .unexpectedResponse(let message):
            message
        }
    }

    var diagnosticsCategory: String {
        switch self {
        case .offline:
            "offline"
        case .onlineWritingPermissionRequired:
            "online_writing_permission_required"
        case .timedOut:
            "timeout"
        case .rateLimited:
            "rate_limited"
        case .requestNeedsFreshKey:
            "request_needs_fresh_key"
        case .usageLimitReached:
            "usage_limit"
        case .contentBlocked:
            "content_blocked"
        case .serviceUnavailable:
            "service_unavailable"
        case .unexpectedResponse:
            "unexpected_response"
        }
    }
}
