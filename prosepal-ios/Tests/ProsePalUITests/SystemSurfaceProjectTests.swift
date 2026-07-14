import Foundation
import Testing
@testable import ProsePalUI

private enum RelationshipMemoryPersistenceTestError: Error {
    case persistenceFailed
}

@Test
func widgetExtensionTargetStaysWiredIntoTheAppProject() throws {
    let project = try String(
        contentsOf: packageRoot.appending(path: "ProsePal.xcodeproj/project.pbxproj"),
        encoding: .utf8
    )

    #expect(project.contains("ProsePalWidgets"))
    #expect(project.contains("ProsePalWidgets.appex"))
    #expect(project.contains("ProsePalWidgetsStaging"))
    #expect(project.contains("ProsePalWidgetsStaging.appex"))
    #expect(project.contains("ProsePalShareExtension"))
    #expect(project.contains("ProsePalShareExtension.appex"))
    #expect(project.contains("ProsePalShareExtensionStaging"))
    #expect(project.contains("ProsePalShareExtensionStaging.appex"))
    #expect(project.contains("com.apple.product-type.app-extension"))
    #expect(project.contains("Embed App Extensions"))
    #expect(project.contains("ProsePalWidgets.appex in Embed App Extensions"))
    #expect(project.contains("ProsePalShareExtension.appex in Embed App Extensions"))
    #expect(project.contains("ProsePalWidgetsStaging.appex in Embed App Extensions"))
    #expect(project.contains("ProsePalShareExtensionStaging.appex in Embed App Extensions"))
    #expect(project.contains("com.prosepal.prosepal.staging.widgets"))
    #expect(project.contains("com.prosepal.prosepal.staging.share"))
    #expect(project.contains("PROSEPAL_WIDGET_DISPLAY_NAME = \"ProsePal Widgets\";"))
    #expect(project.contains("PROSEPAL_WIDGET_DISPLAY_NAME = \"ProsePal Staging Widgets\";"))
    #expect(project.contains("PROSEPAL_SHARE_DISPLAY_NAME = ProsePal;"))
    #expect(project.contains("PROSEPAL_SHARE_DISPLAY_NAME = \"ProsePal Staging\";"))
}

@Test
func careGlanceWidgetAndStartMomentControlStayDeclared() throws {
    let source = try String(
        contentsOf: packageRoot.appending(path: "Widgets/ProsePalWidgets.swift"),
        encoding: .utf8
    )

    #expect(source.contains("struct CareGlanceWidget: Widget"))
    #expect(source.contains("StaticConfiguration("))
    #expect(source.contains("Care Glance"))
    #expect(source.contains("source=widget"))
    #expect(source.contains("prosepal-staging"))
    #expect(source.contains("struct StartMomentControlWidget: ControlWidget"))
    #expect(source.contains("StaticControlConfiguration("))
    #expect(source.contains("ControlWidgetButton(action: OpenURLIntent"))
    #expect(source.contains("source=control_center"))
    #expect(source.contains("struct ProsePalWidgetsBundle: WidgetBundle"))
}

@Test
func shareExtensionDeclaresSafeTextHandoff() throws {
    let source = try String(
        contentsOf: packageRoot.appending(path: "ShareExtension/ShareViewController.swift"),
        encoding: .utf8
    )

    #expect(source.contains("final class ShareViewController: UIViewController"))
    #expect(source.contains("ShareLaunchStore().save(payload)"))
    #expect(source.contains("momentURL"))
    #expect(source.contains("source=share_extension"))
    #expect(source.contains("prosepal-staging"))
    #expect(source.contains("group.com.prosepal.prosepal"))
    #expect(source.contains("prosepal.native.pendingSharedMoment.v1"))
    #expect(!source.contains("prosepal://moment?text="))
    #expect(!source.contains("sharedText="))
    #expect(source.contains("maxTextCharacterCount = 1_200"))
}

@Test
func shareExtensionPlistAndEntitlementsDeclareShareSurface() throws {
    let plist = try String(
        contentsOf: packageRoot.appending(path: "ShareExtension/Info.plist"),
        encoding: .utf8
    )
    let entitlements = try String(
        contentsOf: packageRoot.appending(path: "ShareExtension/ProsePalShareExtension.entitlements"),
        encoding: .utf8
    )
    let appEntitlements = try String(
        contentsOf: packageRoot.appending(path: "App/ProsePal.entitlements"),
        encoding: .utf8
    )

    #expect(plist.contains("com.apple.share-services"))
    #expect(plist.contains("CFBundleDisplayName"))
    #expect(plist.contains("$(PROSEPAL_SHARE_DISPLAY_NAME)"))
    #expect(plist.contains("NSExtensionActivationSupportsText"))
    #expect(plist.contains("NSExtensionActivationSupportsWebURLWithMaxCount"))
    #expect(plist.contains("$(PRODUCT_MODULE_NAME).ShareViewController"))
    #expect(entitlements.contains("group.com.prosepal.prosepal"))
    #expect(appEntitlements.contains("group.com.prosepal.prosepal"))
}

