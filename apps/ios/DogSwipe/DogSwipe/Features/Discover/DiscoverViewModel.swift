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
    @Published var menuQuery = ""
    @Published var selectedCategory: String?

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
        self.locationProvider = locationProvider ?? UserLocationProviderFactory.defaultProvider()
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

    var canRestartDeck: Bool {
        !allProfiles.isEmpty && state != .loading
    }

    var hasReviewedEveryHotdog: Bool {
        !allProfiles.isEmpty && deck.isEmpty && !deck.history.isEmpty
    }

    var hasMenuQuery: Bool {
        menuQueryParameter != nil
    }

    var availableCategories: [String] {
        let cats = Set(allProfiles.map(\.category))
        return Array(cats).sorted()
    }

    func load() async {
        state = .loading
        do {
            let location = await locationProvider.currentLocation()
            currentLocation = location
            isUsingCurrentLocation = location != nil
            let profiles = try await apiClient.discovery(
                limit: 20,
                location: location,
                menuQuery: menuQueryParameter
            )
            allProfiles = rank(profiles)
            deck = SwipeDeckState(profiles: filteredProfiles)
            lastMatch = nil
            state = .ready
        } catch {
            currentLocation = nil
            isUsingCurrentLocation = false
            if allProfiles.isEmpty || hasMenuQuery {
                allProfiles = rank(HotdogProfile.samples)
                deck = SwipeDeckState(profiles: filteredProfiles)
            }
            state = .failed("Could not refresh profiles.")
        }
    }

    func searchMenu() async {
        menuQuery = menuQueryParameter ?? ""
        await load()
    }

    func clearMenuQuery() async {
        guard hasMenuQuery else {
            menuQuery = ""
            return
        }
        menuQuery = ""
        await load()
    }

    func resetToSamples() {
        menuQuery = ""
        selectedCategory = nil
        currentLocation = nil
        isUsingCurrentLocation = false
        allProfiles = rank(HotdogProfile.samples)
        deck = SwipeDeckState(profiles: filteredProfiles)
        lastMatch = nil
        state = .ready
    }

    func applyPreferences() {
        guard !allProfiles.isEmpty, deck.history.isEmpty else {
            return
        }
        allProfiles = rank(allProfiles)
        deck = SwipeDeckState(profiles: filteredProfiles)
    }

    func selectCategory(_ category: String?) {
        selectedCategory = category
        guard !allProfiles.isEmpty else { return }
        deck = SwipeDeckState(profiles: filteredProfiles)
    }

    private var filteredProfiles: [HotdogProfile] {
        guard let selectedCategory else { return allProfiles }
        return allProfiles.filter { $0.category == selectedCategory }
    }

    @discardableResult
    func record(_ decision: SwipeDecision) -> HotdogProfile? {
        guard let profile = deck.currentProfile else {
            return nil
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
        return profile
    }

    private func rank(_ profiles: [HotdogProfile]) -> [HotdogProfile] {
        MatchScorer.ranked(
            profiles: profiles,
            preferences: preferencesStore.preferences,
            menuQuery: menuQueryParameter
        )
    }

    private var menuQueryParameter: String? {
        let normalized = menuQuery
            .split(whereSeparator: \.isWhitespace)
            .joined(separator: " ")
        guard !normalized.isEmpty else {
            return nil
        }
        return String(normalized.prefix(64))
    }
}
