import DogSwipeCore
import Foundation

@MainActor
final class AdminReviewStore: ObservableObject {
    private let apiClient: DogSwipeAPIClient

    @Published private(set) var pendingSubmissions: [HotdogProfile] = []
    @Published private(set) var isReviewing = false
    @Published private(set) var reviewMessage: String?

    init(apiClient: DogSwipeAPIClient = AppEnvironment.apiClient()) {
        self.apiClient = apiClient
    }

    func load() async {
        isReviewing = true
        defer { isReviewing = false }
        do {
            pendingSubmissions = try await apiClient.adminReviewQueue()
            reviewMessage = nil
        } catch {
            pendingSubmissions = []
            reviewMessage = "Review queue could not be loaded."
        }
    }

    func approve(_ profile: HotdogProfile) async {
        isReviewing = true
        defer { isReviewing = false }
        do {
            let approved = try await apiClient.approveVendorSubmission(
                profileID: profile.id,
                craveScore: 0.72
            )
            pendingSubmissions.removeAll { $0.id == approved.id }
            reviewMessage = "\(approved.name) approved."
        } catch {
            reviewMessage = "Submission could not be approved."
        }
    }
}
