import AppIntents
import ProsePalUI

struct ProsePalNativeAppShortcuts: AppShortcutsProvider {
    static let shortcutTileColor: ShortcutTileColor = .navy

    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: StartMomentIntent(),
            phrases: [
                "Start a moment in \(.applicationName)",
                "Write with \(.applicationName)",
                "Open \(.applicationName) for someone"
            ],
            shortTitle: "Start Moment",
            systemImageName: "square.and.pencil"
        )
    }
}
