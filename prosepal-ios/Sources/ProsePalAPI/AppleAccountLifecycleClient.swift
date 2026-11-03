import Foundation

public protocol AppleAccountLifecycleClient: Sendable {
    func storeRevocationMaterial(
        authorizationCode: String,
        appleUserID: String,
        accessToken: String
    ) async throws
}

public enum AppleAccountLifecycleError: Error, Equatable, Sendable {
    case configurationMissing
    case missingAuthorizationCode
    case missingCredentialIdentifier
    case authenticationRequired
    case invalidResponse
    case networkUnavailable
    case timedOut
    case requestFailed(statusCode: Int, message: String)
}

public extension AppleAccountLifecycleError {
    var userSafeMessage: String {
        switch self {
        case .configurationMissing:
            String(localized: "Apple account continuity is not configured for this build.")
        case .missingAuthorizationCode, .missingCredentialIdentifier:
            String(localized: "Apple sign-in did not return the information needed. Please try again.")
        case .authenticationRequired:
            String(localized: "Sign in with Apple again and retry.")
        case .invalidResponse:
            String(localized: "Apple account setup returned an unexpected response. Please try again.")
        case .networkUnavailable:
            String(localized: "ProsePal services could not be reached. Check your connection and try again.")
        case .timedOut:
            String(localized: "Apple account setup took too long. Please try again.")
        case .requestFailed(_, let message):
            message
        }
    }

    var diagnosticsOutcome: String {
        switch self {
        case .configurationMissing:
            "configuration_missing"
        case .missingAuthorizationCode:
            "missing_authorization_code"
        case .missingCredentialIdentifier:
            "missing_credential_identifier"
        case .authenticationRequired:
            "authentication_required"
        case .invalidResponse:
            "invalid_response"
        case .networkUnavailable:
            "network_unavailable"
        case .timedOut:
            "timed_out"
        case .requestFailed(let statusCode, _):
            switch statusCode {
            case 400, 401, 403:
                "server_rejected"
            case 408:
                "timed_out"
            case 429:
                "rate_limited"
            case 500...599:
                "server_unavailable"
            default:
                "server_http_error"
            }
        }
    }

    var diagnosticsStatusCode: Int? {
        guard case .requestFailed(let statusCode, _) = self else { return nil }
        return statusCode
    }
}

public struct SupabaseAppleAccountLifecycleClient: AppleAccountLifecycleClient {
    public var projectURL: URL
    public var anonKey: String
    public var session: URLSession
    public var requestTimeout: TimeInterval

    public init(
        projectURL: URL,
        anonKey: String,
        session: URLSession = .shared,
        requestTimeout: TimeInterval = 15
    ) {
        self.projectURL = projectURL
        self.anonKey = anonKey
        self.session = session
        self.requestTimeout = requestTimeout
    }

    public func storeRevocationMaterial(
        authorizationCode: String,
        appleUserID: String,
        accessToken: String
    ) async throws {
        let trimmedAnonKey = anonKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedAnonKey.isEmpty else {
            throw AppleAccountLifecycleError.configurationMissing
        }

        let trimmedCode = authorizationCode.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedCode.isEmpty else {
            throw AppleAccountLifecycleError.missingAuthorizationCode
        }
        let trimmedAppleUserID = appleUserID.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedAppleUserID.isEmpty else {
            throw AppleAccountLifecycleError.missingCredentialIdentifier
        }
        let trimmedAccessToken = accessToken.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedAccessToken.isEmpty else {
            throw AppleAccountLifecycleError.authenticationRequired
        }

        let endpoint = projectURL
            .appendingPathComponent("functions")
            .appendingPathComponent("v1")
            .appendingPathComponent("exchange-apple-token")

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.timeoutInterval = requestTimeout
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(trimmedAnonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(trimmedAccessToken)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONEncoder.appleAccountLifecycle.encode(
            ExchangeRequest(
                authorizationCode: trimmedCode,
                appleUserID: trimmedAppleUserID
            )
        )

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch let error as URLError where error.code == .timedOut {
            throw AppleAccountLifecycleError.timedOut
        } catch let error as URLError where error.isProsePalConnectivityFailure {
            throw AppleAccountLifecycleError.networkUnavailable
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AppleAccountLifecycleError.invalidResponse
        }
        guard (200..<300).contains(httpResponse.statusCode) else {
            throw AppleAccountLifecycleError.requestFailed(
                statusCode: httpResponse.statusCode,
                message: decodeErrorMessage(from: data)
            )
        }

        guard let result = try? JSONDecoder.appleAccountLifecycle.decode(ExchangeResponse.self, from: data),
              result.success else {
            throw AppleAccountLifecycleError.invalidResponse
        }
    }

    private func decodeErrorMessage(from data: Data) -> String {
        let fallback = String(localized: "Apple account setup failed. Please try again.")
        guard let response = try? JSONDecoder.appleAccountLifecycle.decode(ErrorResponse.self, from: data) else {
            return fallback
        }
        return response.error?.trimmedNonEmpty ?? response.message?.trimmedNonEmpty ?? fallback
    }
}

private struct ExchangeRequest: Encodable {
    var authorizationCode: String
    var appleUserID: String
}

private struct ExchangeResponse: Decodable {
    var success: Bool
}

private struct ErrorResponse: Decodable {
    var error: String?
    var message: String?
}

private extension JSONEncoder {
    static let appleAccountLifecycle: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        return encoder
    }()
}

private extension JSONDecoder {
    static let appleAccountLifecycle: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }()
}

private extension String {
    var trimmedNonEmpty: String? {
        let value = trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? nil : value
    }
}
