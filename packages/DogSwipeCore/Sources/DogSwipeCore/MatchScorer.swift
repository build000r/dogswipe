import Foundation

public struct DiscoveryPreferences: Codable, Equatable, Sendable {
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

    enum CodingKeys: String, CodingKey {
        case maxDistanceMiles = "max_distance_miles"
        case spicyFriendly = "spicy_friendly"
        case classicOnly = "classic_only"
    }
}

public enum MatchScorer {
    public static func isEligible(
        profile: HotdogProfile,
        preferences: DiscoveryPreferences
    ) -> Bool {
        let maxDistanceMiles = max(preferences.maxDistanceMiles, 1)
        if profile.distanceMiles > maxDistanceMiles {
            return false
        }
        if preferences.classicOnly && !isClassic(profile: profile) {
            return false
        }
        return true
    }

    public static func score(profile: HotdogProfile, preferences: DiscoveryPreferences) -> Double {
        let distanceScore = max(0, 1 - (profile.distanceMiles / max(preferences.maxDistanceMiles, 1)))
        let spicyScore = preferences.spicyFriendly || !isSpicy(profile: profile) ? 1.0 : 0.58
        let classicScore = !preferences.classicOnly || isClassic(profile: profile) ? 1.0 : 0.62
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
        profiles
            .filter { isEligible(profile: $0, preferences: preferences) }
            .sorted {
                score(profile: $0, preferences: preferences) > score(profile: $1, preferences: preferences)
            }
    }

    private static func isSpicy(profile: HotdogProfile) -> Bool {
        let text = flavorText(profile: profile)
        return text.contains("jalapeno")
            || text.contains("gochujang")
            || text.contains("pepper")
    }

    private static func isClassic(profile: HotdogProfile) -> Bool {
        let text = flavorText(profile: profile)
        return text.contains("classic")
            || text.contains("chicago")
            || text.contains("mustard")
    }

    private static func flavorText(profile: HotdogProfile) -> String {
        "\(profile.name) \(profile.style) \(profile.signatureNotes)".lowercased()
    }
}
