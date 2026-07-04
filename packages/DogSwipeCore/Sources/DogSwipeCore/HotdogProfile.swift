import Foundation

public struct HotdogProfile: Identifiable, Codable, Equatable, Sendable {
    public let id: String
    public let name: String
    public let style: String
    public let category: String
    public let tags: [String]
    public let creditCost: Int
    public let signatureNotes: String
    public let distanceMiles: Double
    public let latitude: Double?
    public let longitude: Double?
    public let walkingTimeMinutes: Int?
    public let vendorName: String
    public let addressText: String?
    public let imageURL: URL?
    public let menuURL: URL?
    public let menuStatus: String?
    public let menuExcerpt: String?
    public let menuHighlights: [String]?
    public let menuCheckedAt: String?
    public let mediaAltText: String?
    public let craveScore: Double
    public let availabilityStatus: AvailabilityStatus
    public let reviewNote: String?
    public let lastVerifiedAt: String?
    public let lastReviewedAt: String?
    public let addOns: [DogSwipeOrderAddOn]
    public let reputationRating: Double?
    public let reputationReviewCount: Int

    public init(
        id: String,
        name: String,
        style: String,
        category: String = "hotdog",
        tags: [String] = [],
        creditCost: Int,
        signatureNotes: String,
        distanceMiles: Double,
        latitude: Double? = nil,
        longitude: Double? = nil,
        walkingTimeMinutes: Int? = nil,
        vendorName: String,
        addressText: String? = nil,
        imageURL: URL? = nil,
        menuURL: URL? = nil,
        menuStatus: String? = nil,
        menuExcerpt: String? = nil,
        menuHighlights: [String]? = nil,
        menuCheckedAt: String? = nil,
        mediaAltText: String? = nil,
        craveScore: Double,
        availabilityStatus: AvailabilityStatus = .available,
        reviewNote: String? = nil,
        lastVerifiedAt: String? = nil,
        lastReviewedAt: String? = nil,
        addOns: [DogSwipeOrderAddOn] = [],
        reputationRating: Double? = nil,
        reputationReviewCount: Int = 0
    ) {
        self.id = id
        self.name = name
        self.style = style
        self.category = category
        self.tags = tags
        self.creditCost = creditCost
        self.signatureNotes = signatureNotes
        self.distanceMiles = distanceMiles
        self.latitude = latitude
        self.longitude = longitude
        self.walkingTimeMinutes = walkingTimeMinutes
        self.vendorName = vendorName
        self.addressText = addressText
        self.imageURL = imageURL
        self.menuURL = menuURL
        self.menuStatus = menuStatus
        self.menuExcerpt = menuExcerpt
        self.menuHighlights = menuHighlights
        self.menuCheckedAt = menuCheckedAt
        self.mediaAltText = mediaAltText
        self.craveScore = craveScore
        self.availabilityStatus = availabilityStatus
        self.reviewNote = reviewNote
        self.lastVerifiedAt = lastVerifiedAt
        self.lastReviewedAt = lastReviewedAt
        self.addOns = addOns
        self.reputationRating = reputationRating
        self.reputationReviewCount = reputationReviewCount
    }

    public var creditLabel: String {
        "\(creditCost) credits"
    }

    public var categoryLabel: String {
        category.prefix(1).uppercased() + category.dropFirst()
    }

    public var walkingTimeLabel: String {
        let minutes = walkingTimeMinutes ?? max(1, Int(((distanceMiles / 3) * 60).rounded()))
        return "\(minutes) min"
    }

    public var reputationLabel: String? {
        guard let rating = reputationRating, reputationReviewCount > 0 else { return nil }
        return String(format: "%.1f (%d)", rating, reputationReviewCount)
    }

    public var menuHighlightLabels: [String] {
        menuHighlights ?? []
    }

