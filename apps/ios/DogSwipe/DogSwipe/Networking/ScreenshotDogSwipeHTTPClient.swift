import DogSwipeCore
import Foundation

struct ScreenshotDogSwipeHTTPClient: DogSwipeHTTPClient {
    func data(for request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        let url = request.url ?? AppEnvironment.apiBaseURL
        let data = try responseData(for: request)
        let response = HTTPURLResponse(
            url: url,
            statusCode: 200,
            httpVersion: nil,
            headerFields: ["Content-Type": "application/json"]
        )!
        return (data, response)
    }

    private func responseData(for request: URLRequest) throws -> Data {
        let path = request.url?.path ?? "/"
        let method = request.httpMethod ?? "GET"
        let encoder = JSONEncoder()

        switch (method, path) {
        case ("GET", "/v1/discovery"):
            return try encoder.encode(DiscoveryResponse(profiles: ScreenshotHotdogs.discovery))
        case ("POST", "/v1/swipes"):
            return try encoder.encode(
                SwipeResponse(profileID: "screenshot-coney", decision: .like, matched: true)
            )
        case ("GET", "/v1/matches"):
            return try encoder.encode(MatchResponse(matches: ScreenshotHotdogs.matches))
        case ("GET", "/v1/preferences"), ("PUT", "/v1/preferences"):
            return try encoder.encode(
                DiscoveryPreferences(maxDistanceMiles: 6, spicyFriendly: true, classicOnly: false)
            )
        case ("GET", "/v1/vendor/submissions"):
            return try encoder.encode(
                VendorSubmissionListResponse(submissions: ScreenshotHotdogs.vendorSubmissions)
            )
        case ("POST", "/v1/vendor/submissions"):
            return try encoder.encode(
                VendorSubmissionResponse(profile: ScreenshotHotdogs.submittedProfile)
            )
        case ("PUT", _)
            where path.hasPrefix("/v1/vendor/submissions/"):
            return try encoder.encode(
                VendorSubmissionResponse(profile: ScreenshotHotdogs.submittedProfile)
            )
        case ("POST", _)
            where path.hasPrefix("/v1/vendor/submissions/")
                && path.hasSuffix("/ingest-menu"):
            return try encoder.encode(
                MenuIngestionResponse(profile: ScreenshotHotdogs.refreshedSubmission)
            )
        case ("GET", "/v1/admin/vendor/submissions"):
            return try encoder.encode(
                AdminReviewQueueResponse(submissions: ScreenshotHotdogs.adminQueue)
            )
        case ("POST", "/v1/admin/vendor/menus/refresh"):
            return try encoder.encode(
                AdminMenuRefreshResponse(
                    checkedCount: 1,
                    refreshedCount: 1,
                    failedCount: 0,
                    profiles: ScreenshotHotdogs.adminQueue
                )
            )
        case ("POST", _)
            where path.hasPrefix("/v1/admin/vendor/submissions/")
                && path.hasSuffix("/approve"):
            return try encoder.encode(
                AdminApprovalResponse(profile: ScreenshotHotdogs.approvedSubmission)
            )
        case ("POST", _)
            where path.hasPrefix("/v1/admin/vendor/submissions/")
                && path.hasSuffix("/request-changes"):
            return try encoder.encode(
                AdminModerationResponse(profile: ScreenshotHotdogs.changesRequestedSubmission)
            )
        case ("POST", _)
            where path.hasPrefix("/v1/admin/vendor/submissions/")
                && path.hasSuffix("/reject"):
            return try encoder.encode(
                AdminModerationResponse(profile: ScreenshotHotdogs.rejectedSubmission)
            )
        case ("POST", "/api/auth/magic-link"):
            return Data(#"{"success":true,"data":{}}"#.utf8)
        case ("POST", "/api/auth/verify-magic-link"), ("POST", "/api/auth/refresh"):
            return Data(
                """
                {"access_token":"screenshot-access-token","refresh_token":"screenshot-refresh-token","user":{"email":"taster@example.com"}}
                """.utf8
            )
        default:
            return Data(#"{}"#.utf8)
        }
    }
}

private enum ScreenshotHotdogs {
    static let discovery = [
        coney,
        kimchi,
        chicago,
        nightcap
    ]

    static let matches = [
        coney,
        chicago,
        kimchi
    ]

    static let vendorSubmissions = [
        pendingVendorSubmission,
        changesRequestedSubmission
    ]

    static let adminQueue = [
        pendingVendorSubmission,
        kimchiReview
    ]

    static let coney = HotdogProfile(
        id: "screenshot-coney",
        name: "Coney Classic",
        style: "Chili dog",
        priceDollars: 6.5,
        signatureNotes: "Beef frank, snap casing, chili, diced onion, and yellow mustard.",
        distanceMiles: 0.7,
        latitude: 43.6539,
        longitude: -79.3843,
        walkingTimeMinutes: 9,
        vendorName: "Franklin Cart",
        addressText: "100 Queen St W, Toronto, ON",
        menuURL: URL(string: "https://example.com/franklin-cart-menu"),
        menuStatus: "ok",
        menuExcerpt: "Coney Classic with chili, onion, and mustard.",
        menuHighlights: ["Chili", "Mustard", "Onion"],
        menuCheckedAt: "2026-05-05T16:30:00Z",
        mediaAltText: "Classic chili hotdog in a paper tray",
        craveScore: 0.94
    )

    static let kimchi = HotdogProfile(
        id: "screenshot-kimchi",
        name: "Kimchi Crunch",
        style: "Korean street dog",
        priceDollars: 8.75,
        signatureNotes: "Gochujang mayo, kimchi, scallion, and sesame crunch.",
        distanceMiles: 1.8,
        latitude: 43.6555,
        longitude: -79.38,
        walkingTimeMinutes: 22,
        vendorName: "Bun Signal",
        addressText: "200 King St W, Toronto, ON",
        menuURL: URL(string: "https://example.com/bun-signal-menu"),
        menuStatus: "ok",
        menuExcerpt: "Kimchi Crunch with fermented cabbage, gochujang mayo, and sesame.",
        menuHighlights: ["Kimchi", "Spicy", "Sesame"],
        mediaAltText: "Korean hotdog with kimchi and scallions",
        craveScore: 0.89
    )

    static let chicago = HotdogProfile(
        id: "screenshot-chicago",
        name: "Garden Snap",
        style: "Chicago dog",
        priceDollars: 7.25,
        signatureNotes: "Sport peppers, relish, tomato, pickle spear, and celery salt.",
        distanceMiles: 2.2,
        latitude: 43.665,
        longitude: -79.407,
        walkingTimeMinutes: 27,
        vendorName: "Northside Stand",
        addressText: "860 Bloor St W, Toronto, ON",
        menuHighlights: ["Relish", "Pickle", "Sport peppers"],
        craveScore: 0.84
    )

    static let nightcap = HotdogProfile(
        id: "screenshot-nightcap",
        name: "Nightcap Melt",
        style: "Chili cheese dog",
        priceDollars: 9,
        signatureNotes: "Sharp cheddar, late-night chili, grilled onions, and jalapeno dust.",
        distanceMiles: 3.4,
        latitude: 43.647,
        longitude: -79.395,
        walkingTimeMinutes: 41,
        vendorName: "Depot Dogs",
        addressText: "65 Front St W, Toronto, ON",
        menuHighlights: ["Cheddar", "Chili", "Jalapeno"],
        craveScore: 0.76,
        availabilityStatus: .limited
    )

    static let pendingVendorSubmission = HotdogProfile(
        id: "screenshot-pending-vendor",
        name: "Boardwalk Snap",
        style: "Classic cart dog",
        priceDollars: 6.25,
        signatureNotes: "Mustard, relish, and onion on a griddled bun.",
        distanceMiles: 1.1,
        latitude: 43.6501,
        longitude: -79.3869,
        walkingTimeMinutes: 14,
        vendorName: "Boardwalk Dogs",
        addressText: "10 Bay St, Toronto, ON",
        menuURL: URL(string: "https://example.com/boardwalk-dogs-menu"),
        menuStatus: "ok",
        menuExcerpt: "Boardwalk Snap with mustard, relish, and onion.",
        menuHighlights: ["Mustard", "Relish", "Onion"],
        mediaAltText: "Classic hotdog from Boardwalk Dogs",
        craveScore: 0.62,
        availabilityStatus: .pendingReview,
        reviewNote: nil,
        lastVerifiedAt: "2026-05-05T15:45:00Z"
    )

    static let kimchiReview = copy(
        kimchi,
        id: "screenshot-kimchi-review",
        craveScore: 0.7,
        availabilityStatus: .pendingReview
    )

    static let submittedProfile = HotdogProfile(
        id: "screenshot-submitted",
        name: "Maple Crunch",
        style: "Canadian street dog",
        priceDollars: 7.5,
        signatureNotes: "Maple mustard, crisp onions, and a smoked beef frank.",
        distanceMiles: 1.4,
        vendorName: "Maple Cart",
        addressText: "150 Front St W, Toronto, ON",
        menuURL: URL(string: "https://example.com/maple-cart-menu"),
        menuHighlights: ["Maple", "Mustard", "Onion"],
        craveScore: 0.55,
        availabilityStatus: .pendingReview
    )

    static let refreshedSubmission = copy(
        pendingVendorSubmission,
        menuStatus: "ok",
        menuExcerpt: "Fresh menu snapshot: mustard, relish, onion, and kettle chips.",
        menuHighlights: ["Fresh menu", "Relish", "Onion"],
        lastVerifiedAt: "2026-05-05T16:30:00Z"
    )

    static let approvedSubmission = copy(
        pendingVendorSubmission,
        craveScore: 0.72,
        availabilityStatus: .available,
        lastReviewedAt: "2026-05-05T16:35:00Z"
    )

    static let changesRequestedSubmission = HotdogProfile(
        id: "screenshot-changes-requested",
        name: "Market Dog",
        style: "Classic cart dog",
        priceDollars: 6.75,
        signatureNotes: "Mustard, onion, relish, and poppyseed bun.",
        distanceMiles: 2.1,
        vendorName: "Market Dogs",
        addressText: "92 Front St E, Toronto, ON",
        menuURL: URL(string: "https://example.com/market-dogs-menu"),
        menuHighlights: ["Mustard", "Relish"],
        craveScore: 0.51,
        availabilityStatus: .changesRequested,
        reviewNote: "Add a current menu photo before review."
    )

    static let rejectedSubmission = HotdogProfile(
        id: "screenshot-rejected",
        name: "Off-menu Sandwich",
        style: "Not a hotdog",
        priceDollars: 11,
        signatureNotes: "Rejected fixture for moderation paths.",
        distanceMiles: 2.4,
        vendorName: "Wrong Bun",
        craveScore: 0.1,
        availabilityStatus: .rejected,
        reviewNote: "Listing does not show a hotdog item."
    )

    private static func copy(
        _ profile: HotdogProfile,
        id: String? = nil,
        menuStatus: String? = nil,
        menuExcerpt: String? = nil,
        menuHighlights: [String]? = nil,
        craveScore: Double? = nil,
        availabilityStatus: AvailabilityStatus? = nil,
        reviewNote: String? = nil,
        lastVerifiedAt: String? = nil,
        lastReviewedAt: String? = nil
    ) -> HotdogProfile {
        HotdogProfile(
            id: id ?? profile.id,
            name: profile.name,
            style: profile.style,
            priceDollars: profile.priceDollars,
            signatureNotes: profile.signatureNotes,
            distanceMiles: profile.distanceMiles,
            latitude: profile.latitude,
            longitude: profile.longitude,
            walkingTimeMinutes: profile.walkingTimeMinutes,
            vendorName: profile.vendorName,
            addressText: profile.addressText,
            imageURL: profile.imageURL,
            menuURL: profile.menuURL,
            menuStatus: menuStatus ?? profile.menuStatus,
            menuExcerpt: menuExcerpt ?? profile.menuExcerpt,
            menuHighlights: menuHighlights ?? profile.menuHighlights,
            menuCheckedAt: profile.menuCheckedAt,
            mediaAltText: profile.mediaAltText,
            craveScore: craveScore ?? profile.craveScore,
            availabilityStatus: availabilityStatus ?? profile.availabilityStatus,
            reviewNote: reviewNote ?? profile.reviewNote,
            lastVerifiedAt: lastVerifiedAt ?? profile.lastVerifiedAt,
            lastReviewedAt: lastReviewedAt ?? profile.lastReviewedAt
        )
    }
}
