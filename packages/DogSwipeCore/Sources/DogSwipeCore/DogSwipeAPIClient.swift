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

public struct DogSwipeAPIClient: Sendable {
    private let baseURL: URL
    private let httpClient: DogSwipeHTTPClient
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    public init(
        baseURL: URL,
        httpClient: DogSwipeHTTPClient = URLSessionDogSwipeHTTPClient(),
        decoder: JSONDecoder = JSONDecoder(),
        encoder: JSONEncoder = JSONEncoder()
    ) {
        self.baseURL = baseURL
        self.httpClient = httpClient
        self.decoder = decoder
        self.encoder = encoder
    }

    public func discovery(limit: Int = 20) async throws -> [DogProfile] {
        var components = components(path: "/v1/discovery")
        components.queryItems = [URLQueryItem(name: "limit", value: String(limit))]
        let response: DiscoveryResponse = try await send(components: components)
        return response.profiles
    }

    @discardableResult
    public func swipe(
        userID: String,
        profileID: String,
        decision: SwipeDecision
    ) async throws -> SwipeResponse {
        let request = SwipeRequest(userID: userID, profileID: profileID, decision: decision)
        return try await send(path: "/v1/swipes", method: "POST", body: request)
    }

    public func matches(userID: String) async throws -> [DogProfile] {
        var components = components(path: "/v1/matches")
        components.queryItems = [URLQueryItem(name: "user_id", value: userID)]
        let response: MatchResponse = try await send(components: components)
        return response.matches
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

    private func components(path: String) -> URLComponents {
        let url = baseURL.appending(path: path)
        return URLComponents(url: url, resolvingAgainstBaseURL: false) ?? URLComponents()
    }
}
