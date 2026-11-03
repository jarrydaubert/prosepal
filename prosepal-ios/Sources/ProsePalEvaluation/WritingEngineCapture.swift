import Foundation
import FoundationModels
import ProsePalAPI
import ProsePalDomain

public enum WritingEngineCapture {
    public static let localeIdentifier = "en_GB"

    public static func recordFoundationModels(
        corpus: [WritingEvaluationScenario],
        engineID: String,
        onProgress: (@Sendable ([RecordedWritingOutput]) throws -> Void)? = nil
    ) async throws -> [RecordedWritingOutput] {
        let model = SystemLanguageModel.default
        try ensureFoundationModelAvailable(model)
        var outputs: [RecordedWritingOutput] = []
        for scenario in try validatedCorpus(corpus, engineID: engineID) {
            let plan = PrivateDraftPromptPlan(
                moment: try moment(for: scenario),
                adjustment: nil,
                currentMessage: nil,
                approvedBeads: [],
                approvedVoiceCard: nil
            )
            let session = LanguageModelSession(
                model: model,
                instructions: Instructions { plan.instructionComponents }
            )
            do {
                let response = try await session.respond(
                    to: Prompt { plan.promptComponents },
                    generating: PrivateDraftContent.self,
                    options: foundationModelsGenerationOptions
                )
                guard let text = ProsePalTextInput.generatedDraft(response.content.messageText) else {
                    throw WritingEngineCaptureError(
                        message: "AFM returned an unusable message for \(scenario.scenarioID)."
                    )
                }
                outputs.append(RecordedWritingOutput(
                    engineID: engineID,
                    scenarioID: scenario.scenarioID,
                    kind: .message,
                    text: text
                ))
            } catch let error as LanguageModelSession.GenerationError {
                guard let refusal = foundationModelsRefusal(error) else {
                    throw WritingEngineCaptureError(
                        message: "AFM failed for \(scenario.scenarioID): \(error.localizedDescription)"
                    )
                }
                outputs.append(RecordedWritingOutput(
                    engineID: engineID,
                    scenarioID: scenario.scenarioID,
                    kind: .refusal,
                    text: refusal.text,
                    privateEvidence: refusal.privateEvidence
                ))
            }
            try onProgress?(outputs)
        }
        return outputs
    }

