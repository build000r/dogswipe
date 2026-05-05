import XCTest
@testable import DogSwipeCore

final class SwipeDeckStateTests: XCTestCase {
    func testDeckStartsWithAvailableProfilesOnly() {
        let unavailable = HotdogProfile(
            id: "sold-out",
            name: "Sold Out",
            style: "Classic",
            priceDollars: 1,
            signatureNotes: "Mustard and onion.",
            distanceMiles: 1,
            vendorName: "Test",
            craveScore: 0.9,
            availabilityStatus: .soldOut
        )
        let state = SwipeDeckState(profiles: HotdogProfile.samples + [unavailable])
        XCTAssertEqual(state.remainingCount, HotdogProfile.samples.count)
        XCTAssertEqual(state.currentProfile?.id, "hotdog-coney")
    }

    func testRecordAdvancesDeckAndStoresHistory() {
        var state = SwipeDeckState(profiles: HotdogProfile.samples)
        let event = state.record(.like, now: Date(timeIntervalSince1970: 1))
        XCTAssertEqual(event?.profileID, "hotdog-coney")
        XCTAssertEqual(state.currentProfile?.id, "hotdog-kimchi")
        XCTAssertEqual(state.positiveProfileIDs(), ["hotdog-coney"])
    }

    func testPassIsNotPositiveSignal() {
        var state = SwipeDeckState(profiles: HotdogProfile.samples)
        state.record(.pass)
        XCTAssertTrue(state.positiveProfileIDs().isEmpty)
    }

    func testUndoRestoresLastProfile() {
        var state = SwipeDeckState(profiles: HotdogProfile.samples)
        state.record(.superLike)
        let restored = state.undo(from: HotdogProfile.samples)
        XCTAssertEqual(restored?.id, "hotdog-coney")
        XCTAssertEqual(state.currentProfile?.id, "hotdog-coney")
        XCTAssertTrue(state.history.isEmpty)
    }

    func testEmptyDeckDoesNotRecord() {
        var state = SwipeDeckState(profiles: [])
        XCTAssertNil(state.record(.like))
        XCTAssertTrue(state.isEmpty)
    }
}
