import Foundation
import ProsePalDomain

public struct GatewayCarefulMomentClient: MomentDraftRefinementClient {
    private let client: any MessageWritingClient
    private let clientContext: ClientContext

    public init(
        client: any MessageWritingClient,
        clientContext: ClientContext
    ) {
        self.client = client
        self.clientContext = clientContext
    }

    public func draft(for moment: MomentInput) async throws -> MomentDraftBundle {
        try await generate(moment: moment, adjustment: nil, currentMessage: nil)
    }

    public func adjust(
        _ bundle: MomentDraftBundle,
        with adjustment: MomentAdjustment,
        moment: MomentInput
    ) async throws -> MomentDraftBundle {
        try await generate(
            moment: moment,
            adjustment: adjustment,
            currentMessage: bundle.messageText
        )
    }

    public func refine(
        currentMessage: String?,
        moment: MomentInput
    ) async throws -> MomentDraftBundle {
        try await generate(
            moment: moment,
            adjustment: nil,
            currentMessage: currentMessage
        )
    }

    private func generate(
        moment: MomentInput,
        adjustment: MomentAdjustment?,
        currentMessage: String?
    ) async throws -> MomentDraftBundle {
        let intent = moment.gatewayIntent(
            adjustment: adjustment,
            currentMessage: currentMessage
        )
        let request = CardRequest(
            intent: intent,
            requestedLane: .standard,
            clientContext: clientContext
        )
        let response = try await client.generateCard(request: request)
        guard let message = response.messages.first?.text.trimmedNonEmpty else {
            throw GenerationError.unexpectedResponse(
                message: "Message generation returned no messages. Please try again."
            )
        }

        return MomentDraftBundle(
            messageText: message,
            lane: .takeMoreCare,
            pressureCheck: PressureCheck(
                notes: response.qualityCheck?.userSafeNote.map { [$0] } ?? []
            ),
            riskNotes: response.userSafeError.map { [$0.message] } ?? []
        )
    }
}

private extension MomentInput {
    func gatewayIntent(
        adjustment: MomentAdjustment?,
        currentMessage: String?
    ) -> CardIntent {
        var include = trueThing.trimmedNonEmpty.map { [$0] } ?? []
        if let adjustment {
            include.append("Please make the message \(adjustment.displayName.lowercased()).")
        }

        var contextParts = [register.userSafeDescription]
        if let currentMessage = currentMessage?.trimmedNonEmpty {
            contextParts.append("Current message to reshape: \(currentMessage)")
        }

        return CardIntent(
            occasion: occasion,
            relationship: relationship,
            tone: tone,
            length: length,
            localeIdentifier: localeIdentifier,
            recipientName: personName.trimmedNonEmpty,
            thingsToInclude: include,
            thingsToAvoid: [],
            userContext: contextParts.joined(separator: "\n")
        )
    }
}

private extension String {
    var trimmedNonEmpty: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
