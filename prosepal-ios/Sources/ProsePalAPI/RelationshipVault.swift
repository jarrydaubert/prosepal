import Foundation
import ProsePalDomain
import SwiftData

@Model
public final class RelationshipTruthBeadRecord {
    public var id: UUID
    public var personName: String
    public var normalizedPersonName: String = ""
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
        self.normalizedPersonName = RelationshipPersonKey.normalized(personName)
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
        self.normalizedPersonName = RelationshipPersonKey.normalized(self.personName)
        self.text = text.trimmingCharacters(in: .whitespacesAndNewlines)
        self.isUserApproved = isUserApproved
        self.updatedAt = updatedAt
    }
}

@Model
public final class RelationshipVoiceCardRecord {
    public var id: UUID
    public var personName: String
    public var normalizedPersonName: String = ""
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
        self.normalizedPersonName = RelationshipPersonKey.normalized(personName)
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
        self.normalizedPersonName = RelationshipPersonKey.normalized(self.personName)
        self.summary = summary.trimmingCharacters(in: .whitespacesAndNewlines)
        self.isUserApproved = isUserApproved
        self.updatedAt = updatedAt
    }
}

public enum RelationshipPersonKey {
    private static let normalizationLocale = Locale(identifier: "en_US_POSIX")

    public static func normalized(_ value: String) -> String {
        value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .folding(
                options: [.caseInsensitive, .diacriticInsensitive],
                locale: normalizationLocale
            )
    }
}

public enum RelationshipVaultSchemaV1: VersionedSchema {
    public static let versionIdentifier = Schema.Version(1, 0, 0)

    public static var models: [any PersistentModel.Type] {
        [
            RelationshipTruthBeadRecord.self,
            RelationshipVoiceCardRecord.self,
            SavedMomentDraftRecord.self
        ]
    }
}

public enum RelationshipVaultMigrationPlan: SchemaMigrationPlan {
    public static var schemas: [any VersionedSchema.Type] {
        [RelationshipVaultSchemaV1.self]
    }

    public static var stages: [MigrationStage] {
        []
    }
}

public enum RelationshipVaultSchema {
    public static var models: [any PersistentModel.Type] {
        RelationshipVaultSchemaV1.models
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

    fileprivate static func excludeFromBackup(_ directory: URL) throws {
        var directory = directory
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        try directory.setResourceValues(values)
    }
}

public enum RelationshipVaultStoreLocationError: Error, Equatable {
    case applicationSupportDirectoryUnavailable
}

public enum RelationshipVaultStorageMode: Equatable {
    case persistent
    case ephemeralFallback
}

public struct RelationshipVaultContainerResult {
    public let container: ModelContainer
    public let storageMode: RelationshipVaultStorageMode
    public let persistentStoreURL: URL?

    public init(
        container: ModelContainer,
        storageMode: RelationshipVaultStorageMode,
        persistentStoreURL: URL? = nil
    ) {
        self.container = container
        self.storageMode = storageMode
        self.persistentStoreURL = persistentStoreURL
    }

    public var isPersistent: Bool {
        storageMode == .persistent
    }
}

public enum RelationshipVaultContainerFactory {
    public static func makePersistentOrEphemeral(
        fileManager: FileManager = .default,
        baseDirectory: URL? = nil
    ) -> RelationshipVaultContainerResult {
        var storeURL: URL?
        do {
            let persistentStoreURL = try RelationshipVaultStoreLocation.storeURL(
                fileManager: fileManager,
                baseDirectory: baseDirectory
            )
            storeURL = persistentStoreURL
            return RelationshipVaultContainerResult(
                container: try makePersistent(storeURL: persistentStoreURL),
                storageMode: .persistent,
                persistentStoreURL: persistentStoreURL
            )
        } catch {
            return RelationshipVaultContainerResult(
                container: makeEphemeralFallback(),
                storageMode: .ephemeralFallback,
                persistentStoreURL: storeURL
            )
        }
    }

    public static func makePersistent(
        fileManager: FileManager = .default,
        baseDirectory: URL? = nil
    ) throws -> ModelContainer {
        try makePersistent(storeURL: RelationshipVaultStoreLocation.storeURL(
            fileManager: fileManager,
            baseDirectory: baseDirectory
        ))
    }

    static func makePersistent(storeURL: URL) throws -> ModelContainer {
        let schema = Schema(versionedSchema: RelationshipVaultSchemaV1.self)
        let configuration = ModelConfiguration(
            schema: schema,
            url: storeURL
        )
        let container = try ModelContainer(
            for: schema,
            migrationPlan: RelationshipVaultMigrationPlan.self,
            configurations: [configuration]
        )
        try RelationshipVaultMaintenance.repairLegacyPersonKeys(in: container)
        return container
    }

