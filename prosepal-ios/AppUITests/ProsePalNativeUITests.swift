import XCTest

@MainActor
class ProsePalNativeUITestCase: XCTestCase {
    enum Scenario: String {
        case firstLaunch = "first-launch"
        case signedOut = "signed-out"
        case signedIn = "signed-in"
        case signInSuccess = "sign-in-success"
        case signInFailure = "sign-in-failure"
        case accountDeletionSuccess = "account-deletion-success"
        case accountDeletionFailure = "account-deletion-failure"
        case accountDeletionIndeterminate = "account-deletion-indeterminate"
        case relationshipMemory = "relationship-memory"
    }

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func launch(
        _ scenario: Scenario,
        writingServiceArgument: String = "--prosepal-use-mock-writing-service",
        accessibilityTextSize: Bool = false,
        additionalArguments: [String] = []
    ) {
        app = XCUIApplication()
        app.launchArguments = [
            "--prosepal-ui-testing",
            "--prosepal-ui-test-scenario",
            scenario.rawValue,
            "--prosepal-use-mock-writing-service",
            "--prosepal-use-mock-subscription-service",
            "-AppleLanguages", "(en)",
            "-AppleLocale", "en_GB"
        ]
        if writingServiceArgument != "--prosepal-use-mock-writing-service" {
            app.launchArguments.append(writingServiceArgument)
        }
        if accessibilityTextSize {
            app.launchArguments.append("--prosepal-force-accessibility-text-size")
        }
        app.launchArguments.append(contentsOf: additionalArguments)
        app.launch()
    }

    func element(_ identifier: String) -> XCUIElement {
        app.descendants(matching: .any)[identifier]
    }

