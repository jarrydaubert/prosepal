import XCTest
@testable import ProsePalAPI

final class LocalModelStoreTests: XCTestCase {
    func testPrepareModelDirectoryCreatesVersionedDirectoryExcludedFromBackup() throws {
        let harness = try LocalModelStoreHarness()
        defer { harness.cleanUp() }
        let manifest = sampleManifest(version: "gemma-4-e2b-2026-06")

        let directory = try harness.store.prepareModelDirectory(for: manifest)
        let storedManifest = try harness.store.readManifest(version: manifest.version)
        let resourceValues = try directory.resourceValues(forKeys: [.isExcludedFromBackupKey])

        XCTAssertTrue(FileManager.default.fileExists(atPath: directory.path))
        XCTAssertEqual(storedManifest, manifest)
        XCTAssertEqual(resourceValues.isExcludedFromBackup, true)
        XCTAssertEqual(try harness.store.installedVersions(), [manifest.version])
    }

    func testActiveVersionRequiresInstalledModelAndClearsWhenRemoved() throws {
        let harness = try LocalModelStoreHarness()
        defer { harness.cleanUp() }
        let manifest = sampleManifest(version: "standard-local-v1")

        XCTAssertThrowsError(try harness.store.setActiveVersion(manifest.version)) { error in
            XCTAssertEqual(
                error as? LocalModelStoreError,
                .modelNotInstalled(version: manifest.version)
            )
        }

        try harness.store.prepareModelDirectory(for: manifest)
        try harness.store.setActiveVersion(manifest.version)

        XCTAssertEqual(try harness.store.activeVersion(), manifest.version)

        try harness.store.removeModel(version: manifest.version)

        XCTAssertNil(try harness.store.activeVersion())
        XCTAssertEqual(try harness.store.installedVersions(), [])
    }

    func testVersionIdentifiersCannotEscapeModelRoot() throws {
        let harness = try LocalModelStoreHarness()
        defer { harness.cleanUp() }

        for unsafeVersion in ["", ".", "..", "../outside", "nested/version", #"nested\version"#] {
            XCTAssertThrowsError(try harness.store.modelDirectory(version: unsafeVersion)) { error in
                XCTAssertEqual(
                    error as? LocalModelStoreError,
                    .invalidVersionIdentifier(unsafeVersion)
                )
            }
        }
    }

    private func sampleManifest(version: String) -> LocalModelManifest {
        LocalModelManifest(
            id: "standard-local",
            version: version,
            byteCount: 1_234_567,
            checksumSHA256: "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef",
            minimumAppVersion: "0.1.0",
            releaseChannel: "staging"
        )
    }
}

private struct LocalModelStoreHarness {
    let rootDirectory: URL
    let store: LocalModelStore

    init() throws {
        rootDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("ProsePalLocalModelStoreTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: rootDirectory, withIntermediateDirectories: true)
        store = LocalModelStore(applicationSupportDirectory: rootDirectory)
    }

    func cleanUp() {
        try? FileManager.default.removeItem(at: rootDirectory)
    }
}
