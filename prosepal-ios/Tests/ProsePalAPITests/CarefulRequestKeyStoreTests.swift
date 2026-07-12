import Foundation
import ProsePalAPI
import ProsePalDomain
import Testing

@Test
func carefulDraftRetryReusesKeyThenSuccessClearsIt() async throws {
    let cardClient = SequencedCardClient(results: [
        .failure(.serviceUnavailable(message: "Try again.")),
        .success(successfulCardResponse),
        .success(successfulCardResponse)
    ])
    let client = GatewayCarefulMomentClient(
        client: cardClient,
        clientContext: testClientContext,
        requestKeyStore: CarefulRequestKeyStore()
    )
    let moment = testMoment(name: "Sam")

    await #expect(throws: GenerationError.self) {
        _ = try await client.draft(for: moment)
    }
    _ = try await client.draft(for: moment)
    _ = try await client.draft(for: moment)

    let keys = await cardClient.idempotencyKeys
    #expect(keys.count == 3)
    #expect(keys[0] == keys[1])
    #expect(keys[1] != keys[2])
}

@Test
func carefulDraftInputChangeMintsANewKey() async throws {
    let cardClient = SequencedCardClient(results: [
        .failure(.serviceUnavailable(message: "Try again.")),
        .success(successfulCardResponse)
    ])
    let client = GatewayCarefulMomentClient(
        client: cardClient,
        clientContext: testClientContext,
        requestKeyStore: CarefulRequestKeyStore()
    )

    await #expect(throws: GenerationError.self) {
        _ = try await client.draft(for: testMoment(name: "Sam"))
    }
    _ = try await client.draft(for: testMoment(name: "Alex"))

    let keys = await cardClient.idempotencyKeys
    #expect(keys.count == 2)
    #expect(keys[0] != keys[1])
}

@Test
func carefulDraftKeySurvivesSimulatedRelaunch() async throws {
    let suiteName = "CarefulRequestKeyStoreTests.\(UUID().uuidString)"
    let defaults = try #require(UserDefaults(suiteName: suiteName))
    defer { defaults.removePersistentDomain(forName: suiteName) }
    let persistence = UserDefaultsCarefulRequestKeyPersistence(
        store: defaults,
        key: "pending"
    )
    let firstClient = SequencedCardClient(results: [
        .failure(.serviceUnavailable(message: "Try again."))
    ])
    let first = GatewayCarefulMomentClient(
        client: firstClient,
        clientContext: testClientContext,
        requestKeyStore: CarefulRequestKeyStore(persistence: persistence)
    )

    await #expect(throws: GenerationError.self) {
        _ = try await first.draft(for: testMoment(name: "Sam"))
    }

    let relaunchedClient = SequencedCardClient(results: [
        .success(successfulCardResponse)
    ])
    let relaunched = GatewayCarefulMomentClient(
        client: relaunchedClient,
        clientContext: testClientContext,
        requestKeyStore: CarefulRequestKeyStore(persistence: persistence)
    )
    _ = try await relaunched.draft(for: testMoment(name: "Sam"))

    #expect(await firstClient.idempotencyKeys.first == relaunchedClient.idempotencyKeys.first)
    #expect(persistence.load() == nil)
}

@Test
func replayExpiryClearsKeyWithoutAutomaticallyRetrying() async throws {
    let cardClient = SequencedCardClient(results: [
        .failure(.requestNeedsFreshKey(message: "Earlier draft expired.")),
        .success(successfulCardResponse)
    ])
    let client = GatewayCarefulMomentClient(
        client: cardClient,
        clientContext: testClientContext,
        requestKeyStore: CarefulRequestKeyStore()
    )
    let moment = testMoment(name: "Sam")

    await #expect(throws: GenerationError.self) {
        _ = try await client.draft(for: moment)
    }
    #expect(await cardClient.idempotencyKeys.count == 1)

    _ = try await client.draft(for: moment)
    let keys = await cardClient.idempotencyKeys
    #expect(keys.count == 2)
    #expect(keys[0] != keys[1])
}

private let testClientContext = ClientContext(appVersion: "1.0", buildNumber: "1")

private let successfulCardResponse = CardResponse(
    messages: [GeneratedMessage(id: "one", text: "A careful message.")],
    laneUsed: .standard,
    fallbackStatus: .none,
    retryEligibility: .ineligible
)

private func testMoment(name: String) -> MomentInput {
    MomentInput(
        personName: name,
        relationship: .family,
        occasion: .sympathy,
        trueThing: "You have been on my mind."
    )
}

private actor SequencedCardClient: MessageWritingClient {
    private var results: [Result<CardResponse, GenerationError>]
    private(set) var idempotencyKeys: [String] = []

    init(results: [Result<CardResponse, GenerationError>]) {
        self.results = results
    }

    func generateCard(request: CardRequest) async throws -> CardResponse {
        idempotencyKeys.append(request.idempotencyKey)
        guard !results.isEmpty else {
            throw GenerationError.serviceUnavailable(message: "No result queued.")
        }
        return try results.removeFirst().get()
    }
}