    func assertExists(
        _ identifier: String,
        timeout: TimeInterval = 5,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> XCUIElement {
        let result = element(identifier)
        XCTAssertTrue(
            result.waitForExistence(timeout: timeout),
            "Expected UI outcome \(identifier)",
            file: file,
            line: line
        )
        return result
    }

    func tap(
        _ identifier: String,
        maxScrolls: Int = 7,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let target = assertExists(identifier, file: file, line: line)
        var remainingScrolls = maxScrolls
        while !target.isHittable && remainingScrolls > 0 {
            app.swipeUp()
            remainingScrolls -= 1
        }
        if !target.isHittable {
            let hittable = XCTNSPredicateExpectation(
                predicate: NSPredicate(format: "hittable == true"),
                object: target
            )
            _ = XCTWaiter.wait(for: [hittable], timeout: 3)
        }
        XCTAssertTrue(
            target.isHittable,
            "Expected \(identifier) to be actionable",
            file: file,
            line: line
        )
        target.tap()
    }

    func openSettings() {
        tapRootTab("Settings")
        _ = assertExists("settings.done")
    }

    func tapRootTab(
        _ title: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let tab = app.tabBars.buttons[title]
        XCTAssertTrue(
            tab.waitForExistence(timeout: 5),
            "Expected the native \(title) tab",
            file: file,
            line: line
        )
        XCTAssertTrue(tab.isHittable, "Expected the \(title) tab to be actionable", file: file, line: line)
        tab.tap()
    }

    func enterPerson(_ name: String = "Mira") {
        let person = assertExists("composer.person")
        person.tap()
        person.typeText("\(name)\n")

        if app.keyboards.buttons["Done"].exists {
            app.keyboards.buttons["Done"].tap()
        } else if app.keyboards.buttons["Return"].exists {
            app.keyboards.buttons["Return"].tap()
        }

    }

    func enterPersonAndGenerate() {
        enterPerson()
        tap("composer.generate")
    }

    func createSuccessfulDraft() -> XCUIElement {
        enterPersonAndGenerate()
        return assertExists("activeDraft.editor", timeout: 8)
    }

    func assertGenericSharePresentation(
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let activityList = app.otherElements["ActivityListView"]
        XCTAssertTrue(
            activityList.waitForExistence(timeout: 5),
            "Expected the generic system share presentation",
            file: file,
            line: line
        )
    }

    @discardableResult
    func assertInProgress(
        _ identifier: String,
        timeout: TimeInterval = 1,
        mustBeDisabled: Bool = true,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> XCUIElement {
        let action = assertExists(identifier, timeout: timeout, file: file, line: line)
        XCTAssertEqual(action.value as? String, "In progress", file: file, line: line)
        XCTAssertFalse(
            String(describing: action.value).contains("%"),
            "In-progress work must not expose fake percentage progress",
            file: file,
            line: line
        )
        if mustBeDisabled {
            XCTAssertFalse(action.isEnabled, "Expected duplicate submission to be blocked", file: file, line: line)
        }
        return action
    }

    func assertIndeterminateProgress(
        _ identifier: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let progress = assertExists(identifier, timeout: 1, file: file, line: line)
        XCTAssertEqual(progress.value as? String, "In progress", file: file, line: line)
        XCTAssertFalse(
            String(describing: progress.value).contains("%"),
            "Indeterminate work must not expose fake percentage progress",
            file: file,
            line: line
        )
    }

    func assertPersonInputPreserved(
        _ expectedAccessibilityValue: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        tapRootTab("Write", file: file, line: line)
        let person = assertExists("composer.person", file: file, line: line)
        XCTAssertEqual(person.value as? String, expectedAccessibilityValue, file: file, line: line)
    }

    func openRelationshipMemoryVault() {
        openSettings()
        tap("settings.relationshipMemory")
    }

    func relationshipMemoryRows() -> XCUIElementQuery {
        app.descendants(matching: .any).matching(identifier: "memory.vault.row")
    }

    func openFirstRelationshipMemoryRecord(
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let row = relationshipMemoryRows().firstMatch
        XCTAssertTrue(
            row.waitForExistence(timeout: 5),
            "Expected a saved relationship-memory record",
            file: file,
            line: line
        )
        row.tap()
    }

    func tapDialogAction(
        _ identifier: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let action = app.buttons.matching(identifier: identifier).firstMatch
        XCTAssertTrue(
            action.waitForExistence(timeout: 5),
            "Expected confirmation action \(identifier)",
            file: file,
            line: line
        )
        action.tap()
    }

    func requestAndConfirmAccountDeletion() {
        openSettings()
        tap("settings.account.delete.request")
        let confirm = app.buttons
            .matching(identifier: "settings.account.delete.confirm")
            .firstMatch
        XCTAssertTrue(confirm.waitForExistence(timeout: 5))
        confirm.tap()
    }
}

@MainActor
final class ProsePalDurableSmokeUITests: ProsePalNativeUITestCase {
    func testFirstLaunchCompletesWithoutLosingAuthenticationEntry() {
        launch(.firstLaunch)

        _ = assertExists("moment.onboarding.welcome")
        _ = assertExists("moment.onboarding.signIn")

        for _ in 0..<4 where !element("composer.person").exists {
            tap("moment.onboarding.primary", maxScrolls: 2)
        }

        _ = assertExists("composer.person")
    }

    func testSettingsExposesAuthenticationPlanPurchaseAndRestoreEntryPoints() {
        launch(.signedOut)
        openSettings()

        _ = assertExists("auth.apple.entry.settings")
        _ = assertExists("settings.restorePurchases")
        tap("settings.plan")
        tap("plan.openPaywall")
        _ = assertExists("paywall.close")
        _ = assertExists("paywall.restore")
        _ = assertExists("paywall.purchase")
        XCTAssertTrue(app.staticTexts["More drafts and refines"].exists)
        XCTAssertEqual(
            app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] %@", "unlimited")).count,
            0,
            "The running Plan and Paywall must not promise an unlimited allowance"
        )
    }

    func testGenerationAcknowledgesTapPreservesInputAndExposesAccessibleProgress() {
        launch(
            .signedOut,
            writingServiceArgument: "--prosepal-slow-mock-writing-service"
        )

        enterPerson()
        let originalPersonValue = assertExists("composer.person").value as? String
        tap("composer.generate")
        _ = assertExists("moment.generating")
        assertIndeterminateProgress("moment.generation.progress")
        XCTAssertFalse(element("activeDraft.editor").exists, "Draft must not appear before generation completes")
        XCTAssertFalse(element("composer.generate").exists, "Generate cannot be submitted twice while writing")
        tap("moment.generation.stop", maxScrolls: 5)
        _ = assertExists("composer.generate")
        let person = assertExists("composer.person")
        XCTAssertEqual(person.value as? String, originalPersonValue)
    }

    func testSuccessfulDraftIsVisibleAndEditable() {
        launch(.signedOut)

        let editor = createSuccessfulDraft()
        let originalValue = editor.value as? String
        editor.tap()
        let revisionEditor = assertExists("activeDraft.revision.editor")
        revisionEditor.tap()
        revisionEditor.typeText(" Thank you.")

        XCTAssertNotEqual(revisionEditor.value as? String, originalValue)
    }

    func testOfflineDraftFailureKeepsAnHonestRetryAction() {
        launch(
            .signedOut,
            writingServiceArgument: "--prosepal-force-offline-writing-service"
        )

        enterPersonAndGenerate()
        let retry = assertExists("moment.offline.retry")
        XCTAssertTrue(retry.isEnabled)
    }
}

@MainActor
final class ProsePalReleaseUITests: ProsePalNativeUITestCase {
    func testFirstOnlineWritingUseNotNowPreservesWorkAndSendsNoDraft() {
        launch(
            .signedOut,
            additionalArguments: [
                "--prosepal-force-online-writing-route",
                "--prosepal-reset-online-writing-permission"
            ]
        )

        enterPerson()
        let originalPersonValue = assertExists("composer.person").value as? String
        tap("composer.generate")

        let alert = app.alerts["Use online writing?"]
        XCTAssertTrue(alert.waitForExistence(timeout: 5))
        let approvedMessage = "Some messages need ProsePal’s online writing service. The details you enter are sent securely to ProsePal and an AI provider to create or adjust your draft. Relationship Memory stays on this device. You can turn online writing off at any time in Privacy & Data."
        let message = alert.staticTexts
            .matching(NSPredicate(format: "label == %@", approvedMessage))
            .firstMatch
        XCTAssertTrue(message.exists)
        alert.buttons["Not Now"].firstMatch.tap()

        _ = assertExists("onlineWriting.permission.retry")
        XCTAssertFalse(element("activeDraft.editor").exists)
        app.buttons["Back to your note"].firstMatch.tap()
        XCTAssertEqual(assertExists("composer.person").value as? String, originalPersonValue)
    }

