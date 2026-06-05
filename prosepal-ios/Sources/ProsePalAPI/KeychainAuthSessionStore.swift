import Foundation
import Security

public final class KeychainAuthSessionStore: AuthSessionStore, @unchecked Sendable {
    private let service: String
    private let account: String

    public init(
        service: String,
        account: String = "supabase-session"
    ) {
        self.service = service
        self.account = account
    }

    public func loadSession() async throws -> AuthSession? {
        var query = baseQuery()
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        if status == errSecItemNotFound {
            return nil
        }

        guard status == errSecSuccess else {
            throw AuthError.storageFailed(message: "Could not read saved sign-in state.")
        }

        guard let data = result as? Data else {
            throw AuthError.storageFailed(message: "Saved sign-in state is unreadable.")
        }

        return try JSONDecoder.authSession.decode(AuthSession.self, from: data)
    }

    public func saveSession(_ session: AuthSession) async throws {
        let data = try JSONEncoder.authSession.encode(session)
        var query = baseQuery()
        let attributes: [String: Any] = [
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]

        let updateStatus = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        if updateStatus == errSecSuccess {
            return
        }

        guard updateStatus == errSecItemNotFound else {
            throw AuthError.storageFailed(message: "Could not update saved sign-in state.")
        }

        attributes.forEach { key, value in
            query[key] = value
        }

        let addStatus = SecItemAdd(query as CFDictionary, nil)
        guard addStatus == errSecSuccess else {
            throw AuthError.storageFailed(message: "Could not save sign-in state.")
        }
    }

    public func clearSession() async throws {
        let status = SecItemDelete(baseQuery() as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw AuthError.storageFailed(message: "Could not clear sign-in state.")
        }
    }

    private func baseQuery() -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
    }
}

extension JSONEncoder {
    static var authSession: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.keyEncodingStrategy = .convertToSnakeCase
        return encoder
    }
}

extension JSONDecoder {
    static var authSession: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }
}
