import Foundation

public protocol DogSwipeHTTPClient: Sendable {
    func data(for request: URLRequest) async throws -> (Data, HTTPURLResponse)
}

public struct URLSessionDogSwipeHTTPClient: DogSwipeHTTPClient {
    private let session: URLSession

    public init(session: URLSession = .shared) {
        self.session = session
    }

    public func data(for request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw DogSwipeAPIError.nonHTTPResponse
        }
        return (data, httpResponse)
    }
}

public enum DogSwipeAPIError: Error, Equatable, LocalizedError, Sendable {
    case invalidResponseStatus(Int)
    case nonHTTPResponse
    case invalidURL

    public var errorDescription: String? {
        switch self {
        case .invalidResponseStatus(let statusCode):
            "Request failed with status \(statusCode)."
        case .nonHTTPResponse:
            "The server returned an unsupported response."
        case .invalidURL:
            "The request URL could not be built."
        }
    }
}

public struct DiscoveryLocation: Equatable, Sendable {
    public let latitude: Double
    public let longitude: Double

    public init(latitude: Double, longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
    }
}

public struct DogSwipeAPIClient: Sendable {
    public typealias AuthorizationTokenProvider = @Sendable () async throws -> String?

    private let baseURL: URL
    private let httpClient: DogSwipeHTTPClient
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder
    private let authorizationTokenProvider: AuthorizationTokenProvider?

    public init(
        baseURL: URL,
        httpClient: DogSwipeHTTPClient = URLSessionDogSwipeHTTPClient(),
        decoder: JSONDecoder = JSONDecoder(),
        encoder: JSONEncoder = JSONEncoder(),
        authorizationTokenProvider: AuthorizationTokenProvider? = nil
    ) {
        self.baseURL = baseURL
        self.httpClient = httpClient
        self.decoder = decoder
        self.encoder = encoder
        self.authorizationTokenProvider = authorizationTokenProvider
    }

    public func discovery(limit: Int = 20, location: DiscoveryLocation? = nil) async throws -> [HotdogProfile] {
        var components = components(path: "/v1/discovery")
        var queryItems = [URLQueryItem(name: "limit", value: String(limit))]
        if let location {
            queryItems.append(URLQueryItem(name: "latitude", value: String(location.latitude)))
            queryItems.append(URLQueryItem(name: "longitude", value: String(location.longitude)))
        }
        components.queryItems = queryItems
        let response: DiscoveryResponse = try await send(components: components)
        return response.profiles
    }

    @discardableResult
    public func swipe(
        profileID: String,
        decision: SwipeDecision
    ) async throws -> SwipeResponse {
        let request = SwipeRequest(profileID: profileID, decision: decision)
        return try await send(path: "/v1/swipes", method: "POST", body: request)
    }

    public func matches() async throws -> [HotdogProfile] {
        let components = components(path: "/v1/matches")
        let response: MatchResponse = try await send(components: components)
        return response.matches
    }

    public func preferences() async throws -> DiscoveryPreferences {
        try await send(path: "/v1/preferences")
    }

    @discardableResult
    public func updatePreferences(
        _ preferences: DiscoveryPreferences
    ) async throws -> DiscoveryPreferences {
        try await send(path: "/v1/preferences", method: "PUT", body: preferences)
    }

    public func vendorSubmissions() async throws -> [HotdogProfile] {
        let response: VendorSubmissionListResponse = try await send(path: "/v1/vendor/submissions")
        return response.submissions
    }

    @discardableResult
    public func submitVendorProfile(
        _ submission: VendorSubmissionRequest
    ) async throws -> HotdogProfile {
        let response: VendorSubmissionResponse = try await send(
            path: "/v1/vendor/submissions",
            method: "POST",
            body: submission
        )
        return response.profile
    }

    @discardableResult
    public func updateVendorSubmission(
        profileID: String,
        submission: VendorSubmissionRequest
    ) async throws -> HotdogProfile {
        let response: VendorSubmissionResponse = try await send(
            path: "/v1/vendor/submissions/\(profileID)",
            method: "PUT",
            body: submission
        )
        return response.profile
    }

    @discardableResult
    public func ingestVendorSubmissionMenu(profileID: String) async throws -> HotdogProfile {
        let response: MenuIngestionResponse = try await send(
            path: "/v1/vendor/submissions/\(profileID)/ingest-menu",
            method: "POST"
        )
        return response.profile
    }

    public func adminReviewQueue() async throws -> [HotdogProfile] {
        let response: AdminReviewQueueResponse = try await send(
            path: "/v1/admin/vendor/submissions"
        )
        return response.submissions
    }

    @discardableResult
    public func approveVendorSubmission(
        profileID: String,
        craveScore: Double
    ) async throws -> HotdogProfile {
        let response: AdminApprovalResponse = try await send(
            path: "/v1/admin/vendor/submissions/\(profileID)/approve",
            method: "POST",
            body: AdminApprovalRequest(craveScore: craveScore)
        )
        return response.profile
    }

    @discardableResult
    public func requestVendorSubmissionChanges(
        profileID: String,
        reviewNote: String
    ) async throws -> HotdogProfile {
        let response: AdminModerationResponse = try await send(
            path: "/v1/admin/vendor/submissions/\(profileID)/request-changes",
            method: "POST",
            body: AdminModerationRequest(reviewNote: reviewNote)
        )
        return response.profile
    }

    @discardableResult
    public func rejectVendorSubmission(
        profileID: String,
        reviewNote: String
    ) async throws -> HotdogProfile {
        let response: AdminModerationResponse = try await send(
            path: "/v1/admin/vendor/submissions/\(profileID)/reject",
            method: "POST",
            body: AdminModerationRequest(reviewNote: reviewNote)
        )
        return response.profile
    }

    private func send<Response: Decodable>(
        path: String,
        method: String = "GET",
        body: (some Encodable)? = Optional<String>.none
    ) async throws -> Response {
        try await send(components: components(path: path), method: method, body: body)
    }

    private func send<Response: Decodable>(
        components: URLComponents,
        method: String = "GET",
        body: (some Encodable)? = Optional<String>.none
    ) async throws -> Response {
        guard let url = components.url else {
            throw DogSwipeAPIError.invalidURL
        }
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if let authorizationHeader = try await authorizationHeader() {
            request.setValue(authorizationHeader, forHTTPHeaderField: "Authorization")
        }
        if let body {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try encoder.encode(body)
        }
        let (data, response) = try await httpClient.data(for: request)
        guard 200..<300 ~= response.statusCode else {
            throw DogSwipeAPIError.invalidResponseStatus(response.statusCode)
        }
        return try decoder.decode(Response.self, from: data)
    }

    private func authorizationHeader() async throws -> String? {
        guard let authorizationTokenProvider else {
            return nil
        }
        guard let token = try await authorizationTokenProvider()?.trimmingCharacters(
            in: .whitespacesAndNewlines
        ), !token.isEmpty else {
            return nil
        }
        return "Bearer \(token)"
    }

    private func components(path: String) -> URLComponents {
        let url = baseURL.appending(path: path)
        return URLComponents(url: url, resolvingAgainstBaseURL: false) ?? URLComponents()
    }
}
