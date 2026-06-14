import XCTest
import ProsePalAPI
import ProsePalDomain
@testable import ProsePalUI

@MainActor
final class SavedMessageTests: XCTestCase {
    func testSaveCapturesDraftMetadataAndPreventsDuplicates() throws {
        let harness = try makeHarness()
        defer { harness.cleanup() }

        let model = harness.makeModel()
        model.draft.occasion = .thankYouTeacher
        model.draft.relationship = .teacher
        model.draft.tone = .nostalgic
        model.draft.length = .detailed
        model.draft.recipientName = "Mrs Patel"

        let message = GeneratedMessage(id: "draft-1", text: "Thank you for everything.")

        XCTAssertTrue(model.save(message))
        XCTAssertFalse(model.save(message))
        XCTAssertEqual(model.savedMessages.count, 1)

        let saved = try XCTUnwrap(model.savedMessages.first)
        XCTAssertEqual(saved.text, "Thank you for everything.")
        XCTAssertEqual(saved.occasion, .thankYouTeacher)
        XCTAssertEqual(saved.relationship, .teacher)
        XCTAssertEqual(saved.tone, .nostalgic)
        XCTAssertEqual(saved.length, .detailed)
        XCTAssertEqual(saved.recipientName, "Mrs Patel")
        XCTAssertEqual(saved.title, "Mrs Patel")
        XCTAssertEqual(saved.subtitle, "Thank You Teacher / Teacher / Nostalgic")
    }

    func testSavedMessagesPersistUpdateAndDeleteLocally() throws {
        let harness = try makeHarness()
        defer { harness.cleanup() }

        let model = harness.makeModel()
        model.draft.occasion = .birthday
        model.draft.relationship = .parent
        model.draft.tone = .heartfelt
        model.draft.length = .standard

        XCTAssertTrue(model.save(GeneratedMessage(id: "draft-1", text: " Happy birthday, Dad. ")))
        let saved = try XCTUnwrap(model.savedMessages.first)

        let reloaded = harness.makeModel()
        XCTAssertEqual(reloaded.savedMessages.count, 1)
        XCTAssertEqual(reloaded.savedMessages.first?.text, "Happy birthday, Dad.")

        XCTAssertTrue(reloaded.updateSaved(saved, text: "Happy birthday, Dad. I love you."))
        XCTAssertEqual(reloaded.savedMessages.first?.text, "Happy birthday, Dad. I love you.")

        let reloadedAfterUpdate = harness.makeModel()
        XCTAssertEqual(reloadedAfterUpdate.savedMessages.first?.text, "Happy birthday, Dad. I love you.")

        reloadedAfterUpdate.deleteSaved(try XCTUnwrap(reloadedAfterUpdate.savedMessages.first))
        XCTAssertTrue(reloadedAfterUpdate.savedMessages.isEmpty)

        let reloadedAfterDelete = harness.makeModel()
        XCTAssertTrue(reloadedAfterDelete.savedMessages.isEmpty)
    }

    func testSavedMessagesAreScopedAcrossAnonymousAndSignedInUsers() async throws {
        let harness = try makeHarness()
        defer { harness.cleanup() }

        let sessionStore = SavedMessagesAuthSessionStore()
        let authClient = SavedMessagesAuthClient(
            session: AuthSession(
                accessToken: "user-a-token",
                user: AuthUser(id: "user-a", email: "a@example.com")
            )
        )
        let model = harness.makeModel(
            authSessionController: AuthSessionController(store: sessionStore),
            authClient: authClient
        )

        XCTAssertTrue(model.save(GeneratedMessage(id: "anonymous", text: "Anonymous saved draft.")))
        XCTAssertEqual(model.savedMessages.map(\.text), ["Anonymous saved draft."])

        XCTAssertNotNil(model.beginAppleSignInRequest(source: "settings"))
        await model.completeAppleSignIn(idToken: "apple-id-token", source: "settings")
        XCTAssertEqual(model.signedInUserID, "user-a")
        XCTAssertTrue(model.savedMessages.isEmpty)

        XCTAssertTrue(model.save(GeneratedMessage(id: "user-a", text: "User A saved draft.")))
        XCTAssertEqual(model.savedMessages.map(\.text), ["User A saved draft."])

        await authClient.setSession(
            AuthSession(
                accessToken: "user-b-token",
                user: AuthUser(id: "user-b", email: "b@example.com")
            )
        )
        XCTAssertNotNil(model.beginAppleSignInRequest(source: "settings"))
        await model.completeAppleSignIn(idToken: "apple-id-token", source: "settings")
        XCTAssertEqual(model.signedInUserID, "user-b")
        XCTAssertTrue(model.savedMessages.isEmpty)

        XCTAssertTrue(model.save(GeneratedMessage(id: "user-b", text: "User B saved draft.")))
        XCTAssertEqual(model.savedMessages.map(\.text), ["User B saved draft."])

        await authClient.setSession(
            AuthSession(
                accessToken: "user-a-token",
                user: AuthUser(id: "user-a", email: "a@example.com")
            )
        )
        XCTAssertNotNil(model.beginAppleSignInRequest(source: "settings"))
        await model.completeAppleSignIn(idToken: "apple-id-token", source: "settings")
        XCTAssertEqual(model.savedMessages.map(\.text), ["User A saved draft."])

        await model.signOut()
        XCTAssertFalse(model.isSignedIn)
        XCTAssertEqual(model.savedMessages.map(\.text), ["Anonymous saved draft."])
    }

