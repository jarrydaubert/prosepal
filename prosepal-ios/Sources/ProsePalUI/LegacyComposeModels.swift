import Foundation
import ProsePalDomain

public struct MessageDraft: Equatable, Sendable {
    public var occasion: Occasion = .birthday
    public var relationship: Relationship = .parent
    public var tone: Tone = .heartfelt
    public var length: MessageLength = .standard
    public var spellingPreference: SpellingPreference = .automatic
    public var requestedLane: GenerationLane = .standard
    public var recipientName = ""
    public var thingsToInclude = ""
    public var thingsToAvoid = ""
    public var personalContext = ""

    var intent: CardIntent {
        CardIntent(
            occasion: occasion,
            relationship: relationship,
            tone: tone,
            length: length,
            spellingPreference: spellingPreference,
            localeIdentifier: spellingPreference.localeIdentifier,
            recipientName: recipientName.nilIfBlank,
            thingsToInclude: thingsToInclude.commaSeparatedValues,
            thingsToAvoid: thingsToAvoid.commaSeparatedValues,
            userContext: personalContext.nilIfBlank
        )
    }
}

public struct SavedMessage: Codable, Identifiable, Equatable, Hashable, Sendable {
    public var id: UUID
    public var text: String
    public var occasion: Occasion
    public var relationship: Relationship
    public var tone: Tone
    public var length: MessageLength
    public var recipientName: String?
    public var savedAt: Date

    public init(
        id: UUID = UUID(),
        text: String,
        occasion: Occasion,
        relationship: Relationship,
        tone: Tone,
        length: MessageLength,
        recipientName: String? = nil,
        savedAt: Date = .now
    ) {
        self.id = id
        self.text = text
        self.occasion = occasion
        self.relationship = relationship
        self.tone = tone
        self.length = length
        self.recipientName = recipientName
        self.savedAt = savedAt
    }

    public var title: String {
        guard let recipientName = recipientName?.trimmedForSaving, !recipientName.isEmpty else {
            return occasion.displayName
        }
        return recipientName
    }

    public var subtitle: String {
        "\(occasion.displayName) / \(relationship.displayName) / \(tone.displayName)"
    }
}

public struct AppNotice: Identifiable, Equatable, Sendable {
    public var id: UUID
    public var title: String
    public var systemImage: String

    public init(id: UUID = UUID(), title: String, systemImage: String) {
        self.id = id
        self.title = title
        self.systemImage = systemImage
    }
}

public struct UsageStatus: Equatable, Sendable {
    public var standardLimit: Int
    public var standardRemaining: Int
    public var isPremiumUnlocked: Bool
    public var resetDescription: String
    public var hasAuthoritativeUsage: Bool

    public init(
        standardLimit: Int = 3,
        standardRemaining: Int = 3,
        isPremiumUnlocked: Bool = false,
        resetDescription: String = "today",
        hasAuthoritativeUsage: Bool = false
    ) {
        self.standardLimit = max(0, standardLimit)
        self.standardRemaining = max(0, min(standardRemaining, standardLimit))
        self.isPremiumUnlocked = isPremiumUnlocked
        self.resetDescription = resetDescription
        self.hasAuthoritativeUsage = hasAuthoritativeUsage
    }

    public var usageText: String {
        if isPremiumUnlocked {
            return "Premium active"
        }

        if !hasAuthoritativeUsage {
            return "\(standardLimit) free \(Self.messageWord(for: standardLimit)) daily"
        }

        if standardRemaining == 0 {
            return "Out of free messages today"
        }

        if standardRemaining == standardLimit {
            return "\(standardLimit) free \(Self.messageWord(for: standardLimit)) daily"
        }

        return "\(standardRemaining) free \(Self.messageWord(for: standardRemaining)) left \(resetDescription)"
    }

