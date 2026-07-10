import XCTest
@testable import ProsePalAPI

final class NativeRuntimeConfigTests: XCTestCase {
    func testEnvironmentValuesTakePrecedenceAndAreTrimmed() {
        let config = NativeRuntimeConfig(
            environment: [
                "PROSEPAL_GATEWAY_URL": " https://env.example/functions/v1/generate-card "
            ],
            infoDictionary: [
                "PROSEPAL_GATEWAY_URL": "https://plist.example/functions/v1/generate-card"
            ]
        )

        XCTAssertEqual(
            config.value(named: "PROSEPAL_GATEWAY_URL"),
            "https://env.example/functions/v1/generate-card"
        )
    }

    func testBlankEnvironmentFallsBackToInfoDictionary() {
        let config = NativeRuntimeConfig(
            environment: [
                "PROSEPAL_SUPABASE_URL": "  "
            ],
            infoDictionary: [
                "PROSEPAL_SUPABASE_URL": "https://project-ref.supabase.co"
            ]
        )

        XCTAssertEqual(
            config.url(named: "PROSEPAL_SUPABASE_URL"),
            URL(string: "https://project-ref.supabase.co")
        )
    }

    func testFallbackKeyReadsLegacyEnvironmentName() {
        let config = NativeRuntimeConfig(
            environment: [
                "SUPABASE_ANON_KEY": "anon-key"
            ],
            infoDictionary: [:]
        )

        XCTAssertEqual(
            config.value(named: "PROSEPAL_SUPABASE_ANON_KEY", fallback: "SUPABASE_ANON_KEY"),
            "anon-key"
        )
    }

    func testListSplitsTrimsAndDeduplicatesProductIDs() {
        let config = NativeRuntimeConfig(
            environment: [
                "PROSEPAL_PREMIUM_PRODUCT_IDS": " yearly, monthly\n yearly  lifetime "
            ],
            infoDictionary: [:]
        )

        XCTAssertEqual(
            config.list(named: "PROSEPAL_PREMIUM_PRODUCT_IDS"),
            ["yearly", "monthly", "lifetime"]
        )
    }

    func testInvalidURLReturnsNil() {
        let config = NativeRuntimeConfig(
            environment: [
                "PROSEPAL_GATEWAY_URL": "not a url"
            ],
            infoDictionary: [:]
        )

        XCTAssertNil(config.url(named: "PROSEPAL_GATEWAY_URL"))
    }

    func testProductionRuntimeRejectsInsecureRemoteAndLoopbackURLs() {
        let remote = NativeRuntimeConfig(
            environment: ["URL": "http://example.com/service"],
            infoDictionary: [:]
        )
        let loopback = NativeRuntimeConfig(
            environment: ["URL": "http://127.0.0.1:54321/service"],
            infoDictionary: [:]
        )

        XCTAssertNil(remote.url(named: "URL"))
        XCTAssertNil(loopback.url(named: "URL"))
    }

    func testExplicitDebugPolicyAllowsOnlyInsecureLoopbackURLs() {
        let loopback = NativeRuntimeConfig(
            environment: ["URL": "http://localhost:54321/service"],
            infoDictionary: [:],
            allowsInsecureLoopback: true
        )
        let remote = NativeRuntimeConfig(
            environment: ["URL": "http://example.com/service"],
            infoDictionary: [:],
            allowsInsecureLoopback: true
        )

        XCTAssertEqual(loopback.url(named: "URL"), URL(string: "http://localhost:54321/service"))
        XCTAssertNil(remote.url(named: "URL"))
    }
}
