import Foundation

public protocol AccountMaintenanceClient: Sendable {
    func deleteAccount(accessToken: String) async throws -> AccountDeletionOutcome
}

public enum AccountDeletionOutcome: Equatable, Sendable {
    case deleted
    case indeterminate
}

public enum AccountMaintenanceError: Error, Equatable, Sendable {
    case configurationMissing
    case authenticationRequired
    case invalidResponse
    case networkUnavailable
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
        case .requestFailed(_, let message):
            message
        }
    }

    /// Privacy-safe outcome label for diagnostics. Never contains user text,
    /// tokens, or identifiers.
    var diagnosticsOutcome: String {
        switch self {
        case .configurationMissing:
            "configuration_missing"
        case .authenticationRequired:
            "authentication_required"
        case .invalidResponse:
            "invalid_response"
        case .networkUnavailable:
            "network_unavailable"
        case .requestFailed(let statusCode, _):
            "server_http_\(statusCode)"
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

    public func deleteAccount(accessToken: String) async throws -> AccountDeletionOutcome {
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
        } catch is CancellationError {
            return .indeterminate
        } catch let error as URLError where error.code == .cancelled {
            return .indeterminate
        } catch let error as URLError where error.code == .timedOut {
            return .indeterminate
        } catch let error as URLError where error.code == .networkConnectionLost {
            return .indeterminate
        } catch let error as URLError where error.isProsePalConnectivityFailure {
            throw AccountMaintenanceError.networkUnavailable
        }
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AccountMaintenanceError.invalidResponse
        }

        switch httpResponse.statusCode {
        case 200:
            return .deleted
        case 202:
            guard let response = try? JSONDecoder.accountMaintenance.decode(
                DeletionStatusResponse.self,
                from: data
            ), response.status == "indeterminate" else {
                throw AccountMaintenanceError.invalidResponse
            }
            return .indeterminate
        default:
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

private struct DeletionStatusResponse: Decodable {
    var status: String
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
