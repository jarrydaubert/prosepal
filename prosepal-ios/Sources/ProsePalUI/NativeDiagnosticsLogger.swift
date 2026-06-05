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
        logger.info(
            "generation_started request_id=\(requestID.diagnosticsPrefix, privacy: .public) lane=\(draft.requestedLane.rawValue, privacy: .public) occasion=\(draft.occasion.rawValue, privacy: .public) relationship=\(draft.relationship.rawValue, privacy: .public) tone=\(draft.tone.rawValue, privacy: .public) length=\(draft.length.rawValue, privacy: .public) spelling=\(draft.spellingPreference.rawValue, privacy: .public) recipient_present=\(draft.recipientName.hasDiagnosticsText, privacy: .public) include_count=\(draft.thingsToInclude.diagnosticsCommaCount, privacy: .public) avoid_count=\(draft.thingsToAvoid.diagnosticsCommaCount, privacy: .public) context_chars=\(draft.personalContext.diagnosticsTextCount, privacy: .public)"
        )
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
        logger.info(
            "generation_succeeded request_id=\(requestID.diagnosticsPrefix, privacy: .public) lane_used=\(laneUsed.rawValue, privacy: .public) fallback=\(fallbackStatus.rawValue, privacy: .public) message_count=\(messageCount, privacy: .public) total_message_chars=\(totalMessageCharacters, privacy: .public) usage_source=\(usageSource, privacy: .public) standard_remaining=\(standardRemaining, privacy: .public) duration_ms=\(durationMs, privacy: .public)"
        )
    }

    public func generationFailed(requestID: String?, category: String, durationMs: Int) {
        logger.warning(
            "generation_failed request_id=\((requestID ?? "none").diagnosticsPrefix, privacy: .public) category=\(category, privacy: .public) duration_ms=\(durationMs, privacy: .public)"
        )
    }

    public func messageAction(_ action: String, source: String, messageCharacters: Int) {
        logger.info(
            "message_action action=\(action, privacy: .public) source=\(source, privacy: .public) message_chars=\(messageCharacters, privacy: .public)"
        )
    }
}

private extension String {
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
