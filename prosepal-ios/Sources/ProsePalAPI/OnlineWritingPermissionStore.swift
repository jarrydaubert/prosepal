import Foundation

public enum OnlineWritingPermissionPolicy {
    public static let currentVersion = 1
}

public enum OnlineWritingPermissionState: Equatable, Sendable {
    case notGranted
    case currentGrant
    case stalePolicyGrant
}

public protocol OnlineWritingPermissionStoring: Sendable {
    func state() -> OnlineWritingPermissionState
    func grantCurrentPolicy()
    func revoke()
}

/// The app-composition-owned persistence boundary for online-writing consent.
/// A stored version must exactly match the current policy before online work is
/// allowed; older or otherwise mismatched grants fail closed.
public final class UserDefaultsOnlineWritingPermissionStore: OnlineWritingPermissionStoring, @unchecked Sendable {
    public static let defaultKey = "prosepal.native.onlineWritingPermissionPolicyVersion.v1"

    private let defaults: UserDefaults
    private let key: String
    private let currentPolicyVersion: Int
    private let lock = NSLock()

    public init(
        defaults: UserDefaults = .standard,
        key: String = UserDefaultsOnlineWritingPermissionStore.defaultKey,
        currentPolicyVersion: Int = OnlineWritingPermissionPolicy.currentVersion
    ) {
        self.defaults = defaults
        self.key = key
        self.currentPolicyVersion = currentPolicyVersion
    }

    public func state() -> OnlineWritingPermissionState {
        withLock {
            guard let storedVersion = defaults.object(forKey: key) as? Int else {
                return .notGranted
            }
            return storedVersion == currentPolicyVersion ? .currentGrant : .stalePolicyGrant
        }
    }

    public func grantCurrentPolicy() {
        withLock {
            defaults.set(currentPolicyVersion, forKey: key)
        }
    }

    public func revoke() {
        withLock {
            defaults.removeObject(forKey: key)
        }
    }

    private func withLock<Result>(_ operation: () -> Result) -> Result {
        lock.lock()
        defer { lock.unlock() }
        return operation()
    }
}

/// Fail-closed stand-in for previews and isolated UI/model tests that do not
/// exercise granting. Production composition injects its persisted store.
public struct UnconfiguredOnlineWritingPermissionStore: OnlineWritingPermissionStoring {
    public init() {}

    public func state() -> OnlineWritingPermissionState { .notGranted }
    public func grantCurrentPolicy() {}
    public func revoke() {}
}
