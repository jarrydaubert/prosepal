import Foundation
import FoundationModels
import ProsePalDomain

public protocol RelationshipMemoryProviding: Sendable {
    func approvedTruthBeads(for personName: String) async throws -> [TruthBead]
    func approvedVoiceCard(for personName: String) async throws -> RelationshipVoiceCard?
}

public actor EmptyRelationshipMemoryProvider: RelationshipMemoryProviding {
    public init() {}

    public func approvedTruthBeads(for personName: String) async throws -> [TruthBead] {
        []
    }

    public func approvedVoiceCard(for personName: String) async throws -> RelationshipVoiceCard? {
        nil
    }
}

public struct FoundationModelsPrivateDraftClient: MomentDraftClient {
    private let memoryProvider: any RelationshipMemoryProviding
    private let model: SystemLanguageModel

    public static var isDefaultModelAvailable: Bool {
        switch SystemLanguageModel.default.availability {
        case .available:
            true
        case .unavailable:
            false
        }
    }

    public init(
        memoryProvider: any RelationshipMemoryProviding = EmptyRelationshipMemoryProvider(),
        model: SystemLanguageModel = .default
    ) {
        self.memoryProvider = memoryProvider
        self.model = model
    }

    public func draft(for moment: MomentInput) async throws -> MomentDraftBundle {
        try await generate(moment: moment, adjustment: nil, currentMessage: nil)
    }

    public func adjust(
        _ bundle: MomentDraftBundle,
        with adjustment: MomentAdjustment,
        moment: MomentInput
    ) async throws -> MomentDraftBundle {
        try await generate(
            moment: moment,
            adjustment: adjustment,
            currentMessage: bundle.messageText
        )
    }

    private func generate(
        moment: MomentInput,
        adjustment: MomentAdjustment?,
        currentMessage: String?
    ) async throws -> MomentDraftBundle {
        try ensureModelAvailable()

        let approvedBeads = try await memoryProvider.approvedTruthBeads(for: moment.personName)
        let approvedVoiceCard = try await memoryProvider.approvedVoiceCard(for: moment.personName)
        let session = LanguageModelSession(
            model: model,
            tools: [RelationshipMemoryTool(memoryProvider: memoryProvider)],
            instructions: privateDraftInstructions
        )

        do {
            let response = try await session.respond(
                to: prompt(
                    for: moment,
                    adjustment: adjustment,
                    currentMessage: currentMessage,
                    approvedBeads: approvedBeads,
                    approvedVoiceCard: approvedVoiceCard
                ),
                generating: PrivateDraftContent.self,
                options: GenerationOptions(
                    sampling: .random(probabilityThreshold: 0.92),
                    temperature: 0.7,
                    maximumResponseTokens: 700
                )
            )
            return response.content.bundle(
                lane: .privateDraft,
                approvedBeads: approvedBeads,
                personName: moment.personName
            )
        } catch let error as LanguageModelSession.GenerationError {
            throw error.prosePalGenerationError
        }
    }

    private func ensureModelAvailable() throws {
        switch model.availability {
        case .available:
            return
        case .unavailable(.deviceNotEligible):
            throw GenerationError.serviceUnavailable(
                message: "Private drafting is not available on this device."
            )
        case .unavailable(.appleIntelligenceNotEnabled):
            throw GenerationError.serviceUnavailable(
                message: "Private drafting is not enabled on this device."
            )
        case .unavailable(.modelNotReady):
            throw GenerationError.serviceUnavailable(
                message: "Private draft is still getting ready."
            )
        case .unavailable:
            throw GenerationError.serviceUnavailable(
                message: "Private draft is not available right now."
            )
        }
    }

    private var privateDraftInstructions: Instructions {
        Instructions {
            "You are ProsePal, a private writing assistant for short personal messages."
            "Write like a thoughtful human, not a chatbot."
            "Never mention models, providers, AI, tokens, or implementation details."
            "For hard moments, use the user's own sentence as the emotional anchor and invent less."
            "Treat approved voice cards as style guidance only; do not quote them as facts."
            "Avoid guilt mechanics, relationship scoring, manipulative nudges, and pressure."
            "Return structured fields exactly as requested."
        }
    }

