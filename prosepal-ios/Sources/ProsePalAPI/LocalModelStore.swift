import Foundation

public enum LocalModelLane: String, CaseIterable, Sendable {
    case standard
}

public struct LocalModelManifest: Codable, Equatable, Sendable {
    public var id: String
    public var version: String
    public var byteCount: Int64
    public var checksumSHA256: String
    public var minimumAppVersion: String?
    public var releaseChannel: String

    public init(
        id: String,
        version: String,
        byteCount: Int64,
        checksumSHA256: String,
        minimumAppVersion: String? = nil,
        releaseChannel: String = "staging"
    ) {
        self.id = id
        self.version = version
        self.byteCount = byteCount
        self.checksumSHA256 = checksumSHA256
        self.minimumAppVersion = minimumAppVersion
        self.releaseChannel = releaseChannel
    }
}

public enum LocalModelStoreError: Error, Equatable, Sendable {
    case invalidVersionIdentifier(String)
    case modelNotInstalled(version: String)
    case manifestNotFound(version: String)
}

public struct LocalModelStore {
    private let fileManager: FileManager
    private let applicationSupportDirectory: URL
    private let productDirectoryName: String

    public init(
        applicationSupportDirectory: URL,
        productDirectoryName: String = "ProsePal",
        fileManager: FileManager = .default
    ) {
        self.applicationSupportDirectory = applicationSupportDirectory
        self.productDirectoryName = productDirectoryName
        self.fileManager = fileManager
    }

    public static func live(fileManager: FileManager = .default) throws -> LocalModelStore {
        guard let applicationSupportDirectory = fileManager
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)
            .first
        else {
            throw CocoaError(.fileNoSuchFile)
        }

        return LocalModelStore(
            applicationSupportDirectory: applicationSupportDirectory,
            fileManager: fileManager
        )
    }

    public func modelsRootDirectory() throws -> URL {
        let directory = applicationSupportDirectory
            .appendingPathComponent(productDirectoryName, isDirectory: true)
            .appendingPathComponent("Models", isDirectory: true)

        try createDirectoryExcludedFromBackup(at: directory)
        return directory
    }

    public func laneDirectory(for lane: LocalModelLane = .standard) throws -> URL {
        let directory = try modelsRootDirectory()
            .appendingPathComponent(lane.rawValue, isDirectory: true)

        try createDirectoryExcludedFromBackup(at: directory)
        return directory
    }

    public func modelDirectory(version: String, lane: LocalModelLane = .standard) throws -> URL {
        try validate(version: version)

        return try laneDirectory(for: lane)
            .appendingPathComponent(version, isDirectory: true)
    }

    @discardableResult
    public func prepareModelDirectory(
        for manifest: LocalModelManifest,
        lane: LocalModelLane = .standard
    ) throws -> URL {
        let directory = try modelDirectory(version: manifest.version, lane: lane)
        try createDirectoryExcludedFromBackup(at: directory)
        try writeManifest(manifest, lane: lane)
        return directory
    }

    public func writeManifest(_ manifest: LocalModelManifest, lane: LocalModelLane = .standard) throws {
        let directory = try modelDirectory(version: manifest.version, lane: lane)
        try createDirectoryExcludedFromBackup(at: directory)

        let data = try JSONEncoder.localModelManifest.encode(manifest)
        try data.write(to: manifestURL(version: manifest.version, lane: lane), options: [.atomic])
    }

    public func readManifest(version: String, lane: LocalModelLane = .standard) throws -> LocalModelManifest {
        let url = try manifestURL(version: version, lane: lane)
        guard fileManager.fileExists(atPath: url.path) else {
            throw LocalModelStoreError.manifestNotFound(version: version)
        }

        let data = try Data(contentsOf: url)
        return try JSONDecoder.localModelManifest.decode(LocalModelManifest.self, from: data)
    }

    public func installedVersions(lane: LocalModelLane = .standard) throws -> [String] {
        let directory = try laneDirectory(for: lane)
        let urls = try fileManager.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        )

        return try urls.compactMap { url in
            let resourceValues = try url.resourceValues(forKeys: [.isDirectoryKey])
            return resourceValues.isDirectory == true ? url.lastPathComponent : nil
        }
        .sorted()
    }

    public func setActiveVersion(_ version: String, lane: LocalModelLane = .standard) throws {
        try validate(version: version)
        let directory = try modelDirectory(version: version, lane: lane)
        guard fileManager.fileExists(atPath: directory.path) else {
            throw LocalModelStoreError.modelNotInstalled(version: version)
        }

        let activeURL = try activeVersionURL(lane: lane)
        try version.data(using: .utf8)?.write(to: activeURL, options: [.atomic])
    }

    public func activeVersion(lane: LocalModelLane = .standard) throws -> String? {
        let url = try activeVersionURL(lane: lane)
        guard fileManager.fileExists(atPath: url.path) else { return nil }

        let data = try Data(contentsOf: url)
        return String(data: data, encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .nilIfBlank
    }

    public func removeModel(version: String, lane: LocalModelLane = .standard) throws {
        let directory = try modelDirectory(version: version, lane: lane)
        guard fileManager.fileExists(atPath: directory.path) else { return }

        try fileManager.removeItem(at: directory)

        if try activeVersion(lane: lane) == version {
            try? fileManager.removeItem(at: activeVersionURL(lane: lane))
        }
    }

    private func manifestURL(version: String, lane: LocalModelLane) throws -> URL {
        try modelDirectory(version: version, lane: lane)
            .appendingPathComponent("manifest.json", isDirectory: false)
    }

    private func activeVersionURL(lane: LocalModelLane) throws -> URL {
        try laneDirectory(for: lane)
            .appendingPathComponent(".active-version", isDirectory: false)
    }

    private func createDirectoryExcludedFromBackup(at directory: URL) throws {
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)

        var mutableDirectory = directory
        var resourceValues = URLResourceValues()
        resourceValues.isExcludedFromBackup = true
        try mutableDirectory.setResourceValues(resourceValues)
    }

    private func validate(version: String) throws {
        let trimmedVersion = version.trimmingCharacters(in: .whitespacesAndNewlines)
        let isUnsafePathComponent = trimmedVersion.isEmpty
            || trimmedVersion == "."
            || trimmedVersion == ".."
            || trimmedVersion.contains("/")
            || trimmedVersion.contains("\\")

        if isUnsafePathComponent {
            throw LocalModelStoreError.invalidVersionIdentifier(version)
        }
    }
}

private extension JSONEncoder {
    static var localModelManifest: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }
}

private extension JSONDecoder {
    static var localModelManifest: JSONDecoder {
        JSONDecoder()
    }
}

private extension String {
    var nilIfBlank: String? {
        isEmpty ? nil : self
    }
}
