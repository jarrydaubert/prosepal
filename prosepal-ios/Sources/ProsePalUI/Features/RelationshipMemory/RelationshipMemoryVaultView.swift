import Foundation
import ProsePalAPI
import SwiftData
import SwiftUI

struct RelationshipMemoryVaultView: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \RelationshipTruthBeadRecord.updatedAt, order: .reverse)
    private var beads: [RelationshipTruthBeadRecord]
    @Query(sort: \RelationshipVoiceCardRecord.updatedAt, order: .reverse)
    private var voiceCards: [RelationshipVoiceCardRecord]
    @State private var searchText = ""

    private var allItems: [RelationshipMemoryVaultItem] {
        (beads.map(RelationshipMemoryVaultItem.detail) + voiceCards.map(RelationshipMemoryVaultItem.voice))
            .sorted { $0.updatedAt > $1.updatedAt }
    }

    private var trimmedSearchText: String {
        searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var isSearching: Bool {
        !trimmedSearchText.isEmpty
    }

    private var filteredItems: [RelationshipMemoryVaultItem] {
        let query = trimmedSearchText
        let items = allItems
        guard !query.isEmpty else { return items }

        return items.filter {
            $0.searchText.localizedCaseInsensitiveContains(query)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            vaultTopChrome
                .padding(.horizontal, 20)
                .padding(.top, 10)
                .padding(.bottom, 8)

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    memoryHero

                    if !allItems.isEmpty || isSearching {
                        memorySearchField
                    }

                    if filteredItems.isEmpty {
                        MomentSavedEmptyState(
                            isSearching: isSearching,
                            emptyTitle: isSearching ? "No matching memory" : "No relationship memory yet",
                            emptyDetail: isSearching ? "Try another person or phrase." : "Save details or voice cards from the Moment screen when they should help future drafts.",
                            systemImage: "checkmark.seal"
                        )
                        .padding(.top, 4)
                    } else {
                        memoryList(filteredItems)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 44)
            }
            .scrollIndicators(.hidden)
        }
        .background {
            MomentAtmosphericBackground(isCareful: false)
        }
        .tint(.prosePalCoral)
        #if os(iOS)
        .toolbar(.hidden, for: .navigationBar)
        #endif
    }

    @ViewBuilder
    private func destination(for item: RelationshipMemoryVaultItem) -> some View {
        switch item {
        case .detail(let bead):
            RelationshipMemoryDetailView(bead: bead)
        case .voice(let voiceCard):
            RelationshipVoiceCardDetailView(voiceCard: voiceCard)
        }
    }

    private var vaultTopChrome: some View {
        HStack(alignment: .center) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 17, weight: .semibold))
                    .frame(width: 42, height: 42)
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .foregroundStyle(Color.prosePalCoralDeep)
            .background(Color.prosePalPaper.opacity(0.74), in: Circle())
            .accessibilityLabel("Back")

            Spacer(minLength: 12)

            Text("Memory")
                .font(.headline.weight(.semibold))
                .foregroundStyle(Color.prosePalInk)

            Spacer(minLength: 54)
        }
    }

    private var memoryHero: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: "checkmark.seal")
                .font(.system(size: 24, weight: .regular))
                .foregroundStyle(Color.prosePalCoralDeep)
                .frame(width: 52, height: 52)
                .background(Color.prosePalCoral.opacity(0.12), in: RoundedRectangle(cornerRadius: 17, style: .continuous))

            VStack(alignment: .leading, spacing: 7) {
                Text("What ProsePal may remember")
                    .font(.system(size: 30, weight: .regular, design: .serif))
                    .foregroundStyle(Color.prosePalInk)
                    .fixedSize(horizontal: false, vertical: true)

                Text("Approved details and voice notes stay editable, pausable, and local to this relationship memory.")
                    .font(.callout)
                    .foregroundStyle(Color.prosePalSlate.opacity(0.78))
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var memorySearchField: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(Color.prosePalSlate.opacity(0.70))

            TextField("Search memory", text: $searchText)
                .textFieldStyle(.plain)
                .font(.body)
                .foregroundStyle(Color.prosePalInk)
                .submitLabel(.search)

            if isSearching {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 17, weight: .semibold))
                }
                .buttonStyle(.plain)
                .foregroundStyle(Color.prosePalSlate.opacity(0.55))
                .accessibilityLabel("Clear search")
            }
        }
        .padding(.horizontal, 15)
        .frame(height: 46)
        .background(Color.prosePalPaper.opacity(0.80), in: Capsule(style: .continuous))
        .overlay {
            Capsule(style: .continuous)
                .stroke(Color.prosePalNavy.opacity(0.10), lineWidth: 1)
        }
    }

    private func memoryList(_ items: [RelationshipMemoryVaultItem]) -> some View {
        memoryGroup("Saved memory") {
            ForEach(items.indices, id: \.self) { index in
                let item = items[index]

                NavigationLink {
                    destination(for: item)
                } label: {
                    RelationshipMemoryVaultRow(item: item)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("memory.vault.row")

                if index != items.index(before: items.endIndex) {
                    memoryDivider
                }
            }
        }
    }

    private func memoryGroup<Content: View>(
        _ title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.caption.weight(.semibold))
                .textCase(.uppercase)
                .foregroundStyle(Color.prosePalSlate.opacity(0.62))
                .padding(.horizontal, 2)

            VStack(spacing: 0) {
                content()
            }
            .background(Color.prosePalPaper.opacity(0.94), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(Color.prosePalNavy.opacity(0.10), lineWidth: 1)
            }
            .shadow(color: Color.prosePalCoralDeep.opacity(0.06), radius: 10, x: 0, y: 5)
        }
    }

    private var memoryDivider: some View {
        Rectangle()
            .fill(Color.prosePalNavy.opacity(0.08))
            .frame(height: 1)
            .padding(.leading, 70)
    }
}

