import DogSwipeCore
import XCTest
@testable import DogSwipe

private final class MockPreferencesHTTPClient: DogSwipeHTTPClient, @unchecked Sendable {
    var requests: [URLRequest] = []
    var responses: [Data] = []

    func data(for request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        requests.append(request)
        let response = HTTPURLResponse(
            url: request.url!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )!
        return (responses.isEmpty ? Data() : responses.removeFirst(), response)
    }
}

final class DogSwipeSmokeTests: XCTestCase {
    func testRootViewCanBeCreated() {
        _ = RootView()
    }

    func testCravingPreferencesStoreBuildsDiscoveryPreferences() {
        let store = CravingPreferencesStore(
            spicyFriendly: false,
            classicOnly: true,
            maxDistanceMiles: 7
        )

        let preferences = store.preferences

        XCTAssertFalse(preferences.spicyFriendly)
        XCTAssertTrue(preferences.classicOnly)
        XCTAssertEqual(preferences.maxDistanceMiles, 7)
    }

    @MainActor
    func testCravingPreferencesStoreLoadsAndSavesViaAPI() async throws {
        let http = MockPreferencesHTTPClient()
        http.responses = [
            #"{"max_distance_miles":8,"spicy_friendly":false,"classic_only":true}"#
                .data(using: .utf8)!,
            #"{"max_distance_miles":9,"spicy_friendly":false,"classic_only":true}"#
                .data(using: .utf8)!
        ]
        let apiClient = DogSwipeAPIClient(
            baseURL: URL(string: "http://localhost:8000")!,
            httpClient: http
        )
        let store = CravingPreferencesStore(apiClient: apiClient)

        await store.load()
        store.maxDistanceMiles = 9
        await store.save()

        XCTAssertEqual(store.preferences.maxDistanceMiles, 9)
        XCTAssertEqual(http.requests.map(\.httpMethod), ["GET", "PUT"])
        let body = String(data: http.requests.last!.httpBody!, encoding: .utf8)!
        XCTAssertTrue(body.contains("\"max_distance_miles\":9"))
        XCTAssertFalse(body.contains("user_id"))
    }
}
