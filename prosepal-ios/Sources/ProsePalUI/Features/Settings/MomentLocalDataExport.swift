import CoreTransferable
import Foundation
import ProsePalAPI
import UniformTypeIdentifiers

struct MomentLocalDataExport: Equatable, Sendable, Transferable {
    static let temporaryDirectoryName = "ProsePalLocalDataExports"

    let fileName: String
    let snapshot: RelationshipVaultExportSnapshot
    let jsonData: Data

    init(
        snapshot: RelationshipVaultExportSnapshot,
        exportedAt: Date
    ) throws {
        self.snapshot = snapshot
        fileName = RelationshipVaultExporter.fileName(exportedAt: exportedAt)
        jsonData = try RelationshipVaultExporter.encodedData(for: snapshot)
    }

    var jsonString: String {
        String(decoding: jsonData, as: UTF8.self)
    }

    var preview: String {
        let maxCharacters = 2_400
        guard jsonString.count > maxCharacters else {
            return jsonString
        }

        return String(jsonString.prefix(maxCharacters)) + "\n..."
    }

    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(exportedContentType: .json) { export in
            SentTransferredFile(try export.writeTemporaryFile())
        }
    }

    @discardableResult
    func writeTemporaryFile(
        fileManager: FileManager = .default,
        rootDirectory: URL? = nil
    ) throws -> URL {
        let directory = Self.temporaryDirectory(
            fileManager: fileManager,
            rootDirectory: rootDirectory
        )
        try Self.removeTemporaryFiles(
            fileManager: fileManager,
            rootDirectory: rootDirectory
        )
        try fileManager.createDirectory(
            at: directory,
            withIntermediateDirectories: true
        )

        let fileURL = directory.appendingPathComponent(fileName, isDirectory: false)
        try jsonData.write(to: fileURL, options: [.atomic])
        return fileURL
    }

    static func removeTemporaryFiles(
        fileManager: FileManager = .default,
        rootDirectory: URL? = nil
    ) throws {
        let directory = temporaryDirectory(
            fileManager: fileManager,
            rootDirectory: rootDirectory
        )
        guard fileManager.fileExists(atPath: directory.path) else { return }
        try fileManager.removeItem(at: directory)
    }

    private static func temporaryDirectory(
        fileManager: FileManager,
        rootDirectory: URL?
    ) -> URL {
        (rootDirectory ?? fileManager.temporaryDirectory)
            .appendingPathComponent(temporaryDirectoryName, isDirectory: true)
    }
}
