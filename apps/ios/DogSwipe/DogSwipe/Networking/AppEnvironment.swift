import DogSwipeCore
import Foundation

enum AppEnvironment {
    static var apiBaseURL: URL {
        if let value = Bundle.main.object(forInfoDictionaryKey: "DOGSWIPE_API_BASE_URL") as? String,
           let url = URL(string: value) {
            return url
        }
        return URL(string: "http://localhost:8000")!
    }

    static var defaultUserID: String {
        "local-user"
    }

    static func apiClient() -> DogSwipeAPIClient {
        DogSwipeAPIClient(baseURL: apiBaseURL)
    }
}
