import CryptoKit
import Foundation
import ProsePalDomain

public enum RecordedWritingKind: String, Codable, Sendable {
    case message
    case refusal
}

public struct RecordedWritingOutput: Codable, Equatable, Sendable {
    public var engineID: String
    public var scenarioID: String
    public var kind: RecordedWritingKind
    public var text: String
}

public struct BlindWritingSample: Codable, Equatable, Sendable {
    public var id: String
    public var scenarioID: String
    public var rubricVersion: Int
    public var mode: WritingQualityMode
    public var occasion: Occasion
    public var relationship: Relationship
    public var tone: Tone
    public var length: MessageLength
    public var syntheticInput: String
    public var kind: RecordedWritingKind
    public var text: String
}

public struct BlindWritingRating: Codable, Equatable, Sendable {
    public var criterion: WritingQualityCriterion
    // Empty is unreviewed. Reveal accepts only existing rubric rating raw values.
    public var rating: String
    public var reason: String
}

public struct BlindWritingReview: Codable, Equatable, Sendable {
    public var sample: BlindWritingSample
    public var ratings: [BlindWritingRating]
}

public struct BlindWritingReviewFile: Codable, Equatable, Sendable {
    public var formatVersion: Int
    public var keyFingerprint: String
    public var reviews: [BlindWritingReview]
}

public struct BlindWritingIdentity: Codable, Equatable, Sendable {
    public var engineID: String
    public var sample: BlindWritingSample
    public var advisory: [WritingQualityFinding]
}

public struct BlindWritingKey: Codable, Equatable, Sendable {
    public var formatVersion: Int
    public var seed: UInt64
    public var identities: [BlindWritingIdentity]
}

public struct BlindWritingBatch: Sendable {
    public var review: BlindWritingReviewFile
    public var key: BlindWritingKey
}

public struct RevealedWritingReview: Codable, Equatable, Sendable {
    public var engineID: String
    public var sample: BlindWritingSample
    public var findings: [WritingQualityFinding]
    public var advisory: [WritingQualityFinding]
}

public struct BlindWritingError: Error, LocalizedError {
    public var message: String
    public var errorDescription: String? { message }

    public init(message: String) {
        self.message = message
    }
}

public enum BlindWritingEvaluation {
    public static func prepare(
        corpus: [WritingQualityFixture], outputs: [RecordedWritingOutput], seed: UInt64
    ) throws -> BlindWritingBatch {
        let scenarioIDs = corpus.map(\.scenarioID)
        guard !corpus.isEmpty, Set(scenarioIDs).count == corpus.count,
              corpus.allSatisfy({ !$0.scenarioID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && $0.rubricVersion == 3 }) else {
            throw BlindWritingError(message: "Supply unique, nonempty corpus scenarios using rubric version 3.")
        }
        guard outputs.allSatisfy({
            !$0.engineID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
                !$0.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
                scenarioIDs.contains($0.scenarioID)
        }) else {
            throw BlindWritingError(message: "Each recorded response needs an engine ID, a known scenario and nonblank text.")
        }
        var engines = Array(Set(outputs.map(\.engineID))).sorted()
        guard engines.count >= 2 else {
            throw BlindWritingError(message: "A comparison requires at least two engines.")
        }
        let grouped = Dictionary(grouping: outputs, by: \.engineID)
        guard grouped.values.allSatisfy({
            $0.count == corpus.count && Set($0.map(\.scenarioID)) == Set(scenarioIDs)
        }) else {
            throw BlindWritingError(message: "Supply exactly one response per engine for every corpus scenario; no duplicates or missing cells.")
        }

        var random = StableShuffle(seed: seed)
        random.shuffle(&engines)
        var scenarios = corpus.sorted { $0.scenarioID < $1.scenarioID }
        random.shuffle(&scenarios)
        var identities: [BlindWritingIdentity] = []
        for (scenarioIndex, fixture) in scenarios.enumerated() {
            // Rotate a shuffled engine order: positions differ by at most one
            // over the corpus. Engine lists and seeds never enter the review file.
            for position in engines.indices {
                let engine = engines[(position + scenarioIndex) % engines.count]
                guard let output = grouped[engine]?.first(where: { $0.scenarioID == fixture.scenarioID }) else {
                    throw BlindWritingError(message: "The recorded response matrix is incomplete.")
                }
                let sample = BlindWritingSample(
                    id: String(format: "B%04d", identities.count + 1),
                    scenarioID: fixture.scenarioID, rubricVersion: fixture.rubricVersion,
                    mode: fixture.mode, occasion: fixture.occasion, relationship: fixture.relationship,
                    tone: fixture.tone, length: fixture.length, syntheticInput: fixture.syntheticInput,
                    kind: output.kind, text: output.text
                )
                let advisory = output.kind == .message
                    ? WritingQualityEvaluator().evaluateCandidate(output.text, fixture: fixture) : []
                identities.append(BlindWritingIdentity(engineID: engine, sample: sample, advisory: advisory))
            }
        }
        let key = BlindWritingKey(formatVersion: 1, seed: seed, identities: identities)
        let review = BlindWritingReviewFile(
            formatVersion: 1, keyFingerprint: try fingerprint(key),
            reviews: identities.map { identity in
                BlindWritingReview(sample: identity.sample, ratings: WritingQualityCriterion.allCases.map {
                    BlindWritingRating(criterion: $0, rating: "", reason: "")
                })
            }
        )
        return BlindWritingBatch(review: review, key: key)
    }

