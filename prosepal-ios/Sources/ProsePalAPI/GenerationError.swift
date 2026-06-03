import Foundation

public enum GenerationError: Error, Equatable, Sendable {
    case offline
    case timedOut
    case rateLimited(message: String)
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
        case .timedOut:
            "This is taking longer than expected. Please try again."
        case .rateLimited(let message),
             .usageLimitReached(let message),
             .contentBlocked(let message),
             .serviceUnavailable(let message),
             .unexpectedResponse(let message):
            message
        }
    }
}

