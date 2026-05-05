import DogSwipeCore
import Foundation
import XCTest
@testable import DogSwipe

private final class MockHTTPClient: DogSwipeHTTPClient, @unchecked Sendable {
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
        _ = RootView(
            accessTokenStore: InMemoryBearerTokenStore(),
            refreshTokenStore: InMemoryBearerTokenStore(),
            authClient: makeAuthClient(http: MockHTTPClient())
        )
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
        let http = MockHTTPClient()
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
        let accessStore = InMemoryBearerTokenStore()
        let refreshStore = InMemoryBearerTokenStore()
        refreshStore.storedToken = "old-refresh"
        let store = AuthSessionStore(
            accessTokenStore: accessStore,
            refreshTokenStore: refreshStore,
            authClient: makeAuthClient(http: MockHTTPClient())
        )

        store.save(" jwt-token ")

        XCTAssertEqual(store.bearerToken, "jwt-token")
        XCTAssertEqual(accessStore.storedToken, "jwt-token")
        XCTAssertFalse(store.hasRefreshToken)
        XCTAssertNil(refreshStore.storedToken)

        store.signOut()

        XCTAssertFalse(store.hasBearerToken)
        XCTAssertNil(accessStore.storedToken)
    }

    func testAppEnvironmentUsesTokenStoreForAuthenticatedClient() async throws {
        let tokenStore = InMemoryBearerTokenStore()
        tokenStore.storedToken = " session-jwt "
        let http = MockHTTPClient()
        http.responses = [#"{"profiles":[]}"#.data(using: .utf8)!]
        let client = AppEnvironment.apiClient(tokenStore: tokenStore, httpClient: http)

        _ = try await client.discovery()

        XCTAssertEqual(
            http.requests.first?.value(forHTTPHeaderField: "Authorization"),
            "Bearer session-jwt"
        )
    }

    @MainActor
    func testVendorSubmissionStoreSubmitsDraftViaAPI() async throws {
        let http = MockHTTPClient()
        http.responses = [
            try encodedVendorSubmissionResponse()
        ]
        let apiClient = DogSwipeAPIClient(
            baseURL: URL(string: "http://localhost:8000")!,
            httpClient: http
        )
        let store = VendorSubmissionStore(apiClient: apiClient)
        store.name = " Boardwalk Snap "
        store.style = "Classic cart dog"
        store.price = "6.25"
        store.signatureNotes = "Mustard, relish, and onion."
        store.distance = "1.8"
        store.vendorName = "Boardwalk Dogs"
        store.imageURL = "https://cdn.example.com/boardwalk.jpg"
        store.menuURL = "https://boardwalk.example.com/menu"
        store.mediaAltText = "Classic hotdog on a paper tray"

        await store.submit()

        XCTAssertEqual(store.submissions.map(\.name), ["Boardwalk Snap"])
        XCTAssertEqual(store.submissions.first?.availabilityStatus, .pendingReview)
        XCTAssertEqual(store.message, "Submitted for review.")
        let request = try XCTUnwrap(http.requests.first)
        XCTAssertEqual(request.url?.path, "/v1/vendor/submissions")
        XCTAssertEqual(request.httpMethod, "POST")
        let body = try jsonBody(request)
        XCTAssertEqual(body["name"] as? String, "Boardwalk Snap")
        XCTAssertEqual(body["price_dollars"] as? Double, 6.25)
        XCTAssertEqual(body["menu_url"] as? String, "https://boardwalk.example.com/menu")
        XCTAssertNil(body["user_id"])
    }

    @MainActor
    func testAdminReviewStoreApprovesPendingSubmission() async throws {
        let http = MockHTTPClient()
        let pending = HotdogProfile(
            id: "pending-hotdog",
            name: "Pending Snap",
            style: "Classic cart dog",
            priceDollars: 6.25,
            signatureNotes: "Mustard, relish, and onion.",
            distanceMiles: 1.8,
            vendorName: "Boardwalk Dogs",
            craveScore: 0.5,
            availabilityStatus: .pendingReview
        )
        let approved = HotdogProfile(
            id: pending.id,
            name: pending.name,
            style: pending.style,
            priceDollars: pending.priceDollars,
            signatureNotes: pending.signatureNotes,
            distanceMiles: pending.distanceMiles,
            vendorName: pending.vendorName,
            craveScore: 0.72,
            availabilityStatus: .available
        )
        http.responses = [
            try JSONEncoder().encode(AdminReviewQueueResponse(submissions: [pending])),
            try JSONEncoder().encode(AdminApprovalResponse(profile: approved))
        ]
        let apiClient = DogSwipeAPIClient(
            baseURL: URL(string: "http://localhost:8000")!,
            httpClient: http
        )
        let store = AdminReviewStore(apiClient: apiClient)

        await store.load()
        await store.approve(pending)

        XCTAssertTrue(store.pendingSubmissions.isEmpty)
        XCTAssertEqual(store.reviewMessage, "Pending Snap approved.")
        XCTAssertEqual(http.requests.map { $0.url?.path }, [
            "/v1/admin/vendor/submissions",
            "/v1/admin/vendor/submissions/pending-hotdog/approve"
        ])
        let body = try jsonBody(http.requests.last!)
        XCTAssertEqual(body["crave_score"] as? Double, 0.72)
    }

    func testSPAPSAuthClientRequestsMagicLinkWithPublishableKey() async throws {
        let http = MockHTTPClient()
        let client = makeAuthClient(http: http)

        try await client.requestMagicLink(
            email: "fan@example.com",
            redirectURL: URL(string: "dogswipe://auth")!
        )

        let request = try XCTUnwrap(http.requests.first)
        XCTAssertEqual(request.url?.path, "/api/auth/magic-link")
        XCTAssertEqual(request.httpMethod, "POST")
        XCTAssertEqual(request.value(forHTTPHeaderField: "X-API-Key"), "spaps_pub_test")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Origin"), "https://dogswipe.test")
        XCTAssertNil(request.value(forHTTPHeaderField: "Authorization"))
        let body = try jsonBody(request)
        XCTAssertEqual(body["email"] as? String, "fan@example.com")
        XCTAssertEqual(body["redirect_url"] as? String, "dogswipe://auth")
    }

    @MainActor
    func testAuthSessionStoreVerifiesMagicLinkAndStoresSessionTokens() async throws {
        let accessStore = InMemoryBearerTokenStore()
        let refreshStore = InMemoryBearerTokenStore()
        let http = MockHTTPClient()
        http.responses = [
            #"""
            {
              "success": true,
              "data": {
                "tokens": {
                  "access_token": "access-jwt",
                  "refresh_token": "refresh-jwt"
                },
                "user": {
                  "email": "fan@example.com"
                }
              }
            }
            """#.data(using: .utf8)!
        ]
        let store = AuthSessionStore(
            accessTokenStore: accessStore,
            refreshTokenStore: refreshStore,
            authClient: makeAuthClient(http: http)
        )

        await store.verifyMagicLink(token: " token-from-email ")

        XCTAssertEqual(store.bearerToken, "access-jwt")
        XCTAssertEqual(store.sessionEmail, "fan@example.com")
        XCTAssertTrue(store.hasRefreshToken)
        XCTAssertEqual(accessStore.storedToken, "access-jwt")
        XCTAssertEqual(refreshStore.storedToken, "refresh-jwt")
        let request = try XCTUnwrap(http.requests.first)
        XCTAssertEqual(request.url?.path, "/api/auth/verify-magic-link")
        let body = try jsonBody(request)
        XCTAssertEqual(body["token"] as? String, "token-from-email")
        XCTAssertEqual(body["type"] as? String, "magiclink")
    }

    @MainActor
    func testAuthSessionStoreRefreshesStoredSession() async throws {
        let accessStore = InMemoryBearerTokenStore()
        let refreshStore = InMemoryBearerTokenStore()
        refreshStore.storedToken = "refresh-jwt"
        let http = MockHTTPClient()
        http.responses = [
            #"""
            {
              "success": true,
              "data": {
                "access_token": "next-access-jwt",
                "refresh_token": "next-refresh-jwt",
                "user": {
                  "email": "fan@example.com"
                }
              }
            }
            """#.data(using: .utf8)!
        ]
        let store = AuthSessionStore(
            accessTokenStore: accessStore,
            refreshTokenStore: refreshStore,
            authClient: makeAuthClient(http: http)
        )

        await store.refreshSession()

        XCTAssertEqual(store.bearerToken, "next-access-jwt")
        XCTAssertEqual(store.sessionEmail, "fan@example.com")
        XCTAssertTrue(store.hasRefreshToken)
        XCTAssertEqual(accessStore.storedToken, "next-access-jwt")
        XCTAssertEqual(refreshStore.storedToken, "next-refresh-jwt")
        let request = try XCTUnwrap(http.requests.first)
        XCTAssertEqual(request.url?.path, "/api/auth/refresh")
        let body = try jsonBody(request)
        XCTAssertEqual(body["refresh_token"] as? String, "refresh-jwt")
    }

    func testSPAPSAuthClientRejectsMissingPublishableKey() async {
        let client = SPAPSAuthClient(
            baseURL: URL(string: "https://auth.dogswipe.test")!,
            publishableKey: " ",
            httpClient: MockHTTPClient()
        )

        do {
            try await client.requestMagicLink(email: "fan@example.com")
            XCTFail("Expected missing publishable key error.")
        } catch SPAPSAuthError.missingPublishableKey {
            return
        } catch {
            XCTFail("Expected missing publishable key error, got \(error).")
        }
    }

    private func makeAuthClient(http: MockHTTPClient) -> SPAPSAuthClient {
        SPAPSAuthClient(
            baseURL: URL(string: "https://auth.dogswipe.test")!,
            publishableKey: "spaps_pub_test",
            origin: "https://dogswipe.test",
            httpClient: http
        )
    }

    private func encodedVendorSubmissionResponse() throws -> Data {
        try JSONEncoder().encode(
            VendorSubmissionResponse(
                profile: HotdogProfile(
                    id: "submitted-hotdog",
                    name: "Boardwalk Snap",
                    style: "Classic cart dog",
                    priceDollars: 6.25,
                    signatureNotes: "Mustard, relish, and onion.",
                    distanceMiles: 1.8,
                    vendorName: "Boardwalk Dogs",
                    imageURL: URL(string: "https://cdn.example.com/boardwalk.jpg"),
                    menuURL: URL(string: "https://boardwalk.example.com/menu"),
                    mediaAltText: "Classic hotdog on a paper tray",
                    craveScore: 0.5,
                    availabilityStatus: .pendingReview
                )
            )
        )
    }

    private func jsonBody(
        _ request: URLRequest,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws -> [String: Any] {
        let data = try XCTUnwrap(request.httpBody, file: file, line: line)
        return try XCTUnwrap(
            JSONSerialization.jsonObject(with: data) as? [String: Any],
            file: file,
            line: line
        )
    }
}