    func testPersistedSignedInSessionLoadsItsOwnSavedMessagesAfterRelaunch() async throws {
        let harness = try makeHarness()
        defer { harness.cleanup() }

        let session = AuthSession(
            accessToken: "user-a-token",
            user: AuthUser(id: "user-a", email: "a@example.com")
        )
        let sessionStore = SavedMessagesAuthSessionStore()
        let authClient = SavedMessagesAuthClient(session: session)
        let model = harness.makeModel(
            authSessionController: AuthSessionController(store: sessionStore),
            authClient: authClient
        )

        XCTAssertTrue(model.save(GeneratedMessage(id: "anonymous", text: "Anonymous saved draft.")))
        XCTAssertNotNil(model.beginAppleSignInRequest(source: "settings"))
        await model.completeAppleSignIn(idToken: "apple-id-token", source: "settings")
        XCTAssertTrue(model.save(GeneratedMessage(id: "user-a", text: "User A saved draft.")))

        let relaunched = harness.makeModel(
            authSessionController: AuthSessionController(store: sessionStore),
            authClient: authClient
        )
        XCTAssertEqual(relaunched.savedMessages.map(\.text), ["Anonymous saved draft."])

        await relaunched.loadAuthSession()

        XCTAssertEqual(relaunched.signedInUserID, "user-a")
        XCTAssertEqual(relaunched.savedMessages.map(\.text), ["User A saved draft."])
    }

    func testAccountDeletionRemovesSignedInSavedMessagesAndReturnsToAnonymousScope() async throws {
        let harness = try makeHarness()
        defer { harness.cleanup() }

        let sessionStore = SavedMessagesAuthSessionStore()
        let authClient = SavedMessagesAuthClient(
            session: AuthSession(
                accessToken: "user-a-token",
                user: AuthUser(id: "user-a", email: "a@example.com")
            )
        )
        let accountMaintenanceClient = SavedMessagesAccountMaintenanceClient()
        let model = harness.makeModel(
            authSessionController: AuthSessionController(store: sessionStore),
            authClient: authClient,
            accountMaintenanceClient: accountMaintenanceClient
        )

        XCTAssertTrue(model.save(GeneratedMessage(id: "anonymous", text: "Anonymous saved draft.")))
        XCTAssertNotNil(model.beginAppleSignInRequest(source: "settings"))
        await model.completeAppleSignIn(idToken: "apple-id-token", source: "settings")
        XCTAssertTrue(model.save(GeneratedMessage(id: "user-a", text: "User A saved draft.")))

        model.requestAccountDeletion()
        await model.confirmAccountDeletion()

        let deletedTokens = await accountMaintenanceClient.deletedTokens
        XCTAssertEqual(deletedTokens, ["user-a-token"])
        XCTAssertFalse(model.isSignedIn)
        XCTAssertEqual(model.savedMessages.map(\.text), ["Anonymous saved draft."])

        XCTAssertNotNil(model.beginAppleSignInRequest(source: "settings"))
        await model.completeAppleSignIn(idToken: "apple-id-token", source: "settings")
        XCTAssertTrue(model.savedMessages.isEmpty)
    }

    private func makeHarness() throws -> SavedMessageHarness {
        let suiteName = "prosepal.saved.tests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defaults.removePersistentDomain(forName: suiteName)
        return SavedMessageHarness(suiteName: suiteName, defaults: defaults)
    }
}

@MainActor
private struct SavedMessageHarness {
    let suiteName: String
    let defaults: UserDefaults
    let key = "saved-messages"

    func makeModel(
        authSessionController: AuthSessionController? = nil,
        authClient: (any AuthClient)? = nil,
        accountMaintenanceClient: (any AccountMaintenanceClient)? = nil
    ) -> ProsePalAppModel {
        ProsePalAppModel(
            client: MockMessageWritingClient(
                response: CardResponse(messages: [], laneUsed: .standard)
            ),
            clientContext: ClientContext(appVersion: "0.0.0", buildNumber: "1"),
            savedMessagesStore: defaults,
            savedMessagesKey: key,
            authSessionController: authSessionController,
            authClient: authClient,
            accountMaintenanceClient: accountMaintenanceClient
        )
    }

    func cleanup() {
        defaults.removePersistentDomain(forName: suiteName)
    }
}

private actor SavedMessagesAuthSessionStore: AuthSessionStore {
    private var session: AuthSession?

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

private actor SavedMessagesAuthClient: AuthClient {
    private var session: AuthSession

    init(session: AuthSession) {
        self.session = session
    }

    func setSession(_ session: AuthSession) {
        self.session = session
    }

    func signInWithIDToken(
        provider: AuthProvider,
        idToken: String,
        nonce: String?
    ) async throws -> AuthSession {
        session
    }

    func signOut(accessToken: String) async throws {}
}

private actor SavedMessagesAccountMaintenanceClient: AccountMaintenanceClient {
    private(set) var deletedTokens: [String] = []

    func deleteAccount(accessToken: String) async throws {
        deletedTokens.append(accessToken)
    }
}
