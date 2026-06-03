import ProsePalDomain

public struct TemplateMessageWritingClient: MessageWritingClient {
    public init() {}

    public func generateCard(request: CardRequest) async throws -> CardResponse {
        let name = request.intent.recipientName?.trimmingCharacters(in: .whitespacesAndNewlines)
        let recipient = name?.isEmpty == false ? name! : "there"
        let occasion = request.intent.occasion.displayName.lowercased()
        let relationship = request.intent.relationship.displayName.lowercased()
        let include = request.intent.thingsToInclude.first?.trimmingCharacters(in: .whitespacesAndNewlines)
        let detail = include?.isEmpty == false ? " I loved thinking of \(include!)." : ""

        let messages = [
            "Dear \(recipient), sending you so much love for your \(occasion).\(detail) Hope today feels gentle, bright, and full of the little things that make you smile.",
            "\(recipient), I hope this \(occasion) brings a quiet moment to feel appreciated. You matter more than words usually manage, and I am lucky to have you in my life.",
            "For \(recipient): a \(occasion) note from a grateful \(relationship). Wishing you warmth today, a reason to laugh, and a reminder of how loved you are."
        ]

        return CardResponse(
            messages: messages.map { GeneratedMessage(text: $0) },
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
