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
              "menu_url": "https://franklin.example.com/menu",
              "media_alt_text": "Coney hotdog with chili and onion",
              "crave_score": 0.91,
              "availability_status": "available",
              "last_verified_at": "2026-05-05T13:30:00Z"
            }
          ]
        }
        """.data(using: .utf8)!
        let client = DogSwipeAPIClient(baseURL: URL(string: "http://localhost:8000")!, httpClient: http)

        let profiles = try await client.discovery(limit: 10)

        XCTAssertEqual(profiles.map(\.id), ["hotdog-coney"])
        XCTAssertEqual(profiles.first?.priceLabel, "$6.50")
        XCTAssertEqual(profiles.first?.vendorName, "Franklin Cart")
        XCTAssertEqual(profiles.first?.menuURL?.absoluteString, "https://franklin.example.com/menu")
        XCTAssertEqual(profiles.first?.mediaAltText, "Coney hotdog with chili and onion")
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

    func testVendorSubmissionsDecodeBackendContract() async throws {
        let http = MockHTTPClient()
        http.nextData = """
        {
          "submissions": [
            {
              "id": "submitted-hotdog",
              "name": "Boardwalk Snap",
              "style": "Classic cart dog",
              "price_dollars": 6.25,
              "signature_notes": "Mustard, relish, and onion.",
              "distance_miles": 1.8,
              "vendor_name": "Boardwalk Dogs",
              "image_url": null,
              "menu_url": "https://boardwalk.example.com/menu",
              "media_alt_text": null,
              "crave_score": 0.5,
              "availability_status": "pending_review",
              "last_verified_at": null
            }
          ]
        }
        """.data(using: .utf8)!
        let client = DogSwipeAPIClient(baseURL: URL(string: "http://localhost:8000")!, httpClient: http)

        let submissions = try await client.vendorSubmissions()

        XCTAssertEqual(submissions.map(\.name), ["Boardwalk Snap"])
        XCTAssertEqual(submissions.first?.availabilityStatus, .pendingReview)
        XCTAssertEqual(http.requests.first?.url?.path, "/v1/vendor/submissions")
        XCTAssertEqual(http.requests.first?.httpMethod, "GET")
    }

    func testSubmitVendorProfileEncodesBackendContract() async throws {
        let http = MockHTTPClient()
        http.nextData = """
        {
          "profile": {
            "id": "submitted-hotdog",
            "name": "Boardwalk Snap",
            "style": "Classic cart dog",
            "price_dollars": 6.25,
            "signature_notes": "Mustard, relish, and onion.",
            "distance_miles": 1.8,
            "vendor_name": "Boardwalk Dogs",
            "image_url": "https://cdn.example.com/boardwalk.jpg",
            "menu_url": "https://boardwalk.example.com/menu",
            "media_alt_text": "Classic hotdog on a paper tray",
            "crave_score": 0.5,
            "availability_status": "pending_review",
            "last_verified_at": null
          }
        }
        """.data(using: .utf8)!
        let client = DogSwipeAPIClient(baseURL: URL(string: "http://localhost:8000")!, httpClient: http)

        let profile = try await client.submitVendorProfile(
            VendorSubmissionRequest(
                name: "Boardwalk Snap",
                style: "Classic cart dog",
                priceDollars: 6.25,
                signatureNotes: "Mustard, relish, and onion.",
                distanceMiles: 1.8,
                vendorName: "Boardwalk Dogs",
                imageURL: URL(string: "https://cdn.example.com/boardwalk.jpg"),
                menuURL: URL(string: "https://boardwalk.example.com/menu"),
                mediaAltText: "Classic hotdog on a paper tray"
            )
        )

        XCTAssertEqual(profile.availabilityStatus, .pendingReview)
        XCTAssertEqual(http.requests.first?.url?.path, "/v1/vendor/submissions")
        XCTAssertEqual(http.requests.first?.httpMethod, "POST")
        let body = String(data: http.requests.first!.httpBody!, encoding: .utf8)!
        XCTAssertFalse(body.contains("user_id"))
        XCTAssertTrue(body.contains("\"name\":\"Boardwalk Snap\""))
        XCTAssertTrue(body.contains("\"price_dollars\":6.25"))
        XCTAssertTrue(body.contains("\"menu_url\":\"https:\\/\\/boardwalk.example.com\\/menu\""))
    }

    func testUpdateVendorSubmissionEncodesBackendContract() async throws {
        let http = MockHTTPClient()
        http.nextData = """
        {
          "profile": {
            "id": "submitted-hotdog",
            "name": "Edited Snap",
            "style": "Classic cart dog",
            "price_dollars": 6.5,
            "signature_notes": "Mustard, relish, onion, and celery salt.",
            "distance_miles": 1.9,
            "vendor_name": "Boardwalk Dogs",
            "image_url": null,
            "menu_url": "https://boardwalk.example.com/menu",
            "media_alt_text": null,
            "crave_score": 0.5,
            "availability_status": "pending_review",
            "review_note": null,
            "last_verified_at": null,
            "last_reviewed_at": null
          }
        }
        """.data(using: .utf8)!
        let client = DogSwipeAPIClient(baseURL: URL(string: "http://localhost:8000")!, httpClient: http)

        let profile = try await client.updateVendorSubmission(
            profileID: "submitted-hotdog",
            submission: VendorSubmissionRequest(
                name: "Edited Snap",
                style: "Classic cart dog",
                priceDollars: 6.5,
                signatureNotes: "Mustard, relish, onion, and celery salt.",
                distanceMiles: 1.9,
                vendorName: "Boardwalk Dogs",
                menuURL: URL(string: "https://boardwalk.example.com/menu")
            )
        )

        XCTAssertEqual(profile.name, "Edited Snap")
        XCTAssertEqual(profile.reviewNote, nil)
        XCTAssertEqual(http.requests.first?.url?.path, "/v1/vendor/submissions/submitted-hotdog")
        XCTAssertEqual(http.requests.first?.httpMethod, "PUT")
        let body = String(data: http.requests.first!.httpBody!, encoding: .utf8)!
        XCTAssertTrue(body.contains("\"price_dollars\":6.5"))
    }

    func testAdminReviewQueueDecodesBackendContract() async throws {
        let http = MockHTTPClient()
        http.nextData = try JSONEncoder().encode(
            AdminReviewQueueResponse(
                submissions: [
                    HotdogProfile(
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
                ]
            )
        )
        let client = DogSwipeAPIClient(baseURL: URL(string: "http://localhost:8000")!, httpClient: http)

        let queue = try await client.adminReviewQueue()

        XCTAssertEqual(queue.map(\.id), ["pending-hotdog"])
        XCTAssertEqual(queue.first?.availabilityStatus, .pendingReview)
        XCTAssertEqual(http.requests.first?.url?.path, "/v1/admin/vendor/submissions")
        XCTAssertEqual(http.requests.first?.httpMethod, "GET")
    }

    func testApproveVendorSubmissionEncodesBackendContract() async throws {
        let http = MockHTTPClient()
        http.nextData = try encodedReviewResponse(
            status: .available,
            craveScore: 0.86,
            lastVerifiedAt: "2026-05-05T14:00:00Z"
        )
        let client = DogSwipeAPIClient(baseURL: URL(string: "http://localhost:8000")!, httpClient: http)

        let profile = try await client.approveVendorSubmission(
            profileID: "pending-hotdog",
            craveScore: 0.86
        )

        XCTAssertEqual(profile.availabilityStatus, .available)
        XCTAssertEqual(profile.craveScore, 0.86)
        XCTAssertEqual(
            http.requests.first?.url?.path,
            "/v1/admin/vendor/submissions/pending-hotdog/approve"
        )
        XCTAssertEqual(http.requests.first?.httpMethod, "POST")
        let body = String(data: http.requests.first!.httpBody!, encoding: .utf8)!
        XCTAssertTrue(body.contains("\"crave_score\":0.86"))
    }

    func testRequestVendorSubmissionChangesEncodesBackendContract() async throws {
        let http = MockHTTPClient()
        http.nextData = try encodedReviewResponse(
            status: .changesRequested,
            reviewNote: "Add a current menu URL.",
            lastReviewedAt: "2026-05-05T14:05:00Z"
        )
        let client = DogSwipeAPIClient(baseURL: URL(string: "http://localhost:8000")!, httpClient: http)

        let profile = try await client.requestVendorSubmissionChanges(
            profileID: "pending-hotdog",
            reviewNote: "Add a current menu URL."
        )

        XCTAssertEqual(profile.availabilityStatus, .changesRequested)
        XCTAssertEqual(profile.reviewNote, "Add a current menu URL.")
        XCTAssertEqual(
            http.requests.first?.url?.path,
            "/v1/admin/vendor/submissions/pending-hotdog/request-changes"
        )
        XCTAssertEqual(http.requests.first?.httpMethod, "POST")
        let body = String(data: http.requests.first!.httpBody!, encoding: .utf8)!
        XCTAssertTrue(body.contains("\"review_note\":\"Add a current menu URL.\""))
    }

    func testRejectVendorSubmissionEncodesBackendContract() async throws {
        let http = MockHTTPClient()
        http.nextData = try encodedReviewResponse(
            status: .rejected,
            reviewNote: "Listing does not show a hotdog item.",
            lastReviewedAt: "2026-05-05T14:10:00Z"
        )
        let client = DogSwipeAPIClient(baseURL: URL(string: "http://localhost:8000")!, httpClient: http)

        let profile = try await client.rejectVendorSubmission(
            profileID: "pending-hotdog",
            reviewNote: "Listing does not show a hotdog item."
        )

        XCTAssertEqual(profile.availabilityStatus, .rejected)
        XCTAssertEqual(profile.reviewNote, "Listing does not show a hotdog item.")
        XCTAssertEqual(http.requests.first?.url?.path, "/v1/admin/vendor/submissions/pending-hotdog/reject")
        XCTAssertEqual(http.requests.first?.httpMethod, "POST")
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

    private func encodedReviewResponse(
        status: AvailabilityStatus,
        craveScore: Double = 0.5,
        reviewNote: String? = nil,
        lastVerifiedAt: String? = nil,
        lastReviewedAt: String? = nil
    ) throws -> Data {
        try JSONEncoder().encode(
            AdminModerationResponse(
                profile: HotdogProfile(
                    id: "pending-hotdog",
                    name: "Pending Snap",
                    style: "Classic cart dog",
                    priceDollars: 6.25,
                    signatureNotes: "Mustard, relish, and onion.",
                    distanceMiles: 1.8,
                    vendorName: "Boardwalk Dogs",
                    craveScore: craveScore,
                    availabilityStatus: status,
                    reviewNote: reviewNote,
                    lastVerifiedAt: lastVerifiedAt,
                    lastReviewedAt: lastReviewedAt
                )
            )
        )
    }
}