@Test
func appAndShareExtensionDeclareRequiredReasonAPIUsage() throws {
    let appReasons = try privacyAccessReasons(at: "App/PrivacyInfo.xcprivacy")
    let shareReasons = try privacyAccessReasons(at: "ShareExtension/PrivacyInfo.xcprivacy")

    #expect(appReasons == ["1C8F.1", "CA92.1"])
    #expect(shareReasons == ["1C8F.1"])

    let project = try String(
        contentsOf: packageRoot.appending(path: "ProsePal.xcodeproj/project.pbxproj"),
        encoding: .utf8
    )
    #expect(project.contains("PP00000000000000000000A0 /* PrivacyInfo.xcprivacy in Resources */"))
    #expect(project.contains("PP00000000000000000000A1 /* PrivacyInfo.xcprivacy in Resources */"))
    #expect(project.contains("PP00000000000000000000A2 /* PrivacyInfo.xcprivacy in Resources */"))
    #expect(project.contains("PP00000000000000000000A3 /* PrivacyInfo.xcprivacy in Resources */"))
}

@Test
func archivedAppsRequirePublicRemoteServiceConfiguration() throws {
    let plist = try String(
        contentsOf: packageRoot.appending(path: "App/Info.plist"),
        encoding: .utf8
    )
    let project = try String(
        contentsOf: packageRoot.appending(path: "ProsePal.xcodeproj/project.pbxproj"),
        encoding: .utf8
    )
    let validator = try String(
        contentsOf: packageRoot.appending(path: "scripts/validate-native-service-config.sh"),
        encoding: .utf8
    )

    for key in [
        "PROSEPAL_GATEWAY_URL",
        "PROSEPAL_SUPABASE_URL",
        "PROSEPAL_SUPABASE_ANON_KEY"
    ] {
        #expect(plist.contains("<key>\(key)</key>"))
        #expect(project.contains("\(key) = \"\";"))
        #expect(validator.contains(key))
    }

    #expect(project.contains("Validate Remote Service Configuration"))
    #expect(validator.contains("PROSEPAL_DEV_GATEWAY_SECRET must never be embedded"))
}

@Test
func archiveRemoteConfigValidatorEnforcesSupabasePublicKeyShapes() throws {
    #expect(try archiveValidatorStatus(supabaseKey: "sb_publishable_example") == 0)
    #expect(try archiveValidatorStatus(supabaseKey: "eyJheader.payload.signature") == 0)

    for invalidKey in [
        "llolwgqphwnhbiqewmcq",
        "sb_publishable_",
        "eyJheader.payload",
        "eyJheader.payload.signature.extra",
        "eyJheader..signature",
    ] {
        #expect(try archiveValidatorStatus(supabaseKey: invalidKey) != 0)
    }
}

@Test
func quotaStateUsesServerMessageWithoutInventingLimitsOrResetDates() throws {
    let source = try String(
        contentsOf: packageRoot.appending(path: "Sources/ProsePalUI/MomentExperienceView.swift"),
        encoding: .utf8
    )

    #expect(source.contains("Text(\"Draft limit reached\")"))
    #expect(source.contains("Text(model.errorMessage ??"))
    #expect(source.contains("Label(\"View Pro options\", systemImage: \"feather\")"))
    #expect(!source.contains("10 of 10 used"))
    #expect(!source.contains("reset Monday"))
    #expect(!source.contains("Go Pro — unlimited"))
    #expect(!source.contains("Wait until Monday"))
}

@Test
func confirmedMemoryDeletionPersistsWithoutRollback() throws {
    var didDelete = false
    var didSave = false
    var didRollback = false

    try performConfirmedMemoryDeletion(
        delete: { didDelete = true },
        save: { didSave = true },
        rollback: { didRollback = true }
    )

    #expect(didDelete)
    #expect(didSave)
    #expect(!didRollback)
}

