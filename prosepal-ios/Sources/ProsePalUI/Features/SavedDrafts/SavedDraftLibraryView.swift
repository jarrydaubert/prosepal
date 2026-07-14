import ProsePalAPI
import SwiftData
import SwiftUI

enum SavedDraftLibrarySearch {
    static func filtered(
        _ drafts: [SavedMomentDraftRecord],
        query: String
    ) -> [SavedMomentDraftRecord] {
        let query = trimmed(query)
        guard !query.isEmpty else { return drafts }

        return drafts.filter { draft in
            draft.title.localizedCaseInsensitiveContains(query)
                || draft.subtitle.localizedCaseInsensitiveContains(query)
                || draft.messageText.localizedCaseInsensitiveContains(query)
        }
    }

    static func isSearching(_ query: String) -> Bool {
        !trimmed(query).isEmpty
    }

    private static func trimmed(_ query: String) -> String {
        query.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

struct SavedMomentDraftsView: View {
    let onWriteFirst: () -> Void
    private let referenceDate: Date
    private let calendar: Calendar

    @Query(sort: \SavedMomentDraftRecord.createdAt, order: .reverse)
    private var drafts: [SavedMomentDraftRecord]
    @State private var searchText = ""
    @State private var isShowingSearch = false

    private var filteredDrafts: [SavedMomentDraftRecord] {
        SavedDraftLibrarySearch.filtered(drafts, query: searchText)
    }

    private var isSearching: Bool {
        SavedDraftLibrarySearch.isSearching(searchText)
    }

    private var isFirstRunEmptyState: Bool {
        drafts.isEmpty && !isSearching
    }

    private var canSearch: Bool {
        !drafts.isEmpty || isShowingSearch
    }

    init(
        referenceDate: Date = Date(),
        calendar: Calendar = .current,
        onWriteFirst: @escaping () -> Void = {}
    ) {
        self.referenceDate = referenceDate
        self.calendar = calendar
        self.onWriteFirst = onWriteFirst
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 11) {
                if isShowingSearch {
                    SavedDraftSearchField(searchText: $searchText)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }

                if filteredDrafts.isEmpty {
                    emptyState
                } else {
                    SavedDraftLibraryList(
                        drafts: filteredDrafts,
                        referenceDate: referenceDate,
                        calendar: calendar
                    )
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 2)
            .padding(.bottom, 126)
        }
        .scrollIndicators(.hidden)
        .safeAreaInset(edge: .bottom) {
            Color.clear
                .frame(height: 92)
                .accessibilityHidden(true)
        }
        .background {
            MomentAtmosphericBackground(isCareful: false)
        }
        .navigationTitle(String(localized: "Drafts"))
        #if os(iOS)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                searchButton
            }
        }
        #else
        .toolbar {
            ToolbarItem {
                searchButton
            }
        }
        #endif
    }

    @ViewBuilder
    private var emptyState: some View {
        if isFirstRunEmptyState {
            SavedDraftsLibraryEmptyState(onWriteFirst: onWriteFirst)
                .frame(minHeight: 484)
                .padding(.top, 58)
        } else {
            MomentSavedEmptyState(isSearching: isSearching)
            .padding(.top, 10)
        }
    }

    @ViewBuilder
    private var searchButton: some View {
        if canSearch {
            Button(action: toggleSearch) {
                Image(systemName: isShowingSearch ? "xmark" : "magnifyingglass")
            }
            .accessibilityLabel(isShowingSearch ? "Close search" : "Search drafts")
            .accessibilityIdentifier("savedDrafts.search.toggle")
        }
    }

    private func toggleSearch() {
        withAnimation(.easeInOut(duration: 0.18)) {
            isShowingSearch.toggle()
        }
    }
}

private struct SavedDraftSearchField: View {
    @Binding var searchText: String

    var body: some View {
        TextField(
            String(localized: "Search saved drafts"),
            text: $searchText
        )
        .textFieldStyle(.plain)
        .font(.body)
        .foregroundStyle(Color.prosePalInk)
        .padding(.horizontal, 14)
        .frame(height: 42)
        .background(Color.prosePalPaper.opacity(0.76), in: Capsule(style: .continuous))
        .overlay {
            Capsule(style: .continuous)
                .stroke(Color.prosePalNavy.opacity(0.10), lineWidth: 1)
        }
        .submitLabel(.search)
        .accessibilityIdentifier("savedDrafts.search.field")
    }
}

private struct SavedDraftLibraryList: View {
    let drafts: [SavedMomentDraftRecord]
    let referenceDate: Date
    let calendar: Calendar

    var body: some View {
        ForEach(drafts) { draft in
            NavigationLink {
                SavedMomentDraftDetailView(draft: draft)
            } label: {
                SavedMomentDraftLibraryCard(
                    draft: draft,
                    referenceDate: referenceDate,
                    calendar: calendar
                )
            }
            .buttonStyle(.plain)
        }
    }
}
