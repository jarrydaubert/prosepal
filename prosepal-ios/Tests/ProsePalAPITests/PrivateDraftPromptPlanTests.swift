import Foundation
import XCTest
import ProsePalDomain
@testable import ProsePalAPI

final class PrivateDraftPromptPlanTests: XCTestCase {
    func testApprovedMemoryReachesPromptAndVoiceCardRemainsStyleOnly() {
        // Regression caught: approved memory is fetched but omitted from the model prompt,
        // or a voice card can be treated as factual relationship history.
        let plan = PrivateDraftPromptPlan(
            moment: fixtureMoment,
            adjustment: nil,
            currentMessage: nil,
            approvedBeads: [
                TruthBead(personName: "Sam", text: "Helped with the garden"),
                TruthBead(personName: "Sam", text: "Likes concise notes")
            ],
            approvedVoiceCard: RelationshipVoiceCard(
                personName: "Sam",
                summary: "Warm, plain-spoken, and direct"
            )
        )

        XCTAssertTrue(plan.instructionComponents.contains(
            "Treat approved voice cards as style guidance only; do not quote them as facts."
        ))
        XCTAssertEqual(
            Array(plan.promptComponents.suffix(5)),
            [
                "- Helped with the garden",
                "- Likes concise notes",
                "Approved voice card:",
                "Warm, plain-spoken, and direct",
                finalInstruction
            ]
        )
    }

    func testOptionalPromptSectionsArePresentOnlyWhenMeaningful() {
        // Regression caught: a draft or adjustment is generated from blank/stale optional
        // context, or an explicit reshape request is silently dropped.
        let emptyPlan = PrivateDraftPromptPlan(
            moment: MomentInput(
                personName: "Sam",
                relationship: .closeFriend,
                occasion: .thankYou,
                trueThing: "",
                localeIdentifier: "en_GB"
            ),
            adjustment: nil,
            currentMessage: "  \n ",
            approvedBeads: [],
            approvedVoiceCard: nil
        )

        XCTAssertFalse(emptyPlan.promptComponents.contains { $0.hasPrefix("What is true:") })
        XCTAssertFalse(emptyPlan.promptComponents.contains { $0.hasPrefix("Adjustment requested:") })
        XCTAssertFalse(emptyPlan.promptComponents.contains { $0.hasPrefix("Current message to reshape:") })
        XCTAssertFalse(emptyPlan.promptComponents.contains("Approved relationship memory:"))
        XCTAssertFalse(emptyPlan.promptComponents.contains("Approved voice card:"))

        let reshapePlan = PrivateDraftPromptPlan(
            moment: fixtureMoment,
            adjustment: .shorter,
            currentMessage: "Thank you for helping with the garden.",
            approvedBeads: [],
            approvedVoiceCard: nil
        )

        XCTAssertTrue(reshapePlan.promptComponents.contains("What is true: You helped with the garden."))
        XCTAssertTrue(reshapePlan.promptComponents.contains("Adjustment requested: Shorter"))
        XCTAssertTrue(reshapePlan.promptComponents.contains(
            "Current message to reshape: Thank you for helping with the garden."
        ))
    }

    func testPromptPlanKeepsCurrentComponentOrder() {
        // Regression caught: a testability refactor silently reorders prompt meaning before
        // the writing-quality baseline is recorded.
        let plan = PrivateDraftPromptPlan(
            moment: fixtureMoment,
            adjustment: nil,
            currentMessage: nil,
            approvedBeads: [],
            approvedVoiceCard: nil
        )

        XCTAssertEqual(
            plan.promptComponents,
            [
                "Person: Sam",
                "Relationship: Close Friend",
                "Moment: Thank You",
                "Writing context: Everyday moments that need a quick, warm message.",
                "Tone: Heartfelt",
                "Length: 3-4 sentences",
                "Device locale: en_GB",
                "What is true: You helped with the garden.",
                finalInstruction
            ]
        )
    }

    private var fixtureMoment: MomentInput {
        MomentInput(
            personName: "Sam",
            relationship: .closeFriend,
            occasion: .thankYou,
            trueThing: "You helped with the garden.",
            tone: .heartfelt,
            length: .standard,
            localeIdentifier: "en_GB"
        )
    }

    private var finalInstruction: String {
        "Write one message. Include pressure-check findings if the wording asks the recipient to reassure the sender, explains before apologising, or feels too heavy for the moment."
    }
}
