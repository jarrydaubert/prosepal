import Foundation
import Testing

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