    public var directionsURL: URL? {
        var components = URLComponents(string: "https://maps.apple.com/")
        if let latitude, let longitude {
            components?.queryItems = [
                URLQueryItem(name: "daddr", value: "\(latitude),\(longitude)"),
                URLQueryItem(name: "dirflg", value: "w")
            ]
            return components?.url
        }
        guard let address = addressText?.trimmingCharacters(in: .whitespacesAndNewlines),
              !address.isEmpty else {
            return nil
        }
        components?.queryItems = [
            URLQueryItem(name: "daddr", value: address),
            URLQueryItem(name: "dirflg", value: "w")
        ]
        return components?.url
    }

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case style
        case category
        case tags
        case creditCost = "credit_cost"
        case signatureNotes = "signature_notes"
        case distanceMiles = "distance_miles"
        case latitude
        case longitude
        case walkingTimeMinutes = "walking_time_minutes"
        case vendorName = "vendor_name"
        case addressText = "address_text"
        case imageURL = "image_url"
        case menuURL = "menu_url"
        case menuStatus = "menu_status"
        case menuExcerpt = "menu_excerpt"
        case menuHighlights = "menu_highlights"
        case menuCheckedAt = "menu_checked_at"
        case mediaAltText = "media_alt_text"
        case craveScore = "crave_score"
        case availabilityStatus = "availability_status"
        case reviewNote = "review_note"
        case lastVerifiedAt = "last_verified_at"
        case lastReviewedAt = "last_reviewed_at"
        case addOns = "add_ons"
        case reputationRating = "reputation_rating"
        case reputationReviewCount = "reputation_review_count"
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        name = try c.decode(String.self, forKey: .name)
        style = try c.decode(String.self, forKey: .style)
        category = try c.decodeIfPresent(String.self, forKey: .category) ?? "hotdog"
        tags = try c.decodeIfPresent([String].self, forKey: .tags) ?? []
        creditCost = try c.decode(Int.self, forKey: .creditCost)
        signatureNotes = try c.decode(String.self, forKey: .signatureNotes)
        distanceMiles = try c.decode(Double.self, forKey: .distanceMiles)
        latitude = try c.decodeIfPresent(Double.self, forKey: .latitude)
        longitude = try c.decodeIfPresent(Double.self, forKey: .longitude)
        walkingTimeMinutes = try c.decodeIfPresent(Int.self, forKey: .walkingTimeMinutes)
        vendorName = try c.decode(String.self, forKey: .vendorName)
        addressText = try c.decodeIfPresent(String.self, forKey: .addressText)
        imageURL = try c.decodeIfPresent(URL.self, forKey: .imageURL)
        menuURL = try c.decodeIfPresent(URL.self, forKey: .menuURL)
        menuStatus = try c.decodeIfPresent(String.self, forKey: .menuStatus)
        menuExcerpt = try c.decodeIfPresent(String.self, forKey: .menuExcerpt)
        menuHighlights = try c.decodeIfPresent([String].self, forKey: .menuHighlights)
        menuCheckedAt = try c.decodeIfPresent(String.self, forKey: .menuCheckedAt)
        mediaAltText = try c.decodeIfPresent(String.self, forKey: .mediaAltText)
        craveScore = try c.decode(Double.self, forKey: .craveScore)
        availabilityStatus = try c.decodeIfPresent(AvailabilityStatus.self, forKey: .availabilityStatus) ?? .available
        reviewNote = try c.decodeIfPresent(String.self, forKey: .reviewNote)
        lastVerifiedAt = try c.decodeIfPresent(String.self, forKey: .lastVerifiedAt)
        lastReviewedAt = try c.decodeIfPresent(String.self, forKey: .lastReviewedAt)
        addOns = try c.decodeIfPresent([DogSwipeOrderAddOn].self, forKey: .addOns) ?? []
        reputationRating = try c.decodeIfPresent(Double.self, forKey: .reputationRating)
        reputationReviewCount = try c.decodeIfPresent(Int.self, forKey: .reputationReviewCount) ?? 0
    }
}

public enum AvailabilityStatus: String, Codable, Equatable, Sendable {
    case available
    case limited
    case soldOut = "sold_out"
    case pendingReview = "pending_review"
    case changesRequested = "changes_requested"
    case rejected
}

public struct DiscoveryResponse: Codable, Equatable, Sendable {
    public let profiles: [HotdogProfile]

    public init(profiles: [HotdogProfile]) {
        self.profiles = profiles
    }
}

public struct MatchResponse: Codable, Equatable, Sendable {
    public let matches: [HotdogProfile]

    public init(matches: [HotdogProfile]) {
        self.matches = matches
    }
}

public struct DogSwipeOrderAddOn: Identifiable, Codable, Equatable, Sendable {
    public let id: String
    public let name: String
    public let creditCost: Int

    public init(id: String, name: String, creditCost: Int) {
        self.id = id
        self.name = name
        self.creditCost = creditCost
    }

    public var creditLabel: String {
        Self.creditLabel(for: creditCost)
    }

    public static func creditLabel(for amount: Int) -> String {
        "\(amount) credits"
    }

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case creditCost = "credit_cost"
    }
}

