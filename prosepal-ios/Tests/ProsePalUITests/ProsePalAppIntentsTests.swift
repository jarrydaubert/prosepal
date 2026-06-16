import ProsePalUI
import Testing

@Test
func startMomentIntentIsDiscoverable() {
    #expect(StartMomentIntent.isDiscoverable)
}

@Test
func prosePalShortcutsExposeStartMomentEntryPoint() {
    #expect(ProsePalAppShortcuts.appShortcuts.count == 1)
}
