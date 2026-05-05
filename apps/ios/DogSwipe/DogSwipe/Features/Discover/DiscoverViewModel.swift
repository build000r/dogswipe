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
    @Published private(set) var allProfiles: [DogProfile] = []
    @Published private(set) var deck = SwipeDeckState(profiles: [])
    @Published private(set) var lastMatch: SwipeResponse?

    private let apiClient: DogSwipeAPIClient
    private let userID: String

    init(
        apiClient: DogSwipeAPIClient = AppEnvironment.apiClient(),
        userID: String = AppEnvironment.defaultUserID
    ) {
        self.apiClient = apiClient
        self.userID = userID
    }

    var currentProfile: DogProfile? {
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
            let profiles = try await apiClient.discovery(limit: 20)
            allProfiles = profiles
            deck = SwipeDeckState(profiles: profiles)
            lastMatch = nil
            state = .ready
        } catch {
            if allProfiles.isEmpty {
                allProfiles = DogProfile.samples
                deck = SwipeDeckState(profiles: allProfiles)
            }
            state = .failed("Could not refresh profiles.")
        }
    }

    func resetToSamples() {
        allProfiles = DogProfile.samples
        deck = SwipeDeckState(profiles: allProfiles)
        lastMatch = nil
        state = .ready
    }

    func record(_ decision: SwipeDecision) {
        guard let profile = deck.currentProfile else {
            return
        }
        _ = deck.record(decision)
        Task {
            do {
                lastMatch = try await apiClient.swipe(
                    userID: userID,
                    profileID: profile.id,
                    decision: decision
                )
            } catch {
                lastMatch = nil
            }
        }
    }
}
