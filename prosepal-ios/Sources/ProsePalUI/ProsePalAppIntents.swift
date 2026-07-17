import AppIntents
import Foundation
import ProsePalDomain

// The launch/input contract (MomentLaunchRequest, MomentLaunchStore,
// SharedMomentLaunchPayload, SharedMomentLaunchStore, MomentDeepLink, and the
// MomentHandoffEnvironment routing policy) lives in ProsePalDomain so the app,
// Share Extension, and widget targets all compile against one canonical
// definition. This file holds only the AppIntents-dependent surfaces.

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

    @Parameter(title: "Who is this for?")
    public var personName: String?

    @Parameter(title: "Moment")
    public var occasion: String?

    public init() {}

    public init(personName: String?, occasion: String? = nil) {
        self.personName = personName
        self.occasion = occasion
    }

    public func perform() async throws -> some IntentResult {
        MomentLaunchStore().save(MomentLaunchRequest(
            personName: personName,
            occasion: occasion.flatMap(Occasion.fromLaunchParameter),
            source: MomentLaunchSource.appIntent
        ))
        return .result(dialog: "Opening ProsePal.")
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
