import Foundation
import Testing
@testable import ProsePalDomain

// MARK: - Environment resolution and isolation

@Test
func environmentResolvesStagingFromBundlePrefix() {
    #expect(MomentHandoffEnvironment.resolve(bundleIdentifier: "com.prosepal.prosepal") == .production)
    #expect(MomentHandoffEnvironment.resolve(bundleIdentifier: "com.prosepal.prosepal.staging") == .staging)
    #expect(MomentHandoffEnvironment.resolve(bundleIdentifier: "com.prosepal.prosepal.staging.widgets") == .staging)
    #expect(MomentHandoffEnvironment.resolve(bundleIdentifier: nil) == .production)
}

@Test
func productionAndStagingUseDistinctSchemesAndStorageKeys() {
    #expect(MomentHandoffEnvironment.production.urlScheme == "prosepal")
    #expect(MomentHandoffEnvironment.staging.urlScheme == "prosepal-staging")
    #expect(MomentHandoffEnvironment.production.sharedPayloadKey
        != MomentHandoffEnvironment.staging.sharedPayloadKey)
    // Both environments share one app-group container; isolation is by key.
    #expect(MomentHandoffEnvironment.production.appGroupIdentifier
        == MomentHandoffEnvironment.staging.appGroupIdentifier)
}

@Test
func stagingAndProductionSharedStoresDoNotReadEachOther() throws {
    let suiteName = "prosepal.handoff.isolation.\(UUID().uuidString)"
    let store = try #require(UserDefaults(suiteName: suiteName))
    defer { store.removePersistentDomain(forName: suiteName) }

    let production = SharedMomentLaunchStore(
        store: store,
        key: MomentHandoffEnvironment.production.sharedPayloadKey
    )
    let staging = SharedMomentLaunchStore(
        store: store,
        key: MomentHandoffEnvironment.staging.sharedPayloadKey
    )

    staging.save(SharedMomentLaunchPayload(text: "Staging-only note"))

    // The production reader must not see the staging payload even though both
    // point at the same app-group container.
    #expect(production.consume() == nil)
    #expect(staging.consume()?.text == "Staging-only note")
}

// MARK: - Payload encode/decode, sanitisation, limits

@Test
func sharedPayloadEncodesAndDecodesRoundTrip() throws {
    let payload = SharedMomentLaunchPayload(
        text: "A note to answer carefully.",
        sourceURL: URL(string: "https://example.com/thread")
    )
    let data = try JSONEncoder().encode(payload)
    let decoded = try JSONDecoder().decode(SharedMomentLaunchPayload.self, from: data)

    #expect(decoded == payload)
    #expect(decoded.text == "A note to answer carefully.")
    #expect(decoded.sourceURL == URL(string: "https://example.com/thread"))
}

@Test
func sharedPayloadTrimsAndCapsTextToMomentDetailLimit() {
    let overLimit = String(repeating: "a", count: SharedMomentLaunchPayload.maxTextCharacterCount + 50)
    let payload = SharedMomentLaunchPayload(text: "  \(overLimit)  ")

    #expect(SharedMomentLaunchPayload.maxTextCharacterCount == ProsePalTextLimit.momentDetail)
    #expect(payload.text?.count == SharedMomentLaunchPayload.maxTextCharacterCount)
    #expect(payload.hasMomentContext)
}

@Test
func sharedPayloadTreatsBlankTextAsNoContext() {
    let payload = SharedMomentLaunchPayload(text: "   \n  ")
    #expect(payload.text == nil)
    #expect(!payload.hasMomentContext)
}

@Test
func sharedStoreRejectsPayloadWithoutMomentContext() throws {
    let suiteName = "prosepal.handoff.empty.\(UUID().uuidString)"
    let store = try #require(UserDefaults(suiteName: suiteName))
    defer { store.removePersistentDomain(forName: suiteName) }

    let launchStore = SharedMomentLaunchStore(store: store, key: "k")
    #expect(launchStore.save(SharedMomentLaunchPayload(text: nil)) == false)
    #expect(launchStore.consume() == nil)
}

@Test
func sharedStoreIgnoresMalformedStoredData() throws {
    let suiteName = "prosepal.handoff.malformed.\(UUID().uuidString)"
    let store = try #require(UserDefaults(suiteName: suiteName))
    defer { store.removePersistentDomain(forName: suiteName) }

    let key = "k"
    store.set(Data("not a payload".utf8), forKey: key)

    let launchStore = SharedMomentLaunchStore(store: store, key: key)
    #expect(launchStore.consume() == nil)
}

// MARK: - Consume-once

@Test
func sharedStoreConsumesPayloadExactlyOnce() throws {
    let suiteName = "prosepal.handoff.once.\(UUID().uuidString)"
    let store = try #require(UserDefaults(suiteName: suiteName))
    defer { store.removePersistentDomain(forName: suiteName) }

    let launchStore = SharedMomentLaunchStore(store: store, key: "k")
    launchStore.save(SharedMomentLaunchPayload(text: "Once only"))

    #expect(launchStore.consume()?.text == "Once only")
    #expect(launchStore.consume() == nil)
}

