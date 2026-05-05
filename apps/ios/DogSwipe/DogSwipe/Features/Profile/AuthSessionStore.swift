import Foundation

final class AuthSessionStore: ObservableObject {
    @Published private(set) var bearerToken = ""
    @Published private(set) var hasRefreshToken = false
    @Published private(set) var sessionEmail: String?
    @Published private(set) var isAuthenticating = false
    @Published private(set) var sessionMessage: String?

    private let accessTokenStore: BearerTokenStoring
    private let refreshTokenStore: BearerTokenStoring
    private let authClient: SPAPSAuthClient

    init(
        accessTokenStore: BearerTokenStoring = KeychainBearerTokenStore(),
        refreshTokenStore: BearerTokenStoring = KeychainBearerTokenStore(
            account: "spaps-refresh-token"
        ),
        authClient: SPAPSAuthClient = AppEnvironment.spapsAuthClient()
    ) {
        self.accessTokenStore = accessTokenStore
        self.refreshTokenStore = refreshTokenStore
        self.authClient = authClient
    }

    var hasBearerToken: Bool {
        !bearerToken.isEmpty
    }

    @MainActor
    func load() {
        do {
            bearerToken = try accessTokenStore.token() ?? ""
            hasRefreshToken = try !(refreshTokenStore.token() ?? "").isEmpty
            sessionMessage = nil
        } catch {
            bearerToken = ""
            hasRefreshToken = false
            sessionMessage = "Session token could not be loaded."
        }
    }

    @MainActor
    func save(_ token: String) {
        let trimmedToken = token.trimmingCharacters(in: .whitespacesAndNewlines)
        do {
            if trimmedToken.isEmpty {
                try accessTokenStore.clear()
            } else {
                try accessTokenStore.save(trimmedToken)
            }
            try refreshTokenStore.clear()
            bearerToken = trimmedToken
            hasRefreshToken = false
            sessionEmail = nil
            sessionMessage = nil
        } catch {
            sessionMessage = "Session token could not be saved."
        }
    }

    @MainActor
    func requestMagicLink(email: String) async {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedEmail.isEmpty else {
            sessionMessage = "Email is required."
            return
        }
        isAuthenticating = true
        defer { isAuthenticating = false }
        do {
            try await authClient.requestMagicLink(email: trimmedEmail)
            sessionMessage = "Magic link sent."
        } catch {
            sessionMessage = error.localizedDescription
        }
    }

    @MainActor
    func verifyMagicLink(token: String) async {
        let trimmedToken = token.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedToken.isEmpty else {
            sessionMessage = "Magic link token is required."
            return
        }
        isAuthenticating = true
        defer { isAuthenticating = false }
        do {
            let session = try await authClient.verifyMagicLink(token: trimmedToken)
            try save(session)
            sessionMessage = "Signed in."
        } catch {
            sessionMessage = error.localizedDescription
        }
    }

    @MainActor
    func refreshSession() async {
        do {
            guard let refreshToken = try refreshTokenStore.token(), !refreshToken.isEmpty else {
                sessionMessage = "No refresh token available."
                return
            }
            isAuthenticating = true
            defer { isAuthenticating = false }
            let session = try await authClient.refresh(refreshToken: refreshToken)
            try save(session)
            sessionMessage = "Session refreshed."
        } catch {
            sessionMessage = error.localizedDescription
        }
    }

    @MainActor
    func signOut() {
        do {
            try accessTokenStore.clear()
            try refreshTokenStore.clear()
            bearerToken = ""
            hasRefreshToken = false
            sessionEmail = nil
            sessionMessage = nil
        } catch {
            sessionMessage = "Session token could not be cleared."
        }
    }

    @MainActor
    private func save(_ session: SPAPSAuthSession) throws {
        try accessTokenStore.save(session.accessToken)
        if let refreshToken = session.refreshToken, !refreshToken.isEmpty {
            try refreshTokenStore.save(refreshToken)
            hasRefreshToken = true
        } else {
            try refreshTokenStore.clear()
            hasRefreshToken = false
        }
        bearerToken = session.accessToken
        sessionEmail = session.userEmail
    }
}