    public static func recordLocalCompatible(
        corpus: [WritingEvaluationScenario],
        engineID: String,
        baseURL: URL,
        model: String,
        session suppliedSession: URLSession? = nil,
        onProgress: (@Sendable ([RecordedWritingOutput]) throws -> Void)? = nil
    ) async throws -> [RecordedWritingOutput] {
        let endpoint = try localChatCompletionsEndpoint(baseURL)
        let model = model.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !model.isEmpty else {
            throw WritingEngineCaptureError(message: "The local model name must not be blank.")
        }

        let session: URLSession
        if let suppliedSession {
            session = suppliedSession
        } else {
            let configuration = URLSessionConfiguration.ephemeral
            configuration.timeoutIntervalForRequest = 120
            configuration.timeoutIntervalForResource = 180
            session = URLSession(configuration: configuration)
        }

        var outputs: [RecordedWritingOutput] = []
        for scenario in try validatedCorpus(corpus, engineID: engineID) {
            let plan = PrivateDraftPromptPlan(
                moment: try moment(for: scenario),
                adjustment: nil,
                currentMessage: nil,
                approvedBeads: [],
                approvedVoiceCard: nil
            )
            var request = URLRequest(url: endpoint)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try localCompatibleRequestBody(plan: plan, model: model)

            let (data, response) = try await session.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw WritingEngineCaptureError(
                    message: "Local model returned no HTTP response for \(scenario.scenarioID)."
                )
            }

            let result: CapturedWritingOutcome
            if (200..<300).contains(httpResponse.statusCode) {
                result = try decodeLocalCompatibleResponse(data, scenarioID: scenario.scenarioID)
            } else if let refusal = localPolicyRefusal(
                statusCode: httpResponse.statusCode,
                data: data
            ) {
                result = refusal
            } else {
                throw WritingEngineCaptureError(
                    message: "Local model returned HTTP \(httpResponse.statusCode) for \(scenario.scenarioID)."
                )
            }

            outputs.append(RecordedWritingOutput(
                engineID: engineID,
                scenarioID: scenario.scenarioID,
                kind: result.kind,
                text: result.text,
                privateEvidence: result.privateEvidence
            ))
            try onProgress?(outputs)
        }
        return outputs
    }

    static func moment(for scenario: WritingEvaluationScenario) throws -> MomentInput {
        guard let personName = scenario.personName?.trimmingCharacters(in: .whitespacesAndNewlines),
              !personName.isEmpty else {
            throw WritingEngineCaptureError(
                message: "\(scenario.scenarioID) needs an explicit personName for prompt parity."
            )
        }
        return MomentInput(
            personName: personName,
            relationship: scenario.relationship,
            occasion: scenario.occasion,
            register: scenario.mode == .careful ? .assemble : .react,
            trueThing: scenario.syntheticInput,
            tone: scenario.tone,
            length: scenario.length,
            localeIdentifier: localeIdentifier
        )
    }

    static func localCompatibleRequestBody(
        plan: PrivateDraftPromptPlan,
        model: String
    ) throws -> Data {
        func stringArraySchema(description: String) -> [String: Any] {
            [
                "type": "array",
                "description": description,
                "items": ["type": "string"],
                "maxItems": 3
            ]
        }
        let schema: [String: Any] = [
            "type": "object",
            "description": "A ProsePal private draft bundle",
            "additionalProperties": false,
            "properties": [
                "messageText": [
                    "type": "string",
                    "description": "The message body the user can send or edit"
                ],
                "asksForReassurance": [
                    "type": "boolean",
                    "description": "Whether the message asks the recipient to reassure the sender"
                ],
                "explainsBeforeApology": [
                    "type": "boolean",
                    "description": "Whether an apology explains before it apologises"
                ],
                "mayFeelTooHeavy": [
                    "type": "boolean",
                    "description": "Whether the wording may feel too heavy for the moment"
                ],
                "pressureNotes": stringArraySchema(description: "Short pressure-check notes"),
                "missingInformation": stringArraySchema(
                    description: "Details that would help improve the message"
                ),
                "riskNotes": stringArraySchema(description: "Non-sensitive user-visible risk notes")
            ],
            "required": [
                "messageText",
                "asksForReassurance",
                "explainsBeforeApology",
                "mayFeelTooHeavy",
                "pressureNotes",
                "missingInformation",
                "riskNotes"
            ]
        ]
        let body: [String: Any] = [
            "model": model,
            "messages": [
                ["role": "system", "content": plan.instructionComponents.joined(separator: "\n")],
                ["role": "user", "content": plan.promptComponents.joined(separator: "\n")]
            ],
            "temperature": 0.7,
            "top_p": 0.92,
            "max_tokens": 700,
            "reasoning_effort": "none",
            "stream": false,
            "response_format": [
                "type": "json_schema",
                "json_schema": [
                    "name": "prosepal_private_draft",
                    "strict": true,
                    "schema": schema
                ]
            ]
        ]
        return try JSONSerialization.data(withJSONObject: body, options: [.sortedKeys])
    }

    static let foundationModelsGenerationOptions = GenerationOptions(
        sampling: .random(probabilityThreshold: 0.92),
        temperature: 0.7,
        maximumResponseTokens: 700
    )

    static func decodeLocalCompatibleResponse(
        _ data: Data,
        scenarioID: String
    ) throws -> CapturedWritingOutcome {
        let response: LocalCompatibleResponse
        do {
            response = try JSONDecoder().decode(LocalCompatibleResponse.self, from: data)
        } catch {
            throw WritingEngineCaptureError(
                message: "Local model returned an invalid chat response for \(scenarioID)."
            )
        }
        guard let message = response.choices.first?.message else {
            throw WritingEngineCaptureError(
                message: "Local model returned no choice for \(scenarioID)."
            )
        }
        if let refusal = message.refusal?.trimmedNonEmpty {
            return CapturedWritingOutcome(kind: .refusal, text: refusal, privateEvidence: nil)
        }
        guard let content = message.content,
              let contentData = content.data(using: .utf8) else {
            throw WritingEngineCaptureError(
                message: "Local model returned no structured content for \(scenarioID)."
            )
        }
        let draft: LocalCompatibleDraft
        do {
            draft = try JSONDecoder().decode(LocalCompatibleDraft.self, from: contentData)
        } catch {
            throw WritingEngineCaptureError(
                message: "Local model returned an invalid draft shape for \(scenarioID): \(String(describing: error))"
            )
        }
        guard let text = ProsePalTextInput.generatedDraft(draft.messageText) else {
            throw WritingEngineCaptureError(
                message: "Local model returned an unusable message for \(scenarioID)."
            )
        }
        return CapturedWritingOutcome(kind: .message, text: text, privateEvidence: nil)
    }

    static func localPolicyRefusal(statusCode: Int, data: Data) -> CapturedWritingOutcome? {
        let object = try? JSONSerialization.jsonObject(with: data)
        let explicitRefusal = string(in: object, path: ["refusal"])
            ?? string(in: object, path: ["error", "refusal"])
            ?? string(in: object, path: ["choices", 0, "message", "refusal"])
        let policyMarker = [
            string(in: object, path: ["code"]),
            string(in: object, path: ["type"]),
            string(in: object, path: ["error", "code"]),
            string(in: object, path: ["error", "type"])
        ]
            .compactMap { $0 }
            .joined(separator: " ")
            .lowercased()
        let hasPolicyMarker = ["policy", "moderation", "content_filter", "safety", "guardrail", "refusal"]
            .contains { policyMarker.contains($0) }
        let isPolicyStatus = statusCode == 451
        guard explicitRefusal != nil || hasPolicyMarker || isPolicyStatus else {
            return nil
        }

        return CapturedWritingOutcome(
            kind: .refusal,
            text: explicitRefusal ?? "",
            privateEvidence: String(data: data, encoding: .utf8)?.trimmedNonEmpty
        )
    }

    private static func foundationModelsRefusal(
        _ error: LanguageModelSession.GenerationError
    ) -> CapturedWritingOutcome? {
        switch error {
        case .refusal(_, let context), .guardrailViolation(let context):
            return CapturedWritingOutcome(
                kind: .refusal,
                text: "",
                privateEvidence: context.debugDescription.trimmedNonEmpty
            )
        default:
            return nil
        }
    }

    private static func ensureFoundationModelAvailable(_ model: SystemLanguageModel) throws {
        switch model.availability {
        case .available:
            return
        case .unavailable(.deviceNotEligible):
            throw WritingEngineCaptureError(message: "AFM is not available on this device.")
        case .unavailable(.appleIntelligenceNotEnabled):
            throw WritingEngineCaptureError(message: "AFM is not enabled on this device.")
        case .unavailable(.modelNotReady):
            throw WritingEngineCaptureError(message: "AFM is not ready on this device.")
        case .unavailable:
            throw WritingEngineCaptureError(message: "AFM is unavailable in this runtime.")
        }
    }

    private static func validatedCorpus(
        _ corpus: [WritingEvaluationScenario],
        engineID: String
    ) throws -> [WritingEvaluationScenario] {
        guard !engineID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw WritingEngineCaptureError(message: "The engine ID must not be blank.")
        }
        let scenarioIDs = corpus.map(\.scenarioID)
        guard !corpus.isEmpty,
              Set(scenarioIDs).count == corpus.count,
              corpus.allSatisfy({
                  !$0.scenarioID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
                      $0.rubricVersion == 3
              }) else {
            throw WritingEngineCaptureError(
                message: "Capture requires unique, nonempty rubric-version-3 scenarios."
            )
        }
        return corpus.sorted { $0.scenarioID < $1.scenarioID }
    }

    private static func localChatCompletionsEndpoint(_ baseURL: URL) throws -> URL {
        guard ["http", "https"].contains(baseURL.scheme?.lowercased() ?? ""),
              let host = baseURL.host?.lowercased(),
              ["localhost", "127.0.0.1", "::1"].contains(host) else {
            throw WritingEngineCaptureError(
                message: "record-local accepts only a loopback chat-completions endpoint."
            )
        }
        return baseURL
            .appendingPathComponent("chat")
            .appendingPathComponent("completions")
    }

    private static func string(in value: Any?, path: [Any]) -> String? {
        var current = value
        for component in path {
            if let key = component as? String {
                current = (current as? [String: Any])?[key]
            } else if let index = component as? Int,
                      let array = current as? [Any], array.indices.contains(index) {
                current = array[index]
            } else {
                return nil
            }
        }
        return (current as? String)?.trimmedNonEmpty
    }
}

public struct WritingEngineCaptureError: Error, LocalizedError {
    public let message: String

    public init(message: String) {
        self.message = message
    }

    public var errorDescription: String? { message }
}

struct CapturedWritingOutcome: Equatable {
    var kind: RecordedWritingKind
    var text: String
    var privateEvidence: String?
}

private struct LocalCompatibleResponse: Decodable {
    var choices: [Choice]

    struct Choice: Decodable {
        var message: Message
    }

    struct Message: Decodable {
        var content: String?
        var refusal: String?
    }
}

private struct LocalCompatibleDraft: Decodable {
    var messageText: String
    var asksForReassurance: Bool
    var explainsBeforeApology: Bool
    var mayFeelTooHeavy: Bool
    var pressureNotes: [String]
    var missingInformation: [String]
    var riskNotes: [String]
}

private extension String {
    var trimmedNonEmpty: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
