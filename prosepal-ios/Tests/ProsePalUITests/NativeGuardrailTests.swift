import Foundation
import Testing

@Test
func momentExperienceMonolithCanOnlyShrink() throws {
    // Bug this catches: a feature adds more code to the transitional monolith
    // instead of extracting the touched surface behind a cohesive boundary.
    let source = try String(
        contentsOf: packageRoot.appending(path: "Sources/ProsePalUI/MomentExperienceView.swift"),
        encoding: .utf8
    )
    let currentLineCount = source.reduce(into: 0) { count, character in
        if character == "\n" {
            count += 1
        }
    } + (source.last == "\n" || source.isEmpty ? 0 : 1)

    // This baseline may only move downward. Equality prevents an extraction
    // from leaving unused headroom for later growth.
    let lineCountBaseline = 4_425
    #expect(currentLineCount == lineCountBaseline)
}

@Test
func momentExperienceSourceStringGuardsCanOnlyDecrease() throws {
    // Bug this catches: a new existence-only test further couples the suite to
    // the monolith instead of testing the extracted surface's behaviour.
    let monolithPath = "Sources/ProsePalUI/MomentExperienceView.swift"
    let testFiles = try textFiles(in: [packageRoot.appending(path: "Tests")])
        .filter { $0.lastPathComponent != "NativeGuardrailTests.swift" }
    let referenceCount = try testFiles.reduce(into: 0) { count, file in
        let source = try String(contentsOf: file, encoding: .utf8)
        count += source.components(separatedBy: monolithPath).count - 1
    }

    // This baseline may only move downward as guards become behavioral tests.
    let sourceStringGuardBaseline = 2
    #expect(referenceCount == sourceStringGuardBaseline)
}

@Test
func outgoingShareDiagnosticsCannotClaimDestinationOrSuccessfulSending() throws {
    let files = try textFiles(in: [
        packageRoot.appending(path: "Sources/ProsePalUI")
    ])
    let bannedDiagnosticFragments = [
        "send_handoff",
        "share_messages",
        "share_mail",
        "share_notes",
        "sent_message"
    ]

    #expect(try violations(of: bannedDiagnosticFragments, in: files).isEmpty)
}

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
func premiumPresentationNeverPromisesUnlimitedUsage() throws {
    let files = try textFiles(in: [
        packageRoot.appending(path: "App"),
        packageRoot.appending(path: "Sources/ProsePalUI")
    ])
    let bannedClaims = [
        "unlimited",
        "without counting",
        "write without limits",
        "week's free drafts"
    ]

    #expect(try violations(of: bannedClaims, in: files).isEmpty)
}

@Test
func retiredManualCareActionStaysOutOfNativeUISource() throws {
    let bannedTerms = [
        "Take More Care",
        "Take more care",
        "Take care",
        "takeMoreCare",
        "take_more_care",
        "take-more-care"
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
