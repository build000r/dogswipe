import DogSwipeCore
import Foundation

@MainActor
final class VendorSubmissionStore: ObservableObject {
    @Published var name = ""
    @Published var style = ""
    @Published var price = ""
    @Published var signatureNotes = ""
    @Published var distance = ""
    @Published var vendorName = ""
    @Published var imageURL = ""
    @Published var menuURL = ""
    @Published var mediaAltText = ""
    @Published private(set) var submissions: [HotdogProfile] = []
    @Published private(set) var isSyncing = false
    @Published private(set) var message: String?
    @Published private(set) var editingSubmissionID: String?

    private let apiClient: DogSwipeAPIClient

    init(apiClient: DogSwipeAPIClient = AppEnvironment.apiClient()) {
        self.apiClient = apiClient
    }

    var canSubmit: Bool {
        !trimmed(name).isEmpty &&
            !trimmed(style).isEmpty &&
            Double(trimmed(price)) != nil &&
            !trimmed(signatureNotes).isEmpty &&
            Double(trimmed(distance)) != nil &&
            !trimmed(vendorName).isEmpty
    }

    var isEditing: Bool {
        editingSubmissionID != nil
    }

    func load() async {
        isSyncing = true
        defer { isSyncing = false }
        do {
            submissions = try await apiClient.vendorSubmissions()
            message = nil
        } catch {
            message = "Vendor submissions could not be loaded."
        }
    }

    func submit() async {
        do {
            let request = try submissionRequest()
            isSyncing = true
            defer { isSyncing = false }
            let profile: HotdogProfile
            let wasEditing = editingSubmissionID != nil
            if let editingSubmissionID {
                profile = try await apiClient.updateVendorSubmission(
                    profileID: editingSubmissionID,
                    submission: request
                )
                replaceSubmission(profile)
            } else {
                profile = try await apiClient.submitVendorProfile(request)
                submissions.insert(profile, at: 0)
            }
            clearDraft()
            message = wasEditing ? "Resubmitted for review." : "Submitted for review."
        } catch {
            message = error.localizedDescription
        }
    }

    func edit(_ profile: HotdogProfile) {
        editingSubmissionID = profile.id
        name = profile.name
        style = profile.style
        price = String(format: "%.2f", profile.priceDollars)
        signatureNotes = profile.signatureNotes
        distance = String(profile.distanceMiles)
        vendorName = profile.vendorName
        imageURL = profile.imageURL?.absoluteString ?? ""
        menuURL = profile.menuURL?.absoluteString ?? ""
        mediaAltText = profile.mediaAltText ?? ""
        message = nil
    }

    func cancelEditing() {
        clearDraft()
        message = nil
    }

    private func submissionRequest() throws -> VendorSubmissionRequest {
        guard let priceDollars = Double(trimmed(price)) else {
            throw VendorSubmissionDraftError.invalidPrice
        }
        guard let distanceMiles = Double(trimmed(distance)) else {
            throw VendorSubmissionDraftError.invalidDistance
        }
        return VendorSubmissionRequest(
            name: trimmed(name),
            style: trimmed(style),
            priceDollars: priceDollars,
            signatureNotes: trimmed(signatureNotes),
            distanceMiles: distanceMiles,
            vendorName: trimmed(vendorName),
            imageURL: try optionalURL(imageURL, error: .invalidImageURL),
            menuURL: try optionalURL(menuURL, error: .invalidMenuURL),
            mediaAltText: optionalString(mediaAltText)
        )
    }

    private func clearDraft() {
        name = ""
        style = ""
        price = ""
        signatureNotes = ""
        distance = ""
        vendorName = ""
        imageURL = ""
        menuURL = ""
        mediaAltText = ""
        editingSubmissionID = nil
    }

    private func replaceSubmission(_ profile: HotdogProfile) {
        guard let index = submissions.firstIndex(where: { $0.id == profile.id }) else {
            submissions.insert(profile, at: 0)
            return
        }
        submissions[index] = profile
    }

    private func optionalURL(_ value: String, error: VendorSubmissionDraftError) throws -> URL? {
        let value = trimmed(value)
        guard !value.isEmpty else {
            return nil
        }
        guard let url = URL(string: value), let scheme = url.scheme, !scheme.isEmpty else {
            throw error
        }
        return url
    }

    private func optionalString(_ value: String) -> String? {
        let value = trimmed(value)
        return value.isEmpty ? nil : value
    }

    private func trimmed(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

private enum VendorSubmissionDraftError: LocalizedError {
    case invalidPrice
    case invalidDistance
    case invalidImageURL
    case invalidMenuURL

    var errorDescription: String? {
        switch self {
        case .invalidPrice:
            "Price is required."
        case .invalidDistance:
            "Distance is required."
        case .invalidImageURL:
            "Image URL is invalid."
        case .invalidMenuURL:
            "Menu URL is invalid."
        }
    }
}
