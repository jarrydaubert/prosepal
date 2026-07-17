import Foundation
import ProsePalDomain

public enum WritingQualityRating: String, Codable, CaseIterable, Sendable {
    case pass
    case concern
    case fail
    case notApplicable = "not_applicable"
}

public enum WritingQualityCriterion: String, Codable, CaseIterable, Sendable {
    case preserveMeaning = "preserve_meaning"
    case noInventedPersonalFacts = "no_invented_personal_facts"
    case toneFit = "tone_fit"
    case lengthFit = "length_fit"
    case writingModeFit = "writing_mode_fit"
    case noCoercivePressure = "no_coercive_pressure"
    case noImplementationLeakage = "no_implementation_leakage"
    case usefulChoice = "useful_choice"
}

public enum WritingQualityLane: String, Codable, Sendable {
    case privateDraft = "private"
    case careful = "careful"
}

public enum WritingQualityMode: String, Codable, Sendable {
    case everyday
    case careful
}

public struct WritingQualityOracle: Codable, Equatable, Sendable {
    public var requiredMeaningPhrases: [String]
    public var inventedFactConcernPhrases: [String]
    public var inventedFactFailPhrases: [String]
    public var tonePassPhrases: [String]
    public var toneFailPhrases: [String]
    public var modePassPhrases: [String]
    public var modeFailPhrases: [String]
    public var implementationLeakageConcernPhrases: [String]
    public var implementationLeakageFailPhrases: [String]

    public init(
        requiredMeaningPhrases: [String] = [],
        inventedFactConcernPhrases: [String] = [],
        inventedFactFailPhrases: [String] = [],
        tonePassPhrases: [String] = [],
        toneFailPhrases: [String] = [],
        modePassPhrases: [String] = [],
        modeFailPhrases: [String] = [],
        implementationLeakageConcernPhrases: [String] = [],
        implementationLeakageFailPhrases: [String] = []
    ) {
        self.requiredMeaningPhrases = requiredMeaningPhrases
        self.inventedFactConcernPhrases = inventedFactConcernPhrases
        self.inventedFactFailPhrases = inventedFactFailPhrases
        self.tonePassPhrases = tonePassPhrases
        self.toneFailPhrases = toneFailPhrases
        self.modePassPhrases = modePassPhrases
        self.modeFailPhrases = modeFailPhrases
        self.implementationLeakageConcernPhrases = implementationLeakageConcernPhrases
        self.implementationLeakageFailPhrases = implementationLeakageFailPhrases
    }
}

public struct WritingQualityExpectedFinding: Codable, Equatable, Sendable {
    public var criterion: WritingQualityCriterion
    public var rating: WritingQualityRating

    public init(criterion: WritingQualityCriterion, rating: WritingQualityRating) {
        self.criterion = criterion
        self.rating = rating
    }
}

public struct WritingQualityCandidateFixture: Codable, Equatable, Sendable {
    public var id: String
    public var text: String
    public var expected: [WritingQualityExpectedFinding]

    public init(id: String, text: String, expected: [WritingQualityExpectedFinding] = []) {
        self.id = id
        self.text = text
        self.expected = expected
    }
}

public struct WritingQualityFixture: Codable, Equatable, Sendable {
    public var scenarioID: String
    public var rubricVersion: Int
    public var provenance: String
    public var lane: WritingQualityLane
    public var mode: WritingQualityMode
    public var occasion: Occasion
    public var relationship: Relationship
    public var tone: Tone
    public var length: MessageLength
    public var syntheticInput: String
    public var oracle: WritingQualityOracle
    public var candidates: [WritingQualityCandidateFixture]
    public var expectedSetFinding: WritingQualityExpectedFinding

