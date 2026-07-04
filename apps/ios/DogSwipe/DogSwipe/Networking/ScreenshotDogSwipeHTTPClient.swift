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
        case ("GET", "/v1/orders"):
            return try encoder.encode(OrderListResponse(orders: ScreenshotHotdogs.orders))
        case ("POST", "/v1/orders"):
            return try encoder.encode(OrderResponse(order: ScreenshotHotdogs.createdOrder))
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
        case ("POST", _)
            where path.hasPrefix("/v1/orders/")
                && path.hasSuffix("/claim"):
            return try encoder.encode(OrderResponse(order: ScreenshotHotdogs.claimedOrder))
        case ("POST", _)
            where path.hasPrefix("/v1/orders/")
                && path.hasSuffix("/confirm-ready"):
            return try encoder.encode(OrderResponse(order: ScreenshotHotdogs.readyOrder))
        case ("POST", _)
            where path.hasPrefix("/v1/orders/")
                && path.hasSuffix("/confirm-hand-off"):
            return try encoder.encode(OrderResponse(order: ScreenshotHotdogs.handedOffOrder))
        case ("GET", "/v1/wallet"):
            return try encoder.encode(ScreenshotWallet.walletResponse)
        case ("POST", "/v1/credits/purchase"):
            return try encoder.encode(ScreenshotWallet.purchaseResponse)
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

    static let orders = [
        DogSwipeOrder(
            id: "screenshot-order-1",
            profileID: coney.id,
            hotdogName: coney.name,
            vendorName: coney.vendorName,
            baseCreditCost: coney.creditCost,
            addOns: [
                DogSwipeOrderAddOn(id: "bacon", name: "Bacon", creditCost: 2),
                DogSwipeOrderAddOn(id: "extra-pickle", name: "Extra Pickle", creditCost: 1)
            ],
            totalCredits: 9,
            status: "draft",
            createdAt: "2026-05-06T14:00:00Z"
        ),
        DogSwipeOrder(
            id: "screenshot-order-2",
            profileID: chicago.id,
            hotdogName: chicago.name,
            vendorName: chicago.vendorName,
            baseCreditCost: chicago.creditCost,
            addOns: [
                DogSwipeOrderAddOn(id: "jalapenos", name: "Jalapenos", creditCost: 1)
            ],
            totalCredits: 8,
            status: "ready",
            createdAt: "2026-05-06T13:40:00Z",
            fulfillmentMode: "pickup",
            availableFrom: "2026-05-06T17:00:00Z",
            availableUntil: "2026-05-06T19:00:00Z",
            makerReadyConfirmedAt: "2026-05-06T16:45:00Z"
        ),
        DogSwipeOrder(
            id: "screenshot-order-3",
            profileID: kimchi.id,
            hotdogName: kimchi.name,
            vendorName: kimchi.vendorName,
            baseCreditCost: kimchi.creditCost,
            addOns: [
                DogSwipeOrderAddOn(id: "sesame-crunch", name: "Sesame Crunch", creditCost: 1)
            ],
            totalCredits: 10,
            status: "completed",
            createdAt: "2026-05-05T12:00:00Z",
            makerReadyConfirmedAt: "2026-05-05T12:30:00Z",
            makerHandoffConfirmedAt: "2026-05-05T13:00:00Z",
            claimerHandoffConfirmedAt: "2026-05-05T13:01:00Z",
            completedAt: "2026-05-05T13:01:00Z"
        )
    ]

    static let claimedOrder = DogSwipeOrder(
        id: "screenshot-order-1",
        profileID: coney.id,
        hotdogName: coney.name,
        vendorName: coney.vendorName,
        baseCreditCost: coney.creditCost,
        addOns: [
            DogSwipeOrderAddOn(id: "bacon", name: "Bacon", creditCost: 2),
            DogSwipeOrderAddOn(id: "extra-pickle", name: "Extra Pickle", creditCost: 1)
        ],
        totalCredits: 9,
        status: "claimed",
        createdAt: "2026-05-06T14:00:00Z"
    )

    static let readyOrder = DogSwipeOrder(
        id: "screenshot-order-2",
        profileID: chicago.id,
        hotdogName: chicago.name,
        vendorName: chicago.vendorName,
        baseCreditCost: chicago.creditCost,
        addOns: [
            DogSwipeOrderAddOn(id: "jalapenos", name: "Jalapenos", creditCost: 1)
        ],
        totalCredits: 8,
        status: "ready",
        createdAt: "2026-05-06T13:40:00Z",
        fulfillmentMode: "pickup",
        availableFrom: "2026-05-06T17:00:00Z",
        availableUntil: "2026-05-06T19:00:00Z",
        makerReadyConfirmedAt: "2026-05-06T16:45:00Z"
    )

    static let handedOffOrder = DogSwipeOrder(
        id: "screenshot-order-2",
        profileID: chicago.id,
        hotdogName: chicago.name,
        vendorName: chicago.vendorName,
        baseCreditCost: chicago.creditCost,
        addOns: [
            DogSwipeOrderAddOn(id: "jalapenos", name: "Jalapenos", creditCost: 1)
        ],
        totalCredits: 8,
        status: "handed_off",
        createdAt: "2026-05-06T13:40:00Z",
        fulfillmentMode: "pickup",
        availableFrom: "2026-05-06T17:00:00Z",
        availableUntil: "2026-05-06T19:00:00Z",
        makerReadyConfirmedAt: "2026-05-06T16:45:00Z",
        claimerHandoffConfirmedAt: "2026-05-06T17:15:00Z"
    )

    static let createdOrder = DogSwipeOrder(
        id: "screenshot-order-created",
        profileID: coney.id,
        hotdogName: coney.name,
        vendorName: coney.vendorName,
        baseCreditCost: coney.creditCost,
        addOns: [
            DogSwipeOrderAddOn(id: "bacon", name: "Bacon", creditCost: 2)
        ],
        totalCredits: 8,
        status: "draft",
        createdAt: "2026-05-06T14:10:00Z"
    )

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
        name: "Chicago Classic",
        style: "Chicago style",
        category: "hotdog",
        creditCost: 6,
        signatureNotes: "All-beef dog, mustard, relish, onions, tomato, sport peppers, pickle spear, celery salt.",
        distanceMiles: 0.3,
        latitude: 41.8842,
        longitude: -87.6324,
        walkingTimeMinutes: 9,
        vendorName: "Street Vendor Pack",
        addressText: "35 W Wacker Dr, Chicago, IL",
        menuURL: URL(string: "https://example.com/street-vendor-pack-menu"),
        menuStatus: "ok",
        menuExcerpt: "Chicago Classic with all-beef frank, mustard, relish, onions, tomato, sport peppers, pickle spear, and celery salt.",
        menuHighlights: ["Mild", "All-Beef", "Crunchy", "Popular"],
        menuCheckedAt: "2026-05-05T16:30:00Z",
        mediaAltText: "Chicago style hotdog with mustard, relish, onion, tomato, pickle, and sport peppers",
        craveScore: 0.94,
        addOns: [
            DogSwipeOrderAddOn(id: "bacon", name: "Bacon", creditCost: 2),
            DogSwipeOrderAddOn(id: "extra-pickle", name: "Extra Pickle", creditCost: 1)
        ]
    )

    static let kimchi = HotdogProfile(
        id: "screenshot-kimchi",
        name: "Kimchi Crunch",
        style: "Korean street dog",
        category: "fusion",
        creditCost: 9,
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
        craveScore: 0.89,
        addOns: [
            DogSwipeOrderAddOn(id: "sesame-crunch", name: "Sesame Crunch", creditCost: 1),
            DogSwipeOrderAddOn(id: "extra-kimchi", name: "Extra Kimchi", creditCost: 2)
        ]
    )

    static let chicago = HotdogProfile(
        id: "screenshot-chicago",
        name: "Garden Snap",
        style: "Chicago dog",
        category: "hotdog",
        creditCost: 7,
        signatureNotes: "Sport peppers, relish, tomato, pickle spear, and celery salt.",
        distanceMiles: 2.2,
        latitude: 43.665,
        longitude: -79.407,
        walkingTimeMinutes: 27,
        vendorName: "Northside Stand",
        addressText: "860 Bloor St W, Toronto, ON",
        menuHighlights: ["Relish", "Pickle", "Sport peppers"],
        craveScore: 0.84,
        addOns: [
            DogSwipeOrderAddOn(id: "cheese-sauce", name: "Cheese Sauce", creditCost: 2),
            DogSwipeOrderAddOn(id: "jalapenos", name: "Jalapenos", creditCost: 1)
        ]
    )

    static let nightcap = HotdogProfile(
        id: "screenshot-nightcap",
        name: "Nightcap Melt",
        style: "Chili cheese dog",
        category: "loaded",
        creditCost: 9,
        signatureNotes: "Sharp cheddar, late-night chili, grilled onions, and jalapeno dust.",
        distanceMiles: 3.4,
        latitude: 43.647,
        longitude: -79.395,
        walkingTimeMinutes: 41,
        vendorName: "Depot Dogs",
        addressText: "65 Front St W, Toronto, ON",
        menuHighlights: ["Cheddar", "Chili", "Jalapeno"],
        craveScore: 0.76,
        availabilityStatus: .limited,
        addOns: [
            DogSwipeOrderAddOn(id: "extra-chili", name: "Extra Chili", creditCost: 1),
            DogSwipeOrderAddOn(id: "onion-rings", name: "Onion Rings", creditCost: 3)
        ]
    )

    static let pendingVendorSubmission = HotdogProfile(
        id: "screenshot-pending-vendor",
        name: "Boardwalk Snap",
        style: "Classic cart dog",
        creditCost: 6,
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
        creditCost: 8,
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
        creditCost: 7,
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
        creditCost: 11,
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
            category: profile.category,
            tags: profile.tags,
            creditCost: profile.creditCost,
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
            lastReviewedAt: lastReviewedAt ?? profile.lastReviewedAt,
            addOns: profile.addOns
        )
    }
}

