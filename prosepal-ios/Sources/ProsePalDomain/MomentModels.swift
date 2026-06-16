import Foundation

public enum MomentRegister: String, Codable, CaseIterable, Sendable, Identifiable {
    case react
    case confess
    case assemble

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .react: "React"
        case .confess: "Say it"
        case .assemble: "Take care"
        }
    }

    public var userSafeDescription: String {
        switch self {
        case .react:
            "Everyday moments that need a quick, warm message."
        case .confess:
            "A real sentence from you that ProsePal helps shape."
        case .assemble:
            "Harder moments where your words should lead."
        }
    }
}

public enum MomentDraftLane: String, Codable, Sendable, Equatable {
    case privateDraft
    case takeMoreCare
    case mock
}

public enum MomentAdjustment: String, Codable, CaseIterable, Sendable, Identifiable {
    case warmer
    case shorter
    case moreDirect

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .warmer: "Warmer"
        case .shorter: "Shorter"
        case .moreDirect: "More direct"
        }
    }
}

public struct MomentInput: Codable, Equatable, Sendable {
    public var personName: String
    public var relationship: Relationship
    public var occasion: Occasion
    public var register: MomentRegister
    public var trueThing: String
    public var tone: Tone
    public var length: MessageLength
    public var spellingPreference: SpellingPreference
    public var localeIdentifier: String

    public init(
        personName: String,
        relationship: Relationship,
        occasion: Occasion,
        register: MomentRegister = .react,
        trueThing: String = "",
        tone: Tone = .heartfelt,
        length: MessageLength = .standard,
        spellingPreference: SpellingPreference = .automatic,
        localeIdentifier: String? = nil
    ) {
        self.personName = personName.trimmingCharacters(in: .whitespacesAndNewlines)
        self.relationship = relationship
        self.occasion = occasion
        self.register = register
        self.trueThing = trueThing.trimmingCharacters(in: .whitespacesAndNewlines)
        self.tone = tone
        self.length = length
        self.spellingPreference = spellingPreference
        self.localeIdentifier = localeIdentifier ?? spellingPreference.localeIdentifier
    }

    public var hasEnoughContextForDraft: Bool {
        !personName.isEmpty
    }

    public var requiresCarefulLane: Bool {
        switch register {
        case .assemble:
            true
        case .confess:
            occasion == .sympathy || occasion == .petSympathy || occasion == .apology
        case .react:
            occasion == .sympathy || occasion == .petSympathy
        }
    }

    public var cardIntent: CardIntent {
        CardIntent(
            occasion: occasion,
            relationship: relationship,
            tone: tone,
            length: length,
            spellingPreference: spellingPreference,
            localeIdentifier: localeIdentifier,
            recipientName: personName.nilIfBlank,
            thingsToInclude: trueThing.nilIfBlank.map { [$0] } ?? [],
            thingsToAvoid: [],
            userContext: register.userSafeDescription
        )
    }
}

public struct TruthBead: Codable, Equatable, Identifiable, Sendable {
    public var id: UUID
    public var personName: String
    public var text: String
    public var isUserApproved: Bool
    public var createdAt: Date

    public init(
        id: UUID = UUID(),
        personName: String,
        text: String,
        isUserApproved: Bool = true,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.personName = personName
        self.text = text
        self.isUserApproved = isUserApproved
        self.createdAt = createdAt
    }
}

public struct PressureCheck: Codable, Equatable, Sendable {
    public var asksForReassurance: Bool
    public var explainsBeforeApology: Bool
    public var mayFeelTooHeavy: Bool
    public var notes: [String]

    public init(
        asksForReassurance: Bool = false,
        explainsBeforeApology: Bool = false,
        mayFeelTooHeavy: Bool = false,
        notes: [String] = []
    ) {
        self.asksForReassurance = asksForReassurance
        self.explainsBeforeApology = explainsBeforeApology
        self.mayFeelTooHeavy = mayFeelTooHeavy
        self.notes = notes
    }

    public var hasFindings: Bool {
        asksForReassurance || explainsBeforeApology || mayFeelTooHeavy || !notes.isEmpty
    }
}

public struct MomentDraftBundle: Codable, Equatable, Identifiable, Sendable {
    public var id: UUID
    public var messageText: String
    public var lane: MomentDraftLane
    public var pressureCheck: PressureCheck
    public var truthBeads: [TruthBead]
    public var missingInformation: [String]
    public var riskNotes: [String]

    public init(
        id: UUID = UUID(),
        messageText: String,
        lane: MomentDraftLane,
        pressureCheck: PressureCheck = PressureCheck(),
        truthBeads: [TruthBead] = [],
        missingInformation: [String] = [],
        riskNotes: [String] = []
    ) {
        self.id = id
        self.messageText = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        self.lane = lane
        self.pressureCheck = pressureCheck
        self.truthBeads = truthBeads
        self.missingInformation = missingInformation
        self.riskNotes = riskNotes
    }
}

private extension String {
    var nilIfBlank: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
