import Foundation
import ProsePalAPI
import ProsePalDomain
import Testing
@testable import ProsePalEvaluation

@Suite(.serialized)
struct WritingEngineCaptureTests {
    @Test
    func liveCorpusIsThePinnedSixteenScenarioExperiment() throws {
        let corpus = try loadLiveCorpus()

        #expect(corpus.count == 16)
        #expect(Set(corpus.map(\.scenarioID)) == Set((1...16).map { String(format: "Q%02d", $0) }))
        #expect(corpus.allSatisfy { $0.rubricVersion == 3 })
    }

    @Test
    func scenarioBecomesTheSameExplicitMomentUsedByBothEngines() throws {
        let scenario = try #require(loadLiveCorpus().first { $0.scenarioID == "Q04" })

        let moment = try WritingEngineCapture.moment(for: scenario)

        #expect(moment.personName == "Jordan")
        #expect(moment.relationship == Relationship.acquaintance)
        #expect(moment.occasion == Occasion.sympathy)
        #expect(moment.register == MomentRegister.assemble)
        #expect(moment.trueThing == "Jordan is grieving; no details about the loss.")
        #expect(moment.tone == Tone.heartfelt)
        #expect(moment.length == MessageLength.brief)
        #expect(moment.localeIdentifier == "en_GB")
    }

