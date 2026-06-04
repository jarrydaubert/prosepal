import XCTest
import ProsePalDomain
@testable import ProsePalAPI

final class MessageWritingClientTests: XCTestCase {
    func testMockClientReturnsProvidedGatewayResponse() async throws {
        let response = CardResponse(
            messages: [GeneratedMessage(id: "draft-1", text: "A gateway-shaped draft.")],
            laneUsed: .standard,
            fallbackStatus: .none,
            retryEligibility: .ineligible
        )
        let client = MockMessageWritingClient(response: response)
        let request = CardRequest(
            intent: CardIntent(
                occasion: .birthday,
                relationship: .parent,
                tone: .heartfelt
            ),
            clientContext: ClientContext(appVersion: "0.0.0", buildNumber: "1")
        )

        let generated = try await client.generateCard(request: request)

        XCTAssertEqual(generated, response)
    }

    func testGatewayClientAddsOptionalDevGatewaySecretHeader() async throws {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [CapturingURLProtocol.self]
        let session = URLSession(configuration: configuration)
        let endpoint = try XCTUnwrap(URL(string: "https://gateway.example/functions/v1/generate-card"))
        let client = GatewayMessageWritingClient(
            endpoint: endpoint,
            session: session,
            devGatewaySecret: "dev-secret"
        )
        let request = CardRequest(
            idempotencyKey: "fixed-key",
            intent: CardIntent(
                occasion: .birthday,
                relationship: .parent,
                tone: .heartfelt
            ),
            requestedLane: .standard,
            clientContext: ClientContext(appVersion: "0.0.0", buildNumber: "1")
        )

        CapturingURLProtocol.requestHandler = { request in
            XCTAssertEqual(request.value(forHTTPHeaderField: "X-ProsePal-Dev-Gateway-Secret"), "dev-secret")
            XCTAssertEqual(request.value(forHTTPHeaderField: "Idempotency-Key"), "fixed-key")

            let response = try XCTUnwrap(HTTPURLResponse(
                url: endpoint,
                statusCode: 200,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            ))
            let data = """
            {
              "messages": [
                { "id": "message-1", "text": "A gateway-shaped message." }
              ],
              "lane_used": "standard",
              "fallback_status": "none",
              "retry_eligibility": "ineligible",
              "prompt_contract_version": 1,
              "output_contract_version": 1
            }
            """.data(using: .utf8)!
            return (response, data)
        }
        defer { CapturingURLProtocol.requestHandler = nil }

        let generated = try await client.generateCard(request: request)

        XCTAssertEqual(generated.messages.map(\.text), ["A gateway-shaped message."])
        XCTAssertEqual(generated.laneUsed, .standard)
        XCTAssertEqual(generated.fallbackStatus, .none)
    }

    func testRouterSendsStandardRequestsToStandardClient() async throws {
        let standardClient = RecordingMessageWritingClient(response: CardResponse(
            messages: [GeneratedMessage(id: "standard-1", text: "Standard draft.")],
            laneUsed: .standard
        ))
        let premiumClient = RecordingMessageWritingClient(response: CardResponse(
            messages: [GeneratedMessage(id: "premium-1", text: "Premium draft.")],
            laneUsed: .premium
        ))
        let router = MessageWritingRouter(
            standardClient: standardClient,
            premiumClient: premiumClient
        )

        let generated = try await router.generateCard(request: request(requestedLane: .standard))
        let standardRequestCount = await standardClient.requestCount()
        let standardRequestedLane = await standardClient.firstRequestedLane()
        let premiumRequestCount = await premiumClient.requestCount()

        XCTAssertEqual(generated.laneUsed, .standard)
        XCTAssertEqual(standardRequestCount, 1)
        XCTAssertEqual(standardRequestedLane, .standard)
        XCTAssertEqual(premiumRequestCount, 0)
    }

    func testRouterSendsPremiumRequestsToPremiumClient() async throws {
        let standardClient = RecordingMessageWritingClient(response: CardResponse(
            messages: [GeneratedMessage(id: "standard-1", text: "Standard draft.")],
            laneUsed: .standard
        ))
        let premiumClient = RecordingMessageWritingClient(response: CardResponse(
            messages: [GeneratedMessage(id: "premium-1", text: "Premium draft.")],
            laneUsed: .premium
        ))
        let router = MessageWritingRouter(
            standardClient: standardClient,
            premiumClient: premiumClient
        )

        let generated = try await router.generateCard(request: request(requestedLane: .premium))
        let standardRequestCount = await standardClient.requestCount()
        let premiumRequestCount = await premiumClient.requestCount()
        let premiumRequestedLane = await premiumClient.firstRequestedLane()

        XCTAssertEqual(generated.laneUsed, .premium)
        XCTAssertEqual(standardRequestCount, 0)
        XCTAssertEqual(premiumRequestCount, 1)
        XCTAssertEqual(premiumRequestedLane, .premium)
    }

    func testRouterDoesNotInventLocalFallbackWhenLocalClientIsMissing() async throws {
        let standardClient = RecordingMessageWritingClient(response: CardResponse(
            messages: [GeneratedMessage(id: "standard-1", text: "Standard draft.")],
            laneUsed: .standard
        ))
        let router = MessageWritingRouter(standardClient: standardClient)

        do {
            _ = try await router.generateCard(request: request(requestedLane: .local))
            XCTFail("Expected local lane to fail when no local client is configured.")
        } catch GenerationError.serviceUnavailable(let message) {
            XCTAssertTrue(message.contains("on-device"))
        } catch {
            XCTFail("Expected service unavailable, got \(error).")
        }

        let standardRequestCount = await standardClient.requestCount()
        XCTAssertEqual(standardRequestCount, 0)
    }

    private func request(requestedLane: GenerationLane) -> CardRequest {
        CardRequest(
            intent: CardIntent(
                occasion: .birthday,
                relationship: .parent,
                tone: .heartfelt
            ),
            requestedLane: requestedLane,
            clientContext: ClientContext(appVersion: "0.0.0", buildNumber: "1")
        )
    }
}

private actor RecordingMessageWritingClient: MessageWritingClient {
    private let response: CardResponse
    private var requests: [CardRequest] = []

    init(response: CardResponse) {
        self.response = response
    }

    func generateCard(request: CardRequest) async throws -> CardResponse {
        requests.append(request)
        return response
    }

    func requestCount() -> Int {
        requests.count
    }

    func firstRequestedLane() -> GenerationLane? {
        requests.first?.requestedLane
    }
}

private final class CapturingURLProtocol: URLProtocol {
    typealias Handler = (URLRequest) throws -> (HTTPURLResponse, Data)

    static var requestHandler: Handler?

    override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        guard let requestHandler = Self.requestHandler else {
            client?.urlProtocol(self, didFailWithError: URLError(.badServerResponse))
            return
        }

        do {
            let (response, data) = try requestHandler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}
