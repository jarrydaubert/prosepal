import Foundation
import ProsePalDomain
import SwiftData

@Model
public final class RelationshipTruthBeadRecord {
    public var id: UUID
    public var personName: String
    public var text: String
    public var isUserApproved: Bool
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        id: UUID = UUID(),
        personName: String,
        text: String,
        isUserApproved: Bool = true,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.personName = personName
        self.text = text
        self.isUserApproved = isUserApproved
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    public var truthBead: TruthBead {
        TruthBead(
            id: id,
            personName: personName,
            text: text,
            isUserApproved: isUserApproved,
            createdAt: createdAt
        )
    }

    public func update(
        personName: String,
        text: String,
        isUserApproved: Bool,
        updatedAt: Date = Date()
    ) {
        self.personName = personName.trimmingCharacters(in: .whitespacesAndNewlines)
        self.text = text.trimmingCharacters(in: .whitespacesAndNewlines)
        self.isUserApproved = isUserApproved
        self.updatedAt = updatedAt
    }
}

@Model
public final class RelationshipVoiceCardRecord {
    public var id: UUID
    public var personName: String
    public var summary: String
    public var isUserApproved: Bool
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        id: UUID = UUID(),
        personName: String,
        summary: String,
        isUserApproved: Bool = true,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.personName = personName
        self.summary = summary
        self.isUserApproved = isUserApproved
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    public var voiceCard: RelationshipVoiceCard {
        RelationshipVoiceCard(
            id: id,
            personName: personName,
            summary: summary,
            isUserApproved: isUserApproved,
            createdAt: createdAt
        )
    }

    public func update(
        personName: String,
        summary: String,
        isUserApproved: Bool,
        updatedAt: Date = Date()
    ) {
        self.personName = personName.trimmingCharacters(in: .whitespacesAndNewlines)
        self.summary = summary.trimmingCharacters(in: .whitespacesAndNewlines)
        self.isUserApproved = isUserApproved
        self.updatedAt = updatedAt
    }
}

public enum RelationshipVaultSchema {
    public static var models: [any PersistentModel.Type] {
        [
            RelationshipTruthBeadRecord.self,
            RelationshipVoiceCardRecord.self,
            SavedMomentDraftRecord.self
        ]
    }
}

public enum RelationshipVaultStoreLocation {
    public static let appDirectoryName = "ProsePal"
    public static let vaultDirectoryName = "RelationshipVault"
    public static let storeFileName = "RelationshipVault.store"

    public static func storeURL(
        fileManager: FileManager = .default,
        baseDirectory: URL? = nil
    ) throws -> URL {
        let directory = try prepareStoreDirectory(
            fileManager: fileManager,
            baseDirectory: baseDirectory
        )
        return directory.appendingPathComponent(storeFileName, isDirectory: false)
    }

    public static func prepareStoreDirectory(
        fileManager: FileManager = .default,
        baseDirectory: URL? = nil
    ) throws -> URL {
        let rootDirectory: URL
        if let baseDirectory {
            rootDirectory = baseDirectory
        } else if let applicationSupportDirectory = fileManager.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first {
            rootDirectory = applicationSupportDirectory
        } else {
            throw RelationshipVaultStoreLocationError.applicationSupportDirectoryUnavailable
        }

        let appDirectory = rootDirectory.appendingPathComponent(appDirectoryName, isDirectory: true)
        let vaultDirectory = appDirectory.appendingPathComponent(vaultDirectoryName, isDirectory: true)

        try fileManager.createDirectory(at: vaultDirectory, withIntermediateDirectories: true)
        try excludeFromBackup(appDirectory)
        try excludeFromBackup(vaultDirectory)

        return vaultDirectory
    }

    private static func excludeFromBackup(_ directory: URL) throws {
        var directory = directory
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        try directory.setResourceValues(values)
    }
}

public enum RelationshipVaultStoreLocationError: Error, Equatable {
    case applicationSupportDirectoryUnavailable
}

public actor SwiftDataRelationshipMemoryProvider: RelationshipMemoryProviding {
    private let container: ModelContainer

    public init(container: ModelContainer) {
        self.container = container
    }

    public func approvedTruthBeads(for personName: String) async throws -> [TruthBead] {
        let normalizedName = Self.normalized(personName)
        guard !normalizedName.isEmpty else { return [] }

        let context = ModelContext(container)
        let descriptor = FetchDescriptor<RelationshipTruthBeadRecord>(
            predicate: #Predicate { $0.isUserApproved },
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )

        return try context.fetch(descriptor)
            .filter { Self.normalized($0.personName) == normalizedName }
            .map(\.truthBead)
    }

    public func approvedVoiceCard(for personName: String) async throws -> RelationshipVoiceCard? {
        let normalizedName = Self.normalized(personName)
        guard !normalizedName.isEmpty else { return nil }

        let context = ModelContext(container)
        let descriptor = FetchDescriptor<RelationshipVoiceCardRecord>(
            predicate: #Predicate { $0.isUserApproved },
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )

        return try context.fetch(descriptor)
            .first { Self.normalized($0.personName) == normalizedName }
            .map(\.voiceCard)
    }

    private static func normalized(_ value: String) -> String {
        value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
    }
}

@Model
public final class SavedMomentDraftRecord {
    public var id: UUID
    public var personName: String
    public var relationshipRawValue: String
    public var occasionRawValue: String
    public var registerRawValue: String
    public var toneRawValue: String
    public var lengthRawValue: String
    public var laneRawValue: String
    public var trueThing: String
    public var messageText: String
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        id: UUID = UUID(),
        personName: String,
        relationshipRawValue: String,
        occasionRawValue: String,
        registerRawValue: String,
        toneRawValue: String,
        lengthRawValue: String,
        laneRawValue: String,
        trueThing: String,
        messageText: String,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.personName = personName
        self.relationshipRawValue = relationshipRawValue
        self.occasionRawValue = occasionRawValue
        self.registerRawValue = registerRawValue
        self.toneRawValue = toneRawValue
        self.lengthRawValue = lengthRawValue
        self.laneRawValue = laneRawValue
        self.trueThing = trueThing
        self.messageText = messageText
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    public convenience init(
        moment: MomentInput,
        messageText: String,
        lane: MomentDraftLane,
        createdAt: Date = Date()
    ) {
        self.init(
            personName: moment.personName,
            relationshipRawValue: moment.relationship.rawValue,
            occasionRawValue: moment.occasion.rawValue,
            registerRawValue: moment.register.rawValue,
            toneRawValue: moment.tone.rawValue,
            lengthRawValue: moment.length.rawValue,
            laneRawValue: lane.rawValue,
            trueThing: moment.trueThing,
            messageText: messageText,
            createdAt: createdAt,
            updatedAt: createdAt
        )
    }

    public var relationship: Relationship {
        Relationship(rawValue: relationshipRawValue) ?? .closeFriend
    }

    public var occasion: Occasion {
        Occasion(rawValue: occasionRawValue) ?? .birthday
    }

    public var register: MomentRegister {
        MomentRegister(rawValue: registerRawValue) ?? .react
    }

    public var tone: Tone {
        Tone(rawValue: toneRawValue) ?? .heartfelt
    }

    public var length: MessageLength {
        MessageLength(rawValue: lengthRawValue) ?? .standard
    }

    public var lane: MomentDraftLane {
        MomentDraftLane(rawValue: laneRawValue) ?? .privateDraft
    }

    public var title: String {
        personName.isEmpty ? occasion.displayName : personName
    }

    public var subtitle: String {
        "\(occasion.displayName) · \(relationship.displayName)"
    }
}
