@testable import ProsePalUI
import Testing

@Test
func rootNavigationDefinesThreeDistinctDiscoverableDestinations() {
    let tabs = MomentRootTab.allCases

    #expect(tabs.map(\.rawValue) == ["moment", "saved", "settings"])
    #expect(Set(tabs.map(\.title)).count == tabs.count)
    #expect(Set(tabs.map(\.systemImage)).count == tabs.count)
    #expect(Set(tabs.map(\.accessibilityIdentifier)).count == tabs.count)
    #expect(tabs.allSatisfy { !$0.title.isEmpty })
}
