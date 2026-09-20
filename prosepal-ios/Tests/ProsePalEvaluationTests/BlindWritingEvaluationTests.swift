import Foundation
import Testing
@testable import ProsePalEvaluation

@Suite("Blind writing comparison")
struct BlindWritingEvaluationTests {
    @Test("same seed and private nonce are reproducible independently of input file ordering")
    func deterministicPreparation() throws {
        let corpus = try loadCorpus()
        let outputs = recorded(corpus)
        let first = try prepare(corpus: corpus, outputs: outputs, seed: 42)
        let reordered = try prepare(corpus: corpus.reversed(), outputs: outputs.reversed(), seed: 42)
        #expect(first.review == reordered.review)
        #expect(first.key == reordered.key)
        let changed = try prepare(corpus: corpus, outputs: outputs, seed: 43)
        #expect(first.review.keyFingerprint != changed.review.keyFingerprint)
    }

    @Test("counterbalanced positions cover every engine/scenario without leaking metadata")
    func counterbalanceAndBlinding() throws {
        let corpus = try loadCorpus()
        let outputs = recorded(corpus)
        let batch = try prepare(corpus: corpus, outputs: outputs, seed: 42)
        #expect(batch.review.reviews.count == corpus.count * 3)
        #expect(Set(batch.review.reviews.map { $0.sample.id }).count == corpus.count * 3)
        var positionPenalty = 0
        for engine in ["engine-apple", "engine-pcc", "engine-cloud"] {
            let entries = batch.key.identities.enumerated().filter { $0.element.engineID == engine }
            #expect(Set(entries.map { $0.element.sample.scenarioID }) == Set(corpus.map(\.scenarioID)))
            let counts = (0..<3).map { position in entries.filter { $0.offset % 3 == position }.count }
            positionPenalty += counts.reduce(0) { $0 + $1 * $1 }
        }
        // Soft balance across the full batch, not an exact quota for each engine.
        // Perfect balance scores 18 here; placing each engine always in one slot scores 48.
        #expect(positionPenalty <= 24)
        let json = String(decoding: try JSONEncoder().encode(batch.review), as: UTF8.self)
        for hidden in ["engine-apple", "engine-pcc", "engine-cloud", "engineID", "seed", "advisory", "oracle", "provenance", "lane", "nonce"] {
            #expect(!json.contains("\"\(hidden)\""))
        }
        #expect(batch.review.reviews.allSatisfy { $0.ratings.allSatisfy { $0.rating.isEmpty } })
    }

