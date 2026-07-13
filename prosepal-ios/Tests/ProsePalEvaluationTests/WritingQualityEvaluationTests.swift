import Foundation
import Testing
import ProsePalDomain
@testable import ProsePalEvaluation

@Suite("Writing quality deterministic baseline")
struct WritingQualityBaselineTests {
    @Test("recorded synthetic baseline matches deterministic scorer output")
    func recordedBaselineMatches() throws {
        // Regression caught: a scorer, rubric fixture, or expected rating changes silently
        // immediately before an output-affecting prompt/schema/runtime change.
        let fixtures = try loadBaseline()
        let evaluator = WritingQualityEvaluator()

        #expect(fixtures.map(\.scenarioID) == ["Q02", "Q04", "Q06", "Q16"])
        #expect(Set(fixtures.map(\.lane)) == [.privateDraft, .careful])
        #expect(Set(fixtures.map(\.mode)) == [.everyday, .careful])
        let candidateCriteria = Set(WritingQualityCriterion.allCases.filter { $0 != .usefulChoice })

        for fixture in fixtures {
            #expect(fixture.rubricVersion == 3)
            #expect(fixture.provenance == "repository-authored synthetic content")
            #expect(fixture.candidates.count == 3)

            let result = evaluator.evaluate(fixture)
            for candidate in fixture.candidates {
                #expect(Set(candidate.expected.map(\.criterion)) == candidateCriteria)
                let actual = try #require(result.candidates.first { $0.candidateID == candidate.id })
                for expected in candidate.expected {
                    let finding = try #require(actual.findings.first { $0.criterion == expected.criterion })
                    #expect(finding.rating == expected.rating)
                }
            }
            #expect(fixture.expectedSetFinding.criterion == .usefulChoice)
            #expect(result.setFinding.criterion == fixture.expectedSetFinding.criterion)
            #expect(result.setFinding.rating == fixture.expectedSetFinding.rating)
        }
    }

    private func loadBaseline() throws -> [WritingQualityFixture] {
        let url = try #require(Bundle.module.url(
            forResource: "writing-quality-baseline-v1",
            withExtension: "json"
        ))
        return try JSONDecoder().decode(
            [WritingQualityFixture].self,
            from: Data(contentsOf: url)
        )
    }
}

@Suite("Writing quality scorer exemplars")
struct WritingQualityScorerExemplarTests {
    private let evaluator = WritingQualityEvaluator()

    @Test("phrase scorers distinguish reviewed pass concern fail and abstention examples")
    func phraseScorerExemplars() throws {
        // Regression caught: a deterministic scorer becomes permissive, over-broad, or
        // unable to abstain without a reviewed oracle.
        let base = fixture(oracle: WritingQualityOracle(
            requiredMeaningPhrases: ["garden", "Sunday"],
            inventedFactConcernPhrases: ["holiday"],
            inventedFactFailPhrases: ["diagnosis"],
            tonePassPhrases: ["thank you"],
            toneFailPhrases: ["lol"],
            modePassPhrases: ["I am sorry"],
            modeFailPhrases: ["everything happens for a reason"]
        ))

        try expect(.preserveMeaning, .pass, in: "Thank you for the garden help on Sunday. I am sorry. One. Two.", fixture: base)
        try expect(.preserveMeaning, .concern, in: "Thank you for the garden help. I am sorry. One. Two.", fixture: base)
        try expect(.preserveMeaning, .fail, in: "Thank you for being there. I am sorry. One. Two.", fixture: base)
        try expect(.noInventedPersonalFacts, .pass, in: "Thank you for the garden help. I am sorry. One. Two.", fixture: base)
        try expect(.noInventedPersonalFacts, .concern, in: "Our holiday was lovely. Thank you. I am sorry. One.", fixture: base)
        try expect(.noInventedPersonalFacts, .fail, in: "Your diagnosis changed everything. Thank you. I am sorry. One.", fixture: base)
        try expect(.toneFit, .pass, in: "Thank you for the garden. I am sorry. One. Two.", fixture: base)
        try expect(.toneFit, .concern, in: "The garden was finished. I am sorry. One. Two.", fixture: base)
        try expect(.toneFit, .fail, in: "LOL about the garden. I am sorry. One. Two.", fixture: base)
        try expect(.writingModeFit, .pass, in: "I am sorry about the garden. Thank you. One. Two.", fixture: base)
        try expect(.writingModeFit, .concern, in: "Thank you for the garden. One. Two. Three.", fixture: base)
        try expect(.writingModeFit, .fail, in: "Everything happens for a reason. Thank you. One. Two.", fixture: base)

        let noOracle = fixture(oracle: WritingQualityOracle())
        try expect(.preserveMeaning, .notApplicable, in: "A complete sentence.", fixture: noOracle)
        try expect(.noInventedPersonalFacts, .notApplicable, in: "A complete sentence.", fixture: noOracle)
        try expect(.toneFit, .notApplicable, in: "A complete sentence.", fixture: noOracle)
        try expect(.writingModeFit, .notApplicable, in: "A complete sentence.", fixture: noOracle)
    }

