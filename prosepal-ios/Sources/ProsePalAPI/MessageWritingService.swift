import Foundation
import ProsePalDomain

public protocol MessageWritingService: Sendable {
    func draft(for moment: MomentInput) async throws -> MomentDraftBundle
    func adjust(
        _ bundle: MomentDraftBundle,
        with adjustment: MomentAdjustment,
        moment: MomentInput
    ) async throws -> MomentDraftBundle
    func takeMoreCare(
        _ bundle: MomentDraftBundle?,
        moment: MomentInput
    ) async throws -> MomentDraftBundle
}

public protocol MomentDraftClient: Sendable {
    func draft(for moment: MomentInput) async throws -> MomentDraftBundle
    func adjust(
        _ bundle: MomentDraftBundle,
        with adjustment: MomentAdjustment,
        moment: MomentInput
    ) async throws -> MomentDraftBundle
}

public protocol MomentDraftRefinementClient: MomentDraftClient {
    func refine(
        currentMessage: String?,
        moment: MomentInput
    ) async throws -> MomentDraftBundle
}

public struct RoutingMessageWritingService: MessageWritingService {
    private let privateClient: any MomentDraftClient
    private let carefulClient: any MomentDraftClient

    public init(
        privateClient: any MomentDraftClient,
        carefulClient: any MomentDraftClient
    ) {
        self.privateClient = privateClient
        self.carefulClient = carefulClient
    }

    public func draft(for moment: MomentInput) async throws -> MomentDraftBundle {
        guard moment.hasEnoughContextForDraft else {
            throw GenerationError.unexpectedResponse(
                message: "Add who this is for to begin."
            )
        }
        guard moment.safetySignal.allowsDrafting else {
            throw GenerationError.contentBlocked(
                message: "This needs immediate support, not a draft."
            )
        }

        if moment.requiresCarefulLane {
            do {
                return try await carefulClient.draft(for: moment)
                    .applyingLocalPressureCheck(for: moment)
            } catch let error as GenerationError {
                guard error.shouldFallbackToPrivateDraftFromCarefulLane else { throw error }
                return try await privateClient.draft(for: moment)
                    .applyingLocalPressureCheck(for: moment)
            } catch is CancellationError {
                throw CancellationError()
            } catch {
                return try await privateClient.draft(for: moment)
                    .applyingLocalPressureCheck(for: moment)
            }
        }

        do {
            return try await privateClient.draft(for: moment)
                .applyingLocalPressureCheck(for: moment)
        } catch let error as GenerationError {
            guard error.shouldRouteToCarefulLane else { throw error }
            return try await carefulClient.draft(for: moment)
                .replacingLane(.standardDraft)
                .applyingLocalPressureCheck(for: moment)
        }
    }

    public func adjust(
        _ bundle: MomentDraftBundle,
        with adjustment: MomentAdjustment,
        moment: MomentInput
    ) async throws -> MomentDraftBundle {
        guard moment.safetySignal.allowsDrafting else {
            throw GenerationError.contentBlocked(
                message: "This needs immediate support, not a draft."
            )
        }

        switch bundle.lane {
        case .privateDraft, .mock:
            do {
                return try await privateClient.adjust(bundle, with: adjustment, moment: moment)
                    .applyingLocalPressureCheck(for: moment)
            } catch let error as GenerationError {
                guard error.shouldRouteToCarefulLane else { throw error }
                return try await carefulClient.adjust(bundle, with: adjustment, moment: moment)
                    .replacingLane(.standardDraft)
                    .applyingLocalPressureCheck(for: moment)
            }
        case .standardDraft:
            return try await carefulClient.adjust(bundle, with: adjustment, moment: moment)
                .replacingLane(.standardDraft)
                .applyingLocalPressureCheck(for: moment)
        case .takeMoreCare:
            return try await carefulClient.adjust(bundle, with: adjustment, moment: moment)
                .applyingLocalPressureCheck(for: moment)
        }
    }