    public init(
        scenarioID: String,
        rubricVersion: Int,
        provenance: String,
        lane: WritingQualityLane,
        mode: WritingQualityMode,
        occasion: Occasion,
        relationship: Relationship,
        tone: Tone,
        length: MessageLength,
        syntheticInput: String,
        oracle: WritingQualityOracle,
        candidates: [WritingQualityCandidateFixture],
        expectedSetFinding: WritingQualityExpectedFinding = .init(criterion: .usefulChoice, rating: .pass)
    ) {
        self.scenarioID = scenarioID
        self.rubricVersion = rubricVersion
        self.provenance = provenance
        self.lane = lane
        self.mode = mode
        self.occasion = occasion
        self.relationship = relationship
        self.tone = tone
        self.length = length
        self.syntheticInput = syntheticInput
        self.oracle = oracle
        self.candidates = candidates
        self.expectedSetFinding = expectedSetFinding
    }
}

public struct WritingQualityFinding: Equatable, Sendable {
    public var criterion: WritingQualityCriterion
    public var rating: WritingQualityRating
    public var reason: String

    public init(
        criterion: WritingQualityCriterion,
        rating: WritingQualityRating,
        reason: String
    ) {
        self.criterion = criterion
        self.rating = rating
        self.reason = reason
    }
}

public struct WritingQualityCandidateResult: Equatable, Sendable {
    public var candidateID: String
    public var findings: [WritingQualityFinding]

    public init(candidateID: String, findings: [WritingQualityFinding]) {
        self.candidateID = candidateID
        self.findings = findings
    }
}

public struct WritingQualityFixtureResult: Equatable, Sendable {
    public var scenarioID: String
    public var rubricVersion: Int
    public var lane: WritingQualityLane
    public var candidates: [WritingQualityCandidateResult]
    public var setFinding: WritingQualityFinding

    public init(
        scenarioID: String,
        rubricVersion: Int,
        lane: WritingQualityLane,
        candidates: [WritingQualityCandidateResult],
        setFinding: WritingQualityFinding
    ) {
        self.scenarioID = scenarioID
        self.rubricVersion = rubricVersion
        self.lane = lane
        self.candidates = candidates
        self.setFinding = setFinding
    }
}

public struct WritingQualityEvaluator: Sendable {
    public init() {}

    public func evaluate(_ fixture: WritingQualityFixture) -> WritingQualityFixtureResult {
        WritingQualityFixtureResult(
            scenarioID: fixture.scenarioID,
            rubricVersion: fixture.rubricVersion,
            lane: fixture.lane,
            candidates: fixture.candidates.map { candidate in
                WritingQualityCandidateResult(
                    candidateID: candidate.id,
                    findings: evaluateCandidate(candidate.text, fixture: fixture)
                )
            },
            setFinding: evaluateChoice(fixture.candidates.map(\.text))
        )
    }

    public func evaluateCandidate(
        _ text: String,
        fixture: WritingQualityFixture
    ) -> [WritingQualityFinding] {
        [
            phraseFinding(
                criterion: .preserveMeaning,
                text: text,
                required: fixture.oracle.requiredMeaningPhrases,
                concerns: [],
                failures: [],
                requiresEveryRequiredPhrase: true
            ),
            phraseFinding(
                criterion: .noInventedPersonalFacts,
                text: text,
                required: [],
                concerns: fixture.oracle.inventedFactConcernPhrases,
                failures: fixture.oracle.inventedFactFailPhrases,
                requiresEveryRequiredPhrase: false
            ),
            phraseFinding(
                criterion: .toneFit,
                text: text,
                required: fixture.oracle.tonePassPhrases,
                concerns: [],
                failures: fixture.oracle.toneFailPhrases,
                requiresEveryRequiredPhrase: false
            ),
            lengthFinding(text, requested: fixture.length),
            phraseFinding(
                criterion: .writingModeFit,
                text: text,
                required: fixture.oracle.modePassPhrases,
                concerns: [],
                failures: fixture.oracle.modeFailPhrases,
                requiresEveryRequiredPhrase: false
            ),
            pressureFinding(text),
            leakageFinding(text, oracle: fixture.oracle)
        ]
    }

