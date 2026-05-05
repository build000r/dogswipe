import Foundation

public struct DiscoveryPreferences: Equatable, Sendable {
    public var maxDistanceMiles: Double
    public var spicyFriendly: Bool
    public var classicOnly: Bool

    public init(
        maxDistanceMiles: Double = 10,
        spicyFriendly: Bool = true,
        classicOnly: Bool = false
    ) {
        self.maxDistanceMiles = maxDistanceMiles
        self.spicyFriendly = spicyFriendly
        self.classicOnly = classicOnly
    }
}

public enum MatchScorer {
    public static func score(profile: HotdogProfile, preferences: DiscoveryPreferences) -> Double {
        let distanceScore = max(0, 1 - (profile.distanceMiles / max(preferences.maxDistanceMiles, 1)))
        let flavorText = "\(profile.name) \(profile.style) \(profile.signatureNotes)".lowercased()
        let isSpicy = flavorText.contains("jalapeno")
            || flavorText.contains("gochujang")
            || flavorText.contains("pepper")
        let spicyScore = preferences.spicyFriendly || !isSpicy ? 1.0 : 0.58
        let isClassic = flavorText.contains("classic")
            || flavorText.contains("chicago")
            || flavorText.contains("mustard")
        let classicScore = !preferences.classicOnly || isClassic ? 1.0 : 0.62
        let weightedScore = (profile.craveScore * 0.55)
            + (distanceScore * 0.25)
            + (spicyScore * 0.10)
            + (classicScore * 0.10)
        return min(max(weightedScore, 0), 1)
    }

    public static func ranked(
        profiles: [HotdogProfile],
        preferences: DiscoveryPreferences
    ) -> [HotdogProfile] {
        profiles.sorted {
            score(profile: $0, preferences: preferences) > score(profile: $1, preferences: preferences)
        }
    }
}
