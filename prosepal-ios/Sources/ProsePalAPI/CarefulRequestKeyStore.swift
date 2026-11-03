import Foundation

public struct CarefulPendingRequestKey: Codable, Equatable, Sendable {
    public var identity: String
    public var key: String
    public var createdAt: Date

    public init(identity: String, key: String, createdAt: Date) {
        self.identity = identity
        self.key = key
        self.createdAt = createdAt
    }
}

public protocol CarefulRequestKeyPersisting: Sendable {
    func load() -> CarefulPendingRequestKey?
    func save(_ value: CarefulPendingRequestKey)
    func clear()
}

public struct CarefulRequestKeyNoopPersistence: CarefulRequestKeyPersisting {
    public init() {}
    public func load() -> CarefulPendingRequestKey? { nil }
    public func save(_ value: CarefulPendingRequestKey) {}
    public func clear() {}
}

public struct UserDefaultsCarefulRequestKeyPersistence: CarefulRequestKeyPersisting, @unchecked Sendable {
    public static let defaultKey = "prosepal.native.pendingCarefulRequest.v1"

    private let store: UserDefaults
    private let key: String

    public init(
        store: UserDefaults = .standard,
        key: String = Self.defaultKey
    ) {
        self.store = store
        self.key = key
    }

    public func load() -> CarefulPendingRequestKey? {
        guard let data = store.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(CarefulPendingRequestKey.self, from: data)
    }

    public func save(_ value: CarefulPendingRequestKey) {
        guard let data = try? JSONEncoder().encode(value) else {
            clear()
            return
        }
        store.set(data, forKey: key)
    }

    public func clear() {
        store.removeObject(forKey: key)
    }
}

public actor CarefulRequestKeyStore {
    private let persistence: any CarefulRequestKeyPersisting
    private let timeToLive: TimeInterval
    private let now: @Sendable () -> Date
    private let makeKey: @Sendable () -> String
    private var pending: CarefulPendingRequestKey?

    public init(
        persistence: any CarefulRequestKeyPersisting = CarefulRequestKeyNoopPersistence(),
        timeToLive: TimeInterval = 24 * 60 * 60,
        now: @escaping @Sendable () -> Date = Date.init,
        makeKey: @escaping @Sendable () -> String = { UUID().uuidString }
    ) {
        self.persistence = persistence
        self.timeToLive = timeToLive
        self.now = now
        self.makeKey = makeKey
        self.pending = persistence.load()
    }

    public func key(for identity: String) -> String {
        let currentDate = now()
        if let pending,
           pending.identity == identity,
           currentDate.timeIntervalSince(pending.createdAt) < timeToLive {
            return pending.key
        }

        let next = CarefulPendingRequestKey(
            identity: identity,
            key: makeKey(),
            createdAt: currentDate
        )
        pending = next
        persistence.save(next)
        return next.key
    }

    public func clear(identity: String) {
        guard pending?.identity == identity else { return }
        pending = nil
        persistence.clear()
    }
}
