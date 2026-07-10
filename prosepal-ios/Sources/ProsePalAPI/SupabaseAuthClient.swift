import Foundation

public struct SupabaseAuthClient: AuthClient {
    public var projectURL: URL
    public var anonKey: String
    public var session: URLSession
    public var now: @Sendable () -> Date

    public init(
        projectURL: URL,
        anonKey: String,
        session: URLSession = .shared,
        now: @escaping @Sendable () -> Date = { Date() }
    ) {
        self.projectURL = projectURL
        self.anonKey = anonKey
        self.session = session
        self.now = now
    }

    public func signInWithIDToken(
        provider: AuthProvider,
        idToken: String,
        nonce: String?
    ) async throws -> AuthSession {
        guard !anonKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw AuthError.configurationMissing
        }

        let trimmedIDToken = idToken.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedIDToken.isEmpty else {
            throw AuthError.missingIdentityToken
        }

        var endpoint = projectURL
            .appendingPathComponent("auth")
            .appendingPathComponent("v1")
            .appendingPathComponent("token")
        endpoint.append(queryItems: [URLQueryItem(name: "grant_type", value: "id_token")])

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(anonKey, forHTTPHeaderField: "apikey")

        let body = IDTokenRequest(
            provider: provider.rawValue,
            idToken: trimmedIDToken,
            nonce: nonce?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
        )
        request.httpBody = try JSONEncoder.authSession.encode(body)

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch let error as URLError where error.isProsePalConnectivityFailure {
            throw AuthError.networkUnavailable
        }
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AuthError.invalidResponse
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
            throw AuthError.requestFailed(
                statusCode: httpResponse.statusCode,
                message: decodeErrorMessage(from: data)
            )
        }

        let tokenResponse = try JSONDecoder.authSession.decode(TokenResponse.self, from: data)
        guard !tokenResponse.accessToken.isEmpty else {
            throw AuthError.invalidResponse
        }

        return AuthSession(
            accessToken: tokenResponse.accessToken,
            refreshToken: tokenResponse.refreshToken,
            expiresAt: tokenResponse.resolvedExpiresAt(now: now()),
            user: tokenResponse.user.map { AuthUser(id: $0.id, email: $0.email) }
        )
    }

    public func refreshSession(_ session: AuthSession) async throws -> AuthSession {
        guard !anonKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw AuthError.configurationMissing
        }

        let refreshToken = session.refreshToken?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard let refreshToken, !refreshToken.isEmpty else {
            throw AuthError.invalidResponse
        }

        var endpoint = projectURL
            .appendingPathComponent("auth")
            .appendingPathComponent("v1")
            .appendingPathComponent("token")
        endpoint.append(queryItems: [URLQueryItem(name: "grant_type", value: "refresh_token")])

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(anonKey, forHTTPHeaderField: "apikey")
        request.httpBody = try JSONEncoder.authSession.encode(
            RefreshTokenRequest(refreshToken: refreshToken)
        )

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await self.session.data(for: request)
        } catch let error as URLError where error.isProsePalConnectivityFailure {
            throw AuthError.networkUnavailable
        }
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AuthError.invalidResponse
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
            throw AuthError.requestFailed(
                statusCode: httpResponse.statusCode,
                message: decodeErrorMessage(from: data)
            )
        }

        guard let tokenResponse = try? JSONDecoder.authSession.decode(TokenResponse.self, from: data) else {
            throw AuthError.invalidResponse
        }
        let accessToken = tokenResponse.accessToken.trimmingCharacters(in: .whitespacesAndNewlines)
        let rotatedRefreshToken = tokenResponse.refreshToken?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !accessToken.isEmpty,
              let rotatedRefreshToken,
              !rotatedRefreshToken.isEmpty else {
            throw AuthError.invalidResponse
        }

        return AuthSession(
            accessToken: accessToken,
            refreshToken: rotatedRefreshToken,
            expiresAt: tokenResponse.resolvedExpiresAt(now: now()),
            user: tokenResponse.user.map { AuthUser(id: $0.id, email: $0.email) } ?? session.user
        )
    }

    public func signOut(accessToken: String) async throws {
        guard !anonKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw AuthError.configurationMissing
        }

        let trimmedAccessToken = accessToken.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedAccessToken.isEmpty else { return }

        let endpoint = projectURL
            .appendingPathComponent("auth")
            .appendingPathComponent("v1")
            .appendingPathComponent("logout")

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(anonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(trimmedAccessToken)", forHTTPHeaderField: "Authorization")

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch let error as URLError where error.isProsePalConnectivityFailure {
            throw AuthError.networkUnavailable
        }
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AuthError.invalidResponse
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
            throw AuthError.requestFailed(
                statusCode: httpResponse.statusCode,
                message: decodeErrorMessage(from: data)
            )
        }
    }

    private func decodeErrorMessage(from data: Data) -> String {
        let fallback = "Sign in failed. Please try again."
        guard let error = try? JSONDecoder.authSession.decode(ErrorResponse.self, from: data) else {
            return fallback
        }

        return error.errorDescription?.nilIfEmpty ??
            error.msg?.nilIfEmpty ??
            error.message?.nilIfEmpty ??
            fallback
    }
}

private struct IDTokenRequest: Encodable {
    var provider: String
    var idToken: String
    var nonce: String?
}

private struct RefreshTokenRequest: Encodable {
    var refreshToken: String
}

private struct TokenResponse: Decodable {
    var accessToken: String
    var refreshToken: String?
    var expiresIn: TimeInterval?
    var expiresAt: TimeInterval?
    var user: UserResponse?

    func resolvedExpiresAt(now: Date) -> Date? {
        if let expiresAt {
            return Date(timeIntervalSince1970: expiresAt)
        }

        if let expiresIn {
            return now.addingTimeInterval(expiresIn)
        }

        return nil
    }
}

private struct UserResponse: Decodable {
    var id: String
    var email: String?
}

private struct ErrorResponse: Decodable {
    var message: String?
    var msg: String?
    var errorDescription: String?
}

private extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}
