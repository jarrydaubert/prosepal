import ProsePalAPI
import SwiftData
import SwiftUI

#Preview("Saved drafts") {
    SavedDraftLibraryPreview()
}

#Preview("Saved drafts — empty") {
    SavedDraftEmptyLibraryPreview()
}

#Preview("Saved draft detail") {
    SavedMomentDraftDetailPreview()
}

private struct SavedDraftEmptyLibraryPreview: View {
    private let container = try! RelationshipVaultContainerFactory.makeEphemeral()

    var body: some View {
        NavigationStack {
            SavedMomentDraftsView(
                referenceDate: Date(timeIntervalSince1970: 1_784_030_400),
                calendar: Calendar(identifier: .gregorian)
            )
        }
        .modelContainer(container)
    }
}

private struct SavedDraftLibraryPreview: View {
    private let container: ModelContainer
    private let referenceDate: Date

    init() {
        let calendar = Calendar(identifier: .gregorian)
        referenceDate = calendar.date(
            from: DateComponents(year: 2026, month: 7, day: 14, hour: 12)
        )!
        container = try! RelationshipVaultContainerFactory.makeEphemeral()
        container.mainContext.insert(
            SavedMomentDraftRecord.previewBirthday(createdAt: referenceDate)
        )
        container.mainContext.insert(
            SavedMomentDraftRecord.previewThanks(
                createdAt: referenceDate.addingTimeInterval(-86_400)
            )
        )
    }

    var body: some View {
        NavigationStack {
            SavedMomentDraftsView(
                referenceDate: referenceDate,
                calendar: Calendar(identifier: .gregorian)
            )
        }
        .modelContainer(container)
    }
}

private struct SavedMomentDraftDetailPreview: View {
    private let container: ModelContainer
    private let draft: SavedMomentDraftRecord

    init() {
        container = try! RelationshipVaultContainerFactory.makeEphemeral()
        draft = .previewBirthday(createdAt: Date(timeIntervalSince1970: 1_784_030_400))
        container.mainContext.insert(draft)
    }

    var body: some View {
        NavigationStack {
            SavedMomentDraftDetailView(draft: draft)
        }
        .modelContainer(container)
    }
}

private extension SavedMomentDraftRecord {
    static func previewBirthday(createdAt: Date) -> SavedMomentDraftRecord {
        SavedMomentDraftRecord(
            personName: "Mum",
            relationshipRawValue: "parent",
            occasionRawValue: "birthday",
            registerRawValue: "react",
            toneRawValue: "heartfelt",
            lengthRawValue: "standard",
            laneRawValue: "privateDraft",
            trueThing: "She finally took the pottery class she always talked about.",
            messageText: "Happy birthday, Mum. I love seeing you make time for the things that light you up.",
            createdAt: createdAt,
            updatedAt: createdAt
        )
    }

    static func previewThanks(createdAt: Date) -> SavedMomentDraftRecord {
        SavedMomentDraftRecord(
            personName: "Alex",
            relationshipRawValue: "colleague",
            occasionRawValue: "thankYou",
            registerRawValue: "react",
            toneRawValue: "casual",
            lengthRawValue: "brief",
            laneRawValue: "standardDraft",
            trueThing: "They stayed late to help with the launch.",
            messageText: "Thanks for staying late and helping me get the launch over the line.",
            createdAt: createdAt,
            updatedAt: createdAt
        )
    }
}
