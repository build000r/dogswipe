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

    static func apiClient(
        httpClient: DogSwipeHTTPClient = URLSessionDogSwipeHTTPClient(),
        authorizationTokenProvider: DogSwipeAPIClient.AuthorizationTokenProvider? = nil
    ) -> DogSwipeAPIClient {
        DogSwipeAPIClient(
            baseURL: apiBaseURL,
            httpClient: httpClient,
            authorizationTokenProvider: authorizationTokenProvider
        )
    }

    static func apiClient(
        tokenStore: BearerTokenStoring,
        httpClient: DogSwipeHTTPClient = URLSessionDogSwipeHTTPClient()
    ) -> DogSwipeAPIClient {
        apiClient(
            httpClient: httpClient,
            authorizationTokenProvider: {
                try tokenStore.token()
            }
        )
    }
}
