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

private final class InMemoryBearerTokenStore: BearerTokenStoring, @unchecked Sendable {
    var storedToken: String?

    func token() throws -> String? {
        storedToken
    }

    func save(_ token: String) throws {
        storedToken = token
    }

    func clear() throws {
        storedToken = nil
    }
}

final class DogSwipeSmokeTests: XCTestCase {
    func testRootViewCanBeCreated() {
        _ = RootView(tokenStore: InMemoryBearerTokenStore())
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

    @MainActor
    func testAuthSessionStoreTrimsAndClearsBearerToken() {
        let tokenStore = InMemoryBearerTokenStore()
        let store = AuthSessionStore(tokenStore: tokenStore)

        store.save(" jwt-token ")

        XCTAssertEqual(store.bearerToken, "jwt-token")
        XCTAssertEqual(tokenStore.storedToken, "jwt-token")

        store.signOut()

        XCTAssertFalse(store.hasBearerToken)
        XCTAssertNil(tokenStore.storedToken)
    }

    func testAppEnvironmentUsesTokenStoreForAuthenticatedClient() async throws {
        let tokenStore = InMemoryBearerTokenStore()
        tokenStore.storedToken = " session-jwt "
        let http = MockPreferencesHTTPClient()
        http.responses = [#"{"profiles":[]}"#.data(using: .utf8)!]
        let client = AppEnvironment.apiClient(tokenStore: tokenStore, httpClient: http)

        _ = try await client.discovery()

        XCTAssertEqual(
            http.requests.first?.value(forHTTPHeaderField: "Authorization"),
            "Bearer session-jwt"
        )
    }
}
