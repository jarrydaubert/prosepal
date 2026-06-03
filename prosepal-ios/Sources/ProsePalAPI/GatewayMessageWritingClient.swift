import Foundation
import ProsePalDomain

public struct GatewayMessageWritingClient: MessageWritingClient {
    public var endpoint: URL
    public var session: URLSession
    public var timeoutSeconds: TimeInterval
    public var authorizationTokenProvider: (@Sendable () async throws -> String?)?

    public init(
        endpoint: URL,
        session: URLSession = .shared,
        timeoutSeconds: TimeInterval = 20,
        authorizationTokenProvider: (@Sendable () async throws -> String?)? = nil
    ) {
        self.endpoint = endpoint
        self.session = session
        self.timeoutSeconds = timeoutSeconds
        self.authorizationTokenProvider = authorizationTokenProvider
    }

    public func generateCard(request cardRequest: CardRequest) async throws -> CardResponse {
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.timeoutInterval = timeoutSeconds
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(cardRequest.idempotencyKey, forHTTPHeaderField: "Idempotency-Key")

        if let token = try await authorizationTokenProvider?(), !token.isEmpty {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        request.httpBody = try JSONEncoder.prosePal.encode(cardRequest)

        do {
            let (data, response) = try await session.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw GenerationError.unexpectedResponse(
                    message: "We could not read the generation response. Please try again."
                )
            }

            switch httpResponse.statusCode {
            case 200..<300:
                return try JSONDecoder.prosePal.decode(CardResponse.self, from: data)
            case 402, 403:
                throw GenerationError.usageLimitReached(
                    message: "You have reached your current generation limit."
                )
            case 408:
                throw GenerationError.timedOut
            case 409, 425, 429:
                throw GenerationError.rateLimited(
                    message: "Generation is busy right now. Please wait a moment and try again."
                )
            case 422:
                throw GenerationError.contentBlocked(
                    message: "Those message details could not be used. Try adjusting the wording."
                )
            case 500..<600:
                throw GenerationError.serviceUnavailable(
                    message: "Message generation is temporarily unavailable. Please try again shortly."
                )
            default:
                throw GenerationError.unexpectedResponse(
                    message: "Message generation failed. Please try again."
                )
            }
        } catch let error as GenerationError {
            throw error
        } catch is CancellationError {
            throw GenerationError.timedOut
        } catch let error as URLError where error.code == .notConnectedToInternet {
            throw GenerationError.offline
        } catch let error as URLError where error.code == .timedOut {
            throw GenerationError.timedOut
        } catch {
            throw GenerationError.unexpectedResponse(
                message: "Message generation failed. Please try again."
            )
        }
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

