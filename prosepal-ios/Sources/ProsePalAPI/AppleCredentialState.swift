import Foundation

public enum AppleCredentialState: Equatable, Sendable {
    case authorized
    case revoked
    case notFound
    case transferred
}

public enum AppleCredentialStateError: Error, Equatable, Sendable {
    case invalidUserIdentifier
    case unavailable
    case timedOut
}

public protocol AppleCredentialStateProviding: Sendable {
    func credentialState(forUserID userID: String) async throws -> AppleCredentialState
    func revocationEvents() -> AsyncStream<Void>
}

#if canImport(AuthenticationServices)
import AuthenticationServices

public final class SystemAppleCredentialStateProvider: AppleCredentialStateProviding, @unchecked Sendable {
    private let provider: ASAuthorizationAppleIDProvider
    private let notificationCenter: NotificationCenter
    private let timeout: Duration

    public init(
        provider: ASAuthorizationAppleIDProvider = ASAuthorizationAppleIDProvider(),
        notificationCenter: NotificationCenter = .default,
        timeout: Duration = .seconds(5)
    ) {
        self.provider = provider
        self.notificationCenter = notificationCenter
        self.timeout = timeout
    }

    public func credentialState(forUserID userID: String) async throws -> AppleCredentialState {
        let trimmedUserID = userID.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedUserID.isEmpty else {
            throw AppleCredentialStateError.invalidUserIdentifier
        }

        let stream = AsyncThrowingStream<AppleCredentialState, Error> { continuation in
            provider.getCredentialState(forUserID: trimmedUserID) { state, error in
                if error != nil {
                    continuation.finish(throwing: AppleCredentialStateError.unavailable)
                    return
                }

                switch state {
                case .authorized:
                    continuation.yield(.authorized)
                case .revoked:
                    continuation.yield(.revoked)
                case .notFound:
                    continuation.yield(.notFound)
                case .transferred:
                    continuation.yield(.transferred)
                @unknown default:
                    continuation.finish(throwing: AppleCredentialStateError.unavailable)
                    return
                }
                continuation.finish()
            }
        }

        return try await withThrowingTaskGroup(of: AppleCredentialState.self) { group in
            group.addTask {
                for try await state in stream {
                    return state
                }
                throw AppleCredentialStateError.unavailable
            }
            group.addTask {
                try await Task.sleep(for: self.timeout)
                throw AppleCredentialStateError.timedOut
            }
            defer { group.cancelAll() }
            guard let state = try await group.next() else {
                throw AppleCredentialStateError.unavailable
            }
            return state
        }
    }

    public func revocationEvents() -> AsyncStream<Void> {
        AsyncStream { continuation in
            let observer = notificationCenter.addObserver(
                forName: ASAuthorizationAppleIDProvider.credentialRevokedNotification,
                object: nil,
                queue: nil
            ) { _ in
                continuation.yield(())
            }
            let observerBox = AppleCredentialObserverBox(observer)
            continuation.onTermination = { [notificationCenter] _ in
                notificationCenter.removeObserver(observerBox.observer)
            }
        }
    }
}

private final class AppleCredentialObserverBox: @unchecked Sendable {
    let observer: NSObjectProtocol

    init(_ observer: NSObjectProtocol) {
        self.observer = observer
    }
}
#endif
