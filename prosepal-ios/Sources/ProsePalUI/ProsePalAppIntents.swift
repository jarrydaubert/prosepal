import AppIntents
import Foundation
import ProsePalDomain

public struct MomentLaunchRequest: Codable, Equatable, Sendable {
    public static let defaultSource = "unknown"

    public var personName: String?
    public var occasion: Occasion?
    public var sharedText: String?
    public var source: String
    public var createdAt: Date

    public init(
        personName: String? = nil,
        occasion: Occasion? = nil,
        sharedText: String? = nil,
        source: String = MomentLaunchRequest.defaultSource,
        createdAt: Date = Date()
    ) {
        let trimmedName = personName?.trimmingCharacters(in: .whitespacesAndNewlines)
        self.personName = trimmedName?.isEmpty == false ? trimmedName : nil
        self.occasion = occasion
        self.sharedText = SharedMomentLaunchPayload.sanitized(sharedText)
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

public struct SharedMomentLaunchPayload: Codable, Equatable, Sendable {
    public static let appGroupIdentifier = "group.com.prosepal.prosepal"
    public static let defaultKey = "prosepal.native.pendingSharedMoment.v1"
    public static let maxTextCharacterCount = 1_200

    public var text: String?
    public var sourceURL: URL?
    public var createdAt: Date

    public init(
        text: String?,
        sourceURL: URL? = nil,
        createdAt: Date = Date()
    ) {
        self.text = Self.sanitized(text)
        self.sourceURL = sourceURL
        self.createdAt = createdAt
    }

    public var hasMomentContext: Bool {
        text != nil || sourceURL != nil
    }

    public static func sanitized(_ text: String?) -> String? {
        guard let text else { return nil }
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        return String(trimmed.prefix(maxTextCharacterCount))
    }
}

public struct SharedMomentLaunchStore {
    private let store: UserDefaults?
    private let key: String
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    public init(
        store: UserDefaults? = UserDefaults(suiteName: SharedMomentLaunchPayload.appGroupIdentifier),
        key: String = SharedMomentLaunchPayload.defaultKey
    ) {
        self.store = store
        self.key = key
    }

    @discardableResult
    public func save(_ payload: SharedMomentLaunchPayload) -> Bool {
        guard payload.hasMomentContext, let data = try? encoder.encode(payload) else { return false }
        store?.set(data, forKey: key)
        return store != nil
    }

    public func consume() -> SharedMomentLaunchPayload? {
        guard let data = store?.data(forKey: key) else { return nil }
        store?.removeObject(forKey: key)
        return try? decoder.decode(SharedMomentLaunchPayload.self, from: data)
    }
}

public struct MomentDeepLink: Equatable, Sendable {
    public static let scheme = "prosepal"
    public static let momentHost = "moment"

    public var launchRequest: MomentLaunchRequest

    public init?(url: URL) {
        guard url.scheme == Self.scheme else { return nil }
        guard url.host == Self.momentHost || url.pathComponents.dropFirst().first == Self.momentHost else {
            return nil
        }

        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        let personName = components?.queryItems?.firstValue(named: "person")
            ?? components?.queryItems?.firstValue(named: "personName")
            ?? url.personPathComponent
        let occasion = components?.queryItems?.firstValue(named: "occasion")?.occasionValue
            ?? components?.queryItems?.firstValue(named: "moment")?.occasionValue
        let source = components?.queryItems?.firstValue(named: "source")?.safeMomentLaunchSource ?? "deep_link"

        launchRequest = MomentLaunchRequest(
            personName: personName,
            occasion: occasion,
            source: source
        )
    }
}

public struct ProsePalIntentsPackage: AppIntentsPackage {
    public static var includedPackages: [any AppIntentsPackage.Type] {
        []
    }
}

private extension Array where Element == URLQueryItem {
    func firstValue(named name: String) -> String? {
        first { $0.name == name }?.value
    }
}

private extension URL {
    var personPathComponent: String? {
        let components = pathComponents
            .filter { $0 != "/" && $0 != MomentDeepLink.momentHost }
        guard let rawName = components.first else { return nil }
        return rawName.removingPercentEncoding ?? rawName
    }
}

private extension String {
    var safeMomentLaunchSource: String? {
        let normalized = trimmingCharacters(in: .whitespacesAndNewlines)
        let allowedSources: Set<String> = [
            "app_intent",
            "control_center",
            "deep_link",
            "share_extension",
            "shortcut",
            "widget"
        ]
        return allowedSources.contains(normalized) ? normalized : nil
    }

    var occasionValue: Occasion? {
        let normalized = trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalized.isEmpty else { return nil }
        if let rawValueMatch = Occasion(rawValue: normalized) {
            return rawValueMatch
        }

        let key = normalized.momentParameterKey
        return Occasion.allCases.first {
            $0.rawValue.momentParameterKey == key ||
                $0.displayName.momentParameterKey == key
        }
    }

    private var momentParameterKey: String {
        String(
            folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
                .filter { $0.isLetter || $0.isNumber }
        )
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
            occasion: occasion?.occasionValue,
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