    public static func makeEphemeral() throws -> ModelContainer {
        let schema = Schema(versionedSchema: RelationshipVaultSchemaV1.self)
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        return try ModelContainer(
            for: schema,
            migrationPlan: RelationshipVaultMigrationPlan.self,
            configurations: [configuration]
        )
    }

    private static func makeEphemeralFallback() -> ModelContainer {
        do {
            return try makeEphemeral()
        } catch {
            preconditionFailure("Unable to create an ephemeral ProsePal relationship vault.")
        }
    }
}

public enum RelationshipVaultMaintenance {
    public static func repairLegacyPersonKeys(in container: ModelContainer) throws {
        try repairLegacyPersonKeys(in: ModelContext(container))
    }

    public static func repairLegacyPersonKeys(in context: ModelContext) throws {
        var didRepair = false

        let truthBeadDescriptor = FetchDescriptor<RelationshipTruthBeadRecord>(
            predicate: #Predicate { $0.normalizedPersonName == "" }
        )
        for record in try context.fetch(truthBeadDescriptor) {
            record.normalizedPersonName = RelationshipPersonKey.normalized(record.personName)
            didRepair = true
        }

        let voiceCardDescriptor = FetchDescriptor<RelationshipVoiceCardRecord>(
            predicate: #Predicate { $0.normalizedPersonName == "" }
        )
        for record in try context.fetch(voiceCardDescriptor) {
            record.normalizedPersonName = RelationshipPersonKey.normalized(record.personName)
            didRepair = true
        }

        let savedDraftDescriptor = FetchDescriptor<SavedMomentDraftRecord>(
            predicate: #Predicate { $0.normalizedPersonName == "" }
        )
        for record in try context.fetch(savedDraftDescriptor) {
            record.normalizedPersonName = RelationshipPersonKey.normalized(record.personName)
            didRepair = true
        }

        if didRepair {
            try context.save()
        }
    }
}

public enum RelationshipVaultLocalDataEraser {
    @MainActor
    public static func eraseAll(in result: RelationshipVaultContainerResult) async throws {
        try await eraseAll(in: result.container)

        guard result.storageMode == .ephemeralFallback,
              let persistentStoreURL = result.persistentStoreURL
        else {
            return
        }

        try erasePersistentStoreFiles(at: persistentStoreURL)
    }

    @MainActor
    public static func eraseAll(in container: ModelContainer) async throws {
        let context = ModelContext(container)
        try eraseAll(in: context)
    }

    public static func eraseAll(in context: ModelContext) throws {
        try context.fetch(FetchDescriptor<RelationshipTruthBeadRecord>()).forEach {
            context.delete($0)
        }
        try context.fetch(FetchDescriptor<RelationshipVoiceCardRecord>()).forEach {
            context.delete($0)
        }
        try context.fetch(FetchDescriptor<SavedMomentDraftRecord>()).forEach {
            context.delete($0)
        }
        try context.save()
    }

    public static func erasePersistentStoreFiles(
        at storeURL: URL,
        fileManager: FileManager = .default
    ) throws {
        let vaultDirectory = storeURL.deletingLastPathComponent()

        if fileManager.fileExists(atPath: vaultDirectory.path) {
            try fileManager.removeItem(at: vaultDirectory)
        }

        try fileManager.createDirectory(at: vaultDirectory, withIntermediateDirectories: true)
        try RelationshipVaultStoreLocation.excludeFromBackup(vaultDirectory)
    }
}

public struct RelationshipVaultExportCounts: Codable, Equatable, Sendable {
    public var truthBeads: Int
    public var voiceCards: Int
    public var savedDrafts: Int
}

public struct RelationshipVaultExportSnapshot: Codable, Equatable, Sendable {
    public var schemaVersion: Int
    public var exportedAt: Date
    public var counts: RelationshipVaultExportCounts
    public var truthBeads: [RelationshipTruthBeadExport]
    public var voiceCards: [RelationshipVoiceCardExport]
    public var savedDrafts: [SavedMomentDraftExport]
}

public struct RelationshipTruthBeadExport: Codable, Equatable, Sendable {
    public var id: UUID
    public var personName: String
    public var text: String
    public var isUserApproved: Bool
    public var createdAt: Date
    public var updatedAt: Date
}

public struct RelationshipVoiceCardExport: Codable, Equatable, Sendable {
    public var id: UUID
    public var personName: String
    public var summary: String
    public var isUserApproved: Bool
    public var createdAt: Date
    public var updatedAt: Date
}

public struct SavedMomentDraftExport: Codable, Equatable, Sendable {
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
}

public enum RelationshipVaultExporter {
    public static let currentSchemaVersion = 1

