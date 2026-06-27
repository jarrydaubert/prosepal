import Foundation
import OSLog
import ProsePalDomain

public struct NativeDiagnosticsLogger: Sendable {
    public static let shared = NativeDiagnosticsLogger()

    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.prosepal.prosepal", category: "flow")

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

    public func messageAction(_ action: String, source: String, messageCharacters: Int) {
        let payload = NativeDiagnosticsPayload.messageAction(
            action: action,
            source: source,
            messageCharacters: messageCharacters
        )
        logger.info("\(payload, privacy: .public)")
    }

    public func authEvent(
        _ event: String,
        source: String,
        outcome: String = "none",
        statusCode: Int? = nil
    ) {
        let payload = NativeDiagnosticsPayload.authEvent(
            event: event,
            source: source,
            outcome: outcome,
            statusCode: statusCode
        )
        logger.info("\(payload, privacy: .public)")
    }

    public func momentDraftStarted(requestID: String, moment: MomentInput, trigger: String) {
        let payload = NativeDiagnosticsPayload.momentDraftStarted(
            requestID: requestID,
            moment: moment,
            trigger: trigger
        )
        logger.info("\(payload, privacy: .public)")
    }

    public func momentDraftSucceeded(
        requestID: String,
        bundle: MomentDraftBundle,
        durationMs: Int
    ) {
        let payload = NativeDiagnosticsPayload.momentDraftSucceeded(
            requestID: requestID,
            bundle: bundle,
            durationMs: durationMs
        )
        logger.info("\(payload, privacy: .public)")
    }

    public func momentDraftFailed(requestID: String, category: String, durationMs: Int) {
        let payload = NativeDiagnosticsPayload.momentDraftFailed(
            requestID: requestID,
            category: category,
            durationMs: durationMs
        )
        logger.warning("\(payload, privacy: .public)")
    }

    public func momentLaunchConsumed(_ request: MomentLaunchRequest) {
        let payload = NativeDiagnosticsPayload.momentLaunchConsumed(request)
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
    static func messageAction(action: String, source: String, messageCharacters: Int) -> String {
        "message_action action=\(action) source=\(source) message_chars=\(messageCharacters)"
    }

    static func authEvent(
        event: String,
        source: String,
        outcome: String,
        statusCode: Int?
    ) -> String {
        let status = statusCode.map(String.init) ?? "none"
        return "auth_event event=\(event) source=\(source) outcome=\(outcome) status_code=\(status)"
    }

    static func momentDraftStarted(requestID: String, moment: MomentInput, trigger: String) -> String {
        "moment_draft_started request_id=\(requestID.diagnosticsPrefix) trigger=\(trigger) register=\(moment.register.rawValue) occasion=\(moment.occasion.rawValue) relationship=\(moment.relationship.rawValue) tone=\(moment.tone.rawValue) length=\(moment.length.rawValue) person_present=\(moment.personName.hasDiagnosticsText) true_chars=\(moment.trueThing.diagnosticsTextCount) safety=\(moment.safetySignal.rawValue)"
    }

    static func momentDraftSucceeded(
        requestID: String,
        bundle: MomentDraftBundle,
        durationMs: Int
    ) -> String {
        "moment_draft_succeeded request_id=\(requestID.diagnosticsPrefix) lane=\(bundle.lane.rawValue) pressure_findings=\(bundle.pressureCheck.hasFindings) truth_bead_count=\(bundle.truthBeads.count) missing_count=\(bundle.missingInformation.count) risk_count=\(bundle.riskNotes.count) message_chars=\(bundle.messageText.diagnosticsTextCount) duration_ms=\(durationMs)"
    }

    static func momentDraftFailed(requestID: String, category: String, durationMs: Int) -> String {
        "moment_draft_failed request_id=\(requestID.diagnosticsPrefix) category=\(category) duration_ms=\(durationMs)"
    }

    static func momentLaunchConsumed(_ request: MomentLaunchRequest) -> String {
        "moment_launch_consumed source=\(request.source) person_present=\(request.personName?.hasDiagnosticsText == true) occasion=\(request.occasion?.rawValue ?? "none")"
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
