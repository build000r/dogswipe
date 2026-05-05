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

    private let apiClient: DogSwipeAPIClient

    init(
        apiClient: DogSwipeAPIClient = AppEnvironment.apiClient()
    ) {
        self.apiClient = apiClient
    }

    func load() async {
        state = .loading
        do {
            matches = try await apiClient.matches()
            state = .ready
        } catch {
            matches = MatchScorer.ranked(
                profiles: HotdogProfile.samples,
                preferences: DiscoveryPreferences()
            )
            state = .failed("Could not refresh matches.")
        }
    }
}