private enum RelationshipMemoryVaultItem: Identifiable {
    case detail(RelationshipTruthBeadRecord)
    case voice(RelationshipVoiceCardRecord)

    var id: String {
        switch self {
        case .detail(let bead):
            "detail-\(bead.id.uuidString)"
        case .voice(let voiceCard):
            "voice-\(voiceCard.id.uuidString)"
        }
    }

    var personName: String {
        switch self {
        case .detail(let bead):
            bead.personName
        case .voice(let voiceCard):
            voiceCard.personName
        }
    }

    var bodyText: String {
        switch self {
        case .detail(let bead):
            bead.text
        case .voice(let voiceCard):
            voiceCard.summary
        }
    }

    var kindLabel: String {
        switch self {
        case .detail:
            "Detail"
        case .voice:
            "Voice"
        }
    }

    var isUserApproved: Bool {
        switch self {
        case .detail(let bead):
            bead.isUserApproved
        case .voice(let voiceCard):
            voiceCard.isUserApproved
        }
    }

    var updatedAt: Date {
        switch self {
        case .detail(let bead):
            bead.updatedAt
        case .voice(let voiceCard):
            voiceCard.updatedAt
        }
    }

    var systemImage: String {
        switch self {
        case .detail:
            "text.badge.checkmark"
        case .voice:
            "person.crop.square"
        }
    }

    var updatedAtLabel: String {
        let calendar = Calendar.current

        if calendar.isDateInToday(updatedAt) {
            return "Updated today"
        }
        if calendar.isDateInYesterday(updatedAt) {
            return "Updated yesterday"
        }

        let days = calendar.dateComponents([.day], from: updatedAt, to: Date()).day ?? 0
        if days < 7 {
            return "Updated \(updatedAt.formatted(.dateTime.weekday(.abbreviated)))"
        }

        return "Updated \(updatedAt.formatted(.dateTime.month(.abbreviated).day()))"
    }

    var searchText: String {
        "\(personName) \(kindLabel) \(bodyText)"
    }
}

private struct RelationshipMemoryVaultRow: View {
    let item: RelationshipMemoryVaultItem

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: item.systemImage)
                .font(.system(size: 18, weight: .regular))
                .foregroundStyle(Color.prosePalCoralDeep)
                .frame(width: 42, height: 42)
                .background(Color.prosePalCoral.opacity(0.12), in: RoundedRectangle(cornerRadius: 14, style: .continuous))

            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(item.personName)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(Color.prosePalInk)
                        .lineLimit(1)
                        .minimumScaleFactor(0.84)

                    Spacer(minLength: 8)

                    HStack(spacing: 6) {
                        memoryBadge(item.kindLabel, color: .prosePalCoralDeep)

                        if !item.isUserApproved {
                            memoryBadge("Paused", color: .prosePalSlate)
                        }
                    }
                }

                Text(item.bodyText)
                    .font(.callout)
                    .foregroundStyle(Color.prosePalSlate.opacity(0.82))
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                Label(item.updatedAtLabel, systemImage: "clock")
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(Color.prosePalSlate.opacity(0.66))
            }

            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color.prosePalSlate.opacity(0.40))
                .padding(.top, 14)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity, minHeight: 104, alignment: .leading)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }

    private func memoryBadge(_ title: String, color: Color) -> some View {
        Text(title)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(color)
            .padding(.horizontal, 8)
            .frame(height: 24)
            .background(color.opacity(0.12), in: Capsule(style: .continuous))
    }
}

#Preview("Relationship memory") {
    RelationshipMemoryVaultPopulatedPreview()
}

#Preview("Relationship memory — empty") {
    RelationshipMemoryVaultEmptyPreview()
}

private struct RelationshipMemoryVaultEmptyPreview: View {
    private let container = try! RelationshipVaultContainerFactory.makeEphemeral()

    var body: some View {
        NavigationStack {
            RelationshipMemoryVaultView()
        }
        .modelContainer(container)
    }
}

private struct RelationshipMemoryVaultPopulatedPreview: View {
    private let container: ModelContainer

    init() {
        container = try! RelationshipVaultContainerFactory.makeEphemeral()
        let referenceDate = Date(timeIntervalSince1970: 1_784_030_400)
        container.mainContext.insert(
            RelationshipTruthBeadRecord(
                personName: "Mira",
                text: "Loves the Sunday morning calls and long walks by the river.",
                createdAt: referenceDate,
                updatedAt: referenceDate
            )
        )
        container.mainContext.insert(
            RelationshipVoiceCardRecord(
                personName: "Mira",
                summary: "Warm, short, no fuss.",
                createdAt: referenceDate.addingTimeInterval(-86_400),
                updatedAt: referenceDate.addingTimeInterval(-86_400)
            )
        )
        container.mainContext.insert(
            RelationshipTruthBeadRecord(
                personName: "Alex",
                text: "Just started a new role and is finding the first weeks intense.",
                isUserApproved: false,
                createdAt: referenceDate.addingTimeInterval(-172_800),
                updatedAt: referenceDate.addingTimeInterval(-172_800)
            )
        )
    }

    var body: some View {
        NavigationStack {
            RelationshipMemoryVaultView()
        }
        .modelContainer(container)
    }
}
