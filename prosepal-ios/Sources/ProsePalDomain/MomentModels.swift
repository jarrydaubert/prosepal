import Foundation

public enum MomentRegister: String, Codable, CaseIterable, Sendable, Identifiable {
    case react
    case confess
    case assemble

    public var id: String { rawValue }

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

public enum MomentDraftLane: String, Sendable, Equatable {
    case privateDraft
    case standardDraft
    case careful
    case mock

    public init?(rawValue: String) {
        switch rawValue {
        case Self.privateDraft.rawValue:
            self = .privateDraft
        case Self.standardDraft.rawValue:
            self = .standardDraft
        case Self.careful.rawValue, "takeMoreCare":
            self = .careful
        case Self.mock.rawValue:
            self = .mock
        default:
            return nil
        }
    }
}

extension MomentDraftLane: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        guard let lane = Self(rawValue: rawValue) else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Unsupported moment draft lane."
            )
        }
        self = lane
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
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
        case .moreDirect: "Direct"
        }
    }
}

public enum MomentSafetySignal: String, Codable, Sendable, Equatable {
    case none
    case crisisSupport

    public var allowsDrafting: Bool {
        switch self {
        case .none:
            true
        case .crisisSupport:
            false
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
    public var localeIdentifier: String

    public init(
        personName: String,
        relationship: Relationship,
        occasion: Occasion,
        register: MomentRegister = .react,
        trueThing: String = "",
        tone: Tone = .heartfelt,
        length: MessageLength = .standard,
        localeIdentifier: String? = nil
    ) {
        self.personName = ProsePalTextInput.personName(personName)
        self.relationship = relationship
        self.occasion = occasion
        self.register = register
        self.trueThing = ProsePalTextInput.momentDetail(trueThing)
        self.tone = tone
        self.length = length
        self.localeIdentifier = localeIdentifier ?? Locale.current.identifier
    }

    public var hasEnoughContextForDraft: Bool {
        personName.filter { !$0.isWhitespace }.count >= 2
    }

    public var safetySignal: MomentSafetySignal {
        trueThing.indicatesCrisisSupportNeed ? .crisisSupport : .none
    }

    public var allowsDrafting: Bool {
        hasEnoughContextForDraft && safetySignal.allowsDrafting
    }

    public var isCarefulMode: Bool {
        recommendedRegister == .assemble || requiresCarefulLane || occasion == .apology
    }

    public var prefersCareRegister: Bool {
        occasion == .sympathy || occasion == .petSympathy || occasion == .apology
    }

    public var recommendedRegister: MomentRegister {
        prefersCareRegister && register == .react ? .assemble : register
    }

    public var requiresCarefulLane: Bool {
        switch register {
        case .assemble:
            true
        case .confess:
            occasion == .sympathy || occasion == .petSympathy || occasion == .apology
        case .react:
            prefersCareRegister
        }
    }

    public var cardIntent: CardIntent {
        CardIntent(
            occasion: occasion,
            relationship: relationship,
            tone: tone,
            length: length,
            localeIdentifier: localeIdentifier,
            recipientName: personName.nilIfBlank,
            thingsToInclude: trueThing.nilIfBlank.map { [$0] } ?? [],
            thingsToAvoid: [],
            userContext: recommendedRegister.userSafeDescription
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

public struct RelationshipVoiceCard: Codable, Equatable, Identifiable, Sendable {
    public var id: UUID
    public var personName: String
    public var summary: String
    public var isUserApproved: Bool
    public var createdAt: Date

    public init(
        id: UUID = UUID(),
        personName: String,
        summary: String,
        isUserApproved: Bool = true,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.personName = personName
        self.summary = summary
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

    public var userVisibleNotes: [String] {
        var output = notes.nonEmptyTrimmed

        if asksForReassurance {
            output.appendIfMissing("This asks them to reassure you. Consider making the message easier to receive.")
        }

        if explainsBeforeApology {
            output.appendIfMissing("This apology may sound conditional. Lead with the apology before explaining.")
        }

        if mayFeelTooHeavy {
            output.appendIfMissing("This may feel heavy for this moment. Consider making it lighter or more specific.")
        }

        return output
    }

    public func merged(with other: PressureCheck) -> PressureCheck {
        PressureCheck(
            asksForReassurance: asksForReassurance || other.asksForReassurance,
            explainsBeforeApology: explainsBeforeApology || other.explainsBeforeApology,
            mayFeelTooHeavy: mayFeelTooHeavy || other.mayFeelTooHeavy,
            notes: notes.mergingUserSafeNotes(with: other.notes)
        )
    }

    public static func local(messageText: String, moment: MomentInput) -> PressureCheck {
        let combined = [messageText, moment.trueThing]
            .joined(separator: "\n")
            .momentPressureNormalized

        let asksForReassurance = [
            "please tell me",
            "tell me im",
            "tell me i'm",
            "need you to tell me",
            "do you still",
            "are we okay",
            "you dont hate me",
            "you don't hate me",
            "you still love me"
        ].contains { combined.contains($0) }

        let explainsBeforeApology = [
            "sorry but",
            "sorry, but",
            "i'm sorry but",
            "im sorry but",
            "i am sorry but",
            "sorry if",
            "i'm sorry if",
            "im sorry if",
            "i am sorry if"
        ].contains { combined.contains($0) }

        let mayFeelTooHeavy = moment.register == .react && !moment.requiresCarefulLane && [
            "cant live without you",
            "can't live without you",
            "you are all i have",
            "youre all i have",
            "you're all i have",
            "i need you in my life",
            "i dont know what i would do without you",
            "i don't know what i would do without you"
        ].contains { combined.contains($0) }

        return PressureCheck(
            asksForReassurance: asksForReassurance,
            explainsBeforeApology: explainsBeforeApology,
            mayFeelTooHeavy: mayFeelTooHeavy
        )
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

    public func applyingLocalPressureCheck(for moment: MomentInput) -> MomentDraftBundle {
        MomentDraftBundle(
            id: id,
            messageText: messageText,
            lane: lane,
            pressureCheck: pressureCheck.merged(with: .local(messageText: messageText, moment: moment)),
            truthBeads: truthBeads,
            missingInformation: missingInformation,
            riskNotes: riskNotes
        )
    }

    public func replacingLane(_ lane: MomentDraftLane) -> MomentDraftBundle {
        MomentDraftBundle(
            id: id,
            messageText: messageText,
            lane: lane,
            pressureCheck: pressureCheck,
            truthBeads: truthBeads,
            missingInformation: missingInformation,
            riskNotes: riskNotes
        )
    }
}

private extension String {
    var nilIfBlank: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    var indicatesCrisisSupportNeed: Bool {
        let normalized = folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
            .replacingOccurrences(of: "’", with: "'")

        let phrases = [
            "kill myself",
            "killing myself",
            "end my life",
            "take my own life",
            "suicide",
            "suicidal",
            "want to die",
            "wanna die",
            "wish i was dead",
            "hurt myself",
            "harm myself",
            "self harm",
            "self-harm",
            "can't go on",
            "cannot go on"
        ]

        return phrases.contains { normalized.contains($0) }
    }

    var momentPressureNormalized: String {
        folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
            .replacingOccurrences(of: "’", with: "'")
            .replacingOccurrences(of: "‘", with: "'")
            .replacingOccurrences(of: "“", with: "\"")
            .replacingOccurrences(of: "”", with: "\"")
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "\t", with: " ")
    }
}

private extension Array where Element == String {
    var nonEmptyTrimmed: [String] {
        map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    mutating func appendIfMissing(_ value: String) {
        guard !contains(value) else { return }
        append(value)
    }

    func mergingUserSafeNotes(with other: [String]) -> [String] {
        var merged = nonEmptyTrimmed
        for note in other.nonEmptyTrimmed where !merged.contains(note) {
            merged.append(note)
        }
        return merged
    }
}