    @Test
    func localRequestUsesThePrivateDraftPromptAndEquivalentShape() throws {
        let scenario = try #require(loadLiveCorpus().first { $0.scenarioID == "Q02" })
        let plan = PrivateDraftPromptPlan(
            moment: try WritingEngineCapture.moment(for: scenario),
            adjustment: nil,
            currentMessage: nil,
            approvedBeads: [],
            approvedVoiceCard: nil
        )

        let data = try WritingEngineCapture.localCompatibleRequestBody(
            plan: plan, model: "gemma4:12b"
        )
        let body = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
        let messages = try #require(body["messages"] as? [[String: String]])
        #expect(messages == [
            ["role": "system", "content": plan.instructionComponents.joined(separator: "\n")],
            ["role": "user", "content": plan.promptComponents.joined(separator: "\n")]
        ])
        let responseFormat = try #require(body["response_format"] as? [String: Any])
        let jsonSchema = try #require(responseFormat["json_schema"] as? [String: Any])
        let schema = try #require(jsonSchema["schema"] as? [String: Any])
        let properties = try #require(schema["properties"] as? [String: [String: Any]])
        let required = try #require(schema["required"] as? [String])
        let messageDescription = properties["messageText"]?["description"] as? String
        let pressureDescription = properties["pressureNotes"]?["description"] as? String
        #expect(Set(required) == Set([
            "messageText", "asksForReassurance", "explainsBeforeApology",
            "mayFeelTooHeavy", "pressureNotes", "missingInformation", "riskNotes"
        ]))
        #expect(schema["description"] as? String == "A ProsePal private draft bundle")
        #expect(body["model"] as? String == "gemma4:12b")
        #expect(body["temperature"] as? Double == 0.7)
        #expect(body["top_p"] as? Double == 0.92)
        #expect(body["max_tokens"] as? Int == 700)
        #expect(body["reasoning_effort"] as? String == "none")
        #expect(messageDescription == "The message body the user can send or edit")
        #expect(pressureDescription == "Short pressure-check notes")
    }

    @Test
    func localResponsesPreserveMessagesAndExplicitRefusalText() throws {
        let messageData = successfulResponse(message: "A complete local draft.")
        let refusalData = Data("""
        {"choices":[{"message":{"refusal":"I can’t help with that request."}}]}
        """.utf8)

        let message = try WritingEngineCapture.decodeLocalCompatibleResponse(
            messageData, scenarioID: "Q02"
        )
        let refusal = try WritingEngineCapture.decodeLocalCompatibleResponse(
            refusalData, scenarioID: "Q16"
        )

        #expect(message == CapturedWritingOutcome(
            kind: .message, text: "A complete local draft.", privateEvidence: nil
        ))
        #expect(refusal == CapturedWritingOutcome(
            kind: .refusal, text: "I can’t help with that request.", privateEvidence: nil
        ))
    }

    @Test
    func policyHTTPFailuresBecomePrivateRefusalEvidenceWithoutInventedReviewText() throws {
        let returned = """
        {"error":{"code":"content_policy","message":"Runner-specific policy detail."}}
        """
        let refusal = try #require(WritingEngineCapture.localPolicyRefusal(
            statusCode: 400, data: Data(returned.utf8)
        ))
        let explicit = try #require(WritingEngineCapture.localPolicyRefusal(
            statusCode: 422,
            data: Data("{\"refusal\":\"I can’t help with that.\"}".utf8)
        ))

        #expect(refusal.kind == .refusal)
        #expect(refusal.text.isEmpty)
        #expect(refusal.privateEvidence == returned)
        #expect(explicit.text == "I can’t help with that.")
    }

    @Test
    func bareForbiddenHTTPFailureRemainsTechnicalWithoutPolicyEvidence() throws {
        let bareForbidden = Data("{\"error\":{\"message\":\"Forbidden.\"}}".utf8)
        let supportedForbidden = Data("""
        {"error":{"code":"content_policy","message":"Policy refusal."}}
        """.utf8)

        #expect(WritingEngineCapture.localPolicyRefusal(
            statusCode: 403, data: bareForbidden
        ) == nil)
        #expect(WritingEngineCapture.localPolicyRefusal(
            statusCode: 403, data: supportedForbidden
        )?.kind == .refusal)
    }

    @Test
    func localCaptureMakesExactlyOneRequestPerScenarioAndContinuesAfterPolicyFailure() async throws {
        let corpus = try loadLiveCorpus()
        CapturingURLProtocol.requestCount = 0
        CapturingURLProtocol.requestHandler = { request in
            CapturingURLProtocol.requestCount += 1
            let current = CapturingURLProtocol.requestCount
            if current == 5 {
                return (
                    HTTPURLResponse(
                        url: try #require(request.url),
                        statusCode: 422,
                        httpVersion: nil,
                        headerFields: ["Content-Type": "application/json"]
                    )!,
                    Data("{\"error\":{\"message\":\"Local policy refusal.\"}}".utf8)
                )
            }
            return (
                HTTPURLResponse(
                    url: try #require(request.url),
                    statusCode: 200,
                    httpVersion: nil,
                    headerFields: ["Content-Type": "application/json"]
                )!,
                successfulResponse(message: "Recorded response \(current).")
            )
        }
        defer { CapturingURLProtocol.requestHandler = nil }
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [CapturingURLProtocol.self]

        let outputs = try await WritingEngineCapture.recordLocalCompatible(
            corpus: corpus,
            engineID: "local-test",
            baseURL: URL(string: "http://127.0.0.1:11434/v1")!,
            model: "local-test",
            session: URLSession(configuration: configuration)
        )

        #expect(CapturingURLProtocol.requestCount == corpus.count)
        #expect(outputs.count == corpus.count)
        #expect(outputs.filter { $0.kind == .refusal }.count == 1)
        #expect(outputs.first { $0.kind == .refusal }?.text == "")
        #expect(outputs.first { $0.kind == .refusal }?.privateEvidence?.contains("Local policy refusal") == true)
    }

    private func loadLiveCorpus() throws -> [WritingEvaluationScenario] {
        let url = try #require(Bundle.module.url(
            forResource: "writing-live-corpus-v1", withExtension: "json"
        ))
        return try JSONDecoder().decode([WritingEvaluationScenario].self, from: Data(contentsOf: url))
    }
}

private func successfulResponse(message: String) -> Data {
    let encodedMessage = try! JSONEncoder().encode(message)
    let messageJSON = String(decoding: encodedMessage, as: UTF8.self)
    return Data("""
    {"choices":[{"message":{"content":"{\\"messageText\\":\(messageJSON.replacingOccurrences(of: "\"", with: "\\\"")),\\"asksForReassurance\\":false,\\"explainsBeforeApology\\":false,\\"mayFeelTooHeavy\\":false,\\"pressureNotes\\":[],\\"missingInformation\\":[],\\"riskNotes\\":[]}"}}]}
    """.utf8)
}

private final class CapturingURLProtocol: URLProtocol {
    typealias Handler = @Sendable (URLRequest) throws -> (HTTPURLResponse, Data)
    nonisolated(unsafe) static var requestHandler: Handler?
    nonisolated(unsafe) static var requestCount = 0

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let handler = Self.requestHandler else {
            client?.urlProtocol(self, didFailWithError: URLError(.badServerResponse))
            return
        }
        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}
