import DogSwipeCore
import Foundation

final class CravingPreferencesStore: ObservableObject {
    @Published var spicyFriendly: Bool
    @Published var classicOnly: Bool
    @Published var maxDistanceMiles: Double

    init(
        spicyFriendly: Bool = true,
        classicOnly: Bool = false,
        maxDistanceMiles: Double = 10
    ) {
        self.spicyFriendly = spicyFriendly
        self.classicOnly = classicOnly
        self.maxDistanceMiles = maxDistanceMiles
    }

    var preferences: DiscoveryPreferences {
        DiscoveryPreferences(
            maxDistanceMiles: maxDistanceMiles,
            spicyFriendly: spicyFriendly,
            classicOnly: classicOnly
        )
    }
}
