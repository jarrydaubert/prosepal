import AppIntents
import Foundation

public struct MomentLaunchRequest: Codable, Equatable {
    public static let defaultSource = "unknown"

    public var personName: String?
    public var source: String
    public var createdAt: Date

    public init(
        personName: String? = nil,
        source: String = MomentLaunchRequest.defaultSource,
        createdAt: Date = Date()
    ) {
        let trimmedName = personName?.trimmingCharacters(in: .whitespacesAndNewlines)
        self.personName = trimmedName?.isEmpty == false ? trimmedName : nil
        self.source = source.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? Self.defaultSource
            : source.trimmingCharacters(in: .whitespacesAndNewlines)
        self.createdAt = createdAt
    }
}

public struct MomentLaunchStore {
    public static let defaultKey = "prosepal.native.pendingMomentLaunch.v1"

    private let store: UserDefaults
    private let key: String
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    public init(
        store: UserDefaults = .standard,
        key: String = MomentLaunchStore.defaultKey
    ) {
        self.store = store
        self.key = key
    }

    public func save(_ request: MomentLaunchRequest) {
        guard let data = try? encoder.encode(request) else { return }
        store.set(data, forKey: key)
    }

    public func consume() -> MomentLaunchRequest? {
        guard let data = store.data(forKey: key) else { return nil }
        store.removeObject(forKey: key)
        return try? decoder.decode(MomentLaunchRequest.self, from: data)
    }
}

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

    public init() {}

    public init(personName: String?) {
        self.personName = personName
    }

    public func perform() async throws -> some IntentResult {
        MomentLaunchStore().save(MomentLaunchRequest(
            personName: personName,
            source: "app_intent"
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
