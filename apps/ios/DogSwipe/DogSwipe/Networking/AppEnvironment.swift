import DogSwipeCore
import Foundation

enum AppEnvironment {
    static let screenshotModeArgument = "--dogswipe-screenshot-mode"

    static var isScreenshotMode: Bool {
        ProcessInfo.processInfo.arguments.contains(screenshotModeArgument)
            || ProcessInfo.processInfo.environment["DOGSWIPE_SCREENSHOT_MODE"] == "1"
    }

    static var apiBaseURL: URL {
        if let value = Bundle.main.object(forInfoDictionaryKey: "DOGSWIPE_API_BASE_URL") as? String,
           let url = URL(string: value) {
            return url
        }
        return URL(string: "http://localhost:8000")!
    }

    static var spapsAPIBaseURL: URL {
        if let value = Bundle.main.object(forInfoDictionaryKey: "DOGSWIPE_SPAPS_API_BASE_URL") as? String,
           let url = URL(string: value) {
            return url
        }
        return URL(string: "https://api.sweetpotato.dev")!
    }

    static var spapsPublishableKey: String {
        Bundle.main.object(forInfoDictionaryKey: "DOGSWIPE_SPAPS_PUBLISHABLE_KEY") as? String ?? ""
    }

    static var spapsOrigin: String? {
        Bundle.main.object(forInfoDictionaryKey: "DOGSWIPE_SPAPS_ORIGIN") as? String
    }

    static var magicLinkRedirectURL: URL? {
        guard let value = Bundle.main.object(forInfoDictionaryKey: "DOGSWIPE_AUTH_REDIRECT_URL")
            as? String else {
            return URL(string: "dogswipe://auth")
        }
        let trimmedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedValue.isEmpty else {
            return URL(string: "dogswipe://auth")
        }
        return URL(string: trimmedValue)
    }

    static var authUniversalLinkHosts: Set<String> {
        guard let value = Bundle.main.object(
            forInfoDictionaryKey: "DOGSWIPE_AUTH_UNIVERSAL_LINK_HOSTS"
        ) as? String else {
            return []
        }
        return Set(
            value
                .split(separator: ",")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
                .filter { !$0.isEmpty }
        )
    }

    static func accessTokenStore() -> BearerTokenStoring {
        isScreenshotMode ? EphemeralBearerTokenStore() : KeychainBearerTokenStore()
    }

    static func refreshTokenStore() -> BearerTokenStoring {
        isScreenshotMode
            ? EphemeralBearerTokenStore()
            : KeychainBearerTokenStore(account: "spaps-refresh-token")
    }

    static func apiClient(
        httpClient: DogSwipeHTTPClient? = nil,
        authorizationTokenProvider: DogSwipeAPIClient.AuthorizationTokenProvider? = nil
    ) -> DogSwipeAPIClient {
        DogSwipeAPIClient(
            baseURL: apiBaseURL,
            httpClient: httpClient ?? apiHTTPClient(),
            authorizationTokenProvider: authorizationTokenProvider
        )
    }

    static func apiClient(
        tokenStore: BearerTokenStoring,
        httpClient: DogSwipeHTTPClient? = nil
    ) -> DogSwipeAPIClient {
        apiClient(
            httpClient: httpClient,
            authorizationTokenProvider: {
                try tokenStore.token()
            }
        )
    }

    static func spapsAuthClient(
        httpClient: DogSwipeHTTPClient? = nil
    ) -> SPAPSAuthClient {
        SPAPSAuthClient(
            baseURL: spapsAPIBaseURL,
            publishableKey: screenshotPublishableKey,
            origin: spapsOrigin,
            httpClient: httpClient ?? apiHTTPClient()
        )
    }

    private static func apiHTTPClient() -> DogSwipeHTTPClient {
        isScreenshotMode ? ScreenshotDogSwipeHTTPClient() : URLSessionDogSwipeHTTPClient()
    }

    private static var screenshotPublishableKey: String {
        let key = spapsPublishableKey.trimmingCharacters(in: .whitespacesAndNewlines)
        if isScreenshotMode, key.isEmpty {
            return "dogswipe-screenshot-publishable-key"
        }
        return key
    }
}
