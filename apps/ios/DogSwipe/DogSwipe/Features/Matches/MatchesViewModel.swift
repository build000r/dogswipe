import DogSwipeCore
import Foundation

@MainActor
final class MatchesViewModel: ObservableObject {
    enum LoadState: Equatable {
        case idle
        case loading
        case ready
        case failed(String)
    }

    @Published private(set) var state: LoadState = .idle
    @Published private(set) var matches: [HotdogProfile] = []
    @Published private(set) var isUsingCurrentLocation = false
    @Published private(set) var currentLocation: DiscoveryLocation?

    private struct Dependencies {
        let apiClient: DogSwipeAPIClient
        let preferencesStore: CravingPreferencesStore
        let locationProvider: UserLocationProviding
    }

    private let dependencies: Dependencies

    init(
        apiClient: DogSwipeAPIClient = AppEnvironment.apiClient(),
        preferencesStore: CravingPreferencesStore = CravingPreferencesStore(),
        locationProvider: UserLocationProviding? = nil
    ) {
        dependencies = Dependencies(
            apiClient: apiClient,
            preferencesStore: preferencesStore,
            locationProvider: locationProvider ?? UserLocationProviderFactory.defaultProvider()
        )
    }

    func load() async {
        state = .loading
        let location = await dependencies.locationProvider.currentLocation()
        currentLocation = location
        isUsingCurrentLocation = location != nil
        do {
            matches = try await dependencies.apiClient.matches(location: location)
            state = .ready
        } catch {
            matches = MatchScorer.ranked(
                profiles: HotdogProfile.samples,
                preferences: dependencies.preferencesStore.preferences
            )
            state = .failed("Could not refresh matches.")
        }
    }
}