    public static func reveal(
        _ review: BlindWritingReviewFile, key: BlindWritingKey
    ) throws -> [RevealedWritingReview] {
        guard review.formatVersion == 1, key.formatVersion == 1,
              review.keyFingerprint == (try fingerprint(key)) else {
            throw BlindWritingError(message: "Review and private key must belong to the same supported batch.")
        }
        let ids = key.identities.map { $0.sample.id }
        let reviewIDs = review.reviews.map { $0.sample.id }
        guard !ids.isEmpty, Set(ids).count == ids.count,
              reviewIDs.count == ids.count, Set(reviewIDs) == Set(ids) else {
            throw BlindWritingError(message: "Every anonymous sample must be reviewed exactly once.")
        }
        let byID = Dictionary(uniqueKeysWithValues: key.identities.map { ($0.sample.id, $0) })
        let results = try review.reviews.map { reviewed in
            guard let identity = byID[reviewed.sample.id], identity.sample == reviewed.sample else {
                throw BlindWritingError(message: "Do not edit sample IDs, context or response text during review.")
            }
            guard reviewed.ratings.count == WritingQualityCriterion.allCases.count,
                  Set(reviewed.ratings.map(\.criterion)) == Set(WritingQualityCriterion.allCases) else {
                throw BlindWritingError(message: "Score every rubric criterion exactly once.")
            }
            let findings = try reviewed.ratings.map { score in
                guard let rating = WritingQualityRating(rawValue: score.rating),
                      rating == .pass || !score.reason.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                    throw BlindWritingError(message: "Finish every rating using pass/concern/fail/not_applicable; explain all non-pass ratings.")
                }
                guard score.criterion != .usefulChoice || rating == .notApplicable else {
                    throw BlindWritingError(message: "Use not_applicable for useful_choice: engine responses are not a selectable candidate set.")
                }
                return WritingQualityFinding(criterion: score.criterion, rating: rating, reason: score.reason)
            }
            return RevealedWritingReview(
                engineID: identity.engineID, sample: reviewed.sample,
                findings: findings, advisory: identity.advisory
            )
        }
        return results.sorted {
            $0.engineID == $1.engineID ? $0.sample.scenarioID < $1.sample.scenarioID : $0.engineID < $1.engineID
        }
    }

    private static func fingerprint(_ key: BlindWritingKey) throws -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
        return SHA256.hash(data: try encoder.encode(key)).map { String(format: "%02x", $0) }.joined()
    }
}

// Explicit SplitMix64 + Fisher-Yates avoids system RNG and Swift hash ordering.
private struct StableShuffle {
    var seed: UInt64

    mutating func next() -> UInt64 {
        seed &+= 0x9E3779B97F4A7C15
        var value = seed
        value = (value ^ (value >> 30)) &* 0xBF58476D1CE4E5B9
        value = (value ^ (value >> 27)) &* 0x94D049BB133111EB
        return value ^ (value >> 31)
    }

    mutating func shuffle<Element>(_ values: inout [Element]) {
        guard values.count > 1 else { return }
        for index in stride(from: values.count - 1, through: 1, by: -1) {
            values.swapAt(index, Int(next() % UInt64(index + 1)))
        }
    }
}
