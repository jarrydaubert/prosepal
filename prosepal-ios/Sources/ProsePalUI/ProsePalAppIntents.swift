import AppIntents
import Foundation

public struct ProsePalIntentsPackage: AppIntentsPackage {
    public static var includedPackages: [any AppIntentsPackage.Type] {
        []
    }
}

public struct StartMomentIntent: AppIntent {
    public static let title: LocalizedStringResource = "Start a Moment"
    public static let description = IntentDescription(
        "Open ProsePal ready to write for someone."
    )
    public static let supportedModes: IntentModes = .foreground(.dynamic)
    public static let isDiscoverable = true

    public init() {}

    public func perform() async throws -> some IntentResult {
        .result(dialog: "Opening ProsePal.")
    }
}

public struct ProsePalAppShortcuts: AppShortcutsProvider {
    public static let shortcutTileColor: ShortcutTileColor = .navy

    public static var appShortcuts: [AppShortcut] {
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