    func testFirstOnlineWritingUseAllowRetriesBlockedDraft() {
        launch(
            .signedOut,
            additionalArguments: [
                "--prosepal-force-online-writing-route",
                "--prosepal-reset-online-writing-permission"
            ]
        )

        enterPersonAndGenerate()
        let alert = app.alerts["Use online writing?"]
        XCTAssertTrue(alert.waitForExistence(timeout: 5))
        alert.buttons["Allow Online Writing"].firstMatch.tap()

        _ = assertExists("activeDraft.editor", timeout: 8)
    }

    func testPrivacyDataRevocationBlocksTheNextOnlineRoute() {
        launch(
            .signedOut,
            additionalArguments: [
                "--prosepal-force-online-writing-route",
                "--prosepal-reset-online-writing-permission"
            ]
        )

        enterPersonAndGenerate()
        let alert = app.alerts["Use online writing?"]
        XCTAssertTrue(alert.waitForExistence(timeout: 5))
        alert.buttons["Allow Online Writing"].firstMatch.tap()
        _ = assertExists("activeDraft.editor", timeout: 8)

        openSettings()
        tap("settings.privacyData")
        tap("privacy.onlineWriting.revoke")
        XCTAssertTrue(app.staticTexts["Online writing turned off"].waitForExistence(timeout: 5))

        tapRootTab("Write")
        let another = app.buttons["Another"]
        XCTAssertTrue(another.waitForExistence(timeout: 5))
        another.tap()
        XCTAssertTrue(app.alerts["Use online writing?"].waitForExistence(timeout: 5))
    }

    func testSignInAcknowledgesTapBlocksDuplicatesPreservesInputAndReportsSuccess() {
        launch(.signInSuccess)
        enterPerson()
        let originalPersonValue = assertExists("composer.person").value as? String
        openSettings()

        tap("auth.apple.entry.settings")
        _ = assertInProgress("auth.apple.entry.settings")
        XCTAssertFalse(element("auth.apple.succeeded").exists, "Sign-in cannot succeed before exchange confirmation")

        _ = assertExists("auth.apple.succeeded", timeout: 5)
        assertPersonInputPreserved(originalPersonValue ?? "")
    }

    func testSignInFailureReturnsToAnExplicitRetryableState() {
        launch(.signInFailure)
        openSettings()

        tap("auth.apple.entry.settings")
        _ = assertInProgress("auth.apple.entry.settings")

        _ = assertExists("auth.apple.failed", timeout: 5)
        let retry = assertExists("auth.apple.entry.settings")
        XCTAssertTrue(retry.isEnabled)
        XCTAssertEqual(retry.value as? String, "Ready")
    }