    public func evaluateChoice(_ candidates: [String]) -> WritingQualityFinding {
        let nonBlank = candidates.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        guard !nonBlank.isEmpty else {
            return finding(.usefulChoice, .notApplicable, "No candidate set was supplied.")
        }
        guard nonBlank.count == 3 else {
            return finding(.usefulChoice, .fail, "A selectable set must contain exactly three complete candidates.")
        }

        let fingerprints = nonBlank.map(normalizedFingerprint)
        guard Set(fingerprints).count == fingerprints.count else {
            return finding(.usefulChoice, .fail, "The set contains a repeated candidate.")
        }

        let similarities = pairwiseSimilarities(fingerprints)
        let maximumSimilarity = similarities.max() ?? 0
        if maximumSimilarity >= 0.82 {
            return finding(.usefulChoice, .fail, "Candidates differ only superficially.")
        }
        if maximumSimilarity >= 0.68 {
            return finding(.usefulChoice, .concern, "Candidate wording may be too similar for a useful choice.")
        }
        return finding(.usefulChoice, .pass, "The three candidates provide distinct wording while retaining shared context.")
    }

    private func phraseFinding(
        criterion: WritingQualityCriterion,
        text: String,
        required: [String],
        concerns: [String],
        failures: [String],
        requiresEveryRequiredPhrase: Bool
    ) -> WritingQualityFinding {
        let normalized = normalizedText(text)
        guard !normalized.isEmpty else {
            return finding(criterion, .notApplicable, "No candidate text was supplied.")
        }

        if let phrase = failures.first(where: { normalized.contains(normalizedText($0)) }) {
            return finding(criterion, .fail, "Matched reviewed fail phrase: \(phrase)")
        }
        if let phrase = concerns.first(where: { normalized.contains(normalizedText($0)) }) {
            return finding(criterion, .concern, "Matched reviewed concern phrase: \(phrase)")
        }
        guard !required.isEmpty || !concerns.isEmpty || !failures.isEmpty else {
            return finding(criterion, .notApplicable, "This fixture has no deterministic oracle for the criterion.")
        }
        guard !required.isEmpty else {
            return finding(criterion, .pass, "No reviewed concern or fail phrase was present.")
        }

        let matchCount = required.filter { normalized.contains(normalizedText($0)) }.count
        if requiresEveryRequiredPhrase && matchCount == required.count {
            return finding(criterion, .pass, "All required fixture meaning was present.")
        }
        if !requiresEveryRequiredPhrase && matchCount > 0 {
            return finding(criterion, .pass, "A reviewed positive fixture phrase was present.")
        }
        if requiresEveryRequiredPhrase && matchCount > 0 {
            return finding(criterion, .concern, "Only part of the required fixture meaning was present.")
        }
        return finding(
            criterion,
            requiresEveryRequiredPhrase ? .fail : .concern,
            requiresEveryRequiredPhrase
                ? "Required fixture meaning was absent."
                : "No reviewed positive fixture phrase was present."
        )
    }

    private func lengthFinding(
        _ text: String,
        requested: MessageLength
    ) -> WritingQualityFinding {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return finding(.lengthFit, .notApplicable, "No candidate text was supplied.")
        }

        let expectedRange: ClosedRange<Int> = switch requested {
        case .brief: 1...2
        case .standard: 3...4
        case .detailed: 5...7
        }
        let count = sentenceCount(text)
        if expectedRange.contains(count) {
            return finding(.lengthFit, .pass, "Sentence count \(count) matches \(requested.rawValue).")
        }

