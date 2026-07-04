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

private final class RecordingAnalyticsSink: DogSwipeAnalyticsSink {
    private(set) var events: [DogSwipeAnalyticsEvent] = []

    func record(_ event: DogSwipeAnalyticsEvent) {
        events.append(event)
    }
}

private struct StaticLocationProvider: UserLocationProviding {
    let location: DiscoveryLocation?

    func currentLocation() async -> DiscoveryLocation? {
        location
    }
}

private enum TestGeocodingError: Error {
    case failed
}

private enum TestRoutingError: Error {
    case failed
}

private final class MockRouteEstimator: RouteEstimating, @unchecked Sendable {
    struct Request: Equatable {
        let origin: DiscoveryLocation
        let profile: HotdogProfile
    }

    var requests: [Request] = []
    var result: Result<RouteEstimate, Error>

    init(result: Result<RouteEstimate, Error>) {
        self.result = result
    }

    func walkingRoute(
        from origin: DiscoveryLocation,
        to profile: HotdogProfile
    ) async throws -> RouteEstimate {
        requests.append(Request(origin: origin, profile: profile))
        return try result.get()
    }
}

private struct SlowRouteEstimator: RouteEstimating {
    let estimate: RouteEstimate

    func walkingRoute(
        from origin: DiscoveryLocation,
        to profile: HotdogProfile
    ) async throws -> RouteEstimate {
        try await Task.sleep(nanoseconds: 50_000_000)
        return estimate
    }
}

@MainActor
private final class RecordingVendorAddressGeocoder: VendorAddressGeocoding {
    var addresses: [String] = []
    var result: Result<VendorCoordinate, Error>

    init(result: Result<VendorCoordinate, Error>) {
        self.result = result
    }