    func testPaywallProductLoadingIsAcknowledgedWithoutFakePercentageProgress() {
        launch(
            .signedOut,
            additionalArguments: ["--prosepal-slow-mock-subscription-service"]
        )
        openSettings()
        tap("settings.plan")
        tap("plan.openPaywall")

        assertIndeterminateProgress("paywall.products.loading")
        XCTAssertFalse(element("paywall.purchase").exists, "Purchase cannot begin before products are confirmed")
        _ = assertExists("paywall.purchase", timeout: 5)
    }

    func testPurchaseAcknowledgesTapBlocksDuplicatesPreservesInputAndWaitsForConfirmation() {
        launch(
            .signedIn,
            additionalArguments: ["--prosepal-slow-mock-subscription-service"]
        )
        enterPerson()
        let originalPersonValue = assertExists("composer.person").value as? String
        openSettings()
        tap("settings.plan")
        tap("plan.openPaywall")
        let purchase = assertExists("paywall.purchase", timeout: 5)
        purchase.tap()

        _ = assertInProgress("paywall.purchase")
        XCTAssertFalse(element("subscription.purchase.succeeded").exists, "Purchase cannot complete before StoreKit confirmation")
        _ = assertExists("plan.status.premium", timeout: 5)
        assertPersonInputPreserved(originalPersonValue ?? "")
    }

    func testRestoreFailureAcknowledgesTapPreservesInputAndReturnsToRetry() {
        launch(
            .signedOut,
            additionalArguments: [
                "--prosepal-slow-mock-subscription-service",
                "--prosepal-mock-restore-failure"
            ]
        )
        enterPerson()
        let originalPersonValue = assertExists("composer.person").value as? String
        openSettings()

        tap("settings.restorePurchases")
        _ = assertInProgress("settings.restorePurchases")
        XCTAssertFalse(element("subscription.restore.failed").exists, "Restore cannot fail before StoreKit responds")

        _ = assertExists("subscription.restore.failed", timeout: 5)
        let retry = assertExists("settings.restorePurchases")
        XCTAssertTrue(retry.isEnabled)
        XCTAssertEqual(retry.value as? String, "Ready")
        assertPersonInputPreserved(originalPersonValue ?? "")
    }

    func testAccountDeletionSuccessIsConfirmedAndReported() {
        launch(.accountDeletionSuccess)
        requestAndConfirmAccountDeletion()
        _ = assertInProgress("settings.account.delete.request")
        XCTAssertFalse(element("account.deletion.deleted").exists, "Deletion cannot complete before server confirmation")
        _ = assertExists("account.deletion.deleted", timeout: 5)
    }

    func testAccountDeletionFailureKeepsTheAccountAndReportsFailure() {
        launch(.accountDeletionFailure)
        enterPerson()
        let originalPersonValue = assertExists("composer.person").value as? String
        requestAndConfirmAccountDeletion()
        _ = assertInProgress("settings.account.delete.request")
        _ = assertExists("account.deletion.failed", timeout: 5)
        let retry = assertExists("settings.account.delete.request")
        XCTAssertTrue(retry.isEnabled)
        XCTAssertEqual(retry.value as? String, "Ready")
        assertPersonInputPreserved(originalPersonValue ?? "")
    }

    func testAccountDeletionIndeterminateStateIsReportedHonestly() {
        launch(.accountDeletionIndeterminate)
        requestAndConfirmAccountDeletion()
        _ = assertInProgress("settings.account.delete.request")
        XCTAssertFalse(element("account.deletion.indeterminate").exists, "Indeterminate state requires a server outcome")
        _ = assertExists("account.deletion.indeterminate", timeout: 5)
    }

    func testAccountDeletionJourneyReturnsToOnboardingAndFreshSignInSeesNoOldContent() {
        launch(.accountDeletionSuccess)
        _ = createSuccessfulDraft()
        tap("activeDraft.save")
        tapRootTab("Drafts")
        _ = assertExists("savedDraft.card")

        requestAndConfirmAccountDeletion()

        // The confirmation notice is transient; assert it before the durable
        // onboarding surface so its short display window is not missed.
        _ = assertExists("account.deletion.deleted", timeout: 10)
        _ = assertExists("moment.onboarding.signIn", timeout: 10)
        XCTAssertFalse(
            app.tabBars.buttons["Write"].exists,
            "The previous tab hierarchy must not stay mounted after deletion"
        )

        tap("moment.onboarding.signIn")

        for _ in 0..<4 where !element("composer.person").exists {
            tap("moment.onboarding.primary", maxScrolls: 2)
        }

        let person = assertExists("composer.person")
        XCTAssertNotEqual(
            person.value as? String,
            "Mira",
            "The deleted account's composer input must not survive"
        )
        tapRootTab("Drafts")
        XCTAssertFalse(
            element("savedDraft.card").waitForExistence(timeout: 2),
            "The deleted account's saved draft must not survive a fresh sign-in"
        )

        // The delete-account entry renders only for a signed-in account, so
        // its presence proves the fresh sign-in landed in a real session.
        openSettings()
        _ = assertExists("settings.account.delete.request", timeout: 5)
    }

