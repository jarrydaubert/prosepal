import Foundation
import ProsePalDomain
import OSLog

public struct GatewayMessageWritingClient: MessageWritingClient {
    public var endpoint: URL
    public var session: URLSession
    public var timeoutSeconds: TimeInterval
    public var devGatewaySecret: String?
    public var authorizationTokenProvider: (@Sendable () async throws -> String?)?

    public init(
        endpoint: URL,
        session: URLSession = .shared,
        timeoutSeconds: TimeInterval = 45,
        devGatewaySecret: String? = nil,
        authorizationTokenProvider: (@Sendable () async throws -> String?)? = nil
    ) {
        self.endpoint = endpoint
        self.session = session
        self.timeoutSeconds = timeoutSeconds
        self.devGatewaySecret = devGatewaySecret
        self.authorizationTokenProvider = authorizationTokenProvider
    }

    public func generateCard(request cardRequest: CardRequest) async throws -> CardResponse {
        let startedAt = Date()
        let requestID = cardRequest.idempotencyKey.diagnosticsPrefix
        GatewayDiagnosticsLogger.shared.requestStarted(
            requestID: requestID,
            lane: cardRequest.requestedLane,
            endpointHost: endpoint.host,
            hasDevGatewaySecret: hasConfiguredDevGatewaySecret
        )

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.timeoutInterval = timeoutSeconds
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(cardRequest.idempotencyKey, forHTTPHeaderField: "Idempotency-Key")

        if let configuredDevGatewaySecret {
            request.setValue(configuredDevGatewaySecret, forHTTPHeaderField: "X-ProsePal-Dev-Gateway-Secret")
        }

        do {
            if let token = try await authorizationTokenProvider?() {
                let trimmedToken = token.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmedToken.isEmpty {
                    request.setValue("Bearer \(trimmedToken)", forHTTPHeaderField: "Authorization")
                }
            }

            request.httpBody = try JSONEncoder.prosePal.encode(cardRequest)

            let (data, response) = try await session.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw GenerationError.unexpectedResponse(
                    message: "We could not read the generation response. Please try again."
                )
            }

            switch httpResponse.statusCode {
            case 200..<300:
                let response = try JSONDecoder.prosePal.decode(CardResponse.self, from: data)
                try validate(response, statusCode: httpResponse.statusCode, requestID: requestID, startedAt: startedAt)
                GatewayDiagnosticsLogger.shared.requestSucceeded(
                    requestID: requestID,
                    statusCode: httpResponse.statusCode,
                    laneUsed: response.laneUsed,
                    fallbackStatus: response.fallbackStatus,
                    messageCount: response.messages.count,
                    totalMessageCharacters: response.messages.reduce(0) { $0 + $1.text.count },
                    durationMs: startedAt.elapsedMilliseconds
                )
                return response
            case 401:
                GatewayDiagnosticsLogger.shared.requestFailed(
                    requestID: requestID,
                    statusCode: httpResponse.statusCode,
                    category: "gateway_auth",
                    durationMs: startedAt.elapsedMilliseconds
                )
                throw GenerationError.unexpectedResponse(
                    message: userSafeGatewayMessage(
                        from: data,
                        fallback: "Message generation is not configured for this build."
                    )
                )
            case 402, 403:
                GatewayDiagnosticsLogger.shared.requestFailed(
                    requestID: requestID,
                    statusCode: httpResponse.statusCode,
                    category: "usage_or_entitlement",
                    durationMs: startedAt.elapsedMilliseconds
                )
                throw GenerationError.usageLimitReached(
                    message: userSafeGatewayMessage(
                        from: data,
                        fallback: "You have reached your current generation limit."
                    )
                )
            case 408:
                GatewayDiagnosticsLogger.shared.requestFailed(
                    requestID: requestID,
                    statusCode: httpResponse.statusCode,
                    category: "timeout",
                    durationMs: startedAt.elapsedMilliseconds
                )
                throw GenerationError.timedOut
            case 409, 425, 429:
                GatewayDiagnosticsLogger.shared.requestFailed(
                    requestID: requestID,
                    statusCode: httpResponse.statusCode,
                    category: "rate_limited",
                    durationMs: startedAt.elapsedMilliseconds
                )
                throw GenerationError.rateLimited(
                    message: userSafeGatewayMessage(
                        from: data,
                        fallback: "Generation is busy right now. Please wait a moment and try again."
                    )
                )
            case 422:
                GatewayDiagnosticsLogger.shared.requestFailed(
                    requestID: requestID,
                    statusCode: httpResponse.statusCode,
                    category: "content_blocked",
                    durationMs: startedAt.elapsedMilliseconds
                )
                throw GenerationError.contentBlocked(
                    message: userSafeGatewayMessage(
                        from: data,
                        fallback: "Those message details could not be used. Try adjusting the wording."
                    )
                )
            case 500..<600:
                GatewayDiagnosticsLogger.shared.requestFailed(
                    requestID: requestID,
                    statusCode: httpResponse.statusCode,
                    category: "gateway_unavailable",
                    durationMs: startedAt.elapsedMilliseconds
                )
                throw GenerationError.serviceUnavailable(
                    message: userSafeGatewayMessage(
                        from: data,
                        fallback: "Message generation is temporarily unavailable. Please try again shortly."
                    )
                )
            default:
                GatewayDiagnosticsLogger.shared.requestFailed(
                    requestID: requestID,
                    statusCode: httpResponse.statusCode,
                    category: "unexpected_status",
                    durationMs: startedAt.elapsedMilliseconds
                )
                throw GenerationError.unexpectedResponse(
                    message: userSafeGatewayMessage(
                        from: data,
                        fallback: "Message generation failed. Please try again."
                    )
                )
            }
        } catch let error as GenerationError {
            throw error
        } catch is CancellationError {
            GatewayDiagnosticsLogger.shared.requestFailed(
                requestID: requestID,
                statusCode: nil,
                category: "cancelled",
                durationMs: startedAt.elapsedMilliseconds
            )
            throw CancellationError()
        } catch let error as URLError where error.code == .cancelled {
            GatewayDiagnosticsLogger.shared.requestFailed(
                requestID: requestID,
                statusCode: nil,
                category: "cancelled",
                durationMs: startedAt.elapsedMilliseconds
            )
            throw CancellationError()
        } catch let error as URLError where error.code == .notConnectedToInternet {
            GatewayDiagnosticsLogger.shared.requestFailed(
                requestID: requestID,
                statusCode: nil,
                category: "offline",
                durationMs: startedAt.elapsedMilliseconds
            )
            throw GenerationError.offline
        } catch let error as URLError where error.code == .timedOut {
            GatewayDiagnosticsLogger.shared.requestFailed(
                requestID: requestID,
                statusCode: nil,
                category: "timeout",
                durationMs: startedAt.elapsedMilliseconds
            )
            throw GenerationError.timedOut
        } catch {
            GatewayDiagnosticsLogger.shared.requestFailed(
                requestID: requestID,
                statusCode: nil,
                category: "unexpected_error",
                durationMs: startedAt.elapsedMilliseconds
            )
            throw GenerationError.unexpectedResponse(
                message: "Message generation failed. Please try again."
            )
        }
    }

    private var configuredDevGatewaySecret: String? {
        let trimmedSecret = devGatewaySecret?.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let trimmedSecret, !trimmedSecret.isEmpty else { return nil }
        return trimmedSecret
    }

    private var hasConfiguredDevGatewaySecret: Bool {
        configuredDevGatewaySecret != nil
    }

    private func validate(
        _ response: CardResponse,
        statusCode: Int,
        requestID: String,
        startedAt: Date
    ) throws {
        guard response.promptContractVersion == CardRequest.currentPromptContractVersion,
              response.outputContractVersion == CardRequest.currentOutputContractVersion else {
            GatewayDiagnosticsLogger.shared.requestFailed(
                requestID: requestID,
                statusCode: statusCode,
                category: "unsupported_contract_version",
                durationMs: startedAt.elapsedMilliseconds
            )
            throw GenerationError.unexpectedResponse(
                message: "This version of ProsePal cannot read the generation response. Please update the app."
            )
        }

        guard !response.messages.isEmpty else {
            GatewayDiagnosticsLogger.shared.requestFailed(
                requestID: requestID,
                statusCode: statusCode,
                category: "empty_response",
                durationMs: startedAt.elapsedMilliseconds
            )
            throw GenerationError.unexpectedResponse(
                message: "Message generation returned no drafts. Please try again."
            )
        }

        guard response.messages.allSatisfy({ !$0.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }) else {
            GatewayDiagnosticsLogger.shared.requestFailed(
                requestID: requestID,
                statusCode: statusCode,
                category: "blank_message",
                durationMs: startedAt.elapsedMilliseconds
            )
            throw GenerationError.unexpectedResponse(
                message: "Message generation returned an empty draft. Please try again."
            )
        }
    }
}

