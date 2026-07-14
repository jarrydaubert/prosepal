import XCTest
@testable import ProsePalAPI

final class AppleAccountLifecycleClientTests: XCTestCase {
    override func tearDown() {
        AppleAccountCapturingURLProtocol.requestHandler = nil
        super.tearDown()
    }

    func testStoreRevocationMaterialForwardsCodeAndUserToAuthenticatedBoundary() async throws {
        let session = makeSession()
        let projectURL = try XCTUnwrap(URL(string: "https://project.supabase.co"))
        let client = SupabaseAppleAccountLifecycleClient(
            projectURL: projectURL,
            anonKey: " anon-key ",
            session: session,
            requestTimeout: 9
        )

        AppleAccountCapturingURLProtocol.requestHandler = { request in
            XCTAssertEqual(request.httpMethod, "POST")
            XCTAssertEqual(
                request.url?.absoluteString,
                "https://project.supabase.co/functions/v1/exchange-apple-token"
            )
            XCTAssertEqual(request.timeoutInterval, 9)
            XCTAssertEqual(request.value(forHTTPHeaderField: "apikey"), "anon-key")
            XCTAssertEqual(
                request.value(forHTTPHeaderField: "Authorization"),
                "Bearer supabase-access-token"
            )
            let body = try request.capturedBodyData()
            let json = try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [String: String])
            XCTAssertEqual(json, [
                "authorization_code": "one-time-code",
                "apple_user_id": "apple-user"
            ])
            return (
                HTTPURLResponse(
                    url: try XCTUnwrap(request.url),
                    statusCode: 200,
                    httpVersion: nil,
                    headerFields: ["Content-Type": "application/json"]
                )!,
                Data(#"{"success":true}"#.utf8)
            )
        }

        try await client.storeRevocationMaterial(
            authorizationCode: " one-time-code ",
            appleUserID: " apple-user ",
            accessToken: " supabase-access-token "
        )
    }

    func testMissingAuthorizationCodeAndCredentialIdentifierFailBeforeNetwork() async throws {
        let client = SupabaseAppleAccountLifecycleClient(
            projectURL: try XCTUnwrap(URL(string: "https://project.supabase.co")),
            anonKey: "anon-key",
            session: makeSession()
        )
        AppleAccountCapturingURLProtocol.requestHandler = { _ in
            XCTFail("Invalid Apple results must not reach the network.")
            throw URLError(.badServerResponse)
        }

        do {
            try await client.storeRevocationMaterial(
                authorizationCode: " ",
                appleUserID: "apple-user",
                accessToken: "access-token"
            )
            XCTFail("Expected missing authorization code.")
        } catch AppleAccountLifecycleError.missingAuthorizationCode {
            // Expected.
        }

        do {
            try await client.storeRevocationMaterial(
                authorizationCode: "code",
                appleUserID: " ",
                accessToken: "access-token"
            )
            XCTFail("Expected missing credential identifier.")
        } catch AppleAccountLifecycleError.missingCredentialIdentifier {
            // Expected.
        }
    }

    func testTimeoutAndServerFailureReturnSafeRetryableErrors() async throws {
        let session = makeSession()
        let client = SupabaseAppleAccountLifecycleClient(
            projectURL: try XCTUnwrap(URL(string: "https://project.supabase.co")),
            anonKey: "anon-key",
            session: session
        )
        AppleAccountCapturingURLProtocol.requestHandler = { _ in
            throw URLError(.timedOut)
        }

        do {
            try await client.storeRevocationMaterial(
                authorizationCode: "private-code",
                appleUserID: "apple-user",
                accessToken: "private-access-token"
            )
            XCTFail("Expected timeout.")
        } catch AppleAccountLifecycleError.timedOut {
            // Expected.
        }

        AppleAccountCapturingURLProtocol.requestHandler = { request in
            return (
                HTTPURLResponse(
                    url: try XCTUnwrap(request.url),
                    statusCode: 503,
                    httpVersion: nil,
                    headerFields: ["Content-Type": "application/json"]
                )!,
                Data(#"{"error":"Apple account setup failed safely."}"#.utf8)
            )
        }

        do {
            try await client.storeRevocationMaterial(
                authorizationCode: "private-code",
                appleUserID: "apple-user",
                accessToken: "private-access-token"
            )
            XCTFail("Expected server failure.")
        } catch AppleAccountLifecycleError.requestFailed(let status, let message) {
            XCTAssertEqual(status, 503)
            XCTAssertEqual(message, "Apple account setup failed safely.")
            XCTAssertFalse(message.contains("private-code"))
            XCTAssertFalse(message.contains("private-access-token"))
        }
    }

    func testMalformedSuccessResponseFailsClosed() async throws {
        let client = SupabaseAppleAccountLifecycleClient(
            projectURL: try XCTUnwrap(URL(string: "https://project.supabase.co")),
            anonKey: "anon-key",
            session: makeSession()
        )
        AppleAccountCapturingURLProtocol.requestHandler = { request in
            return (
                HTTPURLResponse(
                    url: try XCTUnwrap(request.url),
                    statusCode: 200,
                    httpVersion: nil,
                    headerFields: nil
                )!,
                Data(#"{"success":false}"#.utf8)
            )
        }

        do {
            try await client.storeRevocationMaterial(
                authorizationCode: "code",
                appleUserID: "apple-user",
                accessToken: "access-token"
            )
            XCTFail("Expected invalid response.")
        } catch AppleAccountLifecycleError.invalidResponse {
            // Expected.
        }
    }

    func testLegacyStoredSessionDecodesWithoutAppleCredentialIdentifier() throws {
        let data = Data(#"""
        {
          "accessToken":"access",
          "refreshToken":"refresh",
          "user":{"id":"user-1"}
        }
        """#.utf8)
        let session = try JSONDecoder().decode(AuthSession.self, from: data)

        XCTAssertEqual(session.accessToken, "access")
        XCTAssertNil(session.appleCredentialUserID)
    }

    private func makeSession() -> URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [AppleAccountCapturingURLProtocol.self]
        return URLSession(configuration: configuration)
    }
}

private final class AppleAccountCapturingURLProtocol: URLProtocol {
    typealias Handler = (URLRequest) throws -> (HTTPURLResponse, Data)
    nonisolated(unsafe) static var requestHandler: Handler?

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

private extension URLRequest {
    func capturedBodyData() throws -> Data {
        if let httpBody { return httpBody }
        let stream = try XCTUnwrap(httpBodyStream)
        stream.open()
        defer { stream.close() }
        var data = Data()
        let bufferSize = 1_024
        var buffer = [UInt8](repeating: 0, count: bufferSize)
        while stream.hasBytesAvailable {
            let count = stream.read(&buffer, maxLength: bufferSize)
            if count < 0 {
                throw stream.streamError ?? URLError(.cannotDecodeContentData)
            }
            if count == 0 { break }
            data.append(buffer, count: count)
        }
        return data
    }
}
