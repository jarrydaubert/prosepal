import Foundation
import SwiftData
import XCTest
import ProsePalDomain
@testable import ProsePalAPI

final class RelationshipVaultTests: XCTestCase {
    func testRelationshipRecordsEnforceDomainOwnedTextLimitsBeforePersistence() {
        let longName = String(repeating: "n", count: ProsePalTextLimit.personName + 20)
        let truthBead = RelationshipTruthBeadRecord(
            personName: longName,
            text: String(repeating: "t", count: ProsePalTextLimit.relationshipMemory + 20)
        )
        let voiceCard = RelationshipVoiceCardRecord(
            personName: longName,
            summary: String(repeating: "v", count: ProsePalTextLimit.voiceCard + 20)
        )
        let draft = SavedMomentDraftRecord(
            moment: MomentInput(
                personName: longName,
                relationship: .closeFriend,
                occasion: .birthday,
                trueThing: String(repeating: "d", count: ProsePalTextLimit.momentDetail + 20)
            ),
            messageText: String(repeating: "m", count: ProsePalTextLimit.draft + 20),
            lane: .privateDraft
        )

        XCTAssertEqual(truthBead.personName.count, ProsePalTextLimit.personName)
        XCTAssertEqual(truthBead.text.count, ProsePalTextLimit.relationshipMemory)
        XCTAssertEqual(voiceCard.summary.count, ProsePalTextLimit.voiceCard)
        XCTAssertEqual(draft.trueThing.count, ProsePalTextLimit.momentDetail)
        XCTAssertEqual(draft.messageText.count, ProsePalTextLimit.draft)
    }

    func testRelationshipMemoryProviderReturnsOnlyApprovedBeadsForPerson() async throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        context.insert(RelationshipTruthBeadRecord(
            personName: "José",
            text: "Loves Sunday walks",
            isUserApproved: true
        ))
        context.insert(RelationshipTruthBeadRecord(
            personName: "José",
            text: "Draft detail that was not approved",
            isUserApproved: false
        ))
        context.insert(RelationshipTruthBeadRecord(
            personName: "Asha",
            text: "Prefers short notes",
            isUserApproved: true
        ))
        try context.save()

        let provider = SwiftDataRelationshipMemoryProvider(container: container)
        let beads = try await provider.approvedTruthBeads(for: "  JOSE  ")

