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
    private let preferencesStore: CravingPreferencesStore

    init(
        apiClient: DogSwipeAPIClient = AppEnvironment.apiClient(),
        preferencesStore: CravingPreferencesStore = CravingPreferencesStore()
    ) {
        self.apiClient = apiClient
        self.preferencesStore = preferencesStore
    }

    func load() async {
        state = .loading
        do {
            matches = try await apiClient.matches()
            state = .ready
        } catch {
            matches = MatchScorer.ranked(
                profiles: HotdogProfile.samples,
                preferences: preferencesStore.preferences
            )
            state = .failed("Could not refresh matches.")
        }
    }
}
