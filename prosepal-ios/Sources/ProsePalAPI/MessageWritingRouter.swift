import ProsePalDomain

public struct MessageWritingRouter: MessageWritingClient {
    private let standardClient: any MessageWritingClient
    private let premiumClient: any MessageWritingClient
    private let localClient: (any MessageWritingClient)?

    public init(
        standardClient: any MessageWritingClient,
        premiumClient: (any MessageWritingClient)? = nil,
        localClient: (any MessageWritingClient)? = nil
    ) {
        self.standardClient = standardClient
        self.premiumClient = premiumClient ?? standardClient
        self.localClient = localClient
    }

    public func generateCard(request: CardRequest) async throws -> CardResponse {
        switch request.requestedLane {
        case .automatic, .standard:
            return try await standardClient.generateCard(request: request)
        case .premium:
            return try await premiumClient.generateCard(request: request)
        case .local:
            guard let localClient else {
                throw GenerationError.serviceUnavailable(
                    message: "Private on-device writing is not available in this build."
                )
            }

            return try await localClient.generateCard(request: request)
        }
    }
}
