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

    func testSessionControllerRefreshesExpiredSessionAndPersistsRotatedTokens() async throws {
        let expiredSession = AuthSession(
            accessToken: "expired-token",
            refreshToken: "refresh-token-1",
            expiresAt: Date(timeIntervalSince1970: 1_700_000_000),
            user: AuthUser(id: "user-1", email: "user@example.com")
        )
        let rotatedSession = AuthSession(
            accessToken: "access-token-2",
            refreshToken: "refresh-token-2",
            expiresAt: Date(timeIntervalSince1970: 1_700_003_600),
            user: AuthUser(id: "user-1", email: "user@example.com")
        )
        let store = InMemoryAuthSessionStore(session: expiredSession)
        let client = RefreshingAuthClient(responses: [.success(rotatedSession)])
        let controller = AuthSessionController(store: store, authClient: client)

        let token = try await controller.currentAccessToken(
            at: Date(timeIntervalSince1970: 1_700_000_001)
        )
        let storedRotatedSession = try await store.loadSession()
        let recordedRefreshTokens = await client.refreshTokens()

        XCTAssertEqual(token, "access-token-2")
        XCTAssertEqual(storedRotatedSession, rotatedSession)
        XCTAssertEqual(recordedRefreshTokens, ["refresh-token-1"])

        let relaunchedController = AuthSessionController(store: store, authClient: client)
        let relaunchedToken = try await relaunchedController.currentAccessToken(
            at: Date(timeIntervalSince1970: 1_700_000_002)
        )
        let refreshCallCount = await client.refreshCallCount()
        XCTAssertEqual(relaunchedToken, "access-token-2")
        XCTAssertEqual(refreshCallCount, 1)
    }

    func testSessionControllerSerializesConcurrentRefreshCallers() async throws {
        let expiredSession = AuthSession(
            accessToken: "expired-token",
            refreshToken: "refresh-token-1",
            expiresAt: Date(timeIntervalSince1970: 1_700_000_000)
        )
        let rotatedSession = AuthSession(
            accessToken: "access-token-2",
            refreshToken: "refresh-token-2",
            expiresAt: Date(timeIntervalSince1970: 1_700_003_600)
        )
        let store = InMemoryAuthSessionStore(session: expiredSession)
        let client = RefreshingAuthClient(
            responses: [.success(rotatedSession)],
            delay: .milliseconds(30)
        )
        let controller = AuthSessionController(store: store, authClient: client)
        let requestDate = Date(timeIntervalSince1970: 1_700_000_001)

        let tokens = try await withThrowingTaskGroup(of: String?.self) { group in
            for _ in 0..<8 {
                group.addTask {
                    try await controller.currentAccessToken(at: requestDate)
                }
            }

            var tokens: [String?] = []
            for try await token in group {
                tokens.append(token)
            }
            return tokens
        }
        let refreshCallCount = await client.refreshCallCount()
        let storedSession = try await store.loadSession()

        XCTAssertEqual(tokens.compactMap { $0 }, Array(repeating: "access-token-2", count: 8))
        XCTAssertEqual(refreshCallCount, 1)
        XCTAssertEqual(storedSession, rotatedSession)
    }

    func testSessionControllerPreservesExpiredSessionAcrossOfflineRefreshAndRecovers() async throws {
        let expiredSession = AuthSession(
            accessToken: "expired-token",
            refreshToken: "refresh-token-1",
            expiresAt: Date(timeIntervalSince1970: 1_700_000_000),
            user: AuthUser(id: "user-1", email: "user@example.com")
        )
        let rotatedSession = AuthSession(
            accessToken: "access-token-2",
            refreshToken: "refresh-token-2",
            expiresAt: Date(timeIntervalSince1970: 1_700_003_600),
            user: expiredSession.user
        )
        let store = InMemoryAuthSessionStore(session: expiredSession)
        let client = RefreshingAuthClient(responses: [
            .failure(.networkUnavailable),
            .success(rotatedSession)
        ])
        let controller = AuthSessionController(store: store, authClient: client)
        let requestDate = Date(timeIntervalSince1970: 1_700_000_001)

        do {
            _ = try await controller.currentAccessToken(at: requestDate)
            XCTFail("Expected offline refresh to fail without clearing the session.")
        } catch AuthError.networkUnavailable {
            // Expected path.
        }

        let storedExpiredSession = try await store.loadSession()
        let cachedExpiredSession = try await controller.persistedSession()

        XCTAssertEqual(storedExpiredSession, expiredSession)
        XCTAssertEqual(cachedExpiredSession, expiredSession)

        let recoveredToken = try await controller.currentAccessToken(at: requestDate)
        let storedRotatedSession = try await store.loadSession()
        let refreshCallCount = await client.refreshCallCount()
        XCTAssertEqual(recoveredToken, "access-token-2")
        XCTAssertEqual(storedRotatedSession, rotatedSession)
        XCTAssertEqual(refreshCallCount, 2)
    }

    func testSessionControllerClearsSessionAfterTerminalRefreshRejection() async throws {
        let expiredSession = AuthSession(
            accessToken: "expired-token",
            refreshToken: "refresh-token-1",
            expiresAt: Date(timeIntervalSince1970: 1_700_000_000)
        )
        let store = InMemoryAuthSessionStore(session: expiredSession)
        let client = RefreshingAuthClient(responses: [
            .failure(.requestFailed(statusCode: 401, message: "Refresh token rejected."))
        ])
        let controller = AuthSessionController(store: store, authClient: client)

        do {
            _ = try await controller.currentAccessToken(
                at: Date(timeIntervalSince1970: 1_700_000_001)
            )
            XCTFail("Expected terminal refresh rejection.")
        } catch AuthError.requestFailed(let statusCode, _) {
            XCTAssertEqual(statusCode, 401)
        }

        let storedSession = try await store.loadSession()
        let cachedSession = try await controller.persistedSession()

        XCTAssertNil(storedSession)
        XCTAssertNil(cachedSession)
    }

    func testClearingSessionDuringRefreshCannotRestoreRotatedSession() async throws {
        let expiredSession = AuthSession(
            accessToken: "expired-token",
            refreshToken: "refresh-token-1",
            expiresAt: Date(timeIntervalSince1970: 1_700_000_000)
        )
        let rotatedSession = AuthSession(
            accessToken: "access-token-2",
            refreshToken: "refresh-token-2",
            expiresAt: Date(timeIntervalSince1970: 1_700_003_600)
        )
        let store = InMemoryAuthSessionStore(session: expiredSession)
        let client = RefreshingAuthClient(
            responses: [.success(rotatedSession)],
            delay: .seconds(1)
        )
        let controller = AuthSessionController(store: store, authClient: client)
        let refreshTask = Task {
            try await controller.currentAccessToken(
                at: Date(timeIntervalSince1970: 1_700_000_001)
            )
        }

        while await client.refreshCallCount() == 0 {
            await Task.yield()
        }
        try await controller.clearSession()

        do {
            _ = try await refreshTask.value
            XCTFail("Expected the in-flight refresh to be cancelled by session clearing.")
        } catch is CancellationError {
            // Expected path.
        }
        let storedSession = try await store.loadSession()
        let cachedSession = try await controller.persistedSession()
        XCTAssertNil(storedSession)
        XCTAssertNil(cachedSession)
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
        XCTAssertEqual(AuthError.networkUnavailable.diagnosticsOutcome, "network_unavailable")
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

    func testSignInWithIDTokenMapsCannotFindHostToNetworkUnavailable() async throws {
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
            throw URLError(.cannotFindHost)
        }
        defer { AuthCapturingURLProtocol.requestHandler = nil }

        do {
            _ = try await client.signInWithIDToken(
                provider: .apple,
                idToken: "apple-token",
                nonce: "raw-nonce"
            )
            XCTFail("Expected DNS failure to map to networkUnavailable.")
        } catch AuthError.networkUnavailable {
            // Expected path.
        } catch {
            XCTFail("Expected networkUnavailable, got \(error).")
        }
    }

    func testRefreshSessionPostsRefreshGrantAndParsesRotatedSession() async throws {
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
        let existingSession = AuthSession(
            accessToken: "expired-token",
            refreshToken: "refresh-token-1",
            expiresAt: Date(timeIntervalSince1970: 1_699_999_999),
            user: AuthUser(id: "user-1", email: "user@example.com")
        )

        AuthCapturingURLProtocol.requestHandler = { request in
            XCTAssertEqual(request.url?.path, "/auth/v1/token")
            XCTAssertEqual(request.url?.query, "grant_type=refresh_token")
            XCTAssertEqual(request.httpMethod, "POST")
            XCTAssertEqual(request.value(forHTTPHeaderField: "apikey"), "anon-key")
            XCTAssertEqual(request.value(forHTTPHeaderField: "Content-Type"), "application/json")
            XCTAssertNil(request.value(forHTTPHeaderField: "Authorization"))

            let bodyData = try XCTUnwrap(bodyData(from: request))
            let body = try XCTUnwrap(
                JSONSerialization.jsonObject(with: bodyData) as? [String: Any]
            )
            XCTAssertEqual(body["refresh_token"] as? String, "refresh-token-1")

            let response = try XCTUnwrap(HTTPURLResponse(
                url: projectURL,
                statusCode: 200,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            ))
            let data = """
            {
              "access_token": "access-token-2",
              "refresh_token": "refresh-token-2",
              "expires_in": 3600
            }
            """.data(using: .utf8)!
            return (response, data)
        }
        defer { AuthCapturingURLProtocol.requestHandler = nil }

        let refreshedSession = try await client.refreshSession(existingSession)

        XCTAssertEqual(refreshedSession.accessToken, "access-token-2")
        XCTAssertEqual(refreshedSession.refreshToken, "refresh-token-2")
        XCTAssertEqual(refreshedSession.expiresAt, Date(timeIntervalSince1970: 1_700_003_600))
        XCTAssertEqual(refreshedSession.user, existingSession.user)
    }

    func testRefreshSessionMapsConnectivityFailureWithoutExposingRefreshToken() async throws {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [AuthCapturingURLProtocol.self]
        let session = URLSession(configuration: configuration)
        let projectURL = try XCTUnwrap(URL(string: "https://project.supabase.co"))
        let client = SupabaseAuthClient(
            projectURL: projectURL,
            anonKey: "anon-key",
            session: session
        )
        let existingSession = AuthSession(
            accessToken: "expired-token",
            refreshToken: "private-refresh-token"
        )

        AuthCapturingURLProtocol.requestHandler = { _ in
            throw URLError(.notConnectedToInternet)
        }
        defer { AuthCapturingURLProtocol.requestHandler = nil }

        do {
            _ = try await client.refreshSession(existingSession)
            XCTFail("Expected refresh connectivity failure.")
        } catch let error as AuthError {
            XCTAssertEqual(error, .networkUnavailable)
            XCTAssertFalse(error.userSafeMessage.contains("private-refresh-token"))
        }
    }

    func testRefreshSessionMapsMalformedSuccessResponseToInvalidResponse() async throws {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [AuthCapturingURLProtocol.self]
        let session = URLSession(configuration: configuration)
        let projectURL = try XCTUnwrap(URL(string: "https://project.supabase.co"))
        let client = SupabaseAuthClient(
            projectURL: projectURL,
            anonKey: "anon-key",
            session: session
        )
        let existingSession = AuthSession(
            accessToken: "expired-token",
            refreshToken: "refresh-token-1"
        )

        AuthCapturingURLProtocol.requestHandler = { _ in
            let response = try XCTUnwrap(HTTPURLResponse(
                url: projectURL,
                statusCode: 200,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            ))
            return (response, #"{"unexpected":true}"#.data(using: .utf8)!)
        }
        defer { AuthCapturingURLProtocol.requestHandler = nil }

        do {
            _ = try await client.refreshSession(existingSession)
            XCTFail("Expected a malformed refresh response to fail.")
        } catch AuthError.invalidResponse {
            // Expected path.
        }
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

private actor RefreshingAuthClient: AuthClient {
    enum Response: Sendable {
        case success(AuthSession)
        case failure(AuthError)
    }

    private var responses: [Response]
    private let delay: Duration?
    private var recordedRefreshTokens: [String] = []

    init(responses: [Response], delay: Duration? = nil) {
        self.responses = responses
        self.delay = delay
    }

    func signInWithIDToken(
        provider: AuthProvider,
        idToken: String,
        nonce: String?
    ) async throws -> AuthSession {
        throw AuthError.invalidResponse
    }

    func refreshSession(_ session: AuthSession) async throws -> AuthSession {
        recordedRefreshTokens.append(session.refreshToken ?? "")
        if let delay {
            try await Task.sleep(for: delay)
        }
        guard !responses.isEmpty else {
            throw AuthError.invalidResponse
        }

        switch responses.removeFirst() {
        case .success(let session):
            return session
        case .failure(let error):
            throw error
        }
    }

    func signOut(accessToken: String) async throws {}

    func refreshTokens() -> [String] {
        recordedRefreshTokens
    }

    func refreshCallCount() -> Int {
        recordedRefreshTokens.count
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
