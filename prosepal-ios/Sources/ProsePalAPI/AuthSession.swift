import Foundation
import CryptoKit
import Security

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
    case missingNonce
    case nonceGenerationFailed
    case invalidResponse
    case networkUnavailable
    case requestFailed(statusCode: Int, message: String)
    case storageFailed(message: String)
}

public extension AuthError {
    var userSafeMessage: String {
        switch self {
        case .configurationMissing:
            "Sign in is not configured for this build."
        case .missingIdentityToken:
            "Apple sign-in did not return the information needed. Please try again."
        case .missingNonce:
            "Apple sign-in could not be completed. Please try again."
        case .nonceGenerationFailed:
            "Apple sign-in could not start securely. Please try again."
        case .invalidResponse:
            "Sign in returned an unexpected response. Please try again."
        case .networkUnavailable:
            "ProsePal services could not be reached. Check your connection and try again."
        case .requestFailed(_, let message),
             .storageFailed(let message):
            message
        }
    }

    var diagnosticsOutcome: String {
        switch self {
        case .configurationMissing:
            "configuration_missing"
        case .missingIdentityToken:
            "missing_identity_token"
        case .missingNonce:
            "missing_nonce"
        case .nonceGenerationFailed:
            "nonce_generation_failed"
        case .invalidResponse:
            "supabase_invalid_response"
        case .networkUnavailable:
            "network_unavailable"
        case .requestFailed(let statusCode, _):
            switch statusCode {
            case 400, 401, 403:
                "supabase_rejected"
            case 429:
                "supabase_rate_limited"
            case 500...599:
                "supabase_unavailable"
            default:
                "supabase_http_error"
            }
        case .storageFailed:
            "session_storage_failed"
        }
    }

    var diagnosticsStatusCode: Int? {
        if case .requestFailed(let statusCode, _) = self {
            return statusCode
        }

        return nil
    }
}

public protocol AuthClient: Sendable {
    func signInWithIDToken(
        provider: AuthProvider,
        idToken: String,
        nonce: String?
    ) async throws -> AuthSession

    func refreshSession(_ session: AuthSession) async throws -> AuthSession

    func signOut(accessToken: String) async throws
}

public protocol AuthSessionStore: Sendable {
    func loadSession() async throws -> AuthSession?
    func saveSession(_ session: AuthSession) async throws
    func clearSession() async throws
}

public actor AuthSessionController {
    private let store: AuthSessionStore
    private let authClient: (any AuthClient)?
    private var cachedSession: AuthSession?
    private var hasLoadedStoredSession = false
    private var refreshOperation: AuthSessionRefreshOperation?

    public init(
        store: AuthSessionStore,
        authClient: (any AuthClient)? = nil
    ) {
        self.store = store
        self.authClient = authClient
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
        await cancelRefreshIfNeeded()
        try await store.saveSession(session)
        cachedSession = session
        hasLoadedStoredSession = true
        return session
    }

    public func clearSession() async throws {
        await cancelRefreshIfNeeded()
        try await store.clearSession()
        cachedSession = nil
        hasLoadedStoredSession = true
    }

    public func persistedSession() async throws -> AuthSession? {
        try await loadedSession()
    }

    public func currentSession(at date: Date = Date()) async throws -> AuthSession? {
        guard let session = try await loadedSession() else {
            return nil
        }
        guard !session.isUsable(at: date) else {
            return session
        }

        return try await refreshSessionIfPossible(session, at: date)
    }

    public func currentAccessToken(at date: Date = Date()) async throws -> String? {
        guard let session = try await currentSession(at: date) else {
            return nil
        }

        return session.accessToken
    }

    private func refreshSessionIfPossible(
        _ session: AuthSession,
        at date: Date
    ) async throws -> AuthSession? {
        let refreshToken = session.refreshToken?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard refreshToken?.isEmpty == false else {
            try await store.clearSession()
            cachedSession = nil
            hasLoadedStoredSession = true
            return nil
        }
        guard let authClient else {
            return nil
        }

        let operation: AuthSessionRefreshOperation
        if let refreshOperation {
            operation = refreshOperation
        } else {
            let store = store
            let task = Task {
                let refreshedSession = try await authClient.refreshSession(session)
                try Task.checkCancellation()
                guard refreshedSession.isUsable(at: date) else {
                    throw AuthError.invalidResponse
                }
                try await store.saveSession(refreshedSession)
                return refreshedSession
            }
            operation = AuthSessionRefreshOperation(id: UUID(), task: task)
            refreshOperation = operation
        }

        do {
            let refreshedSession = try await operation.task.value
            guard refreshedSession.isUsable(at: date) else {
                throw AuthError.invalidResponse
            }
            cachedSession = refreshedSession
            hasLoadedStoredSession = true
            clearRefreshOperation(ifMatching: operation.id)
            return refreshedSession
        } catch is CancellationError {
            clearRefreshOperation(ifMatching: operation.id)
            throw CancellationError()
        } catch let error as AuthError {
            let ownsRefreshOperation = refreshOperation?.id == operation.id
            clearRefreshOperation(ifMatching: operation.id)
            if ownsRefreshOperation && error.clearsSessionAfterRefreshFailure {
                cachedSession = nil
                hasLoadedStoredSession = true
                try? await store.clearSession()
            }
            throw error
        } catch {
            clearRefreshOperation(ifMatching: operation.id)
            throw error
        }
    }

    private func cancelRefreshIfNeeded() async {
        guard let refreshOperation else { return }
        self.refreshOperation = nil
        refreshOperation.task.cancel()
        _ = try? await refreshOperation.task.value
    }

    private func clearRefreshOperation(ifMatching id: UUID) {
        guard refreshOperation?.id == id else { return }
        refreshOperation = nil
    }

    private func loadedSession() async throws -> AuthSession? {
        if !hasLoadedStoredSession {
            return try await loadPersistedSession()
        }

        return cachedSession
    }
}

private struct AuthSessionRefreshOperation: Sendable {
    let id: UUID
    let task: Task<AuthSession, Error>
}

private extension AuthError {
    var clearsSessionAfterRefreshFailure: Bool {
        guard case .requestFailed(let statusCode, _) = self else {
            return false
        }
        return statusCode == 400 || statusCode == 401 || statusCode == 403
    }
}

public struct AppleSignInNonce: Equatable, Sendable {
    public var rawValue: String
    public var sha256Value: String

    public init(rawValue: String) {
        self.rawValue = rawValue
        self.sha256Value = Self.sha256(rawValue)
    }

    public static func make(length: Int = 32) throws -> AppleSignInNonce {
        let allowedCharacters = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var randomBytes = [UInt8](repeating: 0, count: length)
        let status = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        guard status == errSecSuccess else {
            throw AuthError.nonceGenerationFailed
        }

        let rawValue = String(randomBytes.map { allowedCharacters[Int($0) % allowedCharacters.count] })
        return AppleSignInNonce(rawValue: rawValue)
    }

    private static func sha256(_ input: String) -> String {
        let digest = SHA256.hash(data: Data(input.utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}