        XCTAssertEqual(beads.map(\.text), ["Loves Sunday walks"])
    }

    func testRelationshipMemoryProviderReturnsNothingForBlankPerson() async throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        context.insert(RelationshipTruthBeadRecord(
            personName: "Mum",
            text: "Loves handwritten notes",
            isUserApproved: true
        ))
        try context.save()

        let provider = SwiftDataRelationshipMemoryProvider(container: container)
        let beads = try await provider.approvedTruthBeads(for: "   ")

        XCTAssertTrue(beads.isEmpty)
    }

    func testRelationshipMemoryProviderReturnsOnlyApprovedVoiceCardForPerson() async throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        context.insert(RelationshipVoiceCardRecord(
            personName: "José",
            summary: "Warm and direct",
            isUserApproved: true,
            updatedAt: Date(timeIntervalSince1970: 2_000)
        ))
        context.insert(RelationshipVoiceCardRecord(
            personName: "José",
            summary: "Paused style",
            isUserApproved: false,
            updatedAt: Date(timeIntervalSince1970: 3_000)
        ))
        context.insert(RelationshipVoiceCardRecord(
            personName: "Asha",
            summary: "More formal",
            isUserApproved: true,
            updatedAt: Date(timeIntervalSince1970: 4_000)
        ))
        try context.save()

        let provider = SwiftDataRelationshipMemoryProvider(container: container)
        let voiceCard = try await provider.approvedVoiceCard(for: "  JOSE  ")

        XCTAssertEqual(voiceCard?.summary, "Warm and direct")
    }

    func testPrivateDraftUsesApprovedPromptMemoryWithoutToolCalling() throws {
        let source = try String(
            contentsOf: packageRoot.appending(path: "Sources/ProsePalAPI/FoundationModelsPrivateDraftClient.swift"),
            encoding: .utf8
        )

        XCTAssertTrue(source.contains("let approvedBeads = try await memoryProvider.approvedTruthBeads"))
        XCTAssertTrue(source.contains("let approvedVoiceCard = try await memoryProvider.approvedVoiceCard"))
        XCTAssertTrue(source.contains("Approved relationship memory:"))
        XCTAssertTrue(source.contains("Treat approved voice cards as style guidance only; do not quote them as facts."))
        XCTAssertTrue(source.contains("Approved voice card:"))
        XCTAssertTrue(source.contains("generating: PrivateDraftContent.self"))
        XCTAssertTrue(source.contains("catch let error as LanguageModelSession.GenerationError"))
        XCTAssertFalse(source.contains("RelationshipMemoryArguments"))
        XCTAssertFalse(source.contains("RelationshipMemoryTool"))
        XCTAssertFalse(source.contains("tools:"))
    }

    func testRelationshipRecordsPersistStableNormalizedPersonKeys() {
        let truthBead = RelationshipTruthBeadRecord(
            personName: " José ",
            text: "Loves Sunday walks"
        )
        let voiceCard = RelationshipVoiceCardRecord(
            personName: " Élodie ",
            summary: "Gentle and direct"
        )
        let savedDraft = SavedMomentDraftRecord(
            moment: MomentInput(
                personName: " Mira ",
                relationship: .closeFriend,
                occasion: .thankYou,
                trueThing: "She checked in."
            ),
            messageText: "Thank you for checking in.",
            lane: .privateDraft
        )

        XCTAssertEqual(truthBead.normalizedPersonName, "jose")
        XCTAssertEqual(voiceCard.normalizedPersonName, "elodie")
        XCTAssertEqual(savedDraft.normalizedPersonName, "mira")
    }

    func testRelationshipVaultMaintenanceRepairsLegacyMissingPersonKeys() async throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let truthBead = RelationshipTruthBeadRecord(
            personName: "José",
            text: "Loves Sunday walks",
            isUserApproved: true
        )
        truthBead.normalizedPersonName = ""
        let voiceCard = RelationshipVoiceCardRecord(
            personName: "José",
            summary: "Warm and direct",
            isUserApproved: true
        )
        voiceCard.normalizedPersonName = ""
        let savedDraft = SavedMomentDraftRecord(
            moment: MomentInput(
                personName: "José",
                relationship: .closeFriend,
                occasion: .thankYou,
                trueThing: "He helped with the garden."
            ),
            messageText: "Thank you for the garden help.",
            lane: .privateDraft
        )
        savedDraft.normalizedPersonName = ""

        context.insert(truthBead)
        context.insert(voiceCard)
        context.insert(savedDraft)
        try context.save()

        try RelationshipVaultMaintenance.repairLegacyPersonKeys(in: container)
        let provider = SwiftDataRelationshipMemoryProvider(container: container)
        let beads = try await provider.approvedTruthBeads(for: "  JOSE  ")
        let approvedVoiceCard = try await provider.approvedVoiceCard(for: "  JOSE  ")

        XCTAssertEqual(beads.map(\.text), ["Loves Sunday walks"])
        XCTAssertEqual(approvedVoiceCard?.summary, "Warm and direct")

        let verificationContext = ModelContext(container)
        let storedTruthBead = try XCTUnwrap(
            verificationContext.fetch(FetchDescriptor<RelationshipTruthBeadRecord>()).first
        )
        let storedVoiceCard = try XCTUnwrap(
            verificationContext.fetch(FetchDescriptor<RelationshipVoiceCardRecord>()).first
        )
        let storedDraft = try XCTUnwrap(
            verificationContext.fetch(FetchDescriptor<SavedMomentDraftRecord>()).first
        )
        XCTAssertEqual(storedTruthBead.normalizedPersonName, "jose")
        XCTAssertEqual(storedVoiceCard.normalizedPersonName, "jose")
        XCTAssertEqual(storedDraft.normalizedPersonName, "jose")
    }

    func testVersionedContainerOpensLegacyFixtureAndRepairsPersonKeys() throws {
        let fileManager = FileManager.default
        let rootDirectory = fileManager.temporaryDirectory
            .appendingPathComponent("ProsePalVaultMigrationTests-\(UUID().uuidString)", isDirectory: true)
        try fileManager.createDirectory(at: rootDirectory, withIntermediateDirectories: true)
        defer { try? fileManager.removeItem(at: rootDirectory) }
        let storeURL = rootDirectory.appendingPathComponent("legacy.store")

        do {
            let legacySchema = Schema(RelationshipVaultSchema.models)
            let legacyConfiguration = ModelConfiguration(schema: legacySchema, url: storeURL)
            let legacyContainer = try ModelContainer(
                for: legacySchema,
                configurations: [legacyConfiguration]
            )
            let legacyContext = ModelContext(legacyContainer)
            let truthBead = RelationshipTruthBeadRecord(
                personName: " José ",
                text: "Legacy detail"
            )
            truthBead.normalizedPersonName = ""
            legacyContext.insert(truthBead)
            try legacyContext.save()
        }

        let upgradedContainer = try RelationshipVaultContainerFactory.makePersistent(
            storeURL: storeURL
        )
        let upgradedContext = ModelContext(upgradedContainer)
        let upgradedRecord = try XCTUnwrap(
            upgradedContext.fetch(FetchDescriptor<RelationshipTruthBeadRecord>()).first
        )

        XCTAssertEqual(upgradedRecord.text, "Legacy detail")
        XCTAssertEqual(upgradedRecord.normalizedPersonName, "jose")
        XCTAssertEqual(RelationshipVaultSchemaV1.versionIdentifier, Schema.Version(1, 0, 0))
        XCTAssertEqual(RelationshipVaultMigrationPlan.schemas.count, 1)
    }

    func testRelationshipTruthBeadRecordUpdateTrimsAndTouchesTimestamp() {
        let originalDate = Date(timeIntervalSince1970: 1_000)
        let updatedDate = Date(timeIntervalSince1970: 2_000)
        let record = RelationshipTruthBeadRecord(
            personName: " Alex ",
            text: " Likes long walks ",
            isUserApproved: true,
            updatedAt: originalDate
        )

        record.update(
            personName: "  Asha  ",
            text: "  Prefers short notes  ",
            isUserApproved: false,
            updatedAt: updatedDate
        )

        XCTAssertEqual(record.personName, "Asha")
        XCTAssertEqual(record.normalizedPersonName, "asha")
        XCTAssertEqual(record.text, "Prefers short notes")
        XCTAssertFalse(record.isUserApproved)
        XCTAssertEqual(record.updatedAt, updatedDate)
    }

    func testRelationshipVoiceCardRecordUpdateTrimsAndTouchesTimestamp() {
        let originalDate = Date(timeIntervalSince1970: 1_000)
        let updatedDate = Date(timeIntervalSince1970: 2_000)
        let record = RelationshipVoiceCardRecord(
            personName: " Alex ",
            summary: " Short and funny ",
            isUserApproved: true,
            updatedAt: originalDate
        )

        record.update(
            personName: "  Asha  ",
            summary: "  Gentle and simple  ",
            isUserApproved: false,
            updatedAt: updatedDate
        )

        XCTAssertEqual(record.personName, "Asha")
        XCTAssertEqual(record.normalizedPersonName, "asha")
        XCTAssertEqual(record.summary, "Gentle and simple")
        XCTAssertFalse(record.isUserApproved)
        XCTAssertEqual(record.updatedAt, updatedDate)
    }

    func testSavedMomentDraftRecordCapturesMomentMetadata() {
        let createdAt = Date(timeIntervalSince1970: 2_000)
        let moment = MomentInput(
            personName: "Asha",
            relationship: .romantic,
            occasion: .anniversary,
            register: .confess,
            trueThing: "I still love quiet mornings together.",
            tone: .poetic,
            length: .detailed
        )

        let record = SavedMomentDraftRecord(
            moment: moment,
            messageText: "A saved anniversary draft.",
            lane: .takeMoreCare,
            createdAt: createdAt
        )

        XCTAssertEqual(record.personName, "Asha")
        XCTAssertEqual(record.relationship, Relationship.romantic)
        XCTAssertEqual(record.occasion, Occasion.anniversary)
        XCTAssertEqual(record.register, MomentRegister.confess)
        XCTAssertEqual(record.tone, Tone.poetic)
        XCTAssertEqual(record.length, MessageLength.detailed)
        XCTAssertEqual(record.lane, MomentDraftLane.takeMoreCare)
        XCTAssertEqual(record.trueThing, "I still love quiet mornings together.")
        XCTAssertEqual(record.messageText, "A saved anniversary draft.")
        XCTAssertEqual(record.normalizedPersonName, "asha")
        XCTAssertEqual(record.title, "Asha")
        XCTAssertEqual(record.subtitle, "Anniversary · Partner")
        XCTAssertEqual(record.createdAt, createdAt)
        XCTAssertEqual(record.updatedAt, createdAt)
    }

    func testSavedMomentDraftRecordUpdateMessageTextTrimsAndTouchesTimestamp() {
        let originalDate = Date(timeIntervalSince1970: 3_000)
        let updatedDate = Date(timeIntervalSince1970: 4_000)
        let record = SavedMomentDraftRecord(
            moment: MomentInput(
                personName: "Dad",
                relationship: .parent,
                occasion: .birthday,
                trueThing: "He loves a quiet cup of tea."
            ),
            messageText: "Happy birthday, Dad.",
            lane: .privateDraft,
            createdAt: originalDate
        )

        record.updateMessageText("  Updated birthday draft.  ", updatedAt: updatedDate)

        XCTAssertEqual(record.messageText, "Updated birthday draft.")
        XCTAssertEqual(record.createdAt, originalDate)
        XCTAssertEqual(record.updatedAt, updatedDate)
    }

    func testSavedMomentDraftRecordsPersistFetchUpdateAndDeleteLocally() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let draft = SavedMomentDraftRecord(
            moment: MomentInput(
                personName: "Dad",
                relationship: .parent,
                occasion: .birthday,
                trueThing: "He loves a quiet cup of tea."
            ),
            messageText: "Happy birthday, Dad.",
            lane: .privateDraft,
            createdAt: Date(timeIntervalSince1970: 3_000)
        )

        context.insert(draft)
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<SavedMomentDraftRecord>())
        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched.first?.title, "Dad")
        XCTAssertEqual(fetched.first?.subtitle, "Birthday · Parent")

        fetched[0].updateMessageText(
            "Updated birthday draft.",
            updatedAt: Date(timeIntervalSince1970: 4_000)
        )
        try context.save()

        let updated = try XCTUnwrap(context.fetch(FetchDescriptor<SavedMomentDraftRecord>()).first)
        XCTAssertEqual(updated.messageText, "Updated birthday draft.")
        XCTAssertEqual(updated.updatedAt, Date(timeIntervalSince1970: 4_000))

        context.delete(updated)
        try context.save()

        XCTAssertTrue(try context.fetch(FetchDescriptor<SavedMomentDraftRecord>()).isEmpty)
    }

    func testRelationshipVaultExporterCreatesUserReadableSnapshotWithoutInternalKeys() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        context.insert(RelationshipTruthBeadRecord(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000101")!,
            personName: "Asha",
            text: "Loves direct notes",
            isUserApproved: true,
            createdAt: Date(timeIntervalSince1970: 1_000),
            updatedAt: Date(timeIntervalSince1970: 1_500)
        ))
        context.insert(RelationshipTruthBeadRecord(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000102")!,
            personName: "Asha",
            text: "Paused detail",
            isUserApproved: false,
            createdAt: Date(timeIntervalSince1970: 2_000),
            updatedAt: Date(timeIntervalSince1970: 2_500)
        ))
        context.insert(RelationshipVoiceCardRecord(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000201")!,
            personName: "Asha",
            summary: "Warm and brief",
            isUserApproved: true,
            createdAt: Date(timeIntervalSince1970: 3_000),
            updatedAt: Date(timeIntervalSince1970: 3_500)
        ))
        context.insert(SavedMomentDraftRecord(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000301")!,
            personName: "Asha",
            relationshipRawValue: Relationship.closeFriend.rawValue,
            occasionRawValue: Occasion.thankYou.rawValue,
            registerRawValue: MomentRegister.react.rawValue,
            toneRawValue: Tone.heartfelt.rawValue,
            lengthRawValue: MessageLength.standard.rawValue,
            laneRawValue: MomentDraftLane.privateDraft.rawValue,
            trueThing: "Thank you for showing up.",
            messageText: "Thank you for being there.",
            createdAt: Date(timeIntervalSince1970: 4_000),
            updatedAt: Date(timeIntervalSince1970: 4_500)
        ))
        try context.save()

        let snapshot = try RelationshipVaultExporter.snapshot(
            in: context,
            exportedAt: Date(timeIntervalSince1970: 5_000)
        )
        let data = try RelationshipVaultExporter.encodedData(for: snapshot)
        let json = try XCTUnwrap(String(data: data, encoding: .utf8))

        XCTAssertEqual(snapshot.schemaVersion, 1)
        XCTAssertEqual(snapshot.counts.truthBeads, 2)
        XCTAssertEqual(snapshot.counts.voiceCards, 1)
        XCTAssertEqual(snapshot.counts.savedDrafts, 1)
        XCTAssertEqual(snapshot.truthBeads.map(\.text), ["Loves direct notes", "Paused detail"])
        XCTAssertEqual(snapshot.voiceCards.first?.summary, "Warm and brief")
        XCTAssertEqual(snapshot.savedDrafts.first?.messageText, "Thank you for being there.")
        XCTAssertFalse(json.contains("normalizedPersonName"))
        XCTAssertFalse(json.contains("normalized"))
        XCTAssertFalse(json.contains("RelationshipVault.store"))
        XCTAssertTrue(json.contains("Loves direct notes"))
        XCTAssertTrue(json.contains("Thank you for being there."))
    }

    func testRelationshipVaultExporterWritesJsonFile() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        context.insert(RelationshipTruthBeadRecord(
            personName: "Asha",
            text: "Loves direct notes"
        ))
        try context.save()

        let fileManager = FileManager.default
        let directory = fileManager.temporaryDirectory
            .appendingPathComponent("ProsePalVaultExportTests-\(UUID().uuidString)", isDirectory: true)
        defer { try? fileManager.removeItem(at: directory) }

        let fileURL = try RelationshipVaultExporter.writeExportFile(
            in: context,
            directory: directory,
            exportedAt: Date(timeIntervalSince1970: 42)
        )
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(
            RelationshipVaultExportSnapshot.self,
            from: Data(contentsOf: fileURL)
        )

        XCTAssertEqual(fileURL.lastPathComponent, "prosepal-local-data-42.json")
        XCTAssertEqual(decoded.counts.truthBeads, 1)
        XCTAssertEqual(decoded.truthBeads.first?.text, "Loves direct notes")
    }

    func testRelationshipVaultLocalDataEraserDeletesAllLocalVaultRecords() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        context.insert(RelationshipTruthBeadRecord(
            personName: "Asha",
            text: "Loves direct notes"
        ))
        context.insert(RelationshipVoiceCardRecord(
            personName: "Asha",
            summary: "Warm and brief"
        ))
        context.insert(SavedMomentDraftRecord(
            moment: MomentInput(
                personName: "Asha",
                relationship: .closeFriend,
                occasion: .thankYou,
                trueThing: "Thank you for showing up."
            ),
            messageText: "Thank you for being there.",
            lane: .privateDraft
        ))
        try context.save()

        try RelationshipVaultLocalDataEraser.eraseAll(in: context)

        XCTAssertTrue(try context.fetch(FetchDescriptor<RelationshipTruthBeadRecord>()).isEmpty)
        XCTAssertTrue(try context.fetch(FetchDescriptor<RelationshipVoiceCardRecord>()).isEmpty)
        XCTAssertTrue(try context.fetch(FetchDescriptor<SavedMomentDraftRecord>()).isEmpty)
    }

    func testRelationshipVaultLocalDataEraserCreatesContextForContainerErase() async throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        context.insert(RelationshipTruthBeadRecord(
            personName: "Asha",
            text: "Loves direct notes"
        ))
        context.insert(RelationshipVoiceCardRecord(
            personName: "Asha",
            summary: "Warm and brief"
        ))
        context.insert(SavedMomentDraftRecord(
            moment: MomentInput(
                personName: "Asha",
                relationship: .closeFriend,
                occasion: .thankYou,
                trueThing: "Thank you for showing up."
            ),
            messageText: "Thank you for being there.",
            lane: .privateDraft
        ))
        try context.save()

        try await RelationshipVaultLocalDataEraser.eraseAll(in: container)

        let verificationContext = ModelContext(container)
        XCTAssertTrue(try verificationContext.fetch(FetchDescriptor<RelationshipTruthBeadRecord>()).isEmpty)
        XCTAssertTrue(try verificationContext.fetch(FetchDescriptor<RelationshipVoiceCardRecord>()).isEmpty)
        XCTAssertTrue(try verificationContext.fetch(FetchDescriptor<SavedMomentDraftRecord>()).isEmpty)
    }

    func testRelationshipVaultContainerFactoryFallsBackToEphemeralWhenPersistentStoreUnavailable() throws {
        let fileManager = FileManager.default
        let rootDirectory = fileManager.temporaryDirectory
            .appendingPathComponent("ProsePalVaultFactoryTests-\(UUID().uuidString)", isDirectory: true)
        try fileManager.createDirectory(at: rootDirectory, withIntermediateDirectories: true)
        defer { try? fileManager.removeItem(at: rootDirectory) }
        let blockingFile = rootDirectory.appendingPathComponent("not-a-directory", isDirectory: false)
        try "occupied".write(to: blockingFile, atomically: true, encoding: .utf8)

        let result = RelationshipVaultContainerFactory.makePersistentOrEphemeral(
            baseDirectory: blockingFile
        )

        XCTAssertEqual(result.storageMode, .ephemeralFallback)
        XCTAssertFalse(result.isPersistent)

        let context = ModelContext(result.container)
        context.insert(RelationshipTruthBeadRecord(
            personName: "Asha",
            text: "Still usable after persistent store failure"
        ))
        try context.save()

        XCTAssertEqual(
            try context.fetch(FetchDescriptor<RelationshipTruthBeadRecord>()).map(\.text),
            ["Still usable after persistent store failure"]
        )
    }

    func testRelationshipVaultLocalDataEraserRemovesFallbackPersistentStoreFiles() async throws {
        let fileManager = FileManager.default
        let rootDirectory = fileManager.temporaryDirectory
            .appendingPathComponent("ProsePalVaultFallbackEraseTests-\(UUID().uuidString)", isDirectory: true)
        defer { try? fileManager.removeItem(at: rootDirectory) }
        let storeURL = try RelationshipVaultStoreLocation.storeURL(
            fileManager: fileManager,
            baseDirectory: rootDirectory
        )
        try "store".write(to: storeURL, atomically: true, encoding: .utf8)
        let sidecarURL = storeURL.appendingPathExtension("wal")
        try "sidecar".write(to: sidecarURL, atomically: true, encoding: .utf8)
        let result = RelationshipVaultContainerResult(
            container: try makeContainer(),
            storageMode: .ephemeralFallback,
            persistentStoreURL: storeURL
        )

        try await RelationshipVaultLocalDataEraser.eraseAll(in: result)

        XCTAssertTrue(fileManager.fileExists(atPath: storeURL.deletingLastPathComponent().path))
        XCTAssertFalse(fileManager.fileExists(atPath: storeURL.path))
        XCTAssertFalse(fileManager.fileExists(atPath: sidecarURL.path))
    }

    func testRelationshipVaultStoreLocationUsesPrivateBackupExcludedDirectory() throws {
        let fileManager = FileManager.default
        let rootDirectory = fileManager.temporaryDirectory
            .appendingPathComponent("ProsePalVaultTests-\(UUID().uuidString)", isDirectory: true)
        defer { try? fileManager.removeItem(at: rootDirectory) }

        let storeURL = try RelationshipVaultStoreLocation.storeURL(
            fileManager: fileManager,
            baseDirectory: rootDirectory
        )
        let vaultDirectory = storeURL.deletingLastPathComponent()
        let appDirectory = vaultDirectory.deletingLastPathComponent()

        XCTAssertEqual(appDirectory.lastPathComponent, RelationshipVaultStoreLocation.appDirectoryName)
        XCTAssertEqual(vaultDirectory.lastPathComponent, RelationshipVaultStoreLocation.vaultDirectoryName)
        XCTAssertEqual(storeURL.lastPathComponent, RelationshipVaultStoreLocation.storeFileName)
        XCTAssertTrue(fileManager.fileExists(atPath: vaultDirectory.path))

        let resourceValues = try vaultDirectory.resourceValues(forKeys: [.isExcludedFromBackupKey])
        XCTAssertEqual(resourceValues.isExcludedFromBackup, true)
    }

    private func makeContainer() throws -> ModelContainer {
        try RelationshipVaultContainerFactory.makeEphemeral()
    }
}

private var packageRoot: URL {
    URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .deletingLastPathComponent()
}