    @Test("length pressure and leakage scorers match reviewed examples")
    func fixedScorerExemplars() throws {
        // Regression caught: release-blocking pressure or internal terminology is no
        // longer caught, or short/long outputs are misclassified without review.
        let standard = fixture(oracle: WritingQualityOracle(
            implementationLeakageConcernPhrases: ["model", "token"],
            implementationLeakageFailPhrases: ["ChatGPT", "system prompt", "JSON schema"]
        ))
        try expect(.lengthFit, .pass, in: "One. Two. Three.", fixture: standard)
        try expect(.lengthFit, .concern, in: "One. Two.", fixture: standard)
        try expect(.lengthFit, .fail, in: "One.", fixture: standard)
        try expect(.lengthFit, .notApplicable, in: "", fixture: standard)

        try expect(.noCoercivePressure, .pass, in: "Take whatever time you need.", fixture: standard)
        try expect(.noCoercivePressure, .concern, in: "I need you to forgive me.", fixture: standard)
        try expect(.noCoercivePressure, .fail, in: "You have to forgive me.", fixture: standard)
        try expect(.noCoercivePressure, .notApplicable, in: "", fixture: standard)

        try expect(.noImplementationLeakage, .pass, in: "I appreciate your help.", fixture: standard)
        try expect(.noImplementationLeakage, .concern, in: "You have always been a role model.", fixture: standard)
        try expect(.noImplementationLeakage, .fail, in: "ChatGPT wrote this message.", fixture: standard)
        try expect(.noImplementationLeakage, .notApplicable, in: "", fixture: standard)
    }

    @Test("choice scorer distinguishes useful similar duplicate and absent sets")
    func choiceScorerExemplars() {
        // Regression caught: duplicated or synonym-only options pass as a genuine
        // three-way choice, or an absent set is mislabeled as successful.
        #expect(evaluator.evaluateChoice([
            "Thank you for stepping in when I needed help.",
            "Your help with the presentation made a real difference.",
            "I really appreciated how calmly you handled the work."
        ]).rating == .pass)
        #expect(evaluator.evaluateChoice([
            "Thank you for helping with the garden on Sunday morning.",
            "I really want to thank you for helping with the garden on Sunday morning.",
            "Your garden help made Sunday much easier for me."
        ]).rating == .concern)
        #expect(evaluator.evaluateChoice([
            "Thank you for helping.",
            "Thank you for helping!",
            "I appreciate your help."
        ]).rating == .fail)
        #expect(evaluator.evaluateChoice([]).rating == .notApplicable)
    }

    private func fixture(oracle: WritingQualityOracle) -> WritingQualityFixture {
        WritingQualityFixture(
            scenarioID: "EXEMPLAR",
            rubricVersion: 3,
            provenance: "repository-authored synthetic content",
            lane: .privateDraft,
            mode: .everyday,
            occasion: .thankYou,
            relationship: .colleague,
            tone: .heartfelt,
            length: .standard,
            syntheticInput: "Synthetic scorer exemplar.",
            oracle: oracle,
            candidates: []
        )
    }

    private func expect(
        _ criterion: WritingQualityCriterion,
        _ rating: WritingQualityRating,
        in text: String,
        fixture: WritingQualityFixture
    ) throws {
        let finding = try #require(
            evaluator.evaluateCandidate(text, fixture: fixture).first { $0.criterion == criterion }
        )
        #expect(finding.rating == rating)
    }
}
