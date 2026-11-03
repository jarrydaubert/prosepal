import Foundation
import ProsePalAPI
import SwiftData
import Testing
@testable import ProsePalUI

@Test
func draftSharingOffersOnlyCopyAndSystemShare() {
    #expect(MomentTextSharePresentation.actions == [.copy, .share])
    #expect(MomentTextShareAction.copy.title == "Copy")
    #expect(MomentTextShareAction.share.title == "Share")
    #expect(MomentTextShareAction.copy.systemImage == "doc.on.doc")
    #expect(MomentTextShareAction.share.systemImage == "square.and.arrow.up")
}

@Test
func copyingWritesTheExactDraftAndRecordsOnlyCompletedCopy() {
    let presentation = MomentTextSharePresentation(
        text: "Thank you for being there.",
        surface: .activeDraft
    )
    var clipboardText: String?

    let interaction = presentation.copy { clipboardText = $0 }

    #expect(clipboardText == "Thank you for being there.")
    #expect(interaction == .copyCompleted)
    #expect(MomentShareTelemetryPolicy.diagnosticsAction(for: interaction) == "copy")
}

@Test
func presentingOrCancellingShareRecordsNoSendOrDestination() {
    #expect(MomentShareTelemetryPolicy.diagnosticsAction(for: .sharePresented) == nil)
    #expect(MomentShareTelemetryPolicy.diagnosticsAction(for: .shareCancelled) == nil)
}

@Test
func savedDraftSharingUsesTheSameTruthfulTextContract() {
    let presentation = MomentTextSharePresentation(
        text: "Saved words.",
        surface: .savedDraft
    )

    #expect(presentation.text == "Saved words.")
    #expect(presentation.accessibilityIdentifier(for: .copy) == "savedDraft.copy")
    #expect(presentation.accessibilityIdentifier(for: .share) == "savedDraft.share")
}

@Test
func activeDraftSharingExposesStableAccessibilityIdentifiers() {
    let presentation = MomentTextSharePresentation(
        text: "Current words.",
        surface: .activeDraft
    )

    #expect(presentation.accessibilityIdentifier(for: .copy) == "activeDraft.copy")
    #expect(presentation.accessibilityIdentifier(for: .share) == "activeDraft.share")
    #expect(!MomentTextShareAction.copy.title.isEmpty)
    #expect(!MomentTextShareAction.share.title.isEmpty)
}

@Test
@MainActor
func localDataExportPreservesFilenameAndJSONAndCleansTemporaryFiles() throws {
    let container = try RelationshipVaultContainerFactory.makeEphemeral()
    let context = container.mainContext
    context.insert(RelationshipTruthBeadRecord(
        personName: "Asha",
        text: "Loves direct notes"
    ))
    try context.save()

    let exportedAt = Date(timeIntervalSince1970: 42)
    let snapshot = try RelationshipVaultExporter.snapshot(
        in: context,
        exportedAt: exportedAt
    )
    let export = try MomentLocalDataExport(
        snapshot: snapshot,
        exportedAt: exportedAt
    )
    let root = FileManager.default.temporaryDirectory
        .appendingPathComponent("MomentLocalDataExportTests-\(UUID().uuidString)", isDirectory: true)
    defer { try? FileManager.default.removeItem(at: root) }

    let fileURL = try export.writeTemporaryFile(rootDirectory: root)
    let writtenData = try Data(contentsOf: fileURL)
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    let decoded = try decoder.decode(RelationshipVaultExportSnapshot.self, from: writtenData)

    #expect(export.fileName == "prosepal-local-data-42.json")
    #expect(fileURL.lastPathComponent == export.fileName)
    #expect(writtenData == export.jsonData)
    #expect(export.jsonString.contains("Loves direct notes"))
    #expect(decoded.schemaVersion == snapshot.schemaVersion)
    #expect(decoded.exportedAt == snapshot.exportedAt)
    #expect(decoded.counts == snapshot.counts)
    #expect(decoded.truthBeads.map(\.id) == snapshot.truthBeads.map(\.id))
    #expect(decoded.truthBeads.map(\.text) == snapshot.truthBeads.map(\.text))

    try MomentLocalDataExport.removeTemporaryFiles(rootDirectory: root)
    #expect(!FileManager.default.fileExists(atPath: fileURL.path))
}
