import SwiftData
import XCTest
@testable import ProsePalAPI

final class RelationshipVaultTests: XCTestCase {
    func testRelationshipMemoryProviderReturnsOnlyApprovedBeadsForPerson() async throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        context.insert(RelationshipTruthBeadRecord(
            personName: "Jose",
            text: "Loves Sunday walks",
            isUserApproved: true
        ))
        context.insert(RelationshipTruthBeadRecord(
            personName: "Jose",
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
            personName: "Jose",
            summary: "Warm and direct",
            isUserApproved: true,
            updatedAt: Date(timeIntervalSince1970: 2_000)
        ))
        context.insert(RelationshipVoiceCardRecord(
            personName: "Jose",
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
        XCTAssertEqual(record.summary, "Gentle and simple")
        XCTAssertFalse(record.isUserApproved)
        XCTAssertEqual(record.updatedAt, updatedDate)
    }

    private func makeContainer() throws -> ModelContainer {
        let schema = Schema(RelationshipVaultSchema.models)
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        return try ModelContainer(for: schema, configurations: [configuration])
    }
}
