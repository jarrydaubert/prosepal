import ProsePalDomain

public struct MockMessageWritingClient: MessageWritingClient {
    public var response: CardResponse

    public init(response: CardResponse) {
        self.response = response
    }

    public func generateCard(request: CardRequest) async throws -> CardResponse {
        response
    }
}

