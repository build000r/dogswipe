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
    @Published private(set) var matches: [DogProfile] = []

    private let apiClient: DogSwipeAPIClient
    private let userID: String

    init(
        apiClient: DogSwipeAPIClient = AppEnvironment.apiClient(),
        userID: String = AppEnvironment.defaultUserID
    ) {
        self.apiClient = apiClient
        self.userID = userID
    }

    func load() async {
        state = .loading
        do {
            matches = try await apiClient.matches(userID: userID)
            state = .ready
        } catch {
            matches = MatchScorer.ranked(
                profiles: DogProfile.samples,
                preferences: DiscoveryPreferences()
            )
            state = .failed("Could not refresh matches.")
        }
    }
}
