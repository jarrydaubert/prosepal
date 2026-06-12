import Foundation
import OSLog
import ProsePalDomain

public struct NativeDiagnosticsLogger: Sendable {
    public static let shared = NativeDiagnosticsLogger()

    private let logger = Logger(subsystem: "com.prosepal.native", category: "flow")

    public init() {}

    public func appStarted(hasCompletedOnboarding: Bool, savedMessageCount: Int) {
        logger.info(
            "app_started onboarding_completed=\(hasCompletedOnboarding, privacy: .public) saved_count=\(savedMessageCount, privacy: .public)"
        )
    }

    public func runtimeReadiness(_ readiness: NativeRuntimeReadiness) {
        logger.info("\(readiness.diagnosticsPayload, privacy: .public)")
    }

    public func onboardingShown() {
        logger.info("onboarding_shown")
    }

    public func tabSelected(_ tab: String) {
        logger.info("tab_selected tab=\(tab, privacy: .public)")
    }

    public func onboardingCompleted() {
        logger.info("onboarding_completed")
    }

    public func composeFieldFocused(_ field: String?) {
        logger.info("compose_field_focused field=\(field ?? "none", privacy: .public)")
    }

    public func pickerOpened(_ picker: String) {
        logger.info("picker_opened picker=\(picker, privacy: .public)")
    }

    public func selectionChanged(kind: String, value: String) {
        logger.info("selection_changed kind=\(kind, privacy: .public) value=\(value, privacy: .public)")
    }

    public func paywallShown(trigger: String, requestedLane: GenerationLane, standardRemaining: Int) {
        logger.info(
            "paywall_shown trigger=\(trigger, privacy: .public) requested_lane=\(requestedLane.rawValue, privacy: .public) standard_remaining=\(standardRemaining, privacy: .public)"
        )
    }

    public func generationStarted(requestID: String, draft: MessageDraft) {
        let payload = NativeDiagnosticsPayload.generationStarted(requestID: requestID, draft: draft)
        logger.info("\(payload, privacy: .public)")
    }

    public func generationSucceeded(
        requestID: String,
        laneUsed: GenerationLane,
        fallbackStatus: FallbackStatus,
        messageCount: Int,
        totalMessageCharacters: Int,
        usageSource: String,
        standardRemaining: Int,
        durationMs: Int
    ) {
        let payload = NativeDiagnosticsPayload.generationSucceeded(
            requestID: requestID,
            laneUsed: laneUsed,
            fallbackStatus: fallbackStatus,
            messageCount: messageCount,
            totalMessageCharacters: totalMessageCharacters,
            usageSource: usageSource,
            standardRemaining: standardRemaining,
            durationMs: durationMs
        )
        logger.info("\(payload, privacy: .public)")
    }

    public func generationFailed(requestID: String?, category: String, durationMs: Int) {
        let payload = NativeDiagnosticsPayload.generationFailed(
            requestID: requestID,
            category: category,
            durationMs: durationMs
        )
        logger.warning("\(payload, privacy: .public)")
    }

    public func messageAction(_ action: String, source: String, messageCharacters: Int) {
        let payload = NativeDiagnosticsPayload.messageAction(
            action: action,
            source: source,
            messageCharacters: messageCharacters
        )
        logger.info("\(payload, privacy: .public)")
    }

    public func subscriptionEvent(
        _ event: String,
        source: String,
        productCount: Int = 0,
        outcome: String = "none"
    ) {
        logger.info(
            "subscription_event event=\(event, privacy: .public) source=\(source, privacy: .public) product_count=\(productCount, privacy: .public) outcome=\(outcome, privacy: .public)"
        )
    }
}

enum NativeDiagnosticsPayload {
    static func generationStarted(requestID: String, draft: MessageDraft) -> String {
        "generation_started request_id=\(requestID.diagnosticsPrefix) lane=\(draft.requestedLane.rawValue) occasion=\(draft.occasion.rawValue) relationship=\(draft.relationship.rawValue) tone=\(draft.tone.rawValue) length=\(draft.length.rawValue) spelling=\(draft.spellingPreference.rawValue) recipient_present=\(draft.recipientName.hasDiagnosticsText) include_count=\(draft.thingsToInclude.diagnosticsCommaCount) avoid_count=\(draft.thingsToAvoid.diagnosticsCommaCount) context_chars=\(draft.personalContext.diagnosticsTextCount)"
    }

    static func generationSucceeded(
        requestID: String,
        laneUsed: GenerationLane,
        fallbackStatus: FallbackStatus,
        messageCount: Int,
        totalMessageCharacters: Int,
        usageSource: String,
        standardRemaining: Int,
        durationMs: Int
    ) -> String {
        "generation_succeeded request_id=\(requestID.diagnosticsPrefix) lane_used=\(laneUsed.rawValue) fallback=\(fallbackStatus.rawValue) message_count=\(messageCount) total_message_chars=\(totalMessageCharacters) usage_source=\(usageSource) standard_remaining=\(standardRemaining) duration_ms=\(durationMs)"
    }

    static func generationFailed(requestID: String?, category: String, durationMs: Int) -> String {
        "generation_failed request_id=\((requestID ?? "none").diagnosticsPrefix) category=\(category) duration_ms=\(durationMs)"
    }

    static func messageAction(action: String, source: String, messageCharacters: Int) -> String {
        "message_action action=\(action) source=\(source) message_chars=\(messageCharacters)"
    }
}

extension String {
    var diagnosticsPrefix: String {
        if count <= 12 { return self }
        return "\(prefix(12))..."
    }

    var diagnosticsTextCount: Int {
        trimmingCharacters(in: .whitespacesAndNewlines).count
    }

    var hasDiagnosticsText: Bool {
        diagnosticsTextCount > 0
    }

    var diagnosticsCommaCount: Int {
        split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .count
    }
}