    @Test("recorded JSON parses Unicode exactly and rejects malformed response kinds")
    func parsing() throws {
        let data = Data("""
        [{"engineID":"engine-apple","scenarioID":"Q04","kind":"refusal","text":"I can’t help with that. 🌿"}]
        """.utf8)
        let outputs = try JSONDecoder().decode([RecordedWritingOutput].self, from: data)
        #expect(outputs[0].kind == .refusal)
        #expect(outputs[0].text == "I can’t help with that. 🌿")
        #expect(throws: (any Error).self) {
            try JSONDecoder().decode([RecordedWritingOutput].self, from: Data("[] trailing".utf8))
        }
        #expect(throws: (any Error).self) {
            try JSONDecoder().decode([RecordedWritingOutput].self, from: Data(String(decoding: data, as: UTF8.self)
                .replacingOccurrences(of: "refusal", with: "unsupported").utf8))
        }
    }

    @Test("incomplete duplicated unknown or blank matrix cells are rejected")
    func invalidInputs() throws {
        let corpus = try loadCorpus()
        let outputs = recorded(corpus)
        var unknown = outputs
        unknown[0].scenarioID = "Q-UNKNOWN"
        var blank = outputs
        blank[0].text = " \n"
        var blankEngine = outputs
        blankEngine[0].engineID = " "
        for invalid in [Array(outputs.dropLast()), outputs + [outputs[0]], unknown, blank, blankEngine,
                        outputs.filter { $0.engineID == "engine-apple" }] {
            #expect(throws: BlindWritingError.self) {
                try prepare(corpus: corpus, outputs: invalid, seed: 42)
            }
        }
        for invalid in [[], corpus + [corpus[0]]] {
            #expect(throws: BlindWritingError.self) {
                try prepare(corpus: invalid, outputs: outputs, seed: 42)
            }
        }
        var unsupported = corpus
        unsupported[0].rubricVersion = 99
        #expect(throws: BlindWritingError.self) {
            try prepare(corpus: unsupported, outputs: outputs, seed: 42)
        }
    }

    @Test("JSON round trip and reordered reviews retain exact identities and existing scorer findings")
    func revealRoundTrip() throws {
        let corpus = try loadCorpus()
        let outputs = recorded(corpus)
        let batch = try prepare(corpus: corpus, outputs: outputs, seed: 42)
        let encoder = JSONEncoder()
        let key = try JSONDecoder().decode(BlindWritingKey.self, from: encoder.encode(batch.key))
        var reviewed = completed(batch.review)
        reviewed.reviews.reverse()
        reviewed = try JSONDecoder().decode(BlindWritingReviewFile.self, from: encoder.encode(reviewed))
        let results = try BlindWritingEvaluation.reveal(reviewed, key: key)
        #expect(results.count == outputs.count)
        for result in results {
            let original = try #require(outputs.first { $0.engineID == result.engineID && $0.scenarioID == result.sample.scenarioID })
            #expect(result.sample.text == original.text)
            let fixture = try #require(corpus.first { $0.scenarioID == result.sample.scenarioID })
            #expect(result.advisory == WritingQualityEvaluator().evaluateCandidate(original.text, fixture: fixture))
            #expect(result.findings.first { $0.criterion == .usefulChoice }?.rating == .notApplicable)
            #expect(result.advisory.allSatisfy { $0.criterion != .usefulChoice })
        }
    }

    @Test("refusals remain visible and are not scored as generated messages")
    func refusals() throws {
        let corpus = try loadCorpus()
        var outputs = recorded(corpus)
        outputs[0].kind = .refusal
        outputs[0].text = "I can’t help with that request."
        let batch = try prepare(corpus: corpus, outputs: outputs, seed: 42)
        let results = try BlindWritingEvaluation.reveal(completed(batch.review), key: batch.key)
        let refusal = try #require(results.first { $0.sample.kind == .refusal })
        #expect(refusal.sample.text == outputs[0].text)
        #expect(refusal.advisory.isEmpty)
    }

    @Test("transport-only refusal evidence stays out of the anonymous review")
    func privateRefusalEvidence() throws {
        let corpus = try loadCorpus()
        var outputs = recorded(corpus)
        outputs[0].kind = .refusal
        outputs[0].text = ""
        outputs[0].privateEvidence = "Runner-specific HTTP 422 policy metadata."

        let batch = try prepare(corpus: corpus, outputs: outputs, seed: 42)
        let reviewJSON = String(decoding: try JSONEncoder().encode(batch.review), as: UTF8.self)
        let refusal = try #require(batch.review.reviews.first { $0.sample.kind == .refusal })

        #expect(refusal.sample.text.isEmpty)
        #expect(!reviewJSON.contains("Runner-specific"))
        #expect(!reviewJSON.contains("HTTP 422"))
    }

    @Test("unfinished invalid duplicate or unexplained ratings cannot be revealed")
    func invalidRatings() throws {
        let corpus = try loadCorpus()
        let batch = try prepare(corpus: corpus, outputs: recorded(corpus), seed: 42)
        var invalid = completed(batch.review)
        invalid.reviews[0].ratings[0].rating = "excellent"
        var duplicate = completed(batch.review)
        duplicate.reviews[0].ratings[0] = duplicate.reviews[0].ratings[1]
        var unexplained = completed(batch.review)
        unexplained.reviews[0].ratings[0].rating = "concern"
        var choices = completed(batch.review)
        let index = try #require(choices.reviews[0].ratings.firstIndex { $0.criterion == .usefulChoice })
        choices.reviews[0].ratings[index].rating = "pass"
        for review in [batch.review, invalid, duplicate, unexplained, choices] {
            #expect(throws: BlindWritingError.self) {
                try BlindWritingEvaluation.reveal(review, key: batch.key)
            }
        }
    }

    @Test("wrong batch keys and changed omitted duplicated or extra samples fail closed")
    func invalidMapping() throws {
        let corpus = try loadCorpus()
        let outputs = recorded(corpus)
        let batch = try prepare(corpus: corpus, outputs: outputs, seed: 42)
        var changed = completed(batch.review)
        changed.reviews[0].sample.text += " edited"
        var context = completed(batch.review)
        context.reviews[0].sample.syntheticInput += " changed"
        var missing = completed(batch.review)
        missing.reviews.removeLast()
        var duplicate = completed(batch.review)
        duplicate.reviews.append(duplicate.reviews[0])
        var unsupported = completed(batch.review)
        unsupported.formatVersion = 99
        for review in [changed, context, missing, duplicate, unsupported] {
            #expect(throws: BlindWritingError.self) {
                try BlindWritingEvaluation.reveal(review, key: batch.key)
            }
        }
        // Even identical texts across all engines cannot accept another seed's key.
        let other = try prepare(corpus: corpus, outputs: outputs, seed: 43)
        #expect(throws: BlindWritingError.self) {
            try BlindWritingEvaluation.reveal(completed(batch.review), key: other.key)
        }
    }

    @Test("one disclosed response does not establish a cross-scenario engine cohort")
    func noPredictableCohorts() throws {
        let corpus = try loadCorpus()
        let outputs = recorded(corpus)
        // Fixed counterexamples replace a broad nonce search: blocking test work
        // must not starve concurrent lifecycle/deadline checks on CI's shared executor.
        // Each pair has the same public scenario order and disclosed Q02 position,
        // but different positions for that engine on every other scenario.
        for (selectedCorpus, selectedOutputs, engineCount, otherNonce) in [
            (corpus, outputs, 3, UInt8(18)),
            (Array(corpus.prefix(2)), outputs.filter {
                $0.engineID != "engine-pcc" && corpus.prefix(2).map(\.scenarioID).contains($0.scenarioID)
            }, 2, UInt8(48))
        ] {
            let first = try prepare(corpus: selectedCorpus, outputs: selectedOutputs, seed: 42,
                                    nonce: Data(repeating: 0, count: 32))
            let second = try prepare(corpus: selectedCorpus, outputs: selectedOutputs, seed: 42,
                                     nonce: Data(repeating: otherNonce, count: 32))
            #expect(first.review.reviews.map { $0.sample.scenarioID } == second.review.reviews.map { $0.sample.scenarioID })
            let positions = [first, second].map { batch in
                Dictionary(uniqueKeysWithValues: batch.key.identities.enumerated()
                    .filter { $0.element.engineID == "engine-apple" }
                    .map { ($0.element.sample.scenarioID, $0.offset % engineCount) })
            }
            #expect(try #require(positions[0]["Q02"]) == #require(positions[1]["Q02"]))
            for scenario in selectedCorpus where scenario.scenarioID != "Q02" {
                #expect(try #require(positions[0][scenario.scenarioID]) != #require(positions[1][scenario.scenarioID]))
            }
        }
    }

    @Test("the private nonce binds the fingerprint and is absent from reviewer artifacts")
    func secretFingerprint() throws {
        let corpus = try loadCorpus()
        let batch = try prepare(corpus: corpus, outputs: recorded(corpus), seed: 42)
        let reviewData = try JSONEncoder().encode(batch.review)
        let reviewJSON = String(decoding: reviewData, as: UTF8.self)
        #expect(!reviewJSON.contains("nonce"))
        #expect(!reviewJSON.contains(batch.key.nonce.base64EncodedString()))
        // Keep the entire identity mapping and public seed unchanged: only the secret differs.
        var guessedKey = batch.key
        guessedKey.nonce = Data(repeating: 0x22, count: 32)
        #expect(throws: BlindWritingError.self) {
            try BlindWritingEvaluation.reveal(completed(batch.review), key: guessedKey)
        }
        guessedKey.nonce = Data()
        #expect(throws: BlindWritingError.self) {
            try BlindWritingEvaluation.reveal(completed(batch.review), key: guessedKey)
        }
        var encodedKey = try #require(JSONSerialization.jsonObject(with: JSONEncoder().encode(batch.key)) as? [String: Any])
        encodedKey.removeValue(forKey: "nonce")
        #expect(throws: (any Error).self) {
            try JSONDecoder().decode(BlindWritingKey.self, from: JSONSerialization.data(withJSONObject: encodedKey))
        }
        #expect(try BlindWritingEvaluation.reveal(completed(batch.review), key: batch.key).count == batch.review.reviews.count)
    }

    private func prepare(
        corpus: [WritingQualityFixture], outputs: [RecordedWritingOutput], seed: UInt64,
        nonce: Data = Data(repeating: 0x11, count: 32)
    ) throws -> BlindWritingBatch {
        try BlindWritingEvaluation.prepare(corpus: corpus, outputs: outputs, seed: seed, nonce: nonce)
    }

    private func loadCorpus() throws -> [WritingQualityFixture] {
        let url = try #require(Bundle.module.url(forResource: "writing-quality-baseline-v1", withExtension: "json"))
        return try JSONDecoder().decode([WritingQualityFixture].self, from: Data(contentsOf: url))
    }

    private func recorded(_ corpus: [WritingQualityFixture]) -> [RecordedWritingOutput] {
        ["engine-apple", "engine-pcc", "engine-cloud"].flatMap { engine in
            corpus.map { RecordedWritingOutput(engineID: engine, scenarioID: $0.scenarioID, kind: .message, text: $0.candidates[0].text) }
        }
    }

    private func completed(_ review: BlindWritingReviewFile) -> BlindWritingReviewFile {
        var result = review
        for sample in result.reviews.indices {
            for score in result.reviews[sample].ratings.indices {
                let choice = result.reviews[sample].ratings[score].criterion == .usefulChoice
                result.reviews[sample].ratings[score].rating = choice ? "not_applicable" : "pass"
                result.reviews[sample].ratings[score].reason = choice ? "One recorded response; not a candidate set." : ""
            }
        }
        return result
    }
}
