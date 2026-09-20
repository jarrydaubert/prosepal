import Darwin
import Foundation
import ProsePalEvaluation

@main
struct ProsePalWritingEval {
    static func main() async {
        do {
            let args = Array(CommandLine.arguments.dropFirst())
            switch args.first {
            case "prepare" where args.count == 5:
                guard let seed = UInt64(args[3]) else {
                    throw BlindWritingError(message: "Seed must be an unsigned 64-bit integer.")
                }
                let corpus: [WritingEvaluationScenario] = try read(args[1])
                let outputs: [RecordedWritingOutput] = try read(args[2])
                let batch = try BlindWritingEvaluation.prepare(corpus: corpus, outputs: outputs, seed: seed)
                let directory = try externalDestination(args[4], isDirectory: true)
                guard !FileManager.default.fileExists(atPath: directory.path) else {
                    throw BlindWritingError(message: "Prepare requires a new directory; existing files are never overwritten.")
                }
                try FileManager.default.createDirectory(
                    at: directory, withIntermediateDirectories: true, attributes: [.posixPermissions: 0o700]
                )
                try write(batch.review, to: directory.appendingPathComponent("review.json"))
                try write(batch.key, to: directory.appendingPathComponent("private-key.json"))
                print("Prepared review.json and private-key.json. Give reviewers only review.json and the rubric.")
            case "reveal" where args.count == 4:
                let outputURL = try externalDestination(args[3], isDirectory: false)
                let review: BlindWritingReviewFile = try read(args[1])
                let key: BlindWritingKey = try read(args[2])
                let comparison = try BlindWritingEvaluation.reveal(review, key: key)
                try write(comparison, to: outputURL)
                print("Wrote the identified comparison. Human ratings and advisory findings remain separate.")
            case "record-afm" where args.count == 4:
                let corpus: [WritingEvaluationScenario] = try read(args[1])
                let outputURL = try newCaptureOutput(args[3])
                let outputs = try await WritingEngineCapture.recordFoundationModels(
                    corpus: corpus,
                    engineID: args[2],
                    onProgress: { try writeReplacing($0, to: outputURL) }
                )
                print("Recorded \(outputs.count) Apple Foundation Models responses.")
            case "record-local" where args.count == 6:
                let corpus: [WritingEvaluationScenario] = try read(args[1])
                guard let baseURL = URL(string: args[3]) else {
                    throw BlindWritingError(message: "The local chat-completions base URL is invalid.")
                }
                let outputURL = try newCaptureOutput(args[5])
                let outputs = try await WritingEngineCapture.recordLocalCompatible(
                    corpus: corpus,
                    engineID: args[2],
                    baseURL: baseURL,
                    model: args[4],
                    onProgress: { try writeReplacing($0, to: outputURL) }
                )
                print("Recorded \(outputs.count) local chat-completions responses.")
            default:
                throw BlindWritingError(message: """
                Usage:
                  prosepal-writing-eval prepare CORPUS.json OUTPUTS.json SEED NEW_DIRECTORY
                  prosepal-writing-eval reveal REVIEW.json PRIVATE_KEY.json NEW_COMPARISON.json
                  prosepal-writing-eval record-afm CORPUS.json ENGINE_ID NEW_OUTPUT.json
                  prosepal-writing-eval record-local CORPUS.json ENGINE_ID LOOPBACK_BASE_URL MODEL NEW_OUTPUT.json
                """)
            }
        } catch {
            FileHandle.standardError.write(Data("Evaluation failed: \(error.localizedDescription)\n".utf8))
            exit(1)
        }
    }

    private static func read<Value: Decodable>(_ path: String) throws -> Value {
        try JSONDecoder().decode(Value.self, from: Data(contentsOf: URL(fileURLWithPath: path)))
    }

    private static func write<Value: Encodable>(_ value: Value, to url: URL) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        let data = try encoder.encode(value)
        // Create exclusively with private permissions before writing any content.
        let descriptor = open(url.path, O_WRONLY | O_CREAT | O_EXCL, 0o600)
        guard descriptor >= 0 else {
            throw BlindWritingError(message: "Cannot create output file; check its parent directory and ensure the file does not exist.")
        }
        let handle = FileHandle(fileDescriptor: descriptor, closeOnDealloc: true)
        try handle.write(contentsOf: data)
        try handle.close()
    }

    private static func writeReplacing<Value: Encodable>(_ value: Value, to url: URL) throws {
        let temporaryURL = url.deletingLastPathComponent().appendingPathComponent(
            ".\(url.lastPathComponent).\(UUID().uuidString).tmp"
        )
        try write(value, to: temporaryURL)
        guard rename(temporaryURL.path, url.path) == 0 else {
            unlink(temporaryURL.path)
            throw BlindWritingError(message: "Could not preserve capture progress at the requested output path.")
        }
    }

    private static func newCaptureOutput(_ path: String) throws -> URL {
        let url = try externalDestination(path, isDirectory: false)
        guard !FileManager.default.fileExists(atPath: url.path) else {
            throw BlindWritingError(message: "Capture requires a new output file; existing files are never overwritten.")
        }
        return url
    }

    private static func externalDestination(_ path: String, isDirectory: Bool) throws -> URL {
        let candidate: URL
        if path.hasPrefix("/") {
            candidate = URL(fileURLWithPath: path, isDirectory: isDirectory)
        } else {
            candidate = URL(fileURLWithPath: FileManager.default.currentDirectoryPath, isDirectory: true)
                .appendingPathComponent(path, isDirectory: isDirectory)
        }
        let resolvedCandidate = candidate.standardizedFileURL.resolvingSymlinksInPath()
        let repositoryRoot = sourceRepositoryRoot.resolvingSymlinksInPath().path
        guard resolvedCandidate.path != repositoryRoot,
              !resolvedCandidate.path.hasPrefix(repositoryRoot + "/") else {
            throw BlindWritingError(
                message: "Evaluation outputs and blind-review keys must be written outside the repository."
            )
        }
        return resolvedCandidate
    }

    private static var sourceRepositoryRoot: URL {
        var url = URL(fileURLWithPath: #filePath)
        for _ in 0..<4 {
            url.deleteLastPathComponent()
        }
        return url.standardizedFileURL
    }
}
