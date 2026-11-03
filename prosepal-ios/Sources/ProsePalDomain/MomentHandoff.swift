import Foundation

/// Canonical, extension-safe launch and input contract shared by the app, App
/// Intents, the Share Extension, and the widget/control surfaces. Every target
/// links `ProsePalDomain` and uses these types so there is one payload, one
/// storage policy, one URL-routing policy, and one sanitisation policy.
///
/// This module imports only `Foundation`, so app extensions can compile against
/// it without pulling in SwiftUI, AppIntents, or app-only APIs.

// MARK: - Environment

/// Resolves the production/staging environment from the running bundle and owns
/// the values that must differ between them. Production and staging share one
/// app-group container but never read each other's handoff because the storage
/// key and URL scheme are environment-specific.
public enum MomentHandoffEnvironment: Equatable, Sendable {
    case production
    case staging

    /// The environment of the currently running executable (app, extension, or
    /// widget). Staging bundle identifiers are prefixed `com.prosepal.prosepal.staging`.
    public static var current: Self {
        resolve(bundleIdentifier: Bundle.main.bundleIdentifier)
    }

    public static func resolve(bundleIdentifier: String?) -> Self {
        (bundleIdentifier?.hasPrefix("com.prosepal.prosepal.staging") == true)
            ? .staging
            : .production
    }

    /// The registered custom URL scheme for this environment. Matches the
    /// `PROSEPAL_URL_SCHEME` build setting injected into each target's Info.plist.
    public var urlScheme: String {
        switch self {
        case .production: "prosepal"
        case .staging: "prosepal-staging"
        }
    }

    /// Both registered schemes. The reader accepts either so a staging deep link
    /// is not silently dropped; a target only ever receives its own scheme.
    public static let knownSchemes: Set<String> = ["prosepal", "prosepal-staging"]

    /// The shared app-group container. Both environments use one container; the
    /// per-environment storage key below keeps their handoffs isolated.
    public var appGroupIdentifier: String {
        "group.com.prosepal.prosepal"
    }

    /// Environment-specific app-group key for the one-time shared-message payload.
    public var sharedPayloadKey: String {
        switch self {
        case .production: "prosepal.pendingSharedMoment.v1"
        case .staging: "prosepal.pendingSharedMoment.staging.v1"
        }
    }
}

// MARK: - Sources

/// The allowlisted set of launch sources. Any value outside this set is treated
/// as untrusted and normalised away, so a deep link cannot smuggle arbitrary
/// text through the `source` field.
public enum MomentLaunchSource {
    public static let appIntent = "app_intent"
    public static let controlCenter = "control_center"
    public static let deepLink = "deep_link"
    public static let shareExtension = "share_extension"
    public static let shortcut = "shortcut"
    public static let widget = "widget"

    public static let allowed: Set<String> = [
        appIntent, controlCenter, deepLink, shareExtension, shortcut, widget
    ]

    public static func sanitized(_ value: String?) -> String? {
        guard let value else { return nil }
        let normalized = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return allowed.contains(normalized) ? normalized : nil
    }
}

// MARK: - Launch request

/// The one canonical incoming payload every surface prepares. Person and shared
/// text are normalised through the domain text policy; the source is restricted
/// to the allowlist.
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
        let normalizedName = personName.map(ProsePalTextInput.personName)
        self.personName = normalizedName?.isEmpty == false ? normalizedName : nil
        self.occasion = occasion
        self.sharedText = SharedMomentLaunchPayload.sanitized(sharedText)
        let trimmedSource = source.trimmingCharacters(in: .whitespacesAndNewlines)
        self.source = trimmedSource.isEmpty ? Self.defaultSource : trimmedSource
        self.createdAt = createdAt
    }
}

/// One-time App Intent payload in the app's standard `UserDefaults`. App Intents
/// run in the app process, so this does not use the app group.
public struct MomentLaunchStore {
    public static let defaultKey = "prosepal.pendingMomentLaunch.v1"

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

