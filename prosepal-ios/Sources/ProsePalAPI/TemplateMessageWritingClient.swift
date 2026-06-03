import ProsePalDomain

public struct TemplateMessageWritingClient: MessageWritingClient {
    public init() {}

    public func generateCard(request: CardRequest) async throws -> CardResponse {
        let name = request.intent.recipientName?.trimmingCharacters(in: .whitespacesAndNewlines)
        let recipient = name?.isEmpty == false ? name! : "you"
        let occasion = request.intent.occasion.rawValue
        let tone = request.intent.tone.rawValue

        let message = "For \(recipient): wishing you a \(tone) \(occasion) message with care and warmth."

        return CardResponse(
            messages: [GeneratedMessage(text: message)],
            laneUsed: .template,
            fallbackStatus: request.requestedLane == .template ? .none : .degradedToTemplate,
            qualityCheck: QualityCheckSummary(
                passed: true,
                userSafeNote: "Simple fallback message"
            ),
            retryEligibility: .eligible
        )
    }
}

