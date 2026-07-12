import ProsePalAPI
import SwiftData
import SwiftUI

#Preview("Saved draft detail") {
    SavedMomentDraftDetailPreview()
}

private struct SavedMomentDraftDetailPreview: View {
    private let container: ModelContainer
    private let draft: SavedMomentDraftRecord

    init() {
        container = try! RelationshipVaultContainerFactory.makeEphemeral()
        draft = SavedMomentDraftRecord(
            personName: "Mum",
            relationshipRawValue: "parent",
            occasionRawValue: "thinkingOfYou",
            registerRawValue: "react",
            toneRawValue: "heartfelt",
            lengthRawValue: "standard",
            laneRawValue: "privateDraft",
            trueThing: "I appreciate how you always make time for me.",
            messageText: "I was thinking about you and wanted to say how much I appreciate you."
        )
        container.mainContext.insert(draft)
    }

    var body: some View {
        NavigationStack {
            SavedMomentDraftDetailView(draft: draft)
        }
        .modelContainer(container)
    }
}