private enum ScreenshotWallet {
    static let walletResponse = WalletResponse(
        account: CreditAccount(
            userID: "screenshot-user",
            lifetimePurchased: 50,
            lifetimeEarned: 12,
            lifetimeSpent: 23,
            createdAt: "2026-04-01T10:00:00Z",
            updatedAt: "2026-07-03T14:30:00Z"
        ),
        entries: [
            CreditLedgerEntry(
                id: "ledger-1",
                userID: "screenshot-user",
                entryType: .purchase,
                amount: 25,
                balanceAfter: 39,
                purchaseRef: "cs_test_1",
                reason: "Bought 25 credits",
                createdAt: "2026-07-03T14:30:00Z"
            ),
            CreditLedgerEntry(
                id: "ledger-2",
                userID: "screenshot-user",
                entryType: .spend,
                amount: 9,
                balanceAfter: 14,
                orderRef: "order-kimchi",
                reason: "Kimchi Crunch order",
                createdAt: "2026-07-02T18:15:00Z"
            ),
            CreditLedgerEntry(
                id: "ledger-3",
                userID: "screenshot-user",
                entryType: .earn,
                amount: 7,
                balanceAfter: 23,
                reason: "Sold Coney Classic",
                createdAt: "2026-07-01T12:00:00Z"
            ),
            CreditLedgerEntry(
                id: "ledger-4",
                userID: "screenshot-user",
                entryType: .purchase,
                amount: 25,
                balanceAfter: 16,
                purchaseRef: "cs_test_0",
                reason: "Bought 25 credits",
                createdAt: "2026-06-28T09:00:00Z"
            ),
            CreditLedgerEntry(
                id: "ledger-5",
                userID: "screenshot-user",
                entryType: .spend,
                amount: 7,
                balanceAfter: -9,
                orderRef: "order-garden",
                reason: "Garden Snap order",
                createdAt: "2026-06-25T19:45:00Z"
            ),
            CreditLedgerEntry(
                id: "ledger-6",
                userID: "screenshot-user",
                entryType: .earn,
                amount: 5,
                balanceAfter: -2,
                reason: "Sold Boardwalk Snap",
                createdAt: "2026-06-20T11:30:00Z"
            )
        ]
    )

    static let purchaseResponse = CreditPurchaseResponse(
        checkoutSessionID: "cs_test_screenshot",
        checkoutURL: "https://checkout.stripe.com/pay/cs_test_screenshot",
        amountCents: 1000,
        credits: 10
    )
}
