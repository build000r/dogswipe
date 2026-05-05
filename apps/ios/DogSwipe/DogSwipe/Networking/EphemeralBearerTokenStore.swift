import Foundation

final class EphemeralBearerTokenStore: BearerTokenStoring, @unchecked Sendable {
    private var storedToken: String?

    func token() throws -> String? {
        storedToken
    }

    func save(_ token: String) throws {
        storedToken = token
    }

    func clear() throws {
        storedToken = nil
    }
}