    public var detailText: String {
        if isPremiumUnlocked {
            return "Extra help for harder moments and higher limits are available."
        }

        if !hasAuthoritativeUsage {
            return "ProsePal checks your message limit when you write."
        }

        if standardRemaining == 0 {
            return "Premium unlocks more messages and extra rewrites."
        }

        return "Premium adds more messages and extra rewrites."
    }

    public func actionZoneState(requestedLane: GenerationLane) -> MessageActionZoneState {
        if isPremiumUnlocked {
            return MessageActionZoneState(
                statusLine: "Premium active",
                primaryButtonTitle: "Write message",
                primaryAction: .writeMessage,
                showsTryPremium: false,
                showsLaneControl: true
            )
        }

        if isStandardLimitReached(for: requestedLane) {
            return MessageActionZoneState(
                statusLine: "Out of free messages today",
                primaryButtonTitle: "Unlock more messages",
                primaryAction: .openPaywall,
                showsTryPremium: false,
                showsLaneControl: false
            )
        }

        return MessageActionZoneState(
            statusLine: usageText,
            primaryButtonTitle: "Write message",
            primaryAction: .writeMessage,
            showsTryPremium: true,
            showsLaneControl: false
        )
    }

    private static func messageWord(for count: Int) -> String {
        count == 1 ? "message" : "messages"
    }

    public func isPremiumLocked(_ lane: GenerationLane) -> Bool {
        lane == .premium && !isPremiumUnlocked
    }

    public func isStandardLimitReached(for lane: GenerationLane) -> Bool {
        hasAuthoritativeUsage && !isPremiumUnlocked && isStandardLike(lane) && standardRemaining <= 0
    }

    public mutating func recordSuccessfulGeneration(requestedLane: GenerationLane, laneUsed: GenerationLane) {
        // The gateway is the source of truth for usage. Anonymous staging
        // responses may omit usage while still being valid; do not invent a
        // client-side limit in that path.
    }

    public mutating func applyGatewayUsageSummary(_ summary: UsageSummary, now: Date = .now) {
        hasAuthoritativeUsage = true

        if let limit = summary.limit {
            standardLimit = max(0, limit)
        }

        if let remaining = summary.remaining {
            standardRemaining = max(0, min(remaining, standardLimit))
        } else {
            standardRemaining = min(standardRemaining, standardLimit)
        }

        if let resetsAt = summary.resetsAt {
            resetDescription = Self.resetDescription(for: resetsAt, now: now)
        }
    }

    private func isStandardLike(_ lane: GenerationLane) -> Bool {
        switch lane {
        case .automatic, .standard:
            true
        case .premium, .local:
            false
        }
    }

    private static func resetDescription(for resetsAt: Date, now: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDate(resetsAt, inSameDayAs: now) {
            return "until \(resetsAt.formatted(date: .omitted, time: .shortened))"
        }

        return "until \(resetsAt.formatted(date: .abbreviated, time: .shortened))"
    }
}

public struct MessageActionZoneState: Equatable, Sendable {
    public enum PrimaryAction: Equatable, Sendable {
        case writeMessage
        case openPaywall
    }

    public var statusLine: String
    public var primaryButtonTitle: String
    public var primaryAction: PrimaryAction
    public var showsTryPremium: Bool
    public var showsLaneControl: Bool

    public init(
        statusLine: String,
        primaryButtonTitle: String,
        primaryAction: PrimaryAction,
        showsTryPremium: Bool,
        showsLaneControl: Bool
    ) {
        self.statusLine = statusLine
        self.primaryButtonTitle = primaryButtonTitle
        self.primaryAction = primaryAction
        self.showsTryPremium = showsTryPremium
        self.showsLaneControl = showsLaneControl
    }
}

enum AppTab: String, Hashable {
    case compose
    case saved
    case settings
}

enum ComposeField: String, Hashable {
    case recipient
    case include
    case avoid
    case context
}

private extension String {
    var nilIfBlank: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    var commaSeparatedValues: [String] {
        split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    var trimmedForSaving: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
