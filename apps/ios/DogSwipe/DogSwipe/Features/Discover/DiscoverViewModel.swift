import DogSwipeCore
import Foundation

@MainActor
final class DiscoverViewModel: ObservableObject {
    enum LoadState: Equatable {
        case idle
        case loading
        case ready
        case failed(String)
    }

    @Published private(set) var state: LoadState = .idle
    @Published private(set) var allProfiles: [HotdogProfile] = []
    @Published private(set) var deck = SwipeDeckState(profiles: [])
    @Published private(set) var lastMatch: SwipeResponse?
    @Published private(set) var isUsingCurrentLocation = false
    @Published private(set) var currentLocation: DiscoveryLocation?

    private let apiClient: DogSwipeAPIClient
    private let preferencesStore: CravingPreferencesStore
    private let locationProvider: UserLocationProviding

    init(
        apiClient: DogSwipeAPIClient = AppEnvironment.apiClient(),
        preferencesStore: CravingPreferencesStore = CravingPreferencesStore(),
        locationProvider: UserLocationProviding? = nil
    ) {
        self.apiClient = apiClient
        self.preferencesStore = preferencesStore
        self.locationProvider = locationProvider ?? Self.defaultLocationProvider()
    }

    var currentProfile: HotdogProfile? {
        deck.currentProfile
    }

    var remainingCount: Int {
        deck.remainingCount
    }

    var canSwipe: Bool {
        currentProfile != nil && state != .loading
    }

    func load() async {
        state = .loading
        do {
            let location = await locationProvider.currentLocation()
            currentLocation = location
            isUsingCurrentLocation = location != nil
            let profiles = try await apiClient.discovery(limit: 20, location: location)
            allProfiles = rank(profiles)
            deck = SwipeDeckState(profiles: allProfiles)
            lastMatch = nil
            state = .ready
        } catch {
            currentLocation = nil
            isUsingCurrentLocation = false
            if allProfiles.isEmpty {
                allProfiles = rank(HotdogProfile.samples)
                deck = SwipeDeckState(profiles: allProfiles)
            }
            state = .failed("Could not refresh profiles.")
        }
    }

    func resetToSamples() {
        currentLocation = nil
        isUsingCurrentLocation = false
        allProfiles = rank(HotdogProfile.samples)
        deck = SwipeDeckState(profiles: allProfiles)
        lastMatch = nil
        state = .ready
    }

    func applyPreferences() {
        guard !allProfiles.isEmpty, deck.history.isEmpty else {
            return
        }
        allProfiles = rank(allProfiles)
        deck = SwipeDeckState(profiles: allProfiles)
    }

    func record(_ decision: SwipeDecision) {
        guard let profile = deck.currentProfile else {
            return
        }
        _ = deck.record(decision)
        Task {
            do {
                lastMatch = try await apiClient.swipe(
                    profileID: profile.id,
                    decision: decision
                )
            } catch {
                lastMatch = nil
            }
        }
    }

    private func rank(_ profiles: [HotdogProfile]) -> [HotdogProfile] {
        MatchScorer.ranked(profiles: profiles, preferences: preferencesStore.preferences)
    }

    private static func defaultLocationProvider() -> UserLocationProviding {
        AppEnvironment.isScreenshotMode
            ? ScreenshotUserLocationProvider()
            : CoreLocationUserLocationProvider()
    }
}
