import Darwin
import Foundation
import ProsePalEvaluation

@main
struct ProsePalWritingEval {
    static func main() {
        do {
            let args = Array(CommandLine.arguments.dropFirst())
            switch args.first {
            case "prepare" where args.count == 5:
                guard let seed = UInt64(args[3]) else {
                    throw BlindWritingError(message: "Seed must be an unsigned 64-bit integer.")
                }
                let corpus: [WritingQualityFixture] = try read(args[1])
                let outputs: [RecordedWritingOutput] = try read(args[2])
                let batch = try BlindWritingEvaluation.prepare(corpus: corpus, outputs: outputs, seed: seed)
                let directory = URL(fileURLWithPath: args[4], isDirectory: true)
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
                let review: BlindWritingReviewFile = try read(args[1])
                let key: BlindWritingKey = try read(args[2])
                let comparison = try BlindWritingEvaluation.reveal(review, key: key)
                try write(comparison, to: URL(fileURLWithPath: args[3]))
                print("Wrote the identified comparison. Human ratings and advisory findings remain separate.")
            default:
                throw BlindWritingError(message: """
                Usage:
                  prosepal-writing-eval prepare CORPUS.json OUTPUTS.json SEED NEW_DIRECTORY
                  prosepal-writing-eval reveal REVIEW.json PRIVATE_KEY.json NEW_COMPARISON.json
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
}
