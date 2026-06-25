import XCTest
@testable import ProsePalAPI

final class AuthSessionTests: XCTestCase {
    func testSessionControllerLoadsStoredUsableToken() async throws {
        let store = InMemoryAuthSessionStore(
            session: AuthSession(
                accessToken: "access-token",
                refreshToken: "refresh-token",
                expiresAt: Date(timeIntervalSince1970: 1_800_000_000),
                user: AuthUser(id: "user-1", email: "user@example.com")
            )
        )
        let controller = AuthSessionController(store: store)

        let token = try await controller.currentAccessToken(at: Date(timeIntervalSince1970: 1_700_000_000))
        let currentSession = try await controller.currentSession()

        XCTAssertEqual(token, "access-token")
        XCTAssertEqual(currentSession?.user?.id, "user-1")
    }

    func testSessionControllerDoesNotReturnExpiredToken() async throws {
        let store = InMemoryAuthSessionStore(
            session: AuthSession(
                accessToken: "expired-token",
                expiresAt: Date(timeIntervalSince1970: 1_700_000_000)
            )
        )
        let controller = AuthSessionController(store: store)

        let token = try await controller.currentAccessToken(at: Date(timeIntervalSince1970: 1_700_000_001))

        XCTAssertNil(token)
    }

    func testSessionControllerPersistsReplacementAndClearsSignOut() async throws {
        let store = InMemoryAuthSessionStore()
        let controller = AuthSessionController(store: store)
        let session = AuthSession(accessToken: "new-token", user: AuthUser(id: "user-2"))

        try await controller.replaceSession(session)
        let storedSession = try await store.loadSession()
        let token = try await controller.currentAccessToken()
        XCTAssertEqual(storedSession, session)
        XCTAssertEqual(token, "new-token")

        try await controller.clearSession()
        let clearedStoredSession = try await store.loadSession()
        let clearedCurrentSession = try await controller.currentSession()
        XCTAssertNil(clearedStoredSession)
        XCTAssertNil(clearedCurrentSession)
    }

    func testAppleSignInNonceHashesRawValue() {
        let nonce = AppleSignInNonce(rawValue: "raw-nonce")

        XCTAssertEqual(
            nonce.sha256Value,
            "2c5d107938053a2275f022c153c9a71f65ee07754b8bca543ee97a0c3cc66990"
        )
    }

    func testAuthErrorsExposePrivacySafeDiagnosticsOutcomes() {
        XCTAssertEqual(AuthError.configurationMissing.diagnosticsOutcome, "configuration_missing")
        XCTAssertEqual(AuthError.missingIdentityToken.diagnosticsOutcome, "missing_identity_token")
        XCTAssertEqual(AuthError.missingNonce.diagnosticsOutcome, "missing_nonce")
        XCTAssertEqual(AuthError.nonceGenerationFailed.diagnosticsOutcome, "nonce_generation_failed")
        XCTAssertEqual(AuthError.invalidResponse.diagnosticsOutcome, "supabase_invalid_response")
        XCTAssertEqual(
            AuthError.requestFailed(statusCode: 401, message: "safe").diagnosticsOutcome,
            "supabase_rejected"
        )
        XCTAssertEqual(
            AuthError.requestFailed(statusCode: 429, message: "safe").diagnosticsOutcome,
            "supabase_rate_limited"
        )
        XCTAssertEqual(
            AuthError.requestFailed(statusCode: 502, message: "safe").diagnosticsOutcome,
            "supabase_unavailable"
        )
        XCTAssertEqual(
            AuthError.requestFailed(statusCode: 418, message: "safe").diagnosticsOutcome,
            "supabase_http_error"
        )
        XCTAssertEqual(AuthError.storageFailed(message: "safe").diagnosticsOutcome, "session_storage_failed")
    }
}