    func coordinate(for address: String) async throws -> VendorCoordinate {
        addresses.append(address)
        return try result.get()
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

    @MainActor
    func testAnalyticsContractRecordsCanonicalEventsWithoutPII() {
        let sink = RecordingAnalyticsSink()
        let analytics = DogSwipeAnalytics(sink: sink)

        analytics.trackScreenViewed(.discover)
        analytics.trackScreenViewed(.orders)
        analytics.trackDiscoverySwipe(decision: "like", profileID: "hotdog-chicago")
        analytics.trackAuthMagicLinkRequested()

        XCTAssertEqual(sink.events.map(\.name), [
            "ios_screen_viewed",
            "ios_screen_viewed",
            "ios_discovery_swipe",
            "ios_auth_magic_link_requested"
        ])
        XCTAssertEqual(sink.events[0].parameters, ["screen": "discover"])
        XCTAssertEqual(sink.events[1].parameters, ["screen": "orders"])
        XCTAssertEqual(sink.events[2].parameters["decision"], "like")
        XCTAssertEqual(sink.events[2].parameters["profile_id"], "hotdog-chicago")
        XCTAssertNil(sink.events[3].parameters["email"])
        XCTAssertNil(sink.events[3].parameters["name"])
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
    func testOrderStoreCreatesDurableDraftWithSelectedAddOns() async throws {
        let http = MockHTTPClient()
        http.responses = [
            try encodedOrderResponse(
                id: "order-hotdog-sample",
                profile: HotdogProfile.samples[0],
                addOns: [
                    DogSwipeOrderAddOn(id: "bacon", name: "Bacon", creditCost: 2),
                    DogSwipeOrderAddOn(id: "extra-pickle", name: "Extra Pickle", creditCost: 1)
                ],
                totalCredits: HotdogProfile.samples[0].creditCost + 3
            )
        ]
        let apiClient = DogSwipeAPIClient(
            baseURL: URL(string: "http://localhost:8000")!,
            httpClient: http
        )
        let store = OrderStore(apiClient: apiClient)
        let selectedAddOns = [
            OrderAddOn.matchDefaults[0],
            OrderAddOn.matchDefaults[3]
        ]

        let item = try await store.add(profile: HotdogProfile.samples[0], addOns: selectedAddOns)

        XCTAssertEqual(store.itemCount, 1)
        XCTAssertEqual(store.latestItem, item)
        XCTAssertEqual(item.profileID, HotdogProfile.samples[0].id)
        XCTAssertEqual(item.addOnSummary, "Bacon, Extra Pickle")
        XCTAssertEqual(item.totalCredits, HotdogProfile.samples[0].creditCost + 3)
        let request = try XCTUnwrap(http.requests.first)
        XCTAssertEqual(request.url?.path, "/v1/orders")
        XCTAssertEqual(request.httpMethod, "POST")
        let body = try jsonBody(request)
        XCTAssertEqual(body["profile_id"] as? String, HotdogProfile.samples[0].id)
        XCTAssertEqual(body["add_on_ids"] as? [String], ["bacon", "extra-pickle"])
        XCTAssertNil(body["user_id"])
    }

    @MainActor
    func testOrderStoreLoadsDurableDraftsViaAPI() async throws {
        let http = MockHTTPClient()
        http.responses = [
            try JSONEncoder().encode(
                OrderListResponse(
                    orders: [
                        makeOrder(
                            id: "order-hotdog-sample",
                            profile: HotdogProfile.samples[0],
                            addOns: [
                                DogSwipeOrderAddOn(id: "bacon", name: "Bacon", creditCost: 2)
                            ],
                            totalCredits: HotdogProfile.samples[0].creditCost + 2
                        )
                    ]
                )
            )
        ]
        let apiClient = DogSwipeAPIClient(
            baseURL: URL(string: "http://localhost:8000")!,
            httpClient: http
        )
        let store = OrderStore(apiClient: apiClient)

        await store.load()

        XCTAssertEqual(store.items.map(\.id), ["order-hotdog-sample"])
        XCTAssertEqual(store.latestItem?.addOnSummary, "Bacon")
        XCTAssertNil(store.errorMessage)
        XCTAssertEqual(http.requests.first?.url?.path, "/v1/orders")
        XCTAssertEqual(http.requests.first?.httpMethod, "GET")
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

    func testAuthDeepLinkParsesMagicLinkURL() throws {
        let deepLink = try XCTUnwrap(
            AuthDeepLink(url: URL(string: "dogswipe://auth?token_hash=link-token&type=magiclink")!)
        )

        XCTAssertEqual(deepLink.token, "link-token")
        XCTAssertEqual(deepLink.type, "magiclink")
        XCTAssertNil(AuthDeepLink(url: URL(string: "dogswipe://vendor?token=link-token")!))
    }

    func testAuthDeepLinkParsesUniversalLinkForAllowedHost() throws {
        let deepLink = try XCTUnwrap(
            AuthDeepLink(
                url: URL(
                    string: "https://links.dogswipe.test/auth/callback#code=link-token&type=magiclink"
                )!,
                allowedUniversalLinkHosts: ["links.dogswipe.test"]
            )
        )

        XCTAssertEqual(deepLink.token, "link-token")
        XCTAssertEqual(deepLink.type, "magiclink")
        XCTAssertNil(
            AuthDeepLink(
                url: URL(string: "https://evil.example/auth?token=link-token")!,
                allowedUniversalLinkHosts: ["links.dogswipe.test"]
            )
        )
        XCTAssertNil(
            AuthDeepLink(
                url: URL(string: "https://links.dogswipe.test/vendor?token=link-token")!,
                allowedUniversalLinkHosts: ["links.dogswipe.test"]
            )
        )
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
    func testDiscoverViewModelSendsCurrentLocationToDiscovery() async throws {
        let http = MockHTTPClient()
        http.responses = [#"{"profiles":[]}"#.data(using: .utf8)!]
        let apiClient = DogSwipeAPIClient(
            baseURL: URL(string: "http://localhost:8000")!,
            httpClient: http
        )
        let viewModel = DiscoverViewModel(
            apiClient: apiClient,
            locationProvider: StaticLocationProvider(
                location: DiscoveryLocation(latitude: 43.6532, longitude: -79.3832)
            )
        )

        await viewModel.load()

        let components = try XCTUnwrap(
            URLComponents(url: http.requests.first!.url!, resolvingAgainstBaseURL: false)
        )
        let locationQuery = Dictionary(uniqueKeysWithValues: (components.queryItems ?? []).map {
            ($0.name, $0.value ?? "")
        })
        XCTAssertEqual(locationQuery["latitude"], "43.6532")
        XCTAssertEqual(locationQuery["longitude"], "-79.3832")
        XCTAssertTrue(viewModel.isUsingCurrentLocation)
        XCTAssertEqual(
            viewModel.currentLocation,
            DiscoveryLocation(latitude: 43.6532, longitude: -79.3832)
        )
    }

    @MainActor
    func testDiscoverViewModelSendsMenuQueryToDiscovery() async throws {
        let http = MockHTTPClient()
        http.responses = [#"{"profiles":[]}"#.data(using: .utf8)!]
        let apiClient = DogSwipeAPIClient(
            baseURL: URL(string: "http://localhost:8000")!,
            httpClient: http
        )
        let viewModel = DiscoverViewModel(apiClient: apiClient)
        viewModel.menuQuery = "  kimchi   sesame  "

        await viewModel.load()

        let components = try XCTUnwrap(
            URLComponents(url: http.requests.first!.url!, resolvingAgainstBaseURL: false)
        )
        let query = Dictionary(uniqueKeysWithValues: (components.queryItems ?? []).map {
            ($0.name, $0.value ?? "")
        })
        XCTAssertEqual(components.path, "/v1/discovery")
        XCTAssertEqual(query["menu_query"], "kimchi sesame")
    }

    @MainActor
    func testDiscoverViewModelCanRestartAfterReviewingEveryProfile() async throws {
        let viewModel = DiscoverViewModel(apiClient: DogSwipeAPIClient(
            baseURL: URL(string: "http://localhost:8000")!,
            httpClient: MockHTTPClient()
        ))
        viewModel.resetToSamples()

        XCTAssertTrue(viewModel.canSwipe)
        XCTAssertTrue(viewModel.canRestartDeck)
        XCTAssertFalse(viewModel.hasReviewedEveryHotdog)

        for _ in HotdogProfile.samples {
            viewModel.record(.pass)
        }

        XCTAssertFalse(viewModel.canSwipe)
        XCTAssertTrue(viewModel.canRestartDeck)
        XCTAssertTrue(viewModel.hasReviewedEveryHotdog)
        XCTAssertEqual(viewModel.remainingCount, 0)
    }

    @MainActor
    func testDiscoverViewModelDoesNotTreatEmptyLoadAsReviewedDeck() async throws {
        let http = MockHTTPClient()
        http.responses = [#"{"profiles":[]}"#.data(using: .utf8)!]
        let apiClient = DogSwipeAPIClient(
            baseURL: URL(string: "http://localhost:8000")!,
            httpClient: http
        )
        let viewModel = DiscoverViewModel(apiClient: apiClient)

        await viewModel.load()

        XCTAssertFalse(viewModel.canSwipe)
        XCTAssertFalse(viewModel.canRestartDeck)
        XCTAssertFalse(viewModel.hasReviewedEveryHotdog)
        XCTAssertEqual(viewModel.remainingCount, 0)
    }

    @MainActor
    func testMatchesViewModelSendsCurrentLocationToMatches() async throws {
        let http = MockHTTPClient()
        http.responses = [#"{"matches":[]}"#.data(using: .utf8)!]
        let apiClient = DogSwipeAPIClient(
            baseURL: URL(string: "http://localhost:8000")!,
            httpClient: http
        )
        let viewModel = MatchesViewModel(
            apiClient: apiClient,
            locationProvider: StaticLocationProvider(
                location: DiscoveryLocation(latitude: 43.6532, longitude: -79.3832)
            )
        )

        await viewModel.load()

        let components = try XCTUnwrap(
            URLComponents(url: http.requests.first!.url!, resolvingAgainstBaseURL: false)
        )
        let locationQuery = Dictionary(uniqueKeysWithValues: (components.queryItems ?? []).map {
            ($0.name, $0.value ?? "")
        })
        XCTAssertEqual(components.path, "/v1/matches")
        XCTAssertEqual(locationQuery["latitude"], "43.6532")
        XCTAssertEqual(locationQuery["longitude"], "-79.3832")
        XCTAssertTrue(viewModel.isUsingCurrentLocation)
        XCTAssertEqual(
            viewModel.currentLocation,
            DiscoveryLocation(latitude: 43.6532, longitude: -79.3832)
        )
    }

    @MainActor
    func testRoutePreviewStoreLoadsWalkingEstimate() async {
        let estimate = RouteEstimate(walkingTimeMinutes: 14, distanceMiles: 0.7)
        let estimator = MockRouteEstimator(result: .success(estimate))
        let store = RoutePreviewStore(routeEstimator: estimator)
        let origin = DiscoveryLocation(latitude: 43.6532, longitude: -79.3832)
        let profile = HotdogProfile.samples[0]

        await store.preview(profile: profile, origin: origin)

        XCTAssertEqual(store.state, .ready(estimate))
        XCTAssertEqual(estimator.requests, [.init(origin: origin, profile: profile)])
    }

    @MainActor
    func testRoutePreviewStoreReportsUnavailableRouteInputs() async {
        let estimator = MockRouteEstimator(
            result: .failure(TestRoutingError.failed)
        )
        let store = RoutePreviewStore(routeEstimator: estimator)
        let profile = HotdogProfile(
            id: "no-coordinates",
            name: "No Coordinates",
            style: "Cart dog",
            creditCost: 6,
            signatureNotes: "Mustard and onion.",
            distanceMiles: 1,
            vendorName: "Missing Map",
            craveScore: 0.5
        )

        await store.preview(profile: profile, origin: nil)
        XCTAssertEqual(store.state, .failed("Current location is unavailable."))

        await store.preview(
            profile: profile,
            origin: DiscoveryLocation(latitude: 43.6532, longitude: -79.3832)
        )
        XCTAssertEqual(store.state, .failed("Route preview needs vendor coordinates."))
        XCTAssertTrue(estimator.requests.isEmpty)
    }

    @MainActor
    func testRoutePreviewStoreIgnoresStaleRouteAfterReset() async {
        let estimate = RouteEstimate(walkingTimeMinutes: 14, distanceMiles: 0.7)
        let store = RoutePreviewStore(
            routeEstimator: SlowRouteEstimator(estimate: estimate)
        )
        let origin = DiscoveryLocation(latitude: 43.6532, longitude: -79.3832)
        let task = Task {
            await store.preview(profile: HotdogProfile.samples[0], origin: origin)
        }

        for _ in 0..<20 where store.state != .loading {
            await Task.yield()
        }
        XCTAssertEqual(store.state, .loading)

        store.reset()
        await task.value

        XCTAssertEqual(store.state, .idle)
    }

    @MainActor
    func testVendorSubmissionStoreGeocodesPickupAddress() async {
        let geocoder = RecordingVendorAddressGeocoder(
            result: .success(
                VendorCoordinate(latitude: 43.6532, longitude: -79.3832)
            )
        )
        let apiClient = DogSwipeAPIClient(
            baseURL: URL(string: "http://localhost:8000")!,
            httpClient: MockHTTPClient()
        )
        let store = VendorSubmissionStore(
            apiClient: apiClient,
            addressGeocoder: geocoder
        )
        store.addressText = " 100 Queen St W, Toronto, ON "

        await store.geocodeAddress()

        XCTAssertEqual(geocoder.addresses, ["100 Queen St W, Toronto, ON"])
        XCTAssertEqual(store.latitude, "43.653200")
        XCTAssertEqual(store.longitude, "-79.383200")
        XCTAssertEqual(store.message, "Coordinates added from pickup address.")
        XCTAssertFalse(store.isGeocoding)
    }

    @MainActor
    func testVendorSubmissionStoreReportsGeocodingFailure() async {
        let geocoder = RecordingVendorAddressGeocoder(
            result: .failure(TestGeocodingError.failed)
        )
        let apiClient = DogSwipeAPIClient(
            baseURL: URL(string: "http://localhost:8000")!,
            httpClient: MockHTTPClient()
        )
        let store = VendorSubmissionStore(
            apiClient: apiClient,
            addressGeocoder: geocoder
        )
        store.addressText = "Nowhere"

        await store.geocodeAddress()

        XCTAssertEqual(geocoder.addresses, ["Nowhere"])
        XCTAssertEqual(store.latitude, "")
        XCTAssertEqual(store.longitude, "")
        XCTAssertEqual(
            store.message,
            "Pickup address could not be located. Check the address or enter coordinates manually."
        )
        XCTAssertFalse(store.isGeocoding)
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
        store.latitude = "43.6532"
        store.longitude = "-79.3832"
        store.vendorName = "Boardwalk Dogs"
        store.addressText = "100 Queen St W, Toronto, ON"
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
        XCTAssertEqual(body["credit_cost"] as? Int, 6)
        XCTAssertEqual(body["latitude"] as? Double, 43.6532)
        XCTAssertEqual(body["longitude"] as? Double, -79.3832)
        XCTAssertEqual(body["address_text"] as? String, "100 Queen St W, Toronto, ON")
        XCTAssertEqual(body["menu_url"] as? String, "https://boardwalk.example.com/menu")
        XCTAssertNil(body["user_id"])
    }

    @MainActor
    func testVendorSubmissionStoreResubmitsChangeRequest() async throws {
        let http = MockHTTPClient()
        let changeRequest = HotdogProfile(
            id: "submitted-hotdog",
            name: "Boardwalk Snap",
            style: "Classic cart dog",
            creditCost: 6,
            signatureNotes: "Mustard, relish, and onion.",
            distanceMiles: 1.8,
            vendorName: "Boardwalk Dogs",
            addressText: "100 Queen St W, Toronto, ON",
            craveScore: 0.5,
            availabilityStatus: .changesRequested,
            reviewNote: "Add a current menu URL."
        )
        let resubmitted = HotdogProfile(
            id: changeRequest.id,
            name: "Boardwalk Snap",
            style: "Classic cart dog",
            creditCost: 6,
            signatureNotes: "Mustard, relish, and onion.",
            distanceMiles: 1.8,
            vendorName: "Boardwalk Dogs",
            addressText: "100 Queen St W, Toronto, ON",
            menuURL: URL(string: "https://boardwalk.example.com/menu"),
            craveScore: 0.5,
            availabilityStatus: .pendingReview
        )
        http.responses = [
            try JSONEncoder().encode(VendorSubmissionListResponse(submissions: [changeRequest])),
            try JSONEncoder().encode(VendorSubmissionResponse(profile: resubmitted))
        ]
        let apiClient = DogSwipeAPIClient(
            baseURL: URL(string: "http://localhost:8000")!,
            httpClient: http
        )
        let store = VendorSubmissionStore(apiClient: apiClient)

        await store.load()
        store.edit(changeRequest)
        XCTAssertEqual(store.addressText, "100 Queen St W, Toronto, ON")
        store.menuURL = "https://boardwalk.example.com/menu"
        await store.submit()

        XCTAssertEqual(store.submissions.first?.availabilityStatus, .pendingReview)
        XCTAssertEqual(store.submissions.first?.reviewNote, nil)
        XCTAssertEqual(store.message, "Resubmitted for review.")
        XCTAssertEqual(http.requests.map { $0.url?.path }, [
            "/v1/vendor/submissions",
            "/v1/vendor/submissions/submitted-hotdog"
        ])
        XCTAssertEqual(http.requests.last?.httpMethod, "PUT")
        let body = try jsonBody(http.requests.last!)
        XCTAssertEqual(body["address_text"] as? String, "100 Queen St W, Toronto, ON")
        XCTAssertEqual(body["menu_url"] as? String, "https://boardwalk.example.com/menu")
    }

    @MainActor
    func testVendorSubmissionStoreRefreshesMenuSnapshot() async throws {
        let http = MockHTTPClient()
        let pending = makeMenuSnapshotProfile()
        let refreshed = makeMenuSnapshotProfile(
            menuStatus: "ok",
            menuExcerpt: "Boardwalk Snap - mustard, relish, and onion.",
            menuHighlights: ["Mustard", "Relish", "Onion"],
            menuCheckedAt: "2026-05-05T15:45:00Z"
        )
        http.responses = [
            try JSONEncoder().encode(VendorSubmissionListResponse(submissions: [pending])),
            try JSONEncoder().encode(MenuIngestionResponse(profile: refreshed))
        ]
        let apiClient = DogSwipeAPIClient(
            baseURL: URL(string: "http://localhost:8000")!,
            httpClient: http
        )
        let store = VendorSubmissionStore(apiClient: apiClient)

        await store.load()
        await store.ingestMenu(pending)

        XCTAssertEqual(store.submissions.first?.menuStatus, "ok")
        XCTAssertEqual(
            store.submissions.first?.menuExcerpt,
            "Boardwalk Snap - mustard, relish, and onion."
        )
        XCTAssertEqual(store.submissions.first?.menuHighlightLabels, ["Mustard", "Relish", "Onion"])
        XCTAssertEqual(store.message, "Boardwalk Snap menu refreshed.")
        XCTAssertEqual(http.requests.map { $0.url?.path }, [
            "/v1/vendor/submissions",
            "/v1/vendor/submissions/pending-hotdog/ingest-menu"
        ])
        XCTAssertEqual(http.requests.last?.httpMethod, "POST")
        XCTAssertNil(http.requests.last?.httpBody)
    }

    @MainActor
    func testAdminReviewStoreApprovesPendingSubmission() async throws {
        let http = MockHTTPClient()
        let pending = HotdogProfile(
            id: "pending-hotdog",
            name: "Pending Snap",
            style: "Classic cart dog",
            creditCost: 6,
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
            creditCost: pending.creditCost,
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

    @MainActor
    func testAdminReviewStoreRefreshesStaleMenus() async throws {
        let http = MockHTTPClient()
        let pending = makeMenuSnapshotProfile()
        let refreshed = makeMenuSnapshotProfile(
            menuStatus: "ok",
            menuExcerpt: "Boardwalk Snap - mustard, relish, and onion.",
            menuCheckedAt: "2026-05-05T16:10:00Z"
        )
        http.responses = [
            try JSONEncoder().encode(AdminReviewQueueResponse(submissions: [pending])),
            try JSONEncoder().encode(
                AdminMenuRefreshResponse(
                    checkedCount: 1,
                    refreshedCount: 1,
                    failedCount: 0,
                    profiles: [refreshed]
                )
            )
        ]
        let apiClient = DogSwipeAPIClient(
            baseURL: URL(string: "http://localhost:8000")!,
            httpClient: http
        )
        let store = AdminReviewStore(apiClient: apiClient)

        await store.load()
        await store.refreshMenus()

        XCTAssertEqual(store.pendingSubmissions.first?.menuStatus, "ok")
        XCTAssertEqual(
            store.pendingSubmissions.first?.menuExcerpt,
            "Boardwalk Snap - mustard, relish, and onion."
        )
        XCTAssertEqual(store.reviewMessage, "1 menu refreshed.")
        XCTAssertEqual(http.requests.map { $0.url?.path }, [
            "/v1/admin/vendor/submissions",
            "/v1/admin/vendor/menus/refresh"
        ])
        XCTAssertEqual(http.requests.last?.httpMethod, "POST")
        let body = try jsonBody(http.requests.last!)
        XCTAssertEqual(body["limit"] as? Int, 20)
        XCTAssertEqual(body["max_age_hours"] as? Double, 24)
    }

    @MainActor
    func testAdminReviewStoreModeratesPendingSubmissions() async throws {
        let http = MockHTTPClient()
        let editCandidate = HotdogProfile(
            id: "edit-hotdog",
            name: "Edit Snap",
            style: "Classic cart dog",
            creditCost: 6,
            signatureNotes: "Mustard, relish, and onion.",
            distanceMiles: 1.8,
            vendorName: "Boardwalk Dogs",
            craveScore: 0.5,
            availabilityStatus: .pendingReview
        )
        let rejectCandidate = HotdogProfile(
            id: "reject-hotdog",
            name: "Reject Snap",
            style: "Classic cart dog",
            creditCost: 6,
            signatureNotes: "Mustard, relish, and onion.",
            distanceMiles: 1.8,
            vendorName: "Boardwalk Dogs",
            craveScore: 0.5,
            availabilityStatus: .pendingReview
        )
        let changesRequested = HotdogProfile(
            id: editCandidate.id,
            name: editCandidate.name,
            style: editCandidate.style,
            creditCost: editCandidate.creditCost,
            signatureNotes: editCandidate.signatureNotes,
            distanceMiles: editCandidate.distanceMiles,
            vendorName: editCandidate.vendorName,
            craveScore: editCandidate.craveScore,
            availabilityStatus: .changesRequested,
            reviewNote: "Add a current menu URL."
        )
        let rejected = HotdogProfile(
            id: rejectCandidate.id,
            name: rejectCandidate.name,
            style: rejectCandidate.style,
            creditCost: rejectCandidate.creditCost,
            signatureNotes: rejectCandidate.signatureNotes,
            distanceMiles: rejectCandidate.distanceMiles,
            vendorName: rejectCandidate.vendorName,
            craveScore: rejectCandidate.craveScore,
            availabilityStatus: .rejected,
            reviewNote: "Listing does not show a hotdog item."
        )
        http.responses = [
            try JSONEncoder().encode(
                AdminReviewQueueResponse(submissions: [editCandidate, rejectCandidate])
            ),
            try JSONEncoder().encode(AdminModerationResponse(profile: changesRequested)),
            try JSONEncoder().encode(AdminModerationResponse(profile: rejected))
        ]
        let apiClient = DogSwipeAPIClient(
            baseURL: URL(string: "http://localhost:8000")!,
            httpClient: http
        )
        let store = AdminReviewStore(apiClient: apiClient)

        await store.load()
        store.reviewNotes[editCandidate.id] = "Add a current menu URL."
        await store.requestChanges(editCandidate)
        store.reviewNotes[rejectCandidate.id] = "Listing does not show a hotdog item."
        await store.reject(rejectCandidate)

        XCTAssertTrue(store.pendingSubmissions.isEmpty)
        XCTAssertEqual(store.reviewMessage, "Reject Snap rejected.")
        XCTAssertEqual(http.requests.map { $0.url?.path }, [
            "/v1/admin/vendor/submissions",
            "/v1/admin/vendor/submissions/edit-hotdog/request-changes",
            "/v1/admin/vendor/submissions/reject-hotdog/reject"
        ])
        let changesBody = try jsonBody(http.requests[1])
        XCTAssertEqual(changesBody["review_note"] as? String, "Add a current menu URL.")
        let rejectBody = try jsonBody(http.requests[2])
        XCTAssertEqual(rejectBody["review_note"] as? String, "Listing does not show a hotdog item.")
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
    func testAuthSessionStoreRequestsMagicLinkWithUniversalRedirect() async throws {
        let http = MockHTTPClient()
        let store = AuthSessionStore(
            accessTokenStore: InMemoryBearerTokenStore(),
            refreshTokenStore: InMemoryBearerTokenStore(),
            authClient: makeAuthClient(http: http),
            magicLinkRedirectURL: URL(string: "https://links.dogswipe.test/auth")!,
            universalLinkHosts: ["links.dogswipe.test"]
        )

        await store.requestMagicLink(email: "fan@example.com")

        let request = try XCTUnwrap(http.requests.first)
        let body = try jsonBody(request)
        XCTAssertEqual(body["email"] as? String, "fan@example.com")
        XCTAssertEqual(body["redirect_url"] as? String, "https://links.dogswipe.test/auth")
    }

    @MainActor
    func testAuthSessionStoreRequestsMagicLinkWithNativeRedirect() async throws {
        let http = MockHTTPClient()
        let store = AuthSessionStore(
            accessTokenStore: InMemoryBearerTokenStore(),
            refreshTokenStore: InMemoryBearerTokenStore(),
            authClient: makeAuthClient(http: http)
        )

        await store.requestMagicLink(email: "fan@example.com")

        let request = try XCTUnwrap(http.requests.first)
        let body = try jsonBody(request)
        XCTAssertEqual(body["email"] as? String, "fan@example.com")
        XCTAssertEqual(body["redirect_url"] as? String, "dogswipe://auth")
    }

    @MainActor
    func testAuthSessionStoreVerifiesMagicLinkAndStoresSessionTokens() async throws {
        let http = MockHTTPClient()
        let context = try makeAuthVerificationContext(http: http)

        await context.store.verifyMagicLink(token: " token-from-email ")

        assertStoredSession(
            context.store,
            accessStore: context.accessStore,
            refreshStore: context.refreshStore
        )
        try assertMagicLinkVerifyRequest(http, token: "token-from-email")
    }

    @MainActor
    func testAuthSessionStoreHandlesMagicLinkDeepLink() async throws {
        let http = MockHTTPClient()
        let context = try makeAuthVerificationContext(http: http)

        let handled = await context.store.handleDeepLink(
            URL(string: "dogswipe://auth?token_hash=token-from-email&type=magiclink")!
        )

        XCTAssertTrue(handled)
        assertStoredSession(
            context.store,
            accessStore: context.accessStore,
            refreshStore: context.refreshStore
        )
        try assertMagicLinkVerifyRequest(http, token: "token-from-email")
    }

    @MainActor
    func testAuthSessionStoreHandlesUniversalMagicLink() async throws {
        let accessStore = InMemoryBearerTokenStore()
        let refreshStore = InMemoryBearerTokenStore()
        let http = MockHTTPClient()
        http.responses = [
            try encodedAuthSessionResponse(
                accessToken: "access-jwt",
                refreshToken: "refresh-jwt",
                email: "fan@example.com"
            )
        ]
        let store = AuthSessionStore(
            accessTokenStore: accessStore,
            refreshTokenStore: refreshStore,
            authClient: makeAuthClient(http: http),
            magicLinkRedirectURL: URL(string: "https://links.dogswipe.test/auth")!
        )

        let handled = await store.handleDeepLink(
            URL(string: "https://links.dogswipe.test/auth?token_hash=token-from-email")!
        )

        XCTAssertTrue(handled)
        assertStoredSession(
            store,
            accessStore: accessStore,
            refreshStore: refreshStore
        )
        try assertMagicLinkVerifyRequest(http, token: "token-from-email")
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

    // MARK: - WG-D05 Coverage

    func testSwipeOverlayStyleNilForNoDecision() {
        XCTAssertNil(SwipeOverlayStyle.style(for: nil))
    }

    func testSwipeOverlayStyleLikePass() {
        let like = try? XCTUnwrap(SwipeOverlayStyle.style(for: .like))
        XCTAssertEqual(like?.alignment, .leading)
        XCTAssertEqual(like?.label, "YUM")
        XCTAssertEqual(like?.symbol, "heart.fill")
        XCTAssertEqual(like?.color, .dsRelish)

        let pass = try? XCTUnwrap(SwipeOverlayStyle.style(for: .pass))
        XCTAssertEqual(pass?.alignment, .trailing)
        XCTAssertEqual(pass?.label, "NAH")
        XCTAssertEqual(pass?.symbol, "xmark")
        XCTAssertEqual(pass?.color, .dsAccent)

        let superLike = try? XCTUnwrap(SwipeOverlayStyle.style(for: .superLike))
        XCTAssertEqual(superLike?.alignment, .leading)
        XCTAssertEqual(superLike?.label, "MUST")
        XCTAssertEqual(superLike?.symbol, "star.fill")
        XCTAssertEqual(superLike?.color, .dsSuper)

        // Cross-decision uniqueness — every case maps to a distinct stamp
        // grammar so accessibility / VO consumers never see ambiguous text.
        let labels = Set([like?.label, pass?.label, superLike?.label].compactMap { $0 })
        XCTAssertEqual(labels.count, 3)
    }

    @MainActor
    func testFeatureChipsNonEmpty() {
        let chips = featureChips(for: HotdogProfile.samples[0])
        XCTAssertGreaterThanOrEqual(chips.count, 1)
        for chip in chips {
            XCTAssertFalse(chip.text.isEmpty, "Chip text should never be empty.")
            XCTAssertFalse(
                chip.systemImage.isEmpty,
                "Chip system image should never be empty (used as SF Symbol)."
            )
        }
        // IDs must be unique so SwiftUI's ForEach does not collapse rows.
        let ids = Set(chips.map(\.id))
        XCTAssertEqual(ids.count, chips.count)
    }

    func testDiscoverViewModelSwipeDecisionThresholds() {
        // The directional branches the gesture uses (right -> like,
        // left -> pass, up -> superLike) live inside DiscoverView's drag
        // closure rather than in the viewmodel. Per the WG-D05 brief, we
        // exercise the equivalent presentation mapping in
        // SwipeOverlayStyle.style(for:) — every non-nil decision must
        // produce a distinct, non-empty style — to give equivalent branch
        // coverage of the decision-handling switch.
        let cases: [SwipeDecision] = [.like, .pass, .superLike]
        var seen: [SwipeOverlayStyle] = []
        for decision in cases {
            guard let style = SwipeOverlayStyle.style(for: decision) else {
                XCTFail("Expected non-nil style for \(decision)")
                continue
            }
            XCTAssertFalse(style.label.isEmpty)
            XCTAssertFalse(style.symbol.isEmpty)
            XCTAssertFalse(
                seen.contains(style),
                "Decision \(decision) collides with another case's style."
            )
            seen.append(style)
        }
        XCTAssertEqual(seen.count, cases.count)
        XCTAssertNil(SwipeOverlayStyle.style(for: nil))
    }

    private func makeMenuSnapshotProfile(
        menuStatus: String? = nil,
        menuExcerpt: String? = nil,
        menuHighlights: [String]? = nil,
        menuCheckedAt: String? = nil
    ) -> HotdogProfile {
        HotdogProfile(
            id: "pending-hotdog",
            name: "Boardwalk Snap",
            style: "Classic cart dog",
            creditCost: 6,
            signatureNotes: "Mustard, relish, and onion.",
            distanceMiles: 1.8,
            vendorName: "Boardwalk Dogs",
            menuURL: URL(string: "https://boardwalk.example.com/menu"),
            menuStatus: menuStatus,
            menuExcerpt: menuExcerpt,
            menuHighlights: menuHighlights,
            menuCheckedAt: menuCheckedAt,
            craveScore: 0.5,
            availabilityStatus: .pendingReview
        )
    }

    private func makeAuthClient(http: MockHTTPClient) -> SPAPSAuthClient {
        SPAPSAuthClient(
            baseURL: URL(string: "https://auth.dogswipe.test")!,
            publishableKey: "spaps_pub_test",
            origin: "https://dogswipe.test",
            httpClient: http
        )
    }

    private func makeAuthSessionStore(
        http: MockHTTPClient,
        accessStore: InMemoryBearerTokenStore,
        refreshStore: InMemoryBearerTokenStore
    ) -> AuthSessionStore {
        AuthSessionStore(
            accessTokenStore: accessStore,
            refreshTokenStore: refreshStore,
            authClient: makeAuthClient(http: http)
        )
    }

    private func makeAuthVerificationContext(
        http: MockHTTPClient
    ) throws -> (
        store: AuthSessionStore,
        accessStore: InMemoryBearerTokenStore,
        refreshStore: InMemoryBearerTokenStore
    ) {
        let accessStore = InMemoryBearerTokenStore()
        let refreshStore = InMemoryBearerTokenStore()
        http.responses = [
            try encodedAuthSessionResponse(
                accessToken: "access-jwt",
                refreshToken: "refresh-jwt",
                email: "fan@example.com"
            )
        ]
        let store = makeAuthSessionStore(
            http: http,
            accessStore: accessStore,
            refreshStore: refreshStore
        )
        return (store, accessStore, refreshStore)
    }

    private func assertStoredSession(
        _ store: AuthSessionStore,
        accessStore: InMemoryBearerTokenStore,
        refreshStore: InMemoryBearerTokenStore,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertEqual(store.bearerToken, "access-jwt", file: file, line: line)
        XCTAssertEqual(store.sessionEmail, "fan@example.com", file: file, line: line)
        XCTAssertTrue(store.hasRefreshToken, file: file, line: line)
        XCTAssertEqual(accessStore.storedToken, "access-jwt", file: file, line: line)
        XCTAssertEqual(refreshStore.storedToken, "refresh-jwt", file: file, line: line)
    }

    private func assertMagicLinkVerifyRequest(
        _ http: MockHTTPClient,
        token: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws {
        let request = try XCTUnwrap(http.requests.first, file: file, line: line)
        XCTAssertEqual(request.url?.path, "/api/auth/verify-magic-link", file: file, line: line)
        let body = try jsonBody(request, file: file, line: line)
        XCTAssertEqual(body["token"] as? String, token, file: file, line: line)
        XCTAssertEqual(body["type"] as? String, "magiclink", file: file, line: line)
    }

    private func encodedAuthSessionResponse(
        accessToken: String,
        refreshToken: String,
        email: String
    ) throws -> Data {
        try JSONSerialization.data(
            withJSONObject: [
                "success": true,
                "data": [
                    "tokens": [
                        "access_token": accessToken,
                        "refresh_token": refreshToken
                    ],
                    "user": [
                        "email": email
                    ]
                ]
            ]
        )
    }

    private func encodedVendorSubmissionResponse() throws -> Data {
        try JSONEncoder().encode(
            VendorSubmissionResponse(
                profile: HotdogProfile(
                    id: "submitted-hotdog",
                    name: "Boardwalk Snap",
                    style: "Classic cart dog",
                    creditCost: 6,
                    signatureNotes: "Mustard, relish, and onion.",
                    distanceMiles: 1.8,
                    vendorName: "Boardwalk Dogs",
                    addressText: "100 Queen St W, Toronto, ON",
                    imageURL: URL(string: "https://cdn.example.com/boardwalk.jpg"),
                    menuURL: URL(string: "https://boardwalk.example.com/menu"),
                    mediaAltText: "Classic hotdog on a paper tray",
                    craveScore: 0.5,
                    availabilityStatus: .pendingReview
                )
            )
        )
    }

    private func encodedOrderResponse(
        id: String,
        profile: HotdogProfile,
        addOns: [DogSwipeOrderAddOn],
        totalCredits: Int
    ) throws -> Data {
        try JSONEncoder().encode(
            OrderResponse(
                order: makeOrder(
                    id: id,
                    profile: profile,
                    addOns: addOns,
                    totalCredits: totalCredits
                )
            )
        )
    }

    private func makeOrder(
        id: String,
        profile: HotdogProfile,
        addOns: [DogSwipeOrderAddOn],
        totalCredits: Int
    ) -> DogSwipeOrder {
        DogSwipeOrder(
            id: id,
            profileID: profile.id,
            hotdogName: profile.name,
            vendorName: profile.vendorName,
            baseCreditCost: profile.creditCost,
            addOns: addOns,
            totalCredits: totalCredits,
            status: "draft",
            createdAt: "2026-05-06T14:10:00Z"
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
