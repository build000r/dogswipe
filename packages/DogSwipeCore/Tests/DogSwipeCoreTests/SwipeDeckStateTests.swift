import XCTest
@testable import DogSwipeCore

final class SwipeDeckStateTests: XCTestCase {
    func testDeckStartsWithAvailableProfilesOnly() {
        let unavailable = DogProfile(
            id: "adopted",
            name: "Adopted",
            breed: "Mixed",
            ageYears: 1,
            temperament: "Gentle",
            distanceMiles: 1,
            shelterName: "Test",
            compatibilityScore: 0.9,
            adoptionStatus: .adopted
        )
        let state = SwipeDeckState(profiles: DogProfile.samples + [unavailable])
        XCTAssertEqual(state.remainingCount, DogProfile.samples.count)
        XCTAssertEqual(state.currentProfile?.id, "dog-luna")
    }

    func testRecordAdvancesDeckAndStoresHistory() {
        var state = SwipeDeckState(profiles: DogProfile.samples)
        let event = state.record(.like, now: Date(timeIntervalSince1970: 1))
        XCTAssertEqual(event?.profileID, "dog-luna")
        XCTAssertEqual(state.currentProfile?.id, "dog-miso")
        XCTAssertEqual(state.positiveProfileIDs(), ["dog-luna"])
    }

    func testPassIsNotPositiveSignal() {
        var state = SwipeDeckState(profiles: DogProfile.samples)
        state.record(.pass)
        XCTAssertTrue(state.positiveProfileIDs().isEmpty)
    }

    func testUndoRestoresLastProfile() {
        var state = SwipeDeckState(profiles: DogProfile.samples)
        state.record(.superLike)
        let restored = state.undo(from: DogProfile.samples)
        XCTAssertEqual(restored?.id, "dog-luna")
        XCTAssertEqual(state.currentProfile?.id, "dog-luna")
        XCTAssertTrue(state.history.isEmpty)
    }

    func testEmptyDeckDoesNotRecord() {
        var state = SwipeDeckState(profiles: [])
        XCTAssertNil(state.record(.like))
        XCTAssertTrue(state.isEmpty)
    }
}