    func testDraftCanBeCopiedSharedSavedAndReopened() {
        launch(.signedOut)
        _ = createSuccessfulDraft()

        tap("activeDraft.copy")
        _ = assertExists("activeDraft.copy.confirmation")

        tap("activeDraft.share")
        assertGenericSharePresentation()
        app.swipeDown()

        tap("activeDraft.save")
        tapRootTab("Drafts")
        tap("savedDraft.card")
        _ = assertExists("savedDraft.detail")
    }

    func testJSONExportPresentsGenericShareSheet() {
        launch(.signedOut)
        openSettings()

        tap("settings.privacyData")
        tap("privacy.export")
        tap("localDataExport.shareFile")
        assertGenericSharePresentation()
    }

    func testRelationshipMemoryDeletionRequiresConfirmationAndDismissalKeepsTheRecord() {
        launch(.relationshipMemory)
        openRelationshipMemoryVault()

        let seededRecordCount = relationshipMemoryRows().count
        XCTAssertEqual(seededRecordCount, 2, "Expected the seeded relationship-memory library")

        openFirstRelationshipMemoryRecord()
        tap("memory.detail.delete.request")

        // Requesting deletion never deletes on its own: it presents an
        // explicit confirm action and leaves the record intact until chosen.
        let confirm = app.buttons.matching(identifier: "memory.detail.delete.confirm").firstMatch
        XCTAssertTrue(confirm.waitForExistence(timeout: 5), "Expected an explicit confirmation action")

        // This presentation exposes no cancel control, so abandoning the
        // dialog is a tap outside it.
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.25)).tap()

        tap("memory.detail.back")
        let remaining = relationshipMemoryRows()
        let unchanged = NSPredicate(format: "count == %d", seededRecordCount)
        let expectation = XCTNSPredicateExpectation(predicate: unchanged, object: remaining)
        XCTAssertEqual(
            XCTWaiter.wait(for: [expectation], timeout: 5),
            .completed,
            "Expected an unconfirmed deletion to keep every saved record"
        )
    }

    func testRelationshipMemoryDeletionConfirmationRemovesTheRecord() {
        launch(.relationshipMemory)
        openRelationshipMemoryVault()

        let seededRecordCount = relationshipMemoryRows().count
        XCTAssertEqual(seededRecordCount, 2, "Expected the seeded relationship-memory library")

        openFirstRelationshipMemoryRecord()
        tap("memory.detail.delete.request")
        tapDialogAction("memory.detail.delete.confirm")

        // Confirmed deletion returns to the library with the record gone.
        let remaining = relationshipMemoryRows()
        let removed = NSPredicate(format: "count == %d", seededRecordCount - 1)
        let expectation = XCTNSPredicateExpectation(predicate: removed, object: remaining)
        XCTAssertEqual(
            XCTWaiter.wait(for: [expectation], timeout: 5),
            .completed,
            "Expected the confirmed deletion to remove exactly one saved record"
        )
    }

    func testGenerationFailureKeepsAnHonestRetryAction() {
        launch(
            .signedOut,
            writingServiceArgument: "--prosepal-force-generation-error-writing-service",
            additionalArguments: ["--prosepal-reset-online-writing-permission"]
        )

        enterPersonAndGenerate()
        let permissionAlert = app.alerts["Use online writing?"]
        XCTAssertTrue(permissionAlert.waitForExistence(timeout: 5))
        permissionAlert.buttons["Allow Online Writing"].firstMatch.tap()
        let retry = assertExists("moment.generation.retry")
        XCTAssertTrue(retry.isEnabled)
    }

    func testAccessibilityTextSizeSupportsComposerThroughDraftUse() {
        launch(.signedOut, accessibilityTextSize: true)

        _ = createSuccessfulDraft()
        tap("activeDraft.copy")
        _ = assertExists("activeDraft.copy.confirmation")
    }
}
