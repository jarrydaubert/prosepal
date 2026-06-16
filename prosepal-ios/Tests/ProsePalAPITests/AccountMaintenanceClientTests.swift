import XCTest
import ProsePalAPI

final class AccountMaintenanceClientTests: XCTestCase {
    override func tearDown() {
        AccountMaintenanceCapturingURLProtocol.requestHandler = nil
        super.tearDown()
    }

    func testDeleteAccountPostsToDeleteUserFunctionWithBearerToken() async throws {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [AccountMaintenanceCapturingURLProtocol.self]
        let session = URLSession(configuration: configuration)
        let client = SupabaseAccountMaintenanceClient(
            projectURL: try XCTUnwrap(URL(string: "https://project.supabase.co")),
            anonKey: " anon-key ",
            session: session
        )

        AccountMaintenanceCapturingURLProtocol.requestHandler = { request in
            XCTAssertEqual(request.httpMethod, "POST")
            XCTAssertEqual(request.url?.absoluteString, "https://project.supabase.co/functions/v1/delete-user")
            XCTAssertEqual(request.value(forHTTPHeaderField: "Accept"), "application/json")
            XCTAssertEqual(request.value(forHTTPHeaderField: "apikey"), "anon-key")
            XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer supabase-access-token")

            let response = HTTPURLResponse(
                url: try XCTUnwrap(request.url),
                statusCode: 200,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            return (response, Data(#"{"success":true}"#.utf8))
        }

        try await client.deleteAccount(accessToken: " supabase-access-token ")
    }

    func testDeleteAccountRequiresAccessToken() async throws {
        let client = SupabaseAccountMaintenanceClient(
            projectURL: try XCTUnwrap(URL(string: "https://project.supabase.co")),
            anonKey: "anon-key"
        )

        do {
            try await client.deleteAccount(accessToken: "   ")
            XCTFail("Expected blank access token to fail.")
        } catch AccountMaintenanceError.authenticationRequired {
            // Expected.
        } catch {
            XCTFail("Expected authenticationRequired, got \(error).")
        }
    }

    func testDeleteAccountUsesServerSafeErrorMessage() async throws {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [AccountMaintenanceCapturingURLProtocol.self]
        let session = URLSession(configuration: configuration)
        let client = SupabaseAccountMaintenanceClient(
            projectURL: try XCTUnwrap(URL(string: "https://project.supabase.co")),
            anonKey: "anon-key",
            session: session
        )

        AccountMaintenanceCapturingURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: try XCTUnwrap(request.url),
                statusCode: 500,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            return (response, Data(#"{"error":"Connection error. Please try again."}"#.utf8))
        }

        do {
            try await client.deleteAccount(accessToken: "supabase-access-token")
            XCTFail("Expected delete-user failure.")
        } catch AccountMaintenanceError.requestFailed(let statusCode, let message) {
            XCTAssertEqual(statusCode, 500)
            XCTAssertEqual(message, "Connection error. Please try again.")
        } catch {
            XCTFail("Expected requestFailed, got \(error).")
        }
    }
}

private final class AccountMaintenanceCapturingURLProtocol: URLProtocol {
    typealias Handler = (URLRequest) throws -> (HTTPURLResponse, Data)
    nonisolated(unsafe) static var requestHandler: Handler?

    override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        guard let handler = Self.requestHandler else {
            client?.urlProtocol(self, didFailWithError: URLError(.badServerResponse))
            return
        }

        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}