@Test
func momentLaunchStoreConsumesRequestExactlyOnce() throws {
    let suiteName = "prosepal.handoff.launch.\(UUID().uuidString)"
    let store = try #require(UserDefaults(suiteName: suiteName))
    defer { store.removePersistentDomain(forName: suiteName) }

    let launchStore = MomentLaunchStore(store: store, key: "k")
    launchStore.save(MomentLaunchRequest(personName: "Alex", source: MomentLaunchSource.appIntent))

    #expect(launchStore.consume()?.personName == "Alex")
    #expect(launchStore.consume() == nil)
}

// MARK: - URL routing (both schemes, source allowlist)

@Test
func deepLinkAcceptsBothProductionAndStagingSchemes() throws {
    let productionURL = try #require(URL(string: "prosepal://moment?source=widget"))
    let stagingURL = try #require(URL(string: "prosepal-staging://moment?source=widget"))
    let production = try #require(MomentDeepLink(url: productionURL))
    let staging = try #require(MomentDeepLink(url: stagingURL))

    #expect(production.launchRequest.source == MomentLaunchSource.widget)
    #expect(staging.launchRequest.source == MomentLaunchSource.widget)
}

@Test
func deepLinkRejectsUnknownSchemesAndHosts() throws {
    let wrongScheme = try #require(URL(string: "https://moment?source=widget"))
    let wrongHost = try #require(URL(string: "prosepal://settings?person=Alex"))
    #expect(MomentDeepLink(url: wrongScheme) == nil)
    #expect(MomentDeepLink(url: wrongHost) == nil)
}

@Test
func deepLinkNormalisesUntrustedSourceToDeepLink() throws {
    let url = try #require(URL(string: "prosepal://moment?person=Alex&source=Arbitrary%20text"))
    let deepLink = try #require(MomentDeepLink(url: url))
    #expect(deepLink.launchRequest.source == MomentLaunchSource.deepLink)
}

@Test
func momentURLBuilderEncodesSchemeAndAllowlistedSource() throws {
    let production = try #require(MomentDeepLink.momentURL(
        source: MomentLaunchSource.widget,
        environment: .production
    ))
    let staging = try #require(MomentDeepLink.momentURL(
        source: MomentLaunchSource.controlCenter,
        environment: .staging
    ))

    #expect(production.scheme == "prosepal")
    #expect(production.absoluteString == "prosepal://moment?source=widget")
    #expect(staging.scheme == "prosepal-staging")
    #expect(staging.absoluteString == "prosepal-staging://moment?source=control_center")
}

@Test
func momentURLBuilderRefusesToEmitUntrustedSource() throws {
    let url = try #require(MomentDeepLink.momentURL(source: "leaked raw text", environment: .production))
    // An unrecognised source collapses to the deep_link marker; raw text is
    // never placed in the outgoing URL.
    #expect(url.absoluteString == "prosepal://moment?source=deep_link")
}

@Test
func sourceAllowlistRejectsUnknownValues() {
    #expect(MomentLaunchSource.sanitized("widget") == "widget")
    #expect(MomentLaunchSource.sanitized("  app_intent  ") == "app_intent")
    #expect(MomentLaunchSource.sanitized("private raw text") == nil)
    #expect(MomentLaunchSource.sanitized(nil) == nil)
}

// MARK: - Launch request sanitisation

@Test
func launchRequestNormalisesPersonSharedTextAndSource() {
    let request = MomentLaunchRequest(
        personName: "  Alex  ",
        occasion: .birthday,
        sharedText: "  I miss our Sunday calls.  ",
        source: "  app_intent  "
    )

    #expect(request.personName == "Alex")
    #expect(request.occasion == .birthday)
    #expect(request.sharedText == "I miss our Sunday calls.")
    #expect(request.source == "app_intent")
}

@Test
func launchRequestCapsPersonAndSharedTextToDomainLimits() {
    let request = MomentLaunchRequest(
        personName: "Alex\nMorgan " + String(repeating: "x", count: 100),
        sharedText: String(repeating: "🙂", count: ProsePalTextLimit.momentDetail + 20),
        source: MomentLaunchSource.shareExtension
    )

    #expect(request.personName?.count == ProsePalTextLimit.personName)
    #expect(request.personName?.hasPrefix("Alex Morgan") == true)
    #expect(request.sharedText?.count == ProsePalTextLimit.momentDetail)
}

@Test
func occasionFromLaunchParameterMatchesRawAndDisplayNamesButNotUnknownText() {
    #expect(Occasion.fromLaunchParameter("petSympathy") == .petSympathy)
    #expect(Occasion.fromLaunchParameter("Thank You") == .thankYou)
    #expect(Occasion.fromLaunchParameter("Private raw text") == nil)
    #expect(Occasion.fromLaunchParameter(nil) == nil)
}
