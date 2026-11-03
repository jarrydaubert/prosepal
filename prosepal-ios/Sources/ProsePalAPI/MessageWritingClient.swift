import ProsePalDomain

public protocol MessageWritingClient: Sendable {
    func generateCard(request: CardRequest) async throws -> CardResponse
}