final class SupabaseAuthClientTests: XCTestCase {
    func testSignInWithIDTokenPostsAppleTokenAndParsesSession() async throws {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [AuthCapturingURLProtocol.self]
        let session = URLSession(configuration: configuration)
        let projectURL = try XCTUnwrap(URL(string: "https://project.supabase.co"))
        let client = SupabaseAuthClient(
            projectURL: projectURL,
            anonKey: "anon-key",
            session: session,
            now: { Date(timeIntervalSince1970: 1_700_000_000) }
        )

        AuthCapturingURLProtocol.requestHandler = { request in
            XCTAssertEqual(request.url?.path, "/auth/v1/token")
            XCTAssertEqual(request.url?.query, "grant_type=id_token")
            XCTAssertEqual(request.value(forHTTPHeaderField: "apikey"), "anon-key")
            XCTAssertEqual(request.value(forHTTPHeaderField: "Content-Type"), "application/json")

            let bodyData = try XCTUnwrap(bodyData(from: request))
            let body = try XCTUnwrap(
                JSONSerialization.jsonObject(with: bodyData) as? [String: Any]
            )
            XCTAssertEqual(body["provider"] as? String, "apple")
            XCTAssertEqual(body["id_token"] as? String, "apple-id-token")
            XCTAssertEqual(body["nonce"] as? String, "raw-nonce")

            let response = try XCTUnwrap(HTTPURLResponse(
                url: projectURL,
                statusCode: 200,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            ))
            let data = """
            {
              "access_token": "supabase-access-token",
              "refresh_token": "supabase-refresh-token",
              "expires_in": 3600,
              "user": {
                "id": "user-1",
                "email": "user@example.com"
              }
            }
            """.data(using: .utf8)!
            return (response, data)
        }
        defer { AuthCapturingURLProtocol.requestHandler = nil }

        let authSession = try await client.signInWithIDToken(
            provider: .apple,
            idToken: " apple-id-token ",
            nonce: " raw-nonce "
        )

        XCTAssertEqual(authSession.accessToken, "supabase-access-token")
        XCTAssertEqual(authSession.refreshToken, "supabase-refresh-token")
        XCTAssertEqual(authSession.expiresAt, Date(timeIntervalSince1970: 1_700_003_600))
        XCTAssertEqual(authSession.user, AuthUser(id: "user-1", email: "user@example.com"))
    }

    func testSignInWithIDTokenMapsFailureWithoutReturningTokens() async throws {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [AuthCapturingURLProtocol.self]
        let session = URLSession(configuration: configuration)
        let projectURL = try XCTUnwrap(URL(string: "https://project.supabase.co"))
        let client = SupabaseAuthClient(
            projectURL: projectURL,
            anonKey: "anon-key",
            session: session
        )

        AuthCapturingURLProtocol.requestHandler = { _ in
            let response = try XCTUnwrap(HTTPURLResponse(
                url: projectURL,
                statusCode: 401,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            ))
            let data = #"{"error_description":"Invalid identity token"}"#.data(using: .utf8)!
            return (response, data)
        }
        defer { AuthCapturingURLProtocol.requestHandler = nil }

        do {
            _ = try await client.signInWithIDToken(
                provider: .apple,
                idToken: "bad-token",
                nonce: "raw-nonce"
            )
            XCTFail("Expected Supabase auth exchange to fail.")
        } catch AuthError.requestFailed(let statusCode, let message) {
            XCTAssertEqual(statusCode, 401)
            XCTAssertEqual(message, "Invalid identity token")
        } catch {
            XCTFail("Expected requestFailed, got \(error).")
        }
    }

    func testSignOutPostsLogoutWithBearerToken() async throws {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [AuthCapturingURLProtocol.self]
        let session = URLSession(configuration: configuration)
        let projectURL = try XCTUnwrap(URL(string: "https://project.supabase.co"))
        let client = SupabaseAuthClient(
            projectURL: projectURL,
            anonKey: "anon-key",
            session: session
        )

        AuthCapturingURLProtocol.requestHandler = { request in
            XCTAssertEqual(request.url?.path, "/auth/v1/logout")
            XCTAssertEqual(request.httpMethod, "POST")
            XCTAssertEqual(request.value(forHTTPHeaderField: "apikey"), "anon-key")
            XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer supabase-access-token")

            let response = try XCTUnwrap(HTTPURLResponse(
                url: projectURL,
                statusCode: 204,
                httpVersion: nil,
                headerFields: nil
            ))
            return (response, Data())
        }
        defer { AuthCapturingURLProtocol.requestHandler = nil }

        try await client.signOut(accessToken: " supabase-access-token ")
    }
}

private actor InMemoryAuthSessionStore: AuthSessionStore {
    private var session: AuthSession?

    init(session: AuthSession? = nil) {
        self.session = session
    }

    func loadSession() async throws -> AuthSession? {
        session
    }

    func saveSession(_ session: AuthSession) async throws {
        self.session = session
    }

    func clearSession() async throws {
        session = nil
    }
}

private final class AuthCapturingURLProtocol: URLProtocol {
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

private func bodyData(from request: URLRequest) -> Data? {
    if let body = request.httpBody {
        return body
    }

    guard let stream = request.httpBodyStream else {
        return nil
    }

    stream.open()
    defer { stream.close() }

    var data = Data()
    let bufferSize = 4096
    var buffer = [UInt8](repeating: 0, count: bufferSize)

    while stream.hasBytesAvailable {
        let readCount = stream.read(&buffer, maxLength: bufferSize)
        if readCount > 0 {
            data.append(buffer, count: readCount)
        } else {
            break
        }
    }

    return data
}
