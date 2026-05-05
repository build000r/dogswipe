import DogSwipeCore
import Foundation

@MainActor
final class AdminReviewStore: ObservableObject {
    private let apiClient: DogSwipeAPIClient

    @Published private(set) var pendingSubmissions: [HotdogProfile] = []
    @Published private(set) var isReviewing = false
    @Published private(set) var reviewMessage: String?
    @Published var reviewNotes: [String: String] = [:]

    init(apiClient: DogSwipeAPIClient = AppEnvironment.apiClient()) {
        self.apiClient = apiClient
    }

    func load() async {
        isReviewing = true
        defer { isReviewing = false }
        do {
            pendingSubmissions = try await apiClient.adminReviewQueue()
            reviewNotes = Dictionary(
                uniqueKeysWithValues: pendingSubmissions.map { ($0.id, reviewNotes[$0.id] ?? "") }
            )
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
            reviewNotes[approved.id] = nil
            reviewMessage = "\(approved.name) approved."
        } catch {
            reviewMessage = "Submission could not be approved."
        }
    }

    func refreshMenus() async {
        isReviewing = true
        defer { isReviewing = false }
        do {
            let response = try await apiClient.refreshAdminMenus()
            for profile in response.profiles {
                replacePendingSubmission(profile)
            }
            reviewMessage = menuRefreshMessage(response)
        } catch {
            reviewMessage = "Menus could not be refreshed."
        }
    }

    func requestChanges(_ profile: HotdogProfile) async {
        await moderate(
            profile,
            successMessage: "\(profile.name) sent back for edits.",
            action: { profileID, reviewNote in
                try await self.apiClient.requestVendorSubmissionChanges(
                    profileID: profileID,
                    reviewNote: reviewNote
                )
            }
        )
    }

    func reject(_ profile: HotdogProfile) async {
        await moderate(
            profile,
            successMessage: "\(profile.name) rejected.",
            action: { profileID, reviewNote in
                try await self.apiClient.rejectVendorSubmission(
                    profileID: profileID,
                    reviewNote: reviewNote
                )
            }
        )
    }

    func trimmedReviewNote(for profile: HotdogProfile) -> String {
        (reviewNotes[profile.id] ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func moderate(
        _ profile: HotdogProfile,
        successMessage: String,
        action: (String, String) async throws -> HotdogProfile
    ) async {
        let note = trimmedReviewNote(for: profile)
        guard !note.isEmpty else {
            reviewMessage = "A review note is required."
            return
        }
        isReviewing = true
        defer { isReviewing = false }
        do {
            let moderated = try await action(profile.id, note)
            pendingSubmissions.removeAll { $0.id == moderated.id }
            reviewNotes[moderated.id] = nil
            reviewMessage = successMessage
        } catch {
            reviewMessage = "Submission could not be moderated."
        }
    }

    private func replacePendingSubmission(_ profile: HotdogProfile) {
        guard let index = pendingSubmissions.firstIndex(where: { $0.id == profile.id }) else {
            return
        }
        pendingSubmissions[index] = profile
    }

    private func menuRefreshMessage(_ response: AdminMenuRefreshResponse) -> String {
        if response.checkedCount == 0 {
            return "No stale menus to refresh."
        }
        let refreshedLabel = response.refreshedCount == 1 ? "menu" : "menus"
        if response.failedCount == 0 {
            return "\(response.refreshedCount) \(refreshedLabel) refreshed."
        }
        return "\(response.refreshedCount) refreshed, \(response.failedCount) need attention."
    }
}
