import Foundation

public struct HotdogProfile: Identifiable, Codable, Equatable, Sendable {
    public let id: String
    public let name: String
    public let style: String
    public let priceDollars: Double
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
    public let menuCheckedAt: String?
    public let mediaAltText: String?
    public let craveScore: Double
    public let availabilityStatus: AvailabilityStatus
    public let reviewNote: String?
    public let lastVerifiedAt: String?
    public let lastReviewedAt: String?

    public init(
        id: String,
        name: String,
        style: String,
        priceDollars: Double,
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
        menuCheckedAt: String? = nil,
        mediaAltText: String? = nil,
        craveScore: Double,
        availabilityStatus: AvailabilityStatus = .available,
        reviewNote: String? = nil,
        lastVerifiedAt: String? = nil,
        lastReviewedAt: String? = nil
    ) {
        self.id = id
        self.name = name
        self.style = style
        self.priceDollars = priceDollars
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
        self.menuCheckedAt = menuCheckedAt
        self.mediaAltText = mediaAltText
        self.craveScore = craveScore
        self.availabilityStatus = availabilityStatus
        self.reviewNote = reviewNote
        self.lastVerifiedAt = lastVerifiedAt
        self.lastReviewedAt = lastReviewedAt
    }

    public var priceLabel: String {
        if priceDollars.rounded() == priceDollars {
            return "$\(Int(priceDollars))"
        }
        return String(format: "$%.2f", priceDollars)
    }

    public var walkingTimeLabel: String {
        let minutes = walkingTimeMinutes ?? max(1, Int(((distanceMiles / 3) * 60).rounded()))
        return "\(minutes) min"
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
        case priceDollars = "price_dollars"
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
        case menuCheckedAt = "menu_checked_at"
        case mediaAltText = "media_alt_text"
        case craveScore = "crave_score"
        case availabilityStatus = "availability_status"
        case reviewNote = "review_note"
        case lastVerifiedAt = "last_verified_at"
        case lastReviewedAt = "last_reviewed_at"
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

public struct VendorSubmissionRequest: Codable, Equatable, Sendable {
    public let vendorName: String
    public let name: String
    public let signatureNotes: String
    public let style: String
    public let menuURL: URL?
    public let addressText: String?
    public let priceDollars: Double
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
        priceDollars: Double,
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
        self.priceDollars = priceDollars
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
        case priceDollars = "price_dollars"
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
            priceDollars: 6.5,
            signatureNotes: "Beef frank, snap casing, chili, onion, and yellow mustard.",
            distanceMiles: 1.2,
            latitude: 43.6539,
            longitude: -79.3843,
            vendorName: "Franklin Cart",
            addressText: "100 Queen St W, Toronto, ON",
            craveScore: 0.91
        ),
        HotdogProfile(
            id: "hotdog-kimchi",
            name: "Kimchi Crunch",
            style: "Korean street dog",
            priceDollars: 8.75,
            signatureNotes: "Gochujang mayo, kimchi, scallion, and sesame crunch.",
            distanceMiles: 2.4,
            latitude: 43.6555,
            longitude: -79.38,
            vendorName: "Bun Signal",
            addressText: "200 King St W, Toronto, ON",
            craveScore: 0.88
        ),
        HotdogProfile(
            id: "hotdog-chicago",
            name: "Garden Snap",
            style: "Chicago dog",
            priceDollars: 7.25,
            signatureNotes: "Sport peppers, relish, tomato, pickle spear, and celery salt.",
            distanceMiles: 3.1,
            latitude: 43.665,
            longitude: -79.407,
            vendorName: "Northside Stand",
            addressText: "860 Bloor St W, Toronto, ON",
            craveScore: 0.82
        ),
        HotdogProfile(
            id: "hotdog-nightcap",
            name: "Nightcap Melt",
            style: "Chili cheese dog",
            priceDollars: 9,
            signatureNotes: "Sharp cheddar, late-night chili, grilled onions, and jalapeno dust.",
            distanceMiles: 4.8,
            latitude: 43.647,
            longitude: -79.395,
            vendorName: "Depot Dogs",
            addressText: "65 Front St W, Toronto, ON",
            craveScore: 0.69
        )
    ]
}
