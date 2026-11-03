import Foundation
import ProsePalDomain

public enum MomentDraftSnapshotReason: String, Codable, Equatable, Sendable {
    case edit
    case rewrite
}

public struct MomentDraftSnapshot: Codable, Equatable, Identifiable, Sendable {
    public var id: UUID
    public var bundle: MomentDraftBundle
    public var reason: MomentDraftSnapshotReason
    public var createdAt: Date

    public init(
        id: UUID = UUID(),
        bundle: MomentDraftBundle,
        reason: MomentDraftSnapshotReason,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.bundle = bundle
        self.reason = reason
        self.createdAt = createdAt
    }
}

public struct MomentDraftRecoveryState: Codable, Equatable, Sendable {
    public static let schemaVersion = 1

    public var schemaVersion: Int
    public var personName: String
    public var relationship: Relationship
    public var occasion: Occasion
    public var register: MomentRegister
    public var tone: Tone
    public var length: MessageLength
    public var trueThing: String
    public var bundle: MomentDraftBundle
    public var draftSnapshots: [MomentDraftSnapshot]
    public var savedAt: Date

    public init(
        schemaVersion: Int = Self.schemaVersion,
        personName: String,
        relationship: Relationship,
        occasion: Occasion,
        register: MomentRegister,
        tone: Tone = .heartfelt,
        length: MessageLength = .standard,
        trueThing: String,
        bundle: MomentDraftBundle,
        draftSnapshots: [MomentDraftSnapshot],
        savedAt: Date = Date()
    ) {
        self.schemaVersion = schemaVersion
        self.personName = ProsePalTextInput.personName(personName)
        self.relationship = relationship
        self.occasion = occasion
        self.register = register
        self.tone = tone
        self.length = length
        self.trueThing = ProsePalTextInput.momentDetail(trueThing)
        self.bundle = bundle
        self.draftSnapshots = Array(draftSnapshots.suffix(12))
        self.savedAt = savedAt
    }

    public var hasRecoverableDraft: Bool {
        !personName.isEmpty && !bundle.messageText.isEmpty
    }

    private enum CodingKeys: String, CodingKey {
        case schemaVersion
        case personName
        case relationship
        case occasion
        case register
        case tone
        case length
        case trueThing
        case bundle
        case draftSnapshots
        case savedAt
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        schemaVersion = try container.decode(Int.self, forKey: .schemaVersion)
        personName = ProsePalTextInput.personName(
            try container.decode(String.self, forKey: .personName)
        )
        relationship = try container.decode(Relationship.self, forKey: .relationship)
        occasion = try container.decode(Occasion.self, forKey: .occasion)
        register = try container.decode(MomentRegister.self, forKey: .register)
        tone = try container.decodeIfPresent(Tone.self, forKey: .tone) ?? .heartfelt
        length = try container.decodeIfPresent(MessageLength.self, forKey: .length) ?? .standard
        trueThing = ProsePalTextInput.momentDetail(
            try container.decode(String.self, forKey: .trueThing)
        )
        bundle = try container.decode(MomentDraftBundle.self, forKey: .bundle)
        draftSnapshots = Array((try container.decode([MomentDraftSnapshot].self, forKey: .draftSnapshots)).suffix(12))
        savedAt = try container.decode(Date.self, forKey: .savedAt)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(schemaVersion, forKey: .schemaVersion)
        try container.encode(personName, forKey: .personName)
        try container.encode(relationship, forKey: .relationship)
        try container.encode(occasion, forKey: .occasion)
        try container.encode(register, forKey: .register)
        try container.encode(tone, forKey: .tone)
        try container.encode(length, forKey: .length)
        try container.encode(trueThing, forKey: .trueThing)
        try container.encode(bundle, forKey: .bundle)
        try container.encode(draftSnapshots, forKey: .draftSnapshots)
        try container.encode(savedAt, forKey: .savedAt)
    }
}

@MainActor
public protocol MomentDraftRecoveryStoring {
    func load() -> MomentDraftRecoveryState?
    func save(_ state: MomentDraftRecoveryState)
    func clear()
}

public struct MomentDraftRecoveryNoopStore: MomentDraftRecoveryStoring {
    public init() {}

    public func load() -> MomentDraftRecoveryState? { nil }
    public func save(_ state: MomentDraftRecoveryState) {}
    public func clear() {}
}

public struct MomentDraftRecoveryStore: MomentDraftRecoveryStoring {
    public static let defaultKey = "prosepal.native.activeDraftRecovery.v1"

    private let store: UserDefaults
    private let key: String

    public init(
        store: UserDefaults = .standard,
        key: String = MomentDraftRecoveryStore.defaultKey
    ) {
        self.store = store
        self.key = key
    }

    public func load() -> MomentDraftRecoveryState? {
        guard let data = store.data(forKey: key),
              let state = try? JSONDecoder().decode(MomentDraftRecoveryState.self, from: data)
        else {
            return nil
        }

        guard state.schemaVersion == MomentDraftRecoveryState.schemaVersion,
              state.hasRecoverableDraft
        else {
            clear()
            return nil
        }

        return state
    }

    public func save(_ state: MomentDraftRecoveryState) {
        guard state.hasRecoverableDraft,
              let data = try? JSONEncoder().encode(state)
        else {
            clear()
            return
        }

        store.set(data, forKey: key)
    }

    public func clear() {
        store.removeObject(forKey: key)
    }
}
