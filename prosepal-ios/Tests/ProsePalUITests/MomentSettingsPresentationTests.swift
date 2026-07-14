import SwiftUI
import Testing
@testable import ProsePalUI

@Test
func settingsWritingRowsDescribeTruthfulNoninteractiveStatus() {
    let persistentRows = MomentSettingsStaticRowDescriptor.writing(
        isRelationshipVaultPersistent: true
    )
    let temporaryRows = MomentSettingsStaticRowDescriptor.writing(
        isRelationshipVaultPersistent: false
    )

    #expect(persistentRows.map(\.id) == [.toneOptions, .voiceProfile, .textSize])
    #expect(persistentRows.map(\.title) == ["Tone options", "Voice profile", "Text size"])
    #expect(persistentRows.map(\.subtitle) == [
        "Choose a tone for each moment",
        "Relationship memory stays on this device",
        "Follows your device setting",
    ])
    #expect(persistentRows.map(\.trailing) == ["Per draft", "Available", "System"])
    #expect(temporaryRows[1].trailing == "Temporary")
}

@Test
func settingsPrivateDraftRowsDescribeAvailabilityWithoutPromisingAControl() {
    let automatic = MomentSettingsStaticRowDescriptor.privateDraftPrivacy(isConfigured: true)
    let unavailable = MomentSettingsStaticRowDescriptor.privateDraftPrivacy(isConfigured: false)

    #expect(automatic.title == "Private Draft")
    #expect(automatic.subtitle == "Uses on-device writing when available")
    #expect(automatic.trailing == "Automatic")
    #expect(unavailable.trailing == "Unavailable")
}

@Test
func settingsSensitiveWritingRowDescribesAutomaticReadinessWithoutPromisingAControl() {
    let ready = MomentSettingsStaticRowDescriptor.sensitiveWriting(isConfigured: true)
    let unavailable = MomentSettingsStaticRowDescriptor.sensitiveWriting(isConfigured: false)

    #expect(ready.id == .sensitiveWriting)
    #expect(ready.title == "Sensitive moments")
    #expect(ready.trailing == "Ready")
    #expect(unavailable.trailing == "Needs setup")
}

@Test
func draftRevisionTabsExposeOnlyDraftAndOriginal() {
    #expect(MomentDraftRevisionTab.allCases == [.draft, .original])
    #expect(MomentDraftRevisionTab.allCases.map(\.title) == ["Draft", "Original"])
}

@MainActor
@Test
func settingsStaticRowsRenderFromTheirPresentationContract() {
    let rows = MomentSettingsStaticRowDescriptor.writing(
        isRelationshipVaultPersistent: true
    )
    let renderer = ImageRenderer(
        content: MomentSettingsStaticRows(rows: rows).frame(width: 390)
    )

    #expect(renderer.cgImage != nil)
}