    public static func snapshot(
        in context: ModelContext,
        exportedAt: Date = Date()
    ) throws -> RelationshipVaultExportSnapshot {
        let truthBeads = try context
            .fetch(FetchDescriptor<RelationshipTruthBeadRecord>(
                sortBy: [SortDescriptor(\.createdAt)]
            ))
            .map {
                RelationshipTruthBeadExport(
                    id: $0.id,
                    personName: $0.personName,
                    text: $0.text,
                    isUserApproved: $0.isUserApproved,
                    createdAt: $0.createdAt,
                    updatedAt: $0.updatedAt
                )
            }

        let voiceCards = try context
            .fetch(FetchDescriptor<RelationshipVoiceCardRecord>(
                sortBy: [SortDescriptor(\.createdAt)]
            ))
            .map {
                RelationshipVoiceCardExport(
                    id: $0.id,
                    personName: $0.personName,
                    summary: $0.summary,
                    isUserApproved: $0.isUserApproved,
                    createdAt: $0.createdAt,
                    updatedAt: $0.updatedAt
                )
            }

        let savedDrafts = try context
            .fetch(FetchDescriptor<SavedMomentDraftRecord>(
                sortBy: [SortDescriptor(\.createdAt)]
            ))
            .map {
                SavedMomentDraftExport(
                    id: $0.id,
                    personName: $0.personName,
                    relationshipRawValue: $0.relationshipRawValue,
                    occasionRawValue: $0.occasionRawValue,
                    registerRawValue: $0.registerRawValue,
                    toneRawValue: $0.toneRawValue,
                    lengthRawValue: $0.lengthRawValue,
                    laneRawValue: $0.laneRawValue,
                    trueThing: $0.trueThing,
                    messageText: $0.messageText,
                    createdAt: $0.createdAt,
                    updatedAt: $0.updatedAt
                )
            }

        return RelationshipVaultExportSnapshot(
            schemaVersion: currentSchemaVersion,
            exportedAt: exportedAt,
            counts: RelationshipVaultExportCounts(
                truthBeads: truthBeads.count,
                voiceCards: voiceCards.count,
                savedDrafts: savedDrafts.count
            ),
            truthBeads: truthBeads,
            voiceCards: voiceCards,
            savedDrafts: savedDrafts
        )
    }

    public static func encodedData(
        for snapshot: RelationshipVaultExportSnapshot
    ) throws -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        return try encoder.encode(snapshot)
    }

    public static func writeExportFile(
        in context: ModelContext,
        directory: URL = FileManager.default.temporaryDirectory,
        fileManager: FileManager = .default,
        exportedAt: Date = Date()
    ) throws -> URL {
        let snapshot = try snapshot(in: context, exportedAt: exportedAt)
        let data = try encodedData(for: snapshot)
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)

        let fileURL = directory.appendingPathComponent(
            fileName(exportedAt: exportedAt),
            isDirectory: false
        )
        try data.write(to: fileURL, options: [.atomic])
        return fileURL
    }

    public static func fileName(exportedAt: Date) -> String {
        "prosepal-local-data-\(Int(exportedAt.timeIntervalSince1970)).json"
    }
}

public actor SwiftDataRelationshipMemoryProvider: RelationshipMemoryProviding {
    private let container: ModelContainer

    public init(container: ModelContainer) {
        self.container = container
    }

    public func approvedTruthBeads(for personName: String) async throws -> [TruthBead] {
        let normalizedName = RelationshipPersonKey.normalized(personName)
        guard !normalizedName.isEmpty else { return [] }

        let context = ModelContext(container)
        let descriptor = FetchDescriptor<RelationshipTruthBeadRecord>(
            predicate: #Predicate {
                $0.isUserApproved && $0.normalizedPersonName == normalizedName
            },
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )

        return try context.fetch(descriptor).map(\.truthBead)
    }

    public func approvedVoiceCard(for personName: String) async throws -> RelationshipVoiceCard? {
        let normalizedName = RelationshipPersonKey.normalized(personName)
        guard !normalizedName.isEmpty else { return nil }

        let context = ModelContext(container)
        var descriptor = FetchDescriptor<RelationshipVoiceCardRecord>(
            predicate: #Predicate {
                $0.isUserApproved && $0.normalizedPersonName == normalizedName
            },
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )
        descriptor.fetchLimit = 1

        return try context.fetch(descriptor).first?.voiceCard
    }
}

@Model
public final class SavedMomentDraftRecord {
    public var id: UUID
    public var personName: String
    public var normalizedPersonName: String = ""
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
        self.normalizedPersonName = RelationshipPersonKey.normalized(personName)
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

    public func updateMessageText(
        _ messageText: String,
        updatedAt: Date = Date()
    ) {
        self.messageText = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        self.updatedAt = updatedAt
    }
}
