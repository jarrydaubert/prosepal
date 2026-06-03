import Foundation

public enum Occasion: String, Codable, CaseIterable, Sendable, Identifiable {
    case birthday
    case anniversary
    case sympathy
    case apology
    case thankYou
    case congratulations
    case wedding
    case newBaby
    case friendship
    case work
    case getWell
    case thinkingOfYou

    public var id: String { rawValue }
}

public enum Relationship: String, Codable, CaseIterable, Sendable, Identifiable {
    case parent
    case partner
    case friend
    case sibling
    case child
    case colleague
    case manager
    case extendedFamily
    case acquaintance
    case other

    public var id: String { rawValue }
}

public enum Tone: String, Codable, CaseIterable, Sendable, Identifiable {
    case warm
    case heartfelt
    case funny
    case formal
    case simple
    case romantic
    case encouraging
    case thoughtful
    case apologetic

    public var id: String { rawValue }
}

public enum MessageLength: String, Codable, CaseIterable, Sendable, Identifiable {
    case short
    case standard
    case longer

    public var id: String { rawValue }
}

public enum GenerationLane: String, Codable, CaseIterable, Sendable {
    case automatic
    case standard
    case premium
    case local
    case template
}

public enum FallbackStatus: String, Codable, Sendable {
    case none
    case degradedToStandard
    case degradedToTemplate
    case failed
}

public enum RetryEligibility: String, Codable, Sendable {
    case eligible
    case ineligible
    case waitBeforeRetry
}

public struct CardIntent: Codable, Equatable, Sendable {
    public var occasion: Occasion
    public var relationship: Relationship
    public var tone: Tone
    public var length: MessageLength
    public var localeIdentifier: String
    public var recipientName: String?
    public var thingsToInclude: [String]
    public var thingsToAvoid: [String]
    public var userContext: String?

    public init(
        occasion: Occasion,
        relationship: Relationship,
        tone: Tone,
        length: MessageLength = .standard,
        localeIdentifier: String = Locale.current.identifier,
        recipientName: String? = nil,
        thingsToInclude: [String] = [],
        thingsToAvoid: [String] = [],
        userContext: String? = nil
    ) {
        self.occasion = occasion
        self.relationship = relationship
        self.tone = tone
        self.length = length
        self.localeIdentifier = localeIdentifier
        self.recipientName = recipientName
        self.thingsToInclude = thingsToInclude
        self.thingsToAvoid = thingsToAvoid
        self.userContext = userContext
    }
}

public struct ClientContext: Codable, Equatable, Sendable {
    public var appVersion: String
    public var buildNumber: String
    public var platform: String
    public var installationId: String?

    public init(
        appVersion: String,
        buildNumber: String,
        platform: String = "ios",
        installationId: String? = nil
    ) {
        self.appVersion = appVersion
        self.buildNumber = buildNumber
        self.platform = platform
        self.installationId = installationId
    }
}

public struct CardRequest: Codable, Equatable, Sendable {
    public static let currentPromptContractVersion = 1
    public static let currentOutputContractVersion = 1

    public var idempotencyKey: String
    public var intent: CardIntent
    public var requestedLane: GenerationLane
    public var clientContext: ClientContext
    public var promptContractVersion: Int
    public var outputContractVersion: Int

    public init(
        idempotencyKey: String = UUID().uuidString,
        intent: CardIntent,
        requestedLane: GenerationLane = .automatic,
        clientContext: ClientContext,
        promptContractVersion: Int = CardRequest.currentPromptContractVersion,
        outputContractVersion: Int = CardRequest.currentOutputContractVersion
    ) {
        self.idempotencyKey = idempotencyKey
        self.intent = intent
        self.requestedLane = requestedLane
        self.clientContext = clientContext
        self.promptContractVersion = promptContractVersion
        self.outputContractVersion = outputContractVersion
    }
}

public struct GeneratedMessage: Codable, Equatable, Identifiable, Sendable {
    public var id: String
    public var text: String

    public init(id: String = UUID().uuidString, text: String) {
        self.id = id
        self.text = text
    }
}

public struct UsageSummary: Codable, Equatable, Sendable {
    public var remaining: Int?
    public var limit: Int?
    public var resetsAt: Date?

    public init(remaining: Int? = nil, limit: Int? = nil, resetsAt: Date? = nil) {
        self.remaining = remaining
        self.limit = limit
        self.resetsAt = resetsAt
    }
}

public struct QualityCheckSummary: Codable, Equatable, Sendable {
    public var passed: Bool
    public var userSafeNote: String?

    public init(passed: Bool, userSafeNote: String? = nil) {
        self.passed = passed
        self.userSafeNote = userSafeNote
    }
}

public struct UserSafeError: Codable, Equatable, Sendable {
    public var code: String
    public var message: String

    public init(code: String, message: String) {
        self.code = code
        self.message = message
    }
}

public struct CardResponse: Codable, Equatable, Sendable {
    public var messages: [GeneratedMessage]
    public var laneUsed: GenerationLane
    public var fallbackStatus: FallbackStatus
    public var qualityCheck: QualityCheckSummary?
    public var usage: UsageSummary?
    public var retryEligibility: RetryEligibility
    public var userSafeError: UserSafeError?
    public var promptContractVersion: Int
    public var outputContractVersion: Int

    public init(
        messages: [GeneratedMessage],
        laneUsed: GenerationLane,
        fallbackStatus: FallbackStatus = .none,
        qualityCheck: QualityCheckSummary? = nil,
        usage: UsageSummary? = nil,
        retryEligibility: RetryEligibility = .ineligible,
        userSafeError: UserSafeError? = nil,
        promptContractVersion: Int = CardRequest.currentPromptContractVersion,
        outputContractVersion: Int = CardRequest.currentOutputContractVersion
    ) {
        self.messages = messages
        self.laneUsed = laneUsed
        self.fallbackStatus = fallbackStatus
        self.qualityCheck = qualityCheck
        self.usage = usage
        self.retryEligibility = retryEligibility
        self.userSafeError = userSafeError
        self.promptContractVersion = promptContractVersion
        self.outputContractVersion = outputContractVersion
    }
}

