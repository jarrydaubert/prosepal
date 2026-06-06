import XCTest
import ProsePalAPI
import ProsePalDomain
@testable import ProsePalUI

@MainActor
final class SettingsParityStateTests: XCTestCase {
    func testAppleSignInWhenUnconfiguredDoesNotFakeSignedInState() {
        let model = makeModel()

        let nonce = model.beginAppleSignInRequest(source: "settings")

        XCTAssertNil(nonce)
        XCTAssertFalse(model.isSignedIn)
        XCTAssertNotNil(model.notice)
    }

    func testLoadPersistedAuthSessionUpdatesSignedInState() async throws {
        let store = InMemoryAuthSessionStore(
            session: AuthSession(
                accessToken: "saved-token",
                user: AuthUser(id: "user-1", email: "user@example.com")
            )
        )
        let model = makeModel(
            authSessionController: AuthSessionController(store: store),
            authClient: RecordingAuthClient(session: AuthSession(accessToken: "unused"))
        )

        await model.loadAuthSession()

        XCTAssertTrue(model.isSignedIn)
        XCTAssertEqual(model.signedInEmail, "user@example.com")
    }

    func testCompletingAppleSignInStoresSessionAndMarksSignedIn() async throws {
        let store = InMemoryAuthSessionStore()
        let authClient = RecordingAuthClient(
            session: AuthSession(
                accessToken: "supabase-access-token",
                user: AuthUser(id: "user-1", email: "user@example.com")
            )
        )
        let model = makeModel(
            authSessionController: AuthSessionController(store: store),
            authClient: authClient
        )

        let nonce = model.beginAppleSignInRequest(source: "settings")
        XCTAssertNotNil(nonce)
        await model.completeAppleSignIn(idToken: "apple-id-token", source: "settings")

        let request = await authClient.signInRequests.first
        let storedSession = try await store.loadSession()
        XCTAssertEqual(request?.provider, .apple)
        XCTAssertEqual(request?.idToken, "apple-id-token")
        XCTAssertNotNil(request?.nonce)
        XCTAssertEqual(storedSession?.accessToken, "supabase-access-token")
        XCTAssertTrue(model.isSignedIn)
        XCTAssertEqual(model.signedInEmail, "user@example.com")
        XCTAssertFalse(model.isSigningIn)
    }

    func testSignOutClearsAuthSessionAndBiometricState() async throws {
        let store = InMemoryAuthSessionStore(
            session: AuthSession(accessToken: "saved-token", user: AuthUser(id: "user-1"))
        )
        let authClient = RecordingAuthClient(session: AuthSession(accessToken: "unused"))
        let model = makeModel(
            authSessionController: AuthSessionController(store: store),
            authClient: authClient
        )

        await model.loadAuthSession()
        model.setBiometricLockEnabled(true)
        XCTAssertTrue(model.isSignedIn)
        XCTAssertTrue(model.biometricLockEnabled)

        await model.signOut()

        let clearedSession = try await store.loadSession()
        let signOutTokens = await authClient.signOutTokens
        XCTAssertFalse(model.isSignedIn)
        XCTAssertFalse(model.biometricLockEnabled)
        XCTAssertNil(clearedSession)
        XCTAssertEqual(signOutTokens, ["saved-token"])
    }

    func testPremiumPurchasePlaceholderDoesNotUnlockPremium() {
        let model = makeModel()

        model.purchasePremiumPlaceholder(source: "paywall")

        XCTAssertFalse(model.usageStatus.isPremiumUnlocked)
        XCTAssertEqual(model.draft.requestedLane, .standard)
        XCTAssertNotNil(model.notice)
    }

    func testPrivacyTogglesUpdateLocalPreferences() {
        let model = makeModel()

        model.setAnalyticsEnabled(true)
        model.setCrashReportsEnabled(true)

        XCTAssertTrue(model.analyticsEnabled)
        XCTAssertTrue(model.crashReportsEnabled)

        model.setAnalyticsEnabled(false)
        model.setCrashReportsEnabled(false)

        XCTAssertFalse(model.analyticsEnabled)
        XCTAssertFalse(model.crashReportsEnabled)
    }

    func testBiometricLockRequiresSignedInAccount() {
        let model = makeModel()

        model.setBiometricLockEnabled(true)

        XCTAssertFalse(model.biometricLockEnabled)

        model.isSignedIn = true
        model.setBiometricLockEnabled(true)

        XCTAssertTrue(model.biometricLockEnabled)
    }

    func testSuccessfulGenerationUpdatesDisplayedStats() async {
        let model = makeModel(
            client: MockMessageWritingClient(
                response: CardResponse(
                    messages: [
                        GeneratedMessage(id: "draft-1", text: "A thoughtful draft."),
                        GeneratedMessage(id: "draft-2", text: "Another thoughtful draft.")
                    ],
                    laneUsed: .standard,
                    fallbackStatus: .none
                )
            )
        )

        await model.generate()

        XCTAssertEqual(model.totalGeneratedCount, 2)
    }

    private func makeModel(
        client: MessageWritingClient? = nil,
        authSessionController: AuthSessionController? = nil,
        authClient: (any AuthClient)? = nil
    ) -> ProsePalAppModel {
        ProsePalAppModel(
            client: client ?? MockMessageWritingClient(
                response: CardResponse(messages: [], laneUsed: .standard)
            ),
            clientContext: ClientContext(appVersion: "0.0.0", buildNumber: "1"),
            authSessionController: authSessionController,
            authClient: authClient
        )
    }
}

private actor InMemoryAuthSessionStore: AuthSessionStore {
    private var session: AuthSession?

    init(session: AuthSession? = nil) {
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

private actor RecordingAuthClient: AuthClient {
    struct SignInRequest: Equatable {
        var provider: AuthProvider
        var idToken: String
        var nonce: String?
    }

    private let session: AuthSession
    private(set) var signInRequests: [SignInRequest] = []
    private(set) var signOutTokens: [String] = []

    init(session: AuthSession) {
        self.session = session
    }

    func signInWithIDToken(
        provider: AuthProvider,
        idToken: String,
        nonce: String?
    ) async throws -> AuthSession {
        signInRequests.append(SignInRequest(provider: provider, idToken: idToken, nonce: nonce))
        return session
    }

    func signOut(accessToken: String) async throws {
        signOutTokens.append(accessToken)
    }
}
