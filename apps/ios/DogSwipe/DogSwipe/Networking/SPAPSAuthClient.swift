import DogSwipeCore
import Foundation

enum SPAPSAuthError: Error, Equatable, LocalizedError {
    case invalidURL
    case invalidResponse
    case invalidResponseStatus(Int)
    case missingPublishableKey
    case serverMessage(String)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            "SPAPS auth URL could not be built."
        case .invalidResponse:
            "SPAPS auth returned an unsupported response."
        case .invalidResponseStatus(let statusCode):
            "SPAPS auth request failed with status \(statusCode)."
        case .missingPublishableKey:
            "SPAPS publishable key is not configured."
        case .serverMessage(let message):
            message
        }
    }
}

struct SPAPSAuthSession: Equatable, Sendable {
    let accessToken: String
    let refreshToken: String?
    let userEmail: String?
}

struct SPAPSAuthClient: Sendable {
    private let baseURL: URL
    private let publishableKey: String
    private let origin: String?
    private let httpClient: DogSwipeHTTPClient
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init(
        baseURL: URL,
        publishableKey: String,
        origin: String? = nil,
        httpClient: DogSwipeHTTPClient = URLSessionDogSwipeHTTPClient(),
        encoder: JSONEncoder = JSONEncoder(),
        decoder: JSONDecoder = JSONDecoder()
    ) {
        self.baseURL = baseURL
        self.publishableKey = publishableKey
        self.origin = origin
        self.httpClient = httpClient
        self.encoder = encoder
        self.decoder = decoder
    }

    func requestMagicLink(email: String, redirectURL: URL? = nil) async throws {
        let request = MagicLinkRequest(email: email, redirectURL: redirectURL?.absoluteString)
        try await send(path: "/api/auth/magic-link", body: request)
    }

    func verifyMagicLink(token: String, type: String = "magiclink") async throws -> SPAPSAuthSession {
        let request = VerifyMagicLinkRequest(token: token, type: type)
        let payload: AuthResponsePayload = try await send(
            path: "/api/auth/verify-magic-link",
            body: request
        )
        guard let session = payload.session else {
            throw SPAPSAuthError.invalidResponse
        }
        return session
    }

    func refresh(refreshToken: String) async throws -> SPAPSAuthSession {
        let request = RefreshRequest(refreshToken: refreshToken)
        let payload: AuthResponsePayload = try await send(path: "/api/auth/refresh", body: request)
        guard let session = payload.session else {
            throw SPAPSAuthError.invalidResponse
        }
        return session
    }

    func logout(accessToken: String?) async {
        let request = EmptyRequest()
        try? await send(path: "/api/auth/logout", body: request, accessToken: accessToken)
    }

    private func send<Request: Encodable>(
        path: String,
        body: Request,
        accessToken: String? = nil
    ) async throws {
        let data = try await rawResponse(path: path, body: body, accessToken: accessToken)
        if !data.isEmpty, let envelope = try? decoder.decode(SPAPSEnvelope<EmptyResponse>.self, from: data) {
            try validate(envelope)
        }
    }

    private func send<Response: Decodable, Request: Encodable>(
        path: String,
        body: Request,
        accessToken: String? = nil
    ) async throws -> Response {
        let data = try await rawResponse(path: path, body: body, accessToken: accessToken)
        if let envelope = try? decoder.decode(SPAPSEnvelope<Response>.self, from: data),
           envelope.success != nil || envelope.data != nil || envelope.error != nil {
            try validate(envelope)
            if let payload = envelope.data {
                return payload
            }
        }
        return try decoder.decode(Response.self, from: data)
    }

    private func rawResponse<Request: Encodable>(
        path: String,
        body: Request,
        accessToken: String?
    ) async throws -> Data {
        let key = publishableKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !key.isEmpty else {
            throw SPAPSAuthError.missingPublishableKey
        }
        guard let url = URLComponents(
            url: baseURL.appending(path: path),
            resolvingAgainstBaseURL: false
        )?.url else {
            throw SPAPSAuthError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(key, forHTTPHeaderField: "X-API-Key")
        if let origin, !origin.isEmpty {
            request.setValue(origin, forHTTPHeaderField: "Origin")
        }
        if let accessToken, !accessToken.isEmpty {
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        }
        request.httpBody = try encoder.encode(body)

        let (data, response) = try await httpClient.data(for: request)
        guard 200..<300 ~= response.statusCode else {
            throw SPAPSAuthError.invalidResponseStatus(response.statusCode)
        }
        return data
    }

    private func validate<Response>(_ envelope: SPAPSEnvelope<Response>) throws {
        if envelope.success == false {
            throw SPAPSAuthError.serverMessage(
                envelope.error?.message ?? "SPAPS auth request failed."
            )
        }
    }
}

private struct MagicLinkRequest: Encodable {
    let email: String
    let redirectURL: String?

    enum CodingKeys: String, CodingKey {
        case email
        case redirectURL = "redirect_url"
    }
}

private struct VerifyMagicLinkRequest: Encodable {
    let token: String
    let type: String
}

private struct RefreshRequest: Encodable {
    let refreshToken: String

    enum CodingKeys: String, CodingKey {
        case refreshToken = "refresh_token"
    }
}

private struct EmptyRequest: Encodable {}

private struct EmptyResponse: Decodable {}

private struct SPAPSEnvelope<Payload: Decodable>: Decodable {
    let success: Bool?
    let data: Payload?
    let error: SPAPSErrorResponse?
}

private struct SPAPSErrorResponse: Decodable {
    let message: String?
}

private struct AuthResponsePayload: Decodable {
    let accessToken: String?
    let refreshToken: String?
    let tokens: AuthTokens?
    let user: AuthUser?

    var session: SPAPSAuthSession? {
        let accessToken = tokens?.accessToken ?? accessToken
        guard let accessToken, !accessToken.isEmpty else {
            return nil
        }
        return SPAPSAuthSession(
            accessToken: accessToken,
            refreshToken: tokens?.refreshToken ?? refreshToken,
            userEmail: user?.email
        )
    }

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case tokens
        case user
    }
}

private struct AuthTokens: Decodable {
    let accessToken: String?
    let refreshToken: String?

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
    }
}

private struct AuthUser: Decodable {
    let email: String?
}