    public func takeMoreCare(
        _ bundle: MomentDraftBundle?,
        moment: MomentInput
    ) async throws -> MomentDraftBundle {
        guard moment.hasEnoughContextForDraft else {
            throw GenerationError.unexpectedResponse(
                message: "Add who this is for to begin."
            )
        }
        guard moment.safetySignal.allowsDrafting else {
            throw GenerationError.contentBlocked(
                message: "This needs immediate support, not a draft."
            )
        }

        if let refinementClient = carefulClient as? any MomentDraftRefinementClient {
            do {
                return try await refinementClient.refine(
                    currentMessage: bundle?.messageText,
                    moment: moment
                )
                .applyingLocalPressureCheck(for: moment)
            } catch let error as GenerationError {
                guard error.shouldFallbackToPrivateDraftFromCarefulLane else { throw error }
                return try await privateClient.draft(for: moment)
                    .applyingLocalPressureCheck(for: moment)
            } catch is CancellationError {
                throw CancellationError()
            } catch {
                return try await privateClient.draft(for: moment)
                    .applyingLocalPressureCheck(for: moment)
            }
        }

        do {
            return try await carefulClient.draft(for: moment)
                .applyingLocalPressureCheck(for: moment)
        } catch let error as GenerationError {
            guard error.shouldFallbackToPrivateDraftFromCarefulLane else { throw error }
            return try await privateClient.draft(for: moment)
                .applyingLocalPressureCheck(for: moment)
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            return try await privateClient.draft(for: moment)
                .applyingLocalPressureCheck(for: moment)
        }
    }
}

public struct MockMomentDraftClient: MomentDraftClient {
    public var bundle: MomentDraftBundle
    public var delay: Duration?

    public init(bundle: MomentDraftBundle, delay: Duration? = nil) {
        self.bundle = bundle
        self.delay = delay
    }

    public func draft(for moment: MomentInput) async throws -> MomentDraftBundle {
        try await sleepIfNeeded()
        return bundle
    }

    public func adjust(
        _ bundle: MomentDraftBundle,
        with adjustment: MomentAdjustment,
        moment: MomentInput
    ) async throws -> MomentDraftBundle {
        try await sleepIfNeeded()
        return MomentDraftBundle(
            messageText: adjustedText(bundle.messageText, adjustment: adjustment),
            lane: .mock,
            pressureCheck: bundle.pressureCheck,
            truthBeads: bundle.truthBeads,
            missingInformation: bundle.missingInformation,
            riskNotes: bundle.riskNotes
        )
    }

    private func sleepIfNeeded() async throws {
        guard let delay else { return }
        try await Task.sleep(for: delay)
    }

    private func adjustedText(_ text: String, adjustment: MomentAdjustment) -> String {
        switch adjustment {
        case .warmer:
            "\(text)\n\nThinking of you with a bit more warmth."
        case .shorter:
            text.components(separatedBy: ".").first.map { "\($0)." } ?? text
        case .moreDirect:
            "Simply put: \(text)"
        }
    }
}

public struct UnconfiguredMomentDraftClient: MomentDraftClient {
    public init() {}

    public func draft(for moment: MomentInput) async throws -> MomentDraftBundle {
        throw GenerationError.serviceUnavailable(
            message: "Writing is not available in this build."
        )
    }

    public func adjust(
        _ bundle: MomentDraftBundle,
        with adjustment: MomentAdjustment,
        moment: MomentInput
    ) async throws -> MomentDraftBundle {
        throw GenerationError.serviceUnavailable(
            message: "Writing is not available in this build."
        )
    }
}

private extension GenerationError {
    var shouldRouteToCarefulLane: Bool {
        switch self {
        case .offline, .usageLimitReached, .contentBlocked:
            false
        case .timedOut, .rateLimited, .serviceUnavailable, .unexpectedResponse:
            true
        }
    }

    var shouldFallbackToPrivateDraftFromCarefulLane: Bool {
        switch self {
        case .contentBlocked:
            false
        case .offline, .usageLimitReached, .timedOut, .rateLimited, .serviceUnavailable, .unexpectedResponse:
            true
        }
    }
}
