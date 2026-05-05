import Foundation

public struct DiscoveryPreferences: Equatable, Sendable {
    public var maxDistanceMiles: Double
    public var activeLifestyle: Bool
    public var apartmentFriendly: Bool

    public init(
        maxDistanceMiles: Double = 10,
        activeLifestyle: Bool = true,
        apartmentFriendly: Bool = false
    ) {
        self.maxDistanceMiles = maxDistanceMiles
        self.activeLifestyle = activeLifestyle
        self.apartmentFriendly = apartmentFriendly
    }
}

public enum MatchScorer {
    public static func score(profile: DogProfile, preferences: DiscoveryPreferences) -> Double {
        let distanceScore = max(0, 1 - (profile.distanceMiles / max(preferences.maxDistanceMiles, 1)))
        let temperament = profile.temperament.lowercased()
        let activityScore = preferences.activeLifestyle && temperament.contains("active") ? 1.0 : 0.55
        let apartmentScore = preferences.apartmentFriendly && temperament.contains("apartment") ? 1.0 : 0.65
        let weightedScore = (profile.compatibilityScore * 0.55)
            + (distanceScore * 0.25)
            + (activityScore * 0.12)
            + (apartmentScore * 0.08)
        return min(max(weightedScore, 0), 1)
    }

    public static func ranked(
        profiles: [DogProfile],
        preferences: DiscoveryPreferences
    ) -> [DogProfile] {
        profiles.sorted {
            score(profile: $0, preferences: preferences) > score(profile: $1, preferences: preferences)
        }
    }
}