public struct DogSwipeOrder: Identifiable, Codable, Equatable, Sendable {
    public let id: String
    public let profileID: String
    public let hotdogName: String
    public let vendorName: String
    public let baseCreditCost: Int
    public let addOns: [DogSwipeOrderAddOn]
    public let totalCredits: Int
    public let status: String
    public let createdAt: String
    public let fulfillmentMode: String
    public let availableFrom: String?
    public let availableUntil: String?
    public let deliveryAddress: String?
    public let makerReadyConfirmedAt: String?
    public let makerHandoffConfirmedAt: String?
    public let claimerHandoffConfirmedAt: String?
    public let completedAt: String?

    public init(
        id: String,
        profileID: String,
        hotdogName: String,
        vendorName: String,
        baseCreditCost: Int,
        addOns: [DogSwipeOrderAddOn],
        totalCredits: Int,
        status: String,
        createdAt: String,
        fulfillmentMode: String = "pickup",
        availableFrom: String? = nil,
        availableUntil: String? = nil,
        deliveryAddress: String? = nil,
        makerReadyConfirmedAt: String? = nil,
        makerHandoffConfirmedAt: String? = nil,
        claimerHandoffConfirmedAt: String? = nil,
        completedAt: String? = nil
    ) {
        self.id = id
        self.profileID = profileID
        self.hotdogName = hotdogName
        self.vendorName = vendorName
        self.baseCreditCost = baseCreditCost
        self.addOns = addOns
        self.totalCredits = totalCredits
        self.status = status
        self.createdAt = createdAt
        self.fulfillmentMode = fulfillmentMode
        self.availableFrom = availableFrom
        self.availableUntil = availableUntil
        self.deliveryAddress = deliveryAddress
        self.makerReadyConfirmedAt = makerReadyConfirmedAt
        self.makerHandoffConfirmedAt = makerHandoffConfirmedAt
        self.claimerHandoffConfirmedAt = claimerHandoffConfirmedAt
        self.completedAt = completedAt
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        profileID = try c.decode(String.self, forKey: .profileID)
        hotdogName = try c.decode(String.self, forKey: .hotdogName)
        vendorName = try c.decode(String.self, forKey: .vendorName)
        baseCreditCost = try c.decode(Int.self, forKey: .baseCreditCost)
        addOns = try c.decode([DogSwipeOrderAddOn].self, forKey: .addOns)
        totalCredits = try c.decode(Int.self, forKey: .totalCredits)
        status = try c.decode(String.self, forKey: .status)
        createdAt = try c.decode(String.self, forKey: .createdAt)
        fulfillmentMode = try c.decodeIfPresent(String.self, forKey: .fulfillmentMode) ?? "pickup"
        availableFrom = try c.decodeIfPresent(String.self, forKey: .availableFrom)
        availableUntil = try c.decodeIfPresent(String.self, forKey: .availableUntil)
        deliveryAddress = try c.decodeIfPresent(String.self, forKey: .deliveryAddress)
        makerReadyConfirmedAt = try c.decodeIfPresent(String.self, forKey: .makerReadyConfirmedAt)
        makerHandoffConfirmedAt = try c.decodeIfPresent(String.self, forKey: .makerHandoffConfirmedAt)
        claimerHandoffConfirmedAt = try c.decodeIfPresent(String.self, forKey: .claimerHandoffConfirmedAt)
        completedAt = try c.decodeIfPresent(String.self, forKey: .completedAt)
    }

    public var totalLabel: String {
        DogSwipeOrderAddOn.creditLabel(for: totalCredits)
    }

    public var addOnSummary: String {
        guard !addOns.isEmpty else {
            return "No add-ons"
        }
        return addOns.map(\.name).joined(separator: ", ")
    }

    public var isPickup: Bool { fulfillmentMode == "pickup" }
    public var isDelivery: Bool { fulfillmentMode == "delivery" }

    enum CodingKeys: String, CodingKey {
        case id
        case profileID = "profile_id"
        case hotdogName = "hotdog_name"
        case vendorName = "vendor_name"
        case baseCreditCost = "base_credit_cost"
        case addOns = "add_ons"
        case totalCredits = "total_credits"
        case status
        case createdAt = "created_at"
        case fulfillmentMode = "fulfillment_mode"
        case availableFrom = "available_from"
        case availableUntil = "available_until"
        case deliveryAddress = "delivery_address"
        case makerReadyConfirmedAt = "maker_ready_confirmed_at"
        case makerHandoffConfirmedAt = "maker_handoff_confirmed_at"
        case claimerHandoffConfirmedAt = "claimer_handoff_confirmed_at"
        case completedAt = "completed_at"
    }
}

