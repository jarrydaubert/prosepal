import CryptoKit
import Foundation
import ProsePalDomain

public struct GatewayCarefulMomentClient: MomentDraftRefinementClient {
    private let client: any MessageWritingClient
    private let clientContext: ClientContext
    private let requestKeyStore: CarefulRequestKeyStore

    public init(
        client: any MessageWritingClient,
        clientContext: ClientContext,
        requestKeyStore: CarefulRequestKeyStore = CarefulRequestKeyStore()
    ) {
        self.client = client
        self.clientContext = clientContext
        self.requestKeyStore = requestKeyStore
    }

    public func draft(for moment: MomentInput) async throws -> MomentDraftBundle {
        try await generate(
            moment: moment,
            adjustment: nil,
            currentMessage: nil,
            reusesKeyOnRetry: true
        )
    }

    public func adjust(
        _ bundle: MomentDraftBundle,
        with adjustment: MomentAdjustment,
        moment: MomentInput
    ) async throws -> MomentDraftBundle {
        try await generate(
            moment: moment,
            adjustment: adjustment,
            currentMessage: bundle.messageText,
            reusesKeyOnRetry: false
        )
    }

    public func refine(
        currentMessage: String?,
        moment: MomentInput
    ) async throws -> MomentDraftBundle {
        try await generate(
            moment: moment,
            adjustment: nil,
            currentMessage: currentMessage,
            reusesKeyOnRetry: false
        )
    }

    private func generate(
        moment: MomentInput,
        adjustment: MomentAdjustment?,
        currentMessage: String?,
        reusesKeyOnRetry: Bool
    ) async throws -> MomentDraftBundle {
        let intent = moment.gatewayIntent(
            adjustment: adjustment,
            currentMessage: currentMessage
        )
        let identity = try Self.requestIdentity(intent: intent)
        let idempotencyKey = reusesKeyOnRetry
            ? await requestKeyStore.key(for: identity)
            : UUID().uuidString
        let request = CardRequest(
            idempotencyKey: idempotencyKey,
            intent: intent,
            requestedLane: .standard,
            clientContext: clientContext
        )
        let response: CardResponse
        do {
            response = try await client.generateCard(request: request)
        } catch let error as GenerationError {
            if reusesKeyOnRetry,
               case .requestNeedsFreshKey = error {
                await requestKeyStore.clear(identity: identity)
            }
            throw error
        }
        if reusesKeyOnRetry {
            await requestKeyStore.clear(identity: identity)
        }
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

    private static func requestIdentity(intent: CardIntent) throws -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        let payload = StableDraftRequestIdentity(
            intent: intent,
            requestedLane: .standard,
            promptContractVersion: CardRequest.currentPromptContractVersion,
            outputContractVersion: CardRequest.currentOutputContractVersion
        )
        let digest = SHA256.hash(data: try encoder.encode(payload))
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}

private struct StableDraftRequestIdentity: Encodable {
    var intent: CardIntent
    var requestedLane: GenerationLane
    var promptContractVersion: Int
    var outputContractVersion: Int
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
