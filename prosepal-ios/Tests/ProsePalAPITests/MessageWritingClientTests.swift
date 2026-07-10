import XCTest
import ProsePalDomain
@testable import ProsePalAPI

final class MessageWritingClientTests: XCTestCase {
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

    func testGatewayClientDoesNotSendBlankDevGatewaySecretHeader() async throws {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [CapturingURLProtocol.self]
        let session = URLSession(configuration: configuration)
        let endpoint = try XCTUnwrap(URL(string: "https://gateway.example/functions/v1/generate-card"))
        let client = GatewayMessageWritingClient(
            endpoint: endpoint,
            session: session,
            devGatewaySecret: "  \n  "
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
            XCTAssertNil(request.value(forHTTPHeaderField: "X-ProsePal-Dev-Gateway-Secret"))

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

        _ = try await client.generateCard(request: request)
    }

    func testGatewayClientUsesStagingFriendlyDefaultTimeout() async throws {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [CapturingURLProtocol.self]
        let session = URLSession(configuration: configuration)
        let endpoint = try XCTUnwrap(URL(string: "https://gateway.example/functions/v1/generate-card"))
        let client = GatewayMessageWritingClient(endpoint: endpoint, session: session)
        let request = CardRequest(
            idempotencyKey: "timeout-check",
            intent: CardIntent(
                occasion: .birthday,
                relationship: .parent,
                tone: .heartfelt
            ),
            requestedLane: .standard,
            clientContext: ClientContext(appVersion: "0.0.0", buildNumber: "1")
        )

        CapturingURLProtocol.requestHandler = { request in
            XCTAssertEqual(request.timeoutInterval, 45)

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

        _ = try await client.generateCard(request: request)
    }

    func testGatewayClientPropagatesURLCancellationAsTaskCancellation() async throws {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [CapturingURLProtocol.self]
        let session = URLSession(configuration: configuration)
        let endpoint = try XCTUnwrap(URL(string: "https://gateway.example/functions/v1/generate-card"))
        let client = GatewayMessageWritingClient(endpoint: endpoint, session: session)

        CapturingURLProtocol.requestHandler = { _ in
            throw URLError(.cancelled)
        }
        defer { CapturingURLProtocol.requestHandler = nil }

        do {
            _ = try await client.generateCard(request: request(requestedLane: .standard))
            XCTFail("Expected cancellation to be propagated.")
        } catch is CancellationError {
            // Expected path.
        } catch {
            XCTFail("Expected CancellationError, got \(error).")
        }
    }

    func testGatewayClientMapsCannotFindHostToOffline() async throws {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [CapturingURLProtocol.self]
        let session = URLSession(configuration: configuration)
        let endpoint = try XCTUnwrap(URL(string: "https://gateway.example/functions/v1/generate-card"))
        let client = GatewayMessageWritingClient(endpoint: endpoint, session: session)

        CapturingURLProtocol.requestHandler = { _ in
            throw URLError(.cannotFindHost)
        }
        defer { CapturingURLProtocol.requestHandler = nil }

        do {
            _ = try await client.generateCard(request: request(requestedLane: .standard))
            XCTFail("Expected DNS failure to map to offline.")
        } catch GenerationError.offline {
            // Expected path.
        } catch {
            XCTFail("Expected offline, got \(error).")
        }
    }

    func testGatewayClientMapsOfflineAuthRefreshToOffline() async throws {
        let endpoint = try XCTUnwrap(URL(string: "https://gateway.example/functions/v1/generate-card"))
        let client = GatewayMessageWritingClient(
            endpoint: endpoint,
            authorizationTokenProvider: {
                throw AuthError.networkUnavailable
            }
        )

        do {
            _ = try await client.generateCard(request: request(requestedLane: .standard))
            XCTFail("Expected offline auth refresh to map to offline generation.")
        } catch GenerationError.offline {
            // Expected path.
        } catch {
            XCTFail("Expected offline, got \(error).")
        }
    }

    func testGatewayClientAddsAuthorizationHeaderFromTokenProvider() async throws {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [CapturingURLProtocol.self]
        let session = URLSession(configuration: configuration)
        let endpoint = try XCTUnwrap(URL(string: "https://gateway.example/functions/v1/generate-card"))
        let client = GatewayMessageWritingClient(
            endpoint: endpoint,
            session: session,
            authorizationTokenProvider: { "  supabase-access-token\n" }
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
            XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer supabase-access-token")

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

        _ = try await client.generateCard(request: request)
    }

    func testGatewayClientDoesNotSendBlankAuthorizationHeaderFromTokenProvider() async throws {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [CapturingURLProtocol.self]
        let session = URLSession(configuration: configuration)
        let endpoint = try XCTUnwrap(URL(string: "https://gateway.example/functions/v1/generate-card"))
        let client = GatewayMessageWritingClient(
            endpoint: endpoint,
            session: session,
            authorizationTokenProvider: { "  \n  " }
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
            XCTAssertNil(request.value(forHTTPHeaderField: "Authorization"))

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

        _ = try await client.generateCard(request: request)
    }

    func testGatewayClientMapsUnauthorizedResponseToConfigurationMessage() async throws {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [CapturingURLProtocol.self]
        let session = URLSession(configuration: configuration)
        let endpoint = try XCTUnwrap(URL(string: "https://gateway.example/functions/v1/generate-card"))
        let client = GatewayMessageWritingClient(
            endpoint: endpoint,
            session: session
        )
        let request = CardRequest(
            intent: CardIntent(
                occasion: .birthday,
                relationship: .parent,
                tone: .heartfelt
            ),
            requestedLane: .standard,
            clientContext: ClientContext(appVersion: "0.0.0", buildNumber: "1")
        )

        CapturingURLProtocol.requestHandler = { _ in
            let response = try XCTUnwrap(HTTPURLResponse(
                url: endpoint,
                statusCode: 401,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            ))
            return (response, Data("{}".utf8))
        }
        defer { CapturingURLProtocol.requestHandler = nil }

        do {
            _ = try await client.generateCard(request: request)
            XCTFail("Expected unauthorized gateway response to fail.")
        } catch GenerationError.unexpectedResponse(let message) {
            XCTAssertEqual(message, "Message generation is not configured for this build.")
        } catch {
            XCTFail("Expected unexpectedResponse, got \(error).")
        }
    }

    func testGatewayClientRejectsSuccessfulResponseWithNoMessages() async throws {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [CapturingURLProtocol.self]
        let session = URLSession(configuration: configuration)
        let endpoint = try XCTUnwrap(URL(string: "https://gateway.example/functions/v1/generate-card"))
        let client = GatewayMessageWritingClient(
            endpoint: endpoint,
            session: session
        )

        CapturingURLProtocol.requestHandler = { _ in
            let response = try XCTUnwrap(HTTPURLResponse(
                url: endpoint,
                statusCode: 200,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            ))
            let data = """
            {
              "messages": [],
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

        do {
            _ = try await client.generateCard(request: request(requestedLane: .standard))
            XCTFail("Expected empty gateway response to fail.")
        } catch GenerationError.unexpectedResponse(let message) {
            XCTAssertEqual(message, "Message generation returned no messages. Please try again.")
        } catch {
            XCTFail("Expected unexpectedResponse, got \(error).")
        }
    }

    func testGatewayClientRejectsSuccessfulResponseWithBlankMessageText() async throws {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [CapturingURLProtocol.self]
        let session = URLSession(configuration: configuration)
        let endpoint = try XCTUnwrap(URL(string: "https://gateway.example/functions/v1/generate-card"))
        let client = GatewayMessageWritingClient(
            endpoint: endpoint,
            session: session
        )

        CapturingURLProtocol.requestHandler = { _ in
            let response = try XCTUnwrap(HTTPURLResponse(
                url: endpoint,
                statusCode: 200,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            ))
            let data = """
            {
              "messages": [
                { "id": "message-1", "text": "  " }
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

        do {
            _ = try await client.generateCard(request: request(requestedLane: .standard))
            XCTFail("Expected blank gateway message to fail.")
        } catch GenerationError.unexpectedResponse(let message) {
            XCTAssertEqual(message, "Message generation returned an empty message. Please try again.")
        } catch {
            XCTFail("Expected unexpectedResponse, got \(error).")
        }
    }

    func testGatewayClientRejectsUnsupportedContractVersion() async throws {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [CapturingURLProtocol.self]
        let session = URLSession(configuration: configuration)
        let endpoint = try XCTUnwrap(URL(string: "https://gateway.example/functions/v1/generate-card"))
        let client = GatewayMessageWritingClient(
            endpoint: endpoint,
            session: session
        )

        CapturingURLProtocol.requestHandler = { _ in
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
              "output_contract_version": 99
            }
            """.data(using: .utf8)!
            return (response, data)
        }
        defer { CapturingURLProtocol.requestHandler = nil }

        do {
            _ = try await client.generateCard(request: request(requestedLane: .standard))
            XCTFail("Expected unsupported contract version to fail.")
        } catch GenerationError.unexpectedResponse(let message) {
            XCTAssertEqual(message, "This version of ProsePal cannot read the generation response. Please update the app.")
        } catch {
            XCTFail("Expected unexpectedResponse, got \(error).")
        }
    }

    func testGatewayClientMapsMalformedSuccessBodyToUnexpectedResponse() async throws {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [CapturingURLProtocol.self]
        let session = URLSession(configuration: configuration)
        let endpoint = try XCTUnwrap(URL(string: "https://gateway.example/functions/v1/generate-card"))
        let client = GatewayMessageWritingClient(
            endpoint: endpoint,
            session: session
        )

        CapturingURLProtocol.requestHandler = { _ in
            let response = try XCTUnwrap(HTTPURLResponse(
                url: endpoint,
                statusCode: 200,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            ))
            return (response, Data("{not json".utf8))
        }
        defer { CapturingURLProtocol.requestHandler = nil }

        do {
            _ = try await client.generateCard(request: request(requestedLane: .standard))
            XCTFail("Expected malformed gateway response to fail.")
        } catch GenerationError.unexpectedResponse(let message) {
            XCTAssertEqual(message, "Message generation failed. Please try again.")
        } catch {
            XCTFail("Expected unexpectedResponse, got \(error).")
        }
    }

    func testGatewayClientMapsGatewayFailureStatusBuckets() async throws {
        try await assertGatewayFailure(
            statusCode: 408,
            expectedError: .timedOut
        )
        try await assertGatewayFailure(
            statusCode: 429,
            body: """
            {
              "user_safe_error": {
                "code": "rate_limited",
                "message": "Please wait a moment before trying again."
              }
            }
            """,
            expectedError: .rateLimited(message: "Please wait a moment before trying again.")
        )
        try await assertGatewayFailure(
            statusCode: 422,
            body: """
            {
              "user_safe_error": {
                "code": "content_blocked",
                "message": "Try changing a few details before writing this message."
              }
            }
            """,
            expectedError: .contentBlocked(message: "Try changing a few details before writing this message.")
        )
        try await assertGatewayFailure(
            statusCode: 502,
            expectedError: .serviceUnavailable(message: "Message generation is temporarily unavailable. Please try again shortly.")
        )
        try await assertGatewayFailure(
            statusCode: 418,
            expectedError: .unexpectedResponse(message: "Message generation failed. Please try again.")
        )
    }

    func testGatewayClientUsesServerSafeMessageForEntitlementFailures() async throws {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [CapturingURLProtocol.self]
        let session = URLSession(configuration: configuration)
        let endpoint = try XCTUnwrap(URL(string: "https://gateway.example/functions/v1/generate-card"))
        let client = GatewayMessageWritingClient(
            endpoint: endpoint,
            session: session
        )
        let request = CardRequest(
            intent: CardIntent(
                occasion: .birthday,
                relationship: .parent,
                tone: .heartfelt
            ),
            requestedLane: .premium,
            clientContext: ClientContext(appVersion: "0.0.0", buildNumber: "1")
        )

        CapturingURLProtocol.requestHandler = { _ in
            let response = try XCTUnwrap(HTTPURLResponse(
                url: endpoint,
                statusCode: 403,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            ))
            let data = """
            {
              "error": "Premium generation unavailable",
              "user_safe_error": {
                "code": "premium_unavailable",
                "message": "Premium generation is not available in this development gateway yet."
              }
            }
            """.data(using: .utf8)!
            return (response, data)
        }
        defer { CapturingURLProtocol.requestHandler = nil }

        do {
            _ = try await client.generateCard(request: request)
            XCTFail("Expected gateway entitlement response to fail.")
        } catch GenerationError.usageLimitReached(let message) {
            XCTAssertEqual(message, "Premium generation is not available in this development gateway yet.")
        } catch {
            XCTFail("Expected usageLimitReached, got \(error).")
        }
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

    private func assertGatewayFailure(
        statusCode: Int,
        body: String = "{}",
        expectedError: GenerationError,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async throws {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [CapturingURLProtocol.self]
        let session = URLSession(configuration: configuration)
        let endpoint = try XCTUnwrap(URL(string: "https://gateway.example/functions/v1/generate-card"))
        let client = GatewayMessageWritingClient(
            endpoint: endpoint,
            session: session
        )

        CapturingURLProtocol.requestHandler = { _ in
            let response = try XCTUnwrap(HTTPURLResponse(
                url: endpoint,
                statusCode: statusCode,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            ))
            return (response, Data(body.utf8))
        }
        defer { CapturingURLProtocol.requestHandler = nil }

        do {
            _ = try await client.generateCard(request: request(requestedLane: .standard))
            XCTFail("Expected gateway status \(statusCode) to fail.", file: file, line: line)
        } catch let error as GenerationError {
            XCTAssertEqual(error, expectedError, file: file, line: line)
        } catch {
            XCTFail("Expected GenerationError, got \(error).", file: file, line: line)
        }
    }
}

private final class CapturingURLProtocol: URLProtocol {
    typealias Handler = (URLRequest) throws -> (HTTPURLResponse, Data)

    nonisolated(unsafe) static var requestHandler: Handler?

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
