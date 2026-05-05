import Foundation

final class AuthSessionStore: ObservableObject {
    @Published private(set) var bearerToken = ""
    @Published private(set) var sessionMessage: String?

    private let tokenStore: BearerTokenStoring

    init(tokenStore: BearerTokenStoring = KeychainBearerTokenStore()) {
        self.tokenStore = tokenStore
    }

    var hasBearerToken: Bool {
        !bearerToken.isEmpty
    }

    @MainActor
    func load() {
        do {
            bearerToken = try tokenStore.token() ?? ""
            sessionMessage = nil
        } catch {
            bearerToken = ""
            sessionMessage = "Session token could not be loaded."
        }
    }

    @MainActor
    func save(_ token: String) {
        let trimmedToken = token.trimmingCharacters(in: .whitespacesAndNewlines)
        do {
            if trimmedToken.isEmpty {
                try tokenStore.clear()
            } else {
                try tokenStore.save(trimmedToken)
            }
            bearerToken = trimmedToken
            sessionMessage = nil
        } catch {
            sessionMessage = "Session token could not be saved."
        }
    }

    @MainActor
    func signOut() {
        do {
            try tokenStore.clear()
            bearerToken = ""
            sessionMessage = nil
        } catch {
            sessionMessage = "Session token could not be cleared."
        }
    }
}
