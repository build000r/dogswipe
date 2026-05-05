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

    public static func score(
        profile: HotdogProfile,
        preferences: DiscoveryPreferences,
        menuQuery: String? = nil
    ) -> Double {
        let distanceScore = max(0, 1 - (profile.distanceMiles / max(preferences.maxDistanceMiles, 1)))
        let spicyScore = preferences.spicyFriendly || !isSpicy(profile: profile) ? 1.0 : 0.58
        let classicScore = !preferences.classicOnly || isClassic(profile: profile) ? 1.0 : 0.62
        var weightedScore = (profile.craveScore * 0.55)
            + (distanceScore * 0.25)
            + (spicyScore * 0.10)
            + (classicScore * 0.10)
        if let menuQuery = normalizedMenuQuery(menuQuery) {
            weightedScore = (weightedScore * 0.82) + (menuQueryScore(profile: profile, query: menuQuery) * 0.18)
        }
        return min(max(weightedScore, 0), 1)
    }

    public static func ranked(
        profiles: [HotdogProfile],
        preferences: DiscoveryPreferences,
        menuQuery: String? = nil
    ) -> [HotdogProfile] {
        let normalizedQuery = normalizedMenuQuery(menuQuery)
        return profiles
            .filter { isEligible(profile: $0, preferences: preferences) }
            .filter { matchesMenuQuery(profile: $0, query: normalizedQuery) }
            .sorted {
                score(profile: $0, preferences: preferences, menuQuery: normalizedQuery)
                    > score(profile: $1, preferences: preferences, menuQuery: normalizedQuery)
            }
    }

    public static func matchesMenuQuery(profile: HotdogProfile, query: String?) -> Bool {
        guard let query = normalizedMenuQuery(query) else {
            return true
        }
        let terms = queryTerms(query)
        guard !terms.isEmpty else {
            return true
        }
        let searchText = menuSearchText(profile: profile)
        return terms.allSatisfy { searchText.contains($0) }
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
        menuSearchText(profile: profile)
    }

    private static func menuQueryScore(profile: HotdogProfile, query: String) -> Double {
        let terms = queryTerms(query)
        guard !terms.isEmpty else {
            return 0
        }
        let searchText = menuSearchText(profile: profile)
        let menuText = "\(profile.menuExcerpt ?? "") \(profile.menuHighlightLabels.joined(separator: " "))"
            .lowercased()
        let searchMatches = Double(terms.filter { searchText.contains($0) }.count) / Double(terms.count)
        let menuMatches = Double(terms.filter { menuText.contains($0) }.count) / Double(terms.count)
        return min(1, (searchMatches * 0.7) + (menuMatches * 0.3))
    }

    private static func menuSearchText(profile: HotdogProfile) -> String {
        [
            profile.name,
            profile.style,
            profile.signatureNotes,
            profile.vendorName,
            profile.menuExcerpt ?? "",
            profile.menuHighlightLabels.joined(separator: " ")
        ]
        .joined(separator: " ")
        .lowercased()
    }

    private static func normalizedMenuQuery(_ query: String?) -> String? {
        guard let query else {
            return nil
        }
        let normalized = query
            .split(whereSeparator: \.isWhitespace)
            .joined(separator: " ")
        guard !normalized.isEmpty else {
            return nil
        }
        return String(normalized.prefix(64))
    }

    private static func queryTerms(_ query: String) -> [String] {
        query
            .lowercased()
            .split { !$0.isLetter && !$0.isNumber }
            .map(String.init)
    }
}