public struct OrderCreateRequest: Codable, Equatable, Sendable {
    public let profileID: String
    public let addOnIDs: [String]

    public init(profileID: String, addOnIDs: [String]) {
        self.profileID = profileID
        self.addOnIDs = addOnIDs
    }

    enum CodingKeys: String, CodingKey {
        case profileID = "profile_id"
        case addOnIDs = "add_on_ids"
    }
}

public struct OrderResponse: Codable, Equatable, Sendable {
    public let order: DogSwipeOrder

    public init(order: DogSwipeOrder) {
        self.order = order
    }
}

public struct OrderListResponse: Codable, Equatable, Sendable {
    public let orders: [DogSwipeOrder]

    public init(orders: [DogSwipeOrder]) {
        self.orders = orders
    }
}

public struct VendorSubmissionRequest: Codable, Equatable, Sendable {
    public let vendorName: String
    public let name: String
    public let signatureNotes: String
    public let style: String
    public let menuURL: URL?
    public let addressText: String?
    public let creditCost: Int
    public let distanceMiles: Double
    public let imageURL: URL?
    public let latitude: Double?
    public let mediaAltText: String?
    public let longitude: Double?

    public init(
        vendorName: String,
        name: String,
        signatureNotes: String,
        style: String,
        menuURL: URL? = nil,
        addressText: String? = nil,
        creditCost: Int,
        distanceMiles: Double,
        imageURL: URL? = nil,
        latitude: Double? = nil,
        mediaAltText: String? = nil,
        longitude: Double? = nil
    ) {
        self.vendorName = vendorName
        self.name = name
        self.signatureNotes = signatureNotes
        self.style = style
        self.menuURL = menuURL
        self.addressText = addressText
        self.creditCost = creditCost
        self.distanceMiles = distanceMiles
        self.imageURL = imageURL
        self.latitude = latitude
        self.mediaAltText = mediaAltText
        self.longitude = longitude
    }

    enum CodingKeys: String, CodingKey {
        case vendorName = "vendor_name"
        case name
        case signatureNotes = "signature_notes"
        case style
        case menuURL = "menu_url"
        case addressText = "address_text"
        case creditCost = "credit_cost"
        case distanceMiles = "distance_miles"
        case imageURL = "image_url"
        case latitude
        case mediaAltText = "media_alt_text"
        case longitude
    }
}

public struct VendorSubmissionResponse: Codable, Equatable, Sendable {
    public let profile: HotdogProfile

    public init(profile: HotdogProfile) {
        self.profile = profile
    }
}

public struct MenuIngestionResponse: Codable, Equatable, Sendable {
    public let profile: HotdogProfile

    public init(profile: HotdogProfile) {
        self.profile = profile
    }
}

public struct VendorSubmissionListResponse: Codable, Equatable, Sendable {
    public let submissions: [HotdogProfile]

    public init(submissions: [HotdogProfile]) {
        self.submissions = submissions
    }
}

public struct AdminApprovalRequest: Codable, Equatable, Sendable {
    public let craveScore: Double

    public init(craveScore: Double = 0.72) {
        self.craveScore = craveScore
    }

    enum CodingKeys: String, CodingKey {
        case craveScore = "crave_score"
    }
}

public struct AdminReviewQueueResponse: Codable, Equatable, Sendable {
    public let submissions: [HotdogProfile]

    public init(submissions: [HotdogProfile]) {
        self.submissions = submissions
    }
}

public struct AdminApprovalResponse: Codable, Equatable, Sendable {
    public let profile: HotdogProfile

    public init(profile: HotdogProfile) {
        self.profile = profile
    }
}

public struct AdminModerationRequest: Codable, Equatable, Sendable {
    public let reviewNote: String

    public init(reviewNote: String) {
        self.reviewNote = reviewNote
    }

    enum CodingKeys: String, CodingKey {
        case reviewNote = "review_note"
    }
}

public struct AdminModerationResponse: Codable, Equatable, Sendable {
    public let profile: HotdogProfile

    public init(profile: HotdogProfile) {
        self.profile = profile
    }
}

public struct AdminMenuRefreshRequest: Codable, Equatable, Sendable {
    public let limit: Int
    public let maxAgeHours: Double

    public init(limit: Int = 20, maxAgeHours: Double = 24) {
        self.limit = limit
        self.maxAgeHours = maxAgeHours
    }

    enum CodingKeys: String, CodingKey {
        case limit
        case maxAgeHours = "max_age_hours"
    }
}

