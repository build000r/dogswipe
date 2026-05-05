import XCTest
@testable import DogSwipeCore

final class MatchScorerTests: XCTestCase {
    func testScoreStaysWithinBounds() {
        let score = MatchScorer.score(
            profile: DogProfile.samples[0],
            preferences: DiscoveryPreferences(maxDistanceMiles: 0)
        )
        XCTAssertGreaterThanOrEqual(score, 0)
        XCTAssertLessThanOrEqual(score, 1)
    }

    func testRankingPrefersCloserCompatibleDog() {
        let ranked = MatchScorer.ranked(
            profiles: DogProfile.samples,
            preferences: DiscoveryPreferences(maxDistanceMiles: 10, activeLifestyle: true)
        )
        XCTAssertEqual(ranked.first?.id, "dog-luna")
    }

    func testApartmentPreferenceCanLiftApartmentFriendlyProfile() {
        let miso = DogProfile.samples[1]
        let defaultScore = MatchScorer.score(
            profile: miso,
            preferences: DiscoveryPreferences(apartmentFriendly: false)
        )
        let apartmentScore = MatchScorer.score(
            profile: miso,
            preferences: DiscoveryPreferences(apartmentFriendly: true)
        )
        XCTAssertGreaterThan(apartmentScore, defaultScore)
    }
}