    private func prompt(
        for moment: MomentInput,
        adjustment: MomentAdjustment?,
        currentMessage: String?,
        approvedBeads: [TruthBead],
        approvedVoiceCard: RelationshipVoiceCard?
    ) -> Prompt {
        Prompt {
            "Person: \(moment.personName)"
            "Relationship: \(moment.relationship.displayName)"
            "Moment: \(moment.occasion.displayName)"
            "Register: \(moment.register.displayName) - \(moment.register.userSafeDescription)"
            "Tone: \(moment.tone.displayName)"
            "Length: \(moment.length.generationHint)"
            "Device locale: \(moment.localeIdentifier)"

            if !moment.trueThing.isEmpty {
                "What is true: \(moment.trueThing)"
            }

            if let adjustment {
                "Adjustment requested: \(adjustment.displayName)"
            }

            if let currentMessage, !currentMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                "Current message to reshape: \(currentMessage)"
            }

            if !approvedBeads.isEmpty {
                "Approved relationship memory:"
                approvedBeads.map { "- \($0.text)" }
            }

            if let approvedVoiceCard {
                "Approved voice card:"
                approvedVoiceCard.summary
            }

            "Write one message. Include pressure-check findings if the wording asks the recipient to reassure the sender, explains before apologising, or feels too heavy for the moment."
        }
    }
}

@Generable(description: "A ProsePal private draft bundle")
private struct PrivateDraftContent {
    @Guide(description: "The message body the user can send or edit")
    var messageText: String

    @Guide(description: "Whether the message asks the recipient to reassure the sender")
    var asksForReassurance: Bool

    @Guide(description: "Whether an apology explains before it apologises")
    var explainsBeforeApology: Bool

    @Guide(description: "Whether the wording may feel too heavy for the moment")
    var mayFeelTooHeavy: Bool

    @Guide(description: "Short pressure-check notes", .maximumCount(3))
    var pressureNotes: [String]

    @Guide(description: "Details that would help improve the message", .maximumCount(3))
    var missingInformation: [String]

    @Guide(description: "Non-sensitive user-visible risk notes", .maximumCount(3))
    var riskNotes: [String]

    func bundle(
        lane: MomentDraftLane,
        approvedBeads: [TruthBead],
        personName: String
    ) -> MomentDraftBundle {
        MomentDraftBundle(
            messageText: messageText,
            lane: lane,
            pressureCheck: PressureCheck(
                asksForReassurance: asksForReassurance,
                explainsBeforeApology: explainsBeforeApology,
                mayFeelTooHeavy: mayFeelTooHeavy,
                notes: pressureNotes.nonEmptyTrimmed
            ),
            truthBeads: approvedBeads,
            missingInformation: missingInformation.nonEmptyTrimmed,
            riskNotes: riskNotes.nonEmptyTrimmed
        )
    }
}

@Generable(description: "Arguments for looking up approved relationship memory")
private struct RelationshipMemoryArguments {
    @Guide(description: "The person's name")
    var personName: String
}

private struct RelationshipMemoryTool: Tool {
    let memoryProvider: any RelationshipMemoryProviding

    var name: String { "approved_relationship_memory" }

    var description: String {
        "Looks up user-approved facts for a person from ProsePal's private on-device relationship vault."
    }

    @concurrent func call(arguments: RelationshipMemoryArguments) async throws -> String {
        let beads = try await memoryProvider.approvedTruthBeads(for: arguments.personName)
            .filter(\.isUserApproved)
        let voiceCard = try await memoryProvider.approvedVoiceCard(for: arguments.personName)
        guard !beads.isEmpty || voiceCard != nil else {
            return "No approved relationship memory."
        }

        var sections: [String] = []
        if !beads.isEmpty {
            sections.append("Approved details:\n" + beads.map { "- \($0.text)" }.joined(separator: "\n"))
        }
        if let voiceCard {
            sections.append("Approved voice card:\n\(voiceCard.summary)")
        }

        return sections.joined(separator: "\n\n")
    }
}

private extension LanguageModelSession.GenerationError {
    var prosePalGenerationError: GenerationError {
        switch self {
        case .exceededContextWindowSize:
            .unexpectedResponse(message: "There is too much context for Private draft. Try a shorter note.")
        case .assetsUnavailable:
            .serviceUnavailable(message: "Private draft is not ready yet.")
        case .guardrailViolation, .refusal:
            .contentBlocked(message: "That moment needs a different kind of support.")
        case .unsupportedGuide:
            .unexpectedResponse(message: "Private draft could not follow this shape yet.")
        case .unsupportedLanguageOrLocale:
            .unexpectedResponse(message: "Private draft does not support this language yet.")
        case .decodingFailure:
            .unexpectedResponse(message: "Private draft could not shape this message.")
        case .rateLimited, .concurrentRequests:
            .rateLimited(message: "Private draft is busy. Please try again in a moment.")
        @unknown default:
            .unexpectedResponse(message: "Private draft could not finish this message.")
        }
    }
}

private extension [String] {
    var nonEmptyTrimmed: [String] {
        compactMap { item in
            let trimmed = item.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? nil : trimmed
        }
    }
}