public struct AdminMenuRefreshResponse: Codable, Equatable, Sendable {
    public let checkedCount: Int
    public let refreshedCount: Int
    public let failedCount: Int
    public let profiles: [HotdogProfile]

    public init(
        checkedCount: Int,
        refreshedCount: Int,
        failedCount: Int,
        profiles: [HotdogProfile]
    ) {
        self.checkedCount = checkedCount
        self.refreshedCount = refreshedCount
        self.failedCount = failedCount
        self.profiles = profiles
    }

    enum CodingKeys: String, CodingKey {
        case checkedCount = "checked_count"
        case refreshedCount = "refreshed_count"
        case failedCount = "failed_count"
        case profiles
    }
}

public extension HotdogProfile {
    static let samples: [HotdogProfile] = [
        HotdogProfile(
            id: "hotdog-coney",
            name: "Coney Classic",
            style: "Chili dog",
            category: "hotdog",
            creditCost: 7,
            signatureNotes: "Beef frank, snap casing, chili, onion, and yellow mustard.",
            distanceMiles: 1.2,
            latitude: 43.6539,
            longitude: -79.3843,
            vendorName: "Franklin Cart",
            addressText: "100 Queen St W, Toronto, ON",
            menuExcerpt: "Coney Classic with chili, onion, and mustard.",
            menuHighlights: ["Chili", "Mustard", "Onion"],
            craveScore: 0.91,
            addOns: [
                DogSwipeOrderAddOn(id: "bacon", name: "Bacon", creditCost: 2),
                DogSwipeOrderAddOn(id: "extra-pickle", name: "Extra Pickle", creditCost: 1)
            ]
        ),
        HotdogProfile(
            id: "hotdog-kimchi",
            name: "Kimchi Crunch",
            style: "Korean street dog",
            category: "fusion",
            creditCost: 9,
            signatureNotes: "Gochujang mayo, kimchi, scallion, and sesame crunch.",
            distanceMiles: 2.4,
            latitude: 43.6555,
            longitude: -79.38,
            vendorName: "Bun Signal",
            addressText: "200 King St W, Toronto, ON",
            menuExcerpt: "Kimchi Crunch with fermented cabbage, gochujang mayo, and sesame.",
            menuHighlights: ["Kimchi", "Spicy", "Sesame"],
            craveScore: 0.88,
            addOns: [
                DogSwipeOrderAddOn(id: "sesame-crunch", name: "Sesame Crunch", creditCost: 1),
                DogSwipeOrderAddOn(id: "extra-kimchi", name: "Extra Kimchi", creditCost: 2)
            ]
        ),
        HotdogProfile(
            id: "hotdog-chicago",
            name: "Garden Snap",
            style: "Chicago dog",
            category: "hotdog",
            creditCost: 7,
            signatureNotes: "Sport peppers, relish, tomato, pickle spear, and celery salt.",
            distanceMiles: 3.1,
            latitude: 43.665,
            longitude: -79.407,
            vendorName: "Northside Stand",
            addressText: "860 Bloor St W, Toronto, ON",
            menuExcerpt: "Garden Snap with relish, pickle, sport peppers, and celery salt.",
            menuHighlights: ["Relish", "Pickle", "Sport peppers"],
            craveScore: 0.82,
            addOns: [
                DogSwipeOrderAddOn(id: "cheese-sauce", name: "Cheese Sauce", creditCost: 2),
                DogSwipeOrderAddOn(id: "jalapenos", name: "Jalapenos", creditCost: 1)
            ]
        ),
        HotdogProfile(
            id: "hotdog-nightcap",
            name: "Nightcap Melt",
            style: "Chili cheese dog",
            category: "loaded",
            creditCost: 9,
            signatureNotes: "Sharp cheddar, late-night chili, grilled onions, and jalapeno dust.",
            distanceMiles: 4.8,
            latitude: 43.647,
            longitude: -79.395,
            vendorName: "Depot Dogs",
            addressText: "65 Front St W, Toronto, ON",
            menuExcerpt: "Nightcap Melt with sharp cheddar, chili, grilled onions, and jalapeno.",
            menuHighlights: ["Cheddar", "Chili", "Jalapeno"],
            craveScore: 0.69,
            addOns: [
                DogSwipeOrderAddOn(id: "extra-chili", name: "Extra Chili", creditCost: 1),
                DogSwipeOrderAddOn(id: "onion-rings", name: "Onion Rings", creditCost: 3)
            ]
        )
    ]
}
