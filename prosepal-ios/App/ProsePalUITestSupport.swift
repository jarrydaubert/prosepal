import Foundation
import ProsePalAPI
import ProsePalUI

#if DEBUG
enum ProsePalUITestScenario: String {
    case firstLaunch = "first-launch"
    case signedOut = "signed-out"
    case signedIn = "signed-in"
    case accountDeletionSuccess = "account-deletion-success"
    case accountDeletionFailure = "account-deletion-failure"
    case accountDeletionIndeterminate = "account-deletion-indeterminate"

    static let launchMarker = "--prosepal-ui-testing"
    static let scenarioArgument = "--prosepal-ui-test-scenario"

    static var current: Self? {
        let arguments = ProcessInfo.processInfo.arguments
        guard arguments.contains(launchMarker),
              let argumentIndex = arguments.firstIndex(of: scenarioArgument),
              arguments.indices.contains(argumentIndex + 1) else {
            return nil
        }

        return Self(rawValue: arguments[argumentIndex + 1])
    }

    var hasCompletedWelcome: Bool {
        self != .firstLaunch
    }

    var persistedSession: AuthSession? {
        switch self {
        case .signedIn,
             .accountDeletionSuccess,
             .accountDeletionFailure,
             .accountDeletionIndeterminate:
            AuthSession(
                accessToken: "ui-test-access-token",
                refreshToken: "ui-test-refresh-token",
                user: AuthUser(
                    id: "A4F5445E-D598-4B86-A7E4-A7F5A69F5723",
                    email: "writer@example.invalid"
                )
            )
        case .firstLaunch, .signedOut:
            nil
        }
    }

    var accountDeletionBehavior: ProsePalUITestAccountDeletionClient.Behavior {
        switch self {
        case .accountDeletionFailure:
            .failure
        case .accountDeletionIndeterminate:
            .indeterminate
        case .firstLaunch, .signedOut, .signedIn, .accountDeletionSuccess:
            .success
        }
    }

    @MainActor
    func makeWelcomeState() -> MomentWelcomeState {
        let completionKey = "prosepal.ui-testing.welcome-completed"
        UserDefaults.standard.removeObject(forKey: completionKey)
        UserDefaults.standard.set(hasCompletedWelcome, forKey: completionKey)
        return MomentWelcomeState(
            store: .standard,
            completionKey: completionKey
        )
    }
}

actor ProsePalUITestAuthSessionStore: AuthSessionStore {
    private var session: AuthSession?

    init(session: AuthSession?) {
        self.session = session
    }

    func loadSession() async throws -> AuthSession? {
        session
    }

    func saveSession(_ session: AuthSession) async throws {
        self.session = session
    }

    func clearSession() async throws {
        session = nil
    }
}

struct ProsePalUITestAuthClient: AuthClient {
    func signInWithIDToken(
        provider: AuthProvider,
        idToken: String,
        nonce: String?
    ) async throws -> AuthSession {
        AuthSession(
            accessToken: "ui-test-access-token",
            refreshToken: "ui-test-refresh-token",
            user: AuthUser(
                id: "A4F5445E-D598-4B86-A7E4-A7F5A69F5723",
                email: "writer@example.invalid"
            )
        )
    }

    func refreshSession(_ session: AuthSession) async throws -> AuthSession {
        session
    }

    func signOut(accessToken: String) async throws {}
}

struct ProsePalUITestAppleAccountLifecycleClient: AppleAccountLifecycleClient {
    func storeRevocationMaterial(
        authorizationCode: String,
        appleUserID: String,
        accessToken: String
    ) async throws {}
}

struct ProsePalUITestAccountDeletionClient: AccountMaintenanceClient {
    enum Behavior: Sendable {
        case success
        case failure
        case indeterminate
    }

    let behavior: Behavior

    func deleteAccount(accessToken: String) async throws -> AccountDeletionOutcome {
        switch behavior {
        case .success:
            .deleted
        case .failure:
            throw AccountMaintenanceError.requestFailed(
                statusCode: 503,
                message: "Account deletion failed. Please try again."
            )
        case .indeterminate:
            .indeterminate
        }
    }
}
#endif
