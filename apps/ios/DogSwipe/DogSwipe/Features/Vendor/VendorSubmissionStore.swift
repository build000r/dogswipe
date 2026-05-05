import DogSwipeCore
import Foundation

@MainActor
final class VendorSubmissionStore: ObservableObject {
    @Published var name = ""
    @Published var style = ""
    @Published var price = ""
    @Published var signatureNotes = ""
    @Published var distance = ""
    @Published var latitude = ""
    @Published var longitude = ""
    @Published var vendorName = ""
    @Published var addressText = ""
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
        latitude = coordinateString(profile.latitude)
        longitude = coordinateString(profile.longitude)
        vendorName = profile.vendorName
        addressText = profile.addressText ?? ""
        imageURL = profile.imageURL?.absoluteString ?? ""
        menuURL = profile.menuURL?.absoluteString ?? ""
        mediaAltText = profile.mediaAltText ?? ""
        message = nil
    }

    func cancelEditing() {
        clearDraft()
        message = nil
    }

    func ingestMenu(_ profile: HotdogProfile) async {
        guard profile.menuURL != nil else {
            message = "Add a menu URL before refreshing."
            return
        }
        isSyncing = true
        defer { isSyncing = false }
        do {
            let updated = try await apiClient.ingestVendorSubmissionMenu(profileID: profile.id)
            replaceSubmission(updated)
            message = menuIngestionMessage(updated)
        } catch {
            message = "Menu could not be refreshed."
        }
    }

    private func submissionRequest() throws -> VendorSubmissionRequest {
        guard let priceDollars = Double(trimmed(price)) else {
            throw VendorSubmissionDraftError.invalidPrice
        }
        guard let distanceMiles = Double(trimmed(distance)) else {
            throw VendorSubmissionDraftError.invalidDistance
        }
        let latitude = try optionalCoordinate(
            self.latitude,
            range: -90...90,
            error: .invalidLatitude
        )
        let longitude = try optionalCoordinate(
            self.longitude,
            range: -180...180,
            error: .invalidLongitude
        )
        if (latitude == nil) != (longitude == nil) {
            throw VendorSubmissionDraftError.incompleteCoordinates
        }
        return VendorSubmissionRequest(
            vendorName: trimmed(vendorName),
            name: trimmed(name),
            signatureNotes: trimmed(signatureNotes),
            style: trimmed(style),
            menuURL: try optionalURL(menuURL, error: .invalidMenuURL),
            addressText: optionalString(addressText),
            priceDollars: priceDollars,
            distanceMiles: distanceMiles,
            imageURL: try optionalURL(imageURL, error: .invalidImageURL),
            latitude: latitude,
            mediaAltText: optionalString(mediaAltText),
            longitude: longitude
        )
    }

    private func clearDraft() {
        name = ""
        style = ""
        price = ""
        signatureNotes = ""
        distance = ""
        latitude = ""
        longitude = ""
        vendorName = ""
        addressText = ""
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

    private func menuIngestionMessage(_ profile: HotdogProfile) -> String {
        switch profile.menuStatus {
        case "ok":
            "\(profile.name) menu refreshed."
        case "empty":
            "Menu page was reachable, but no text was found."
        case "invalid_url":
            "Menu URL is invalid."
        case "fetch_failed":
            "Menu page could not be loaded."
        case "missing_url":
            "Add a menu URL before refreshing."
        default:
            "Menu refresh recorded."
        }
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

    private func optionalCoordinate(
        _ value: String,
        range: ClosedRange<Double>,
        error: VendorSubmissionDraftError
    ) throws -> Double? {
        let value = trimmed(value)
        guard !value.isEmpty else {
            return nil
        }
        guard let coordinate = Double(value), range.contains(coordinate) else {
            throw error
        }
        return coordinate
    }

    private func coordinateString(_ value: Double?) -> String {
        guard let value else {
            return ""
        }
        return String(value)
    }

    private func trimmed(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

private enum VendorSubmissionDraftError: LocalizedError {
    case invalidPrice
    case invalidDistance
    case invalidLatitude
    case invalidLongitude
    case incompleteCoordinates
    case invalidImageURL
    case invalidMenuURL

    var errorDescription: String? {
        switch self {
        case .invalidPrice:
            "Price is required."
        case .invalidDistance:
            "Distance is required."
        case .invalidLatitude:
            "Latitude must be between -90 and 90."
        case .invalidLongitude:
            "Longitude must be between -180 and 180."
        case .incompleteCoordinates:
            "Latitude and longitude must be provided together."
        case .invalidImageURL:
            "Image URL is invalid."
        case .invalidMenuURL:
            "Menu URL is invalid."
        }
    }
}