private struct GatewayErrorResponse: Decodable {
    var userSafeError: UserSafeError?

    struct UserSafeError: Decodable {
        var code: String?
        var message: String?
    }
}

private func userSafeGatewayMessage(from data: Data, fallback: String) -> String {
    guard
        let response = try? JSONDecoder.prosePal.decode(GatewayErrorResponse.self, from: data),
        let message = response.userSafeError?.message?.trimmingCharacters(in: .whitespacesAndNewlines),
        !message.isEmpty
    else {
        return fallback
    }

    return message
}

private struct GatewayDiagnosticsLogger: Sendable {
    static let shared = GatewayDiagnosticsLogger()

    private let logger = Logger(subsystem: "com.prosepal.native", category: "gateway")

    func requestStarted(
        requestID: String,
        lane: GenerationLane,
        endpointHost: String?,
        hasDevGatewaySecret: Bool
    ) {
        logger.info(
            "gateway_request_started request_id=\(requestID, privacy: .public) lane=\(lane.rawValue, privacy: .public) endpoint_host=\(endpointHost ?? "unknown", privacy: .public) dev_secret_configured=\(hasDevGatewaySecret, privacy: .public)"
        )
    }

    func requestSucceeded(
        requestID: String,
        statusCode: Int,
        laneUsed: GenerationLane,
        fallbackStatus: FallbackStatus,
        messageCount: Int,
        totalMessageCharacters: Int,
        durationMs: Int
    ) {
        logger.info(
            "gateway_request_succeeded request_id=\(requestID, privacy: .public) status=\(statusCode, privacy: .public) lane_used=\(laneUsed.rawValue, privacy: .public) fallback=\(fallbackStatus.rawValue, privacy: .public) message_count=\(messageCount, privacy: .public) total_message_chars=\(totalMessageCharacters, privacy: .public) duration_ms=\(durationMs, privacy: .public)"
        )
    }

    func requestFailed(requestID: String, statusCode: Int?, category: String, durationMs: Int) {
        logger.warning(
            "gateway_request_failed request_id=\(requestID, privacy: .public) status=\(statusCode ?? -1, privacy: .public) category=\(category, privacy: .public) duration_ms=\(durationMs, privacy: .public)"
        )
    }
}

private extension JSONEncoder {
    static var prosePal: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.keyEncodingStrategy = .convertToSnakeCase
        return encoder
    }
}

private extension JSONDecoder {
    static var prosePal: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }
}

private extension String {
    var diagnosticsPrefix: String {
        if count <= 12 { return self }
        return "\(prefix(12))..."
    }
}

private extension Date {
    var elapsedMilliseconds: Int {
        max(0, Int(Date().timeIntervalSince(self) * 1000))
    }
}
