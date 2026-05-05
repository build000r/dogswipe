import Foundation
import XCTest
@testable import DogSwipeCore

private final class MockHTTPClient: DogSwipeHTTPClient, @unchecked Sendable {
    var requests: [URLRequest] = []
    var nextStatusCode = 200
    var nextData = Data()

    func data(for request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        requests.append(request)
        let response = HTTPURLResponse(
            url: request.url!,
            statusCode: nextStatusCode,
            httpVersion: nil,
            headerFields: nil
        )!
        return (nextData, response)
    }
}

final class DogSwipeAPIClientTests: XCTestCase {
    func testDiscoveryDecodesSnakeCaseResponse() async throws {
        let http = MockHTTPClient()
        http.nextData = """
        {
          "profiles": [
            {
              "id": "hotdog-coney",
              "name": "Coney Classic",
              "style": "Chili dog",
              "price_dollars": 6.5,
              "signature_notes": "Beef frank, snap casing, chili, onion, and yellow mustard.",
              "distance_miles": 1.2,
              "vendor_name": "Franklin Cart",
              "image_url": null,
              "crave_score": 0.91,
              "availability_status": "available"
            }
          ]
        }
        """.data(using: .utf8)!
        let client = DogSwipeAPIClient(baseURL: URL(string: "http://localhost:8000")!, httpClient: http)

        let profiles = try await client.discovery(limit: 10)

        XCTAssertEqual(profiles.map(\.id), ["hotdog-coney"])
        XCTAssertEqual(profiles.first?.priceLabel, "$6.50")
        XCTAssertEqual(profiles.first?.vendorName, "Franklin Cart")
        XCTAssertEqual(http.requests.first?.url?.path, "/v1/discovery")
        XCTAssertEqual(http.requests.first?.url?.query, "limit=10")
    }

    func testSwipeEncodesBackendContract() async throws {
        let http = MockHTTPClient()
        http.nextData = """
        {"profile_id":"hotdog-coney","decision":"super_like","matched":true}
        """.data(using: .utf8)!
        let client = DogSwipeAPIClient(baseURL: URL(string: "http://localhost:8000")!, httpClient: http)

        let response = try await client.swipe(
            profileID: "hotdog-coney",
            decision: .superLike
        )

        XCTAssertEqual(response, SwipeResponse(profileID: "hotdog-coney", decision: .superLike, matched: true))
        XCTAssertEqual(http.requests.first?.httpMethod, "POST")
        let body = String(data: http.requests.first!.httpBody!, encoding: .utf8)!
        XCTAssertFalse(body.contains("user_id"))
        XCTAssertTrue(body.contains("\"profile_id\":\"hotdog-coney\""))
        XCTAssertTrue(body.contains("\"decision\":\"super_like\""))
    }

    func testMatchesUsesAuthenticatedPrincipalEndpoint() async throws {
        let http = MockHTTPClient()
        http.nextData = #"{"matches":[]}"#.data(using: .utf8)!
        let client = DogSwipeAPIClient(baseURL: URL(string: "http://localhost:8000")!, httpClient: http)

        let matches = try await client.matches()

        XCTAssertTrue(matches.isEmpty)
        XCTAssertEqual(http.requests.first?.url?.path, "/v1/matches")
        XCTAssertNil(http.requests.first?.url?.query)
    }

    func testPreferencesDecodeBackendContract() async throws {
        let http = MockHTTPClient()
        http.nextData = """
        {"max_distance_miles":7,"spicy_friendly":false,"classic_only":true}
        """.data(using: .utf8)!
        let client = DogSwipeAPIClient(baseURL: URL(string: "http://localhost:8000")!, httpClient: http)

        let preferences = try await client.preferences()

        XCTAssertEqual(
            preferences,
            DiscoveryPreferences(maxDistanceMiles: 7, spicyFriendly: false, classicOnly: true)
        )
        XCTAssertEqual(http.requests.first?.url?.path, "/v1/preferences")
        XCTAssertEqual(http.requests.first?.httpMethod, "GET")
    }

    func testUpdatePreferencesEncodesBackendContract() async throws {
        let http = MockHTTPClient()
        http.nextData = """
        {"max_distance_miles":12,"spicy_friendly":true,"classic_only":false}
        """.data(using: .utf8)!
        let client = DogSwipeAPIClient(baseURL: URL(string: "http://localhost:8000")!, httpClient: http)

        let response = try await client.updatePreferences(
            DiscoveryPreferences(maxDistanceMiles: 12, spicyFriendly: true, classicOnly: false)
        )

        XCTAssertEqual(
            response,
            DiscoveryPreferences(maxDistanceMiles: 12, spicyFriendly: true, classicOnly: false)
        )
        XCTAssertEqual(http.requests.first?.url?.path, "/v1/preferences")
        XCTAssertEqual(http.requests.first?.httpMethod, "PUT")
        let body = String(data: http.requests.first!.httpBody!, encoding: .utf8)!
        XCTAssertFalse(body.contains("user_id"))
        XCTAssertTrue(body.contains("\"max_distance_miles\":12"))
        XCTAssertTrue(body.contains("\"spicy_friendly\":true"))
        XCTAssertTrue(body.contains("\"classic_only\":false"))
    }

    func testAddsBearerTokenWhenProviderReturnsToken() async throws {
        let http = MockHTTPClient()
        http.nextData = #"{"profiles":[]}"#.data(using: .utf8)!
        let client = DogSwipeAPIClient(
            baseURL: URL(string: "http://localhost:8000")!,
            httpClient: http,
            authorizationTokenProvider: { " spaps-token " }
        )

        _ = try await client.discovery()

        XCTAssertEqual(
            http.requests.first?.value(forHTTPHeaderField: "Authorization"),
            "Bearer spaps-token"
        )
    }

    func testOmitsAuthorizationHeaderWhenProviderReturnsBlankToken() async throws {
        let http = MockHTTPClient()
        http.nextData = #"{"profiles":[]}"#.data(using: .utf8)!
        let client = DogSwipeAPIClient(
            baseURL: URL(string: "http://localhost:8000")!,
            httpClient: http,
            authorizationTokenProvider: { " " }
        )

        _ = try await client.discovery()

        XCTAssertNil(http.requests.first?.value(forHTTPHeaderField: "Authorization"))
    }

    func testNonSuccessStatusThrowsAPIError() async {
        let http = MockHTTPClient()
        http.nextStatusCode = 503
        http.nextData = Data()
        let client = DogSwipeAPIClient(baseURL: URL(string: "http://localhost:8000")!, httpClient: http)

        do {
            _ = try await client.discovery()
            XCTFail("Expected request to throw")
        } catch let error as DogSwipeAPIError {
            XCTAssertEqual(error, .invalidResponseStatus(503))
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
}