    /// Consume-once: the stored value is removed before it is decoded, so a
    /// handoff is never silently replayed on a later launch.
    public func consume() -> MomentLaunchRequest? {
        guard let data = store.data(forKey: key) else { return nil }
        store.removeObject(forKey: key)
        return try? decoder.decode(MomentLaunchRequest.self, from: data)
    }
}

// MARK: - Shared app-group payload

/// Text/URL payload written by the Share Extension into the app-group container
/// and read once by the app.
public struct SharedMomentLaunchPayload: Codable, Equatable, Sendable {
    public static let maxTextCharacterCount = ProsePalTextLimit.momentDetail

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
        let normalized = ProsePalTextInput.momentDetail(text)
        return normalized.isEmpty ? nil : normalized
    }
}

/// One-time app-group persistence for the shared payload. The default store and
/// key are resolved from the running environment so production and staging stay
/// isolated even inside the same app-group container.
public struct SharedMomentLaunchStore {
    private let store: UserDefaults?
    private let key: String
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    public init(environment: MomentHandoffEnvironment = .current) {
        self.init(
            store: UserDefaults(suiteName: environment.appGroupIdentifier),
            key: environment.sharedPayloadKey
        )
    }

    public init(
        store: UserDefaults?,
        key: String = MomentHandoffEnvironment.production.sharedPayloadKey
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

// MARK: - URL routing

/// Builds and parses the `prosepal[-staging]://moment` route. One policy for all
/// writers (widget, control, Share Extension) and the reader (app root).
public struct MomentDeepLink: Equatable, Sendable {
    public static let momentHost = "moment"

    public var launchRequest: MomentLaunchRequest

    public init?(url: URL) {
        guard let scheme = url.scheme, MomentHandoffEnvironment.knownSchemes.contains(scheme) else {
            return nil
        }
        guard url.host == Self.momentHost || url.pathComponents.dropFirst().first == Self.momentHost else {
            return nil
        }

        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        let personName = components?.queryItems?.firstValue(named: "person")
            ?? components?.queryItems?.firstValue(named: "personName")
            ?? url.personPathComponent
        let occasion = Occasion.fromLaunchParameter(components?.queryItems?.firstValue(named: "occasion"))
            ?? Occasion.fromLaunchParameter(components?.queryItems?.firstValue(named: "moment"))
        let source = MomentLaunchSource.sanitized(
            components?.queryItems?.firstValue(named: "source")
        ) ?? MomentLaunchSource.deepLink

        launchRequest = MomentLaunchRequest(
            personName: personName,
            occasion: occasion,
            source: source
        )
    }

    /// The canonical open URL for a launch source in a given environment. Writers
    /// use this instead of hand-building a scheme string, and it never places
    /// message content in the URL.
    public static func momentURL(
        source: String,
        environment: MomentHandoffEnvironment = .current
    ) -> URL? {
        let normalizedSource = MomentLaunchSource.sanitized(source) ?? MomentLaunchSource.deepLink
        var components = URLComponents()
        components.scheme = environment.urlScheme
        components.host = Self.momentHost
        components.queryItems = [URLQueryItem(name: "source", value: normalizedSource)]
        return components.url
    }
}

// MARK: - Parsing helpers

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

public extension Occasion {
    /// Resolves an occasion from an untrusted launch parameter: an exact raw
    /// value, or a case-/diacritic-insensitive match against a raw value or
    /// display name. Unknown text returns nil rather than being trusted.
    static func fromLaunchParameter(_ value: String?) -> Occasion? {
        guard let normalized = value?.trimmingCharacters(in: .whitespacesAndNewlines),
              !normalized.isEmpty else {
            return nil
        }
        if let rawValueMatch = Occasion(rawValue: normalized) {
            return rawValueMatch
        }

        let key = normalized.momentParameterKey
        return Occasion.allCases.first {
            $0.rawValue.momentParameterKey == key ||
                $0.displayName.momentParameterKey == key
        }
    }
}

private extension String {
    var momentParameterKey: String {
        String(
            folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
                .filter { $0.isLetter || $0.isNumber }
        )
    }
}