@Test
func failedMemoryDeletionRollsBackAndPropagatesTheFailure() {
    var didDelete = false
    var didRollback = false

    #expect(throws: RelationshipMemoryPersistenceTestError.persistenceFailed) {
        try performConfirmedMemoryDeletion(
            delete: { didDelete = true },
            save: { throw RelationshipMemoryPersistenceTestError.persistenceFailed },
            rollback: { didRollback = true }
        )
    }

    #expect(didDelete)
    #expect(didRollback)
}

@Test
func relationshipMemoryEditReportsSuccessOnlyAfterPersistence() throws {
    var didUpdate = false
    var didSave = false
    var didRollback = false

    try performRelationshipMemorySave(
        update: { didUpdate = true },
        save: { didSave = true },
        rollback: { didRollback = true }
    )

    #expect(didUpdate)
    #expect(didSave)
    #expect(!didRollback)
}

@Test
func failedRelationshipMemoryEditRollsBackAndPropagatesTheFailure() {
    var didUpdate = false
    var didRollback = false

    #expect(throws: RelationshipMemoryPersistenceTestError.persistenceFailed) {
        try performRelationshipMemorySave(
            update: { didUpdate = true },
            save: { throw RelationshipMemoryPersistenceTestError.persistenceFailed },
            rollback: { didRollback = true }
        )
    }

    #expect(didUpdate)
    #expect(didRollback)
}

@Test
func relationshipMemoryDeletionRequiresConfirmationAndSurfacesFailure() throws {
    let source = try String(
        contentsOf: packageRoot.appending(path: "Sources/ProsePalUI/MomentExperienceView.swift"),
        encoding: .utf8
    )

    #expect(source.contains("pendingMemoryDeletion = .truthBead(bead)"))
    #expect(source.contains("pendingMemoryDeletion = .voiceCard(voiceCard)"))
    #expect(source.contains("\"Delete saved memory?\""))
    #expect(source.contains("\"Delete saved detail?\""))
    #expect(source.contains("\"Delete saved voice card?\""))
    #expect(source.contains("Button(\"Cancel\", role: .cancel)"))
    #expect(source.contains("model.resetDraftForMomentChange()"))
    #expect(source.contains("Could not delete this detail. It is still saved."))
    #expect(source.contains("Could not delete this voice card. It is still saved."))
    #expect(source.contains("Could not save this detail. Your previous version is still saved."))
    #expect(source.contains("Could not save this voice card. Your previous version is still saved."))
}

@Test
func widgetExtensionPlistDeclaresWidgetKitExtensionPointAndBundleIdentifier() throws {
    let plist = try String(
        contentsOf: packageRoot.appending(path: "Widgets/Info.plist"),
        encoding: .utf8
    )

    #expect(plist.contains("com.apple.widgetkit-extension"))
    #expect(plist.contains("CFBundleDisplayName"))
    #expect(plist.contains("$(PROSEPAL_WIDGET_DISPLAY_NAME)"))
    #expect(plist.contains("$(PRODUCT_BUNDLE_IDENTIFIER)"))
    #expect(plist.contains("$(EXECUTABLE_NAME)"))
}

private var packageRoot: URL {
    URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .deletingLastPathComponent()
}

private func privacyAccessReasons(at relativePath: String) throws -> [String] {
    let data = try Data(contentsOf: packageRoot.appending(path: relativePath))
    let plist = try #require(
        PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any]
    )
    let entries = try #require(plist["NSPrivacyAccessedAPITypes"] as? [[String: Any]])
    let userDefaultsEntry = try #require(entries.first {
        $0["NSPrivacyAccessedAPIType"] as? String == "NSPrivacyAccessedAPICategoryUserDefaults"
    })
    return try #require(
        userDefaultsEntry["NSPrivacyAccessedAPITypeReasons"] as? [String]
    ).sorted()
}

private func archiveValidatorStatus(supabaseKey: String) throws -> Int32 {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/bin/sh")
    process.arguments = [
        packageRoot.appending(path: "scripts/validate-native-service-config.sh").path
    ]
    process.environment = ProcessInfo.processInfo.environment.merging([
        "ACTION": "build",
        "PROSEPAL_REQUIRE_REMOTE_CONFIG": "YES",
        "PROSEPAL_GATEWAY_URL": "https://gateway.example.invalid",
        "PROSEPAL_SUPABASE_URL": "https://supabase.example.invalid",
        "PROSEPAL_SUPABASE_ANON_KEY": supabaseKey,
        "PROSEPAL_DEV_GATEWAY_SECRET": "",
    ]) { _, testValue in testValue }
    process.standardOutput = Pipe()
    process.standardError = Pipe()

    try process.run()
    process.waitUntilExit()
    return process.terminationStatus
}
