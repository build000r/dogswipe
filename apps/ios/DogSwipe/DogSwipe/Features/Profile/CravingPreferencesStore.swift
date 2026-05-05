import DogSwipeCore
import Foundation

final class CravingPreferencesStore: ObservableObject {
    @Published var spicyFriendly: Bool
    @Published var classicOnly: Bool
    @Published var maxDistanceMiles: Double
    @Published private(set) var isSyncing = false
    @Published private(set) var syncMessage: String?

    private let apiClient: DogSwipeAPIClient
    private var lastSavedPreferences: DiscoveryPreferences

    init(
        spicyFriendly: Bool = true,
        classicOnly: Bool = false,
        maxDistanceMiles: Double = 10,
        apiClient: DogSwipeAPIClient = AppEnvironment.apiClient()
    ) {
        self.spicyFriendly = spicyFriendly
        self.classicOnly = classicOnly
        self.maxDistanceMiles = maxDistanceMiles
        self.apiClient = apiClient
        lastSavedPreferences = DiscoveryPreferences(
            maxDistanceMiles: maxDistanceMiles,
            spicyFriendly: spicyFriendly,
            classicOnly: classicOnly
        )
    }

    var preferences: DiscoveryPreferences {
        DiscoveryPreferences(
            maxDistanceMiles: maxDistanceMiles,
            spicyFriendly: spicyFriendly,
            classicOnly: classicOnly
        )
    }

    @MainActor
    func load() async {
        isSyncing = true
        defer { isSyncing = false }
        do {
            let preferences = try await apiClient.preferences()
            apply(preferences)
            lastSavedPreferences = preferences
            syncMessage = nil
        } catch {
            syncMessage = "Using local craving controls until preferences sync."
        }
    }

    @MainActor
    func save() async {
        let currentPreferences = preferences
        guard currentPreferences != lastSavedPreferences else {
            return
        }
        isSyncing = true
        defer { isSyncing = false }
        do {
            let savedPreferences = try await apiClient.updatePreferences(currentPreferences)
            apply(savedPreferences)
            lastSavedPreferences = savedPreferences
            syncMessage = nil
        } catch {
            syncMessage = "Preferences will retry when the backend is reachable."
        }
    }

    @MainActor
    private func apply(_ preferences: DiscoveryPreferences) {
        maxDistanceMiles = preferences.maxDistanceMiles
        spicyFriendly = preferences.spicyFriendly
        classicOnly = preferences.classicOnly
    }
}