        let distance = count < expectedRange.lowerBound
            ? expectedRange.lowerBound - count
            : count - expectedRange.upperBound
        if distance == 1 {
            return finding(.lengthFit, .concern, "Sentence count \(count) is just outside the requested shape.")
        }
        return finding(.lengthFit, .fail, "Sentence count \(count) materially misses the requested shape.")
    }

    private func pressureFinding(_ text: String) -> WritingQualityFinding {
        let normalized = normalizedText(text)
        guard !normalized.isEmpty else {
            return finding(.noCoercivePressure, .notApplicable, "No candidate text was supplied.")
        }

        let failures = [
            "if you cared", "after everything i've done", "you owe me",
            "you have to forgive me", "you must forgive me", "prove you care",
            "you need to reassure me"
        ]
        let concerns = [
            "i need you to forgive me", "please tell me we're okay", "tell me you still"
        ]
        if let phrase = failures.first(where: { normalized.contains(normalizedText($0)) }) {
            return finding(.noCoercivePressure, .fail, "Matched reviewed pressure phrase: \(phrase)")
        }
        if let phrase = concerns.first(where: { normalized.contains(normalizedText($0)) }) {
            return finding(.noCoercivePressure, .concern, "Matched reviewed pressure concern: \(phrase)")
        }
        return finding(.noCoercivePressure, .pass, "No reviewed coercive-pressure phrase was present.")
    }

    private func leakageFinding(
        _ text: String,
        oracle: WritingQualityOracle
    ) -> WritingQualityFinding {
        let normalized = normalizedText(text)
        guard !normalized.isEmpty else {
            return finding(.noImplementationLeakage, .notApplicable, "No candidate text was supplied.")
        }
        guard !oracle.implementationLeakageConcernPhrases.isEmpty ||
                !oracle.implementationLeakageFailPhrases.isEmpty else {
            return finding(
                .noImplementationLeakage,
                .notApplicable,
                "This fixture has no reviewed implementation-language oracle."
            )
        }

        if let phrase = oracle.implementationLeakageFailPhrases.first(where: {
            normalized.contains(normalizedText($0))
        }) {
            return finding(.noImplementationLeakage, .fail, "Matched reviewed implementation phrase: \(phrase)")
        }
        if oracle.implementationLeakageConcernPhrases.contains(where: {
            normalized.contains(normalizedText($0))
        }) {
            return finding(.noImplementationLeakage, .concern, "Matched an ambiguous implementation term requiring review.")
        }
        return finding(.noImplementationLeakage, .pass, "No reviewed implementation term was present.")
    }

    private func sentenceCount(_ text: String) -> Int {
        let pieces = text.split(whereSeparator: { ".!?".contains($0) })
        return max(1, pieces.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }.count)
    }

    private func pairwiseSimilarities(_ fingerprints: [String]) -> [Double] {
        guard fingerprints.count > 1 else { return [] }
        var output: [Double] = []
        for leftIndex in fingerprints.indices {
            for rightIndex in fingerprints.indices where rightIndex > leftIndex {
                let left = Set(fingerprints[leftIndex].split(separator: " ").map(String.init))
                let right = Set(fingerprints[rightIndex].split(separator: " ").map(String.init))
                let unionCount = left.union(right).count
                output.append(unionCount == 0 ? 1 : Double(left.intersection(right).count) / Double(unionCount))
            }
        }
        return output
    }

    private func normalizedFingerprint(_ text: String) -> String {
        normalizedText(text)
            .unicodeScalars
            .map { CharacterSet.alphanumerics.contains($0) || CharacterSet.whitespaces.contains($0) ? String($0) : " " }
            .joined()
            .split(whereSeparator: \.isWhitespace)
            .joined(separator: " ")
    }

    private func normalizedText(_ text: String) -> String {
        text
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: Locale(identifier: "en_US_POSIX"))
            .replacingOccurrences(of: "’", with: "'")
            .replacingOccurrences(of: "‘", with: "'")
            .replacingOccurrences(of: "“", with: "\"")
            .replacingOccurrences(of: "”", with: "\"")
            .split(whereSeparator: \.isWhitespace)
            .joined(separator: " ")
    }

    private func finding(
        _ criterion: WritingQualityCriterion,
        _ rating: WritingQualityRating,
        _ reason: String
    ) -> WritingQualityFinding {
        WritingQualityFinding(criterion: criterion, rating: rating, reason: reason)
    }
}
