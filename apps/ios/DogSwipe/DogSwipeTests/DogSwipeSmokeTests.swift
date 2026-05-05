import XCTest
@testable import DogSwipe

final class DogSwipeSmokeTests: XCTestCase {
    func testRootViewCanBeCreated() {
        _ = RootView()
    }

    func testCravingPreferencesStoreBuildsDiscoveryPreferences() {
        let store = CravingPreferencesStore(
            spicyFriendly: false,
            classicOnly: true,
            maxDistanceMiles: 7
        )

        let preferences = store.preferences

        XCTAssertFalse(preferences.spicyFriendly)
        XCTAssertTrue(preferences.classicOnly)
        XCTAssertEqual(preferences.maxDistanceMiles, 7)
    }
}
