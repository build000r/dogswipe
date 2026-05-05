import Foundation

public struct DogProfile: Identifiable, Codable, Equatable, Sendable {
    public let id: String
    public let name: String
    public let breed: String
    public let ageYears: Double
    public let temperament: String
    public let distanceMiles: Double
    public let shelterName: String
    public let imageURL: URL?
    public let compatibilityScore: Double
    public let adoptionStatus: AdoptionStatus

    public init(
        id: String,
        name: String,
        breed: String,
        ageYears: Double,
        temperament: String,
        distanceMiles: Double,
        shelterName: String,
        imageURL: URL? = nil,
        compatibilityScore: Double,
        adoptionStatus: AdoptionStatus = .available
    ) {
        self.id = id
        self.name = name
        self.breed = breed
        self.ageYears = ageYears
        self.temperament = temperament
        self.distanceMiles = distanceMiles
        self.shelterName = shelterName
        self.imageURL = imageURL
        self.compatibilityScore = compatibilityScore
        self.adoptionStatus = adoptionStatus
    }

    public var ageLabel: String {
        if ageYears < 1 {
            return "Puppy"
        }
        let roundedAge = Int(ageYears.rounded())
        return "\(roundedAge) year\(roundedAge == 1 ? "" : "s")"
    }

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case breed
        case ageYears = "age_years"
        case temperament
        case distanceMiles = "distance_miles"
        case shelterName = "shelter_name"
        case imageURL = "image_url"
        case compatibilityScore = "compatibility_score"
        case adoptionStatus = "adoption_status"
    }
}

public enum AdoptionStatus: String, Codable, Equatable, Sendable {
    case available
    case pending
    case adopted
}

public struct DiscoveryResponse: Codable, Equatable, Sendable {
    public let profiles: [DogProfile]

    public init(profiles: [DogProfile]) {
        self.profiles = profiles
    }
}

public struct MatchResponse: Codable, Equatable, Sendable {
    public let matches: [DogProfile]

    public init(matches: [DogProfile]) {
        self.matches = matches
    }
}

public extension DogProfile {
    static let samples: [DogProfile] = [
        DogProfile(
            id: "dog-luna",
            name: "Luna",
            breed: "Australian Shepherd",
            ageYears: 2.5,
            temperament: "Active, focused, affectionate",
            distanceMiles: 4.2,
            shelterName: "River North Rescue",
            imageURL: URL(string: "https://images.unsplash.com/photo-1552053831-71594a27632d"),
            compatibilityScore: 0.91
        ),
        DogProfile(
            id: "dog-miso",
            name: "Miso",
            breed: "Shiba Inu",
            ageYears: 4,
            temperament: "Independent, quiet, apartment-ready",
            distanceMiles: 8.7,
            shelterName: "West Loop Humane",
            imageURL: URL(string: "https://images.unsplash.com/photo-1537151625747-768eb6cf92b2"),
            compatibilityScore: 0.68
        ),
        DogProfile(
            id: "dog-sage",
            name: "Sage",
            breed: "Greyhound",
            ageYears: 5,
            temperament: "Calm, warm, couch loyal",
            distanceMiles: 2.1,
            shelterName: "Lakeside Adoption Center",
            imageURL: URL(string: "https://images.unsplash.com/photo-1518717758536-85ae29035b6d"),
            compatibilityScore: 0.84
        )
    ]
}
