import Foundation

public struct AuthUser: Codable, Equatable, Sendable, Identifiable {
    public var id: String
    public var email: String?

    public init(id: String, email: String? = nil) {
        self.id = id
        self.email = email
    }
}

public struct AuthSession: Codable, Equatable, Sendable {
    public var accessToken: String
    public var refreshToken: String?
    public var expiresAt: Date?
    public var user: AuthUser?

    public init(
        accessToken: String,
        refreshToken: String? = nil,
        expiresAt: Date? = nil,
        user: AuthUser? = nil
    ) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.expiresAt = expiresAt
        self.user = user
    }

    public func isUsable(at date: Date = Date(), leeway: TimeInterval = 60) -> Bool {
        guard !accessToken.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return false
        }

        guard let expiresAt else {
            return true
        }

        return expiresAt.timeIntervalSince(date) > leeway
    }
}

public enum AuthProvider: String, Codable, Equatable, Sendable {
    case apple
}

public enum AuthError: Error, Equatable, Sendable {
    case configurationMissing
    case missingIdentityToken
    case invalidResponse
    case requestFailed(statusCode: Int, message: String)
    case storageFailed(message: String)
}

public protocol AuthSessionStore: Sendable {
    func loadSession() async throws -> AuthSession?
    func saveSession(_ session: AuthSession) async throws
    func clearSession() async throws
}

public actor AuthSessionController {
    private let store: AuthSessionStore
    private var cachedSession: AuthSession?
    private var hasLoadedStoredSession = false

    public init(store: AuthSessionStore) {
        self.store = store
    }

    @discardableResult
    public func loadPersistedSession() async throws -> AuthSession? {
        let session = try await store.loadSession()
        cachedSession = session
        hasLoadedStoredSession = true
        return session
    }

    @discardableResult
    public func replaceSession(_ session: AuthSession) async throws -> AuthSession {
        try await store.saveSession(session)
        cachedSession = session
        hasLoadedStoredSession = true
        return session
    }

    public func clearSession() async throws {
        try await store.clearSession()
        cachedSession = nil
        hasLoadedStoredSession = true
    }

    public func currentSession() async throws -> AuthSession? {
        try await loadedSession()
    }

    public func currentAccessToken(at date: Date = Date()) async throws -> String? {
        guard let session = try await loadedSession(), session.isUsable(at: date) else {
            return nil
        }

        return session.accessToken
    }

    private func loadedSession() async throws -> AuthSession? {
        if !hasLoadedStoredSession {
            return try await loadPersistedSession()
        }

        return cachedSession
    }
}
