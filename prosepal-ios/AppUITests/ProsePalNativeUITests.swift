import XCTest

@MainActor
class ProsePalNativeUITestCase: XCTestCase {
    enum Scenario: String {
        case firstLaunch = "first-launch"
        case signedOut = "signed-out"
        case signedIn = "signed-in"
        case accountDeletionSuccess = "account-deletion-success"
        case accountDeletionFailure = "account-deletion-failure"
        case accountDeletionIndeterminate = "account-deletion-indeterminate"
    }

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func launch(
        _ scenario: Scenario,
        writingServiceArgument: String = "--prosepal-use-mock-writing-service",
        accessibilityTextSize: Bool = false
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

    func enterPersonAndGenerate() {
        let person = assertExists("composer.person")
        person.tap()
        person.typeText("Mira\n")

        if app.keyboards.buttons["Done"].exists {
            app.keyboards.buttons["Done"].tap()
        } else if app.keyboards.buttons["Return"].exists {
            app.keyboards.buttons["Return"].tap()
        }

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
    }

    func testTypedInputStartsGenerationAndExposesExistingStopAction() {
        launch(
            .signedOut,
            writingServiceArgument: "--prosepal-slow-mock-writing-service"
        )

        enterPersonAndGenerate()
        _ = assertExists("moment.generating")
        tap("moment.generation.stop", maxScrolls: 5)
        _ = assertExists("composer.generate")
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
    func testAccountDeletionSuccessIsConfirmedAndReported() {
        launch(.accountDeletionSuccess)
        requestAndConfirmAccountDeletion()
        _ = assertExists("account.deletion.deleted")
    }

    func testAccountDeletionFailureKeepsTheAccountAndReportsFailure() {
        launch(.accountDeletionFailure)
        requestAndConfirmAccountDeletion()
        _ = assertExists("account.deletion.failed")
        _ = assertExists("settings.account.delete.request")
    }

    func testAccountDeletionIndeterminateStateIsReportedHonestly() {
        launch(.accountDeletionIndeterminate)
        requestAndConfirmAccountDeletion()
        _ = assertExists("account.deletion.indeterminate")
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

    func testGenerationFailureKeepsAnHonestRetryAction() {
        launch(
            .signedOut,
            writingServiceArgument: "--prosepal-force-generation-error-writing-service"
        )

        enterPersonAndGenerate()
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
