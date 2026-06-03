import ProsePalDomain

public struct TemplateMessageWritingClient: MessageWritingClient {
    public init() {}

    public func generateCard(request: CardRequest) async throws -> CardResponse {
        let name = request.intent.recipientName?.trimmingCharacters(in: .whitespacesAndNewlines)
        let recipient = name?.isEmpty == false ? name! : "there"
        let occasion = request.intent.occasion.displayName
        let relationship = request.intent.relationship.displayName.lowercased()
        let tone = request.intent.tone.displayName.lowercased()
        let length = request.intent.length.generationHint
        let spellingNote = switch request.intent.spellingPreference {
        case .automatic: "I kept the spelling natural for your device locale."
        case .us: "I used US English wording."
        case .uk: "I used UK English wording."
        }
        let include = request.intent.thingsToInclude.first?.trimmingCharacters(in: .whitespacesAndNewlines)
        let avoid = request.intent.thingsToAvoid.first?.trimmingCharacters(in: .whitespacesAndNewlines)
        let includeDetail = include?.isEmpty == false ? " I worked in \(include!)." : ""
        let avoidDetail = avoid?.isEmpty == false ? " I steered clear of \(avoid!)." : ""
        let context = request.intent.userContext?.trimmingCharacters(in: .whitespacesAndNewlines)
        let contextDetail = context?.isEmpty == false ? " Your note mentioned: \(context!)." : ""

        let messages = [
            "\(recipient), this \(occasion) message is shaped for \(relationship) with a \(tone) tone.\(includeDetail) \(spellingNote)",
            "For \(recipient): a \(length) \(occasion) draft that keeps the relationship in mind.\(avoidDetail) It is ready to copy, edit, or use as a starting point.",
            "A simple \(tone) note for \(recipient), shaped around the moment and recipient.\(contextDetail) Use it as a gentle starting point."
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
