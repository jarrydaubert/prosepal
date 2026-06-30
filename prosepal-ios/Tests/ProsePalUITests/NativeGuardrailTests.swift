import Foundation
import Testing

@Test
func providerNamesStayOutOfAppAndUISource() throws {
    let bannedTerms = [
        "Firebase",
        "Vertex",
        "Gemini",
        "RevenueCat",
        "OpenAI",
        "Anthropic",
        "Claude",
        "GoogleGenerativeAI",
        "GenerativeAI"
    ]

    let files = try textFiles(in: [
        packageRoot.appending(path: "App"),
        packageRoot.appending(path: "Sources/ProsePalUI")
    ])

    #expect(try violations(of: bannedTerms, in: files).isEmpty)
}

@Test
func nativeDependencyGuardDoesNotIncludeThirdPartyProviderSDKs() throws {
    let bannedTerms = [
        "Firebase",
        "Vertex",
        "Gemini",
        "RevenueCat",
        "OpenAI",
        "Anthropic",
        "Claude",
        "GoogleGenerativeAI",
        "GenerativeAI"
    ]

    let files = try textFiles(in: [
        packageRoot.appending(path: "Package.swift"),
        packageRoot.appending(path: "ProsePal.xcodeproj"),
        packageRoot.appending(path: "App"),
        packageRoot.appending(path: "Sources")
    ])

    #expect(try violations(of: bannedTerms, in: files).isEmpty)
}

private func textFiles(in roots: [URL]) throws -> [URL] {
    let allowedExtensions = Set([
        "entitlements",
        "pbxproj",
        "plist",
        "storekit",
        "swift",
        "xcscheme"
    ])
    var files: [URL] = []

    for root in roots {
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: root.path, isDirectory: &isDirectory) else {
            continue
        }

        if !isDirectory.boolValue {
            files.append(root)
            continue
        }

        let enumerator = FileManager.default.enumerator(
            at: root,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        )

        while let file = enumerator?.nextObject() as? URL {
            let values = try file.resourceValues(forKeys: [.isRegularFileKey])
            guard values.isRegularFile == true else {
                continue
            }
            if allowedExtensions.contains(file.pathExtension) || file.lastPathComponent == "Package.swift" {
                files.append(file)
            }
        }
    }

    return files.sorted { $0.path < $1.path }
}

private func violations(of bannedTerms: [String], in files: [URL]) throws -> [String] {
    try files.flatMap { file in
        let text = try String(contentsOf: file, encoding: .utf8)
        return bannedTerms.compactMap { term in
            text.range(of: term, options: [.caseInsensitive]) == nil
                ? nil
                : "\(relativePath(file)): \(term)"
        }
    }
}

private func relativePath(_ file: URL) -> String {
    let rootPath = packageRoot.path + "/"
    return file.path.hasPrefix(rootPath)
        ? String(file.path.dropFirst(rootPath.count))
        : file.path
}

private var packageRoot: URL {
    URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .deletingLastPathComponent()
}
