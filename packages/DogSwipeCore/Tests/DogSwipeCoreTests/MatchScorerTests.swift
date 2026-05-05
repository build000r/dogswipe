import XCTest
@testable import DogSwipeCore

final class MatchScorerTests: XCTestCase {
    func testScoreStaysWithinBounds() {
        let score = MatchScorer.score(
            profile: HotdogProfile.samples[0],
            preferences: DiscoveryPreferences(maxDistanceMiles: 0)
        )
        XCTAssertGreaterThanOrEqual(score, 0)
        XCTAssertLessThanOrEqual(score, 1)
    }

    func testRankingPrefersCloserCraveableHotdog() {
        let ranked = MatchScorer.ranked(
            profiles: HotdogProfile.samples,
            preferences: DiscoveryPreferences(maxDistanceMiles: 10, spicyFriendly: true)
        )
        XCTAssertEqual(ranked.first?.id, "hotdog-coney")
    }

    func testClassicPreferenceCanLiftClassicProfile() {
        let coney = HotdogProfile.samples[0]
        let openScore = MatchScorer.score(
            profile: coney,
            preferences: DiscoveryPreferences(classicOnly: false)
        )
        let classicScore = MatchScorer.score(
            profile: coney,
            preferences: DiscoveryPreferences(classicOnly: true)
        )
        XCTAssertGreaterThanOrEqual(classicScore, openScore)
    }
}
