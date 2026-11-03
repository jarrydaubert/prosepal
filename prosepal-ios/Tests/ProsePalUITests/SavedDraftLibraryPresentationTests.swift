import ProsePalAPI
import SwiftUI
import Testing
@testable import ProsePalUI

@Test
func savedDraftSearchMatchesPersonOccasionRelationshipAndMessageText() {
    let mum = makeSavedDraft(
        personName: "Mum",
        relationshipRawValue: "parent",
        occasionRawValue: "birthday",
        messageText: "I love seeing you make time for pottery."
    )
    let alex = makeSavedDraft(
        personName: "Alex",
        relationshipRawValue: "colleague",
        occasionRawValue: "thankYou",
        messageText: "Thanks for helping with the launch."
    )
    let drafts = [mum, alex]

    #expect(SavedDraftLibrarySearch.filtered(drafts, query: "mum").map(\.id) == [mum.id])
    #expect(SavedDraftLibrarySearch.filtered(drafts, query: "BIRTHDAY").map(\.id) == [mum.id])
    #expect(SavedDraftLibrarySearch.filtered(drafts, query: "colleague").map(\.id) == [alex.id])
    #expect(SavedDraftLibrarySearch.filtered(drafts, query: "launch").map(\.id) == [alex.id])
}

@Test
func blankSavedDraftSearchPreservesEveryPersistedRecordInOrder() {
    let first = makeSavedDraft(personName: "Mum", messageText: "First")
    let second = makeSavedDraft(personName: "Alex", messageText: "Second")
    let drafts = [first, second]

    #expect(SavedDraftLibrarySearch.filtered(drafts, query: "  \n ").map(\.id) == [first.id, second.id])
    #expect(!SavedDraftLibrarySearch.isSearching("  \n "))
    #expect(SavedDraftLibrarySearch.isSearching("Alex"))
}

@Test
func savedDraftSearchHasOneTruthfulResultSetRatherThanInventedStatuses() {
    let drafts = [
        makeSavedDraft(personName: "Mum", messageText: "One"),
        makeSavedDraft(personName: "Alex", messageText: "Two"),
    ]

    #expect(SavedDraftLibrarySearch.filtered(drafts, query: "").count == 2)
    #expect(SavedDraftLibrarySearch.filtered(drafts, query: "missing").isEmpty)
}

@Test
func savedDraftRelativeDateLabelsUseAnInjectedReferenceDate() throws {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = try #require(TimeZone(identifier: "Europe/London"))
    let referenceDate = try #require(
        calendar.date(from: DateComponents(year: 2026, month: 7, day: 14, hour: 12))
    )
    let yesterday = try #require(calendar.date(byAdding: .day, value: -1, to: referenceDate))

    #expect(SavedDraftRelativeDateLabel.text(
        createdAt: referenceDate,
        relativeTo: referenceDate,
        calendar: calendar
    ) == "Just now")
    #expect(SavedDraftRelativeDateLabel.text(
        createdAt: yesterday,
        relativeTo: referenceDate,
        calendar: calendar
    ) == "Yesterday")
}

@MainActor
@Test
func savedDraftLibraryCardRendersFromPersistedRecordData() {
    let referenceDate = Date(timeIntervalSince1970: 1_784_030_400)
    let draft = makeSavedDraft(
        personName: "Mum",
        occasionRawValue: "birthday",
        messageText: "Happy birthday, Mum.",
        createdAt: referenceDate
    )
    let renderer = ImageRenderer(
        content: SavedMomentDraftLibraryCard(
            draft: draft,
            referenceDate: referenceDate,
            calendar: Calendar(identifier: .gregorian)
        )
        .frame(width: 390)
    )

    #expect(renderer.cgImage != nil)
}

private func makeSavedDraft(
    personName: String,
    relationshipRawValue: String = "closeFriend",
    occasionRawValue: String = "thinkingOfYou",
    messageText: String,
    createdAt: Date = Date(timeIntervalSince1970: 1_784_030_400)
) -> SavedMomentDraftRecord {
    SavedMomentDraftRecord(
        personName: personName,
        relationshipRawValue: relationshipRawValue,
        occasionRawValue: occasionRawValue,
        registerRawValue: "react",
        toneRawValue: "heartfelt",
        lengthRawValue: "standard",
        laneRawValue: "privateDraft",
        trueThing: "A real detail",
        messageText: messageText,
        createdAt: createdAt,
        updatedAt: createdAt
    )
}
