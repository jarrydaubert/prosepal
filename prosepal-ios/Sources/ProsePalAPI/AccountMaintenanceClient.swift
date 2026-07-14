import Foundation

public protocol AccountMaintenanceClient: Sendable {
    func deleteAccount(accessToken: String) async throws
}

public enum AccountMaintenanceError: Error, Equatable, Sendable {
    case configurationMissing
    case authenticationRequired
    case invalidResponse
    case networkUnavailable
    case timedOut
    case requestFailed(statusCode: Int, message: String)
}

public extension AccountMaintenanceError {
    var userSafeMessage: String {
        switch self {
        case .configurationMissing:
            String(localized: "Account deletion is not configured for this build.")
        case .authenticationRequired:
            String(localized: "Sign in again before deleting your account.")
        case .invalidResponse:
            String(localized: "Account deletion returned an unexpected response. Please try again.")
        case .networkUnavailable:
            String(localized: "ProsePal services could not be reached. Check your connection and try again.")
        case .timedOut:
            String(localized: "Account deletion took too long. Your account is still available; please try again.")
        case .requestFailed(_, let message):
            message
        }
    }
}

public struct SupabaseAccountMaintenanceClient: AccountMaintenanceClient {
    public var projectURL: URL
    public var anonKey: String
    public var session: URLSession
    public var requestTimeout: TimeInterval

    public init(
        projectURL: URL,
        anonKey: String,
        session: URLSession = .shared,
        requestTimeout: TimeInterval = 20
    ) {
        self.projectURL = projectURL
        self.anonKey = anonKey
        self.session = session
        self.requestTimeout = requestTimeout
    }

    public func deleteAccount(accessToken: String) async throws {
        let trimmedAnonKey = anonKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedAnonKey.isEmpty else {
            throw AccountMaintenanceError.configurationMissing
        }

        let trimmedAccessToken = accessToken.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedAccessToken.isEmpty else {
            throw AccountMaintenanceError.authenticationRequired
        }

        let endpoint = projectURL
            .appendingPathComponent("functions")
            .appendingPathComponent("v1")
            .appendingPathComponent("delete-user")

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.timeoutInterval = requestTimeout
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(trimmedAnonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(trimmedAccessToken)", forHTTPHeaderField: "Authorization")

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch let error as URLError where error.code == .timedOut {
            throw AccountMaintenanceError.timedOut
        } catch let error as URLError where error.isProsePalConnectivityFailure {
            throw AccountMaintenanceError.networkUnavailable
        }
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AccountMaintenanceError.invalidResponse
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
            throw AccountMaintenanceError.requestFailed(
                statusCode: httpResponse.statusCode,
                message: decodeErrorMessage(from: data)
            )
        }
    }

    private func decodeErrorMessage(from data: Data) -> String {
        let fallback = "Account deletion failed. Please try again."
        guard let response = try? JSONDecoder.accountMaintenance.decode(ErrorResponse.self, from: data) else {
            return fallback
        }

        return response.error?.nilIfBlank ??
            response.message?.nilIfBlank ??
            fallback
    }
}

private struct ErrorResponse: Decodable {
    var error: String?
    var message: String?
}

private extension JSONDecoder {
    static let accountMaintenance: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }()
}

private extension String {
    var nilIfBlank: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
