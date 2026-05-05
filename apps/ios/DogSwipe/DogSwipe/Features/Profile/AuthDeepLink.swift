import Foundation

struct AuthDeepLink: Equatable, Sendable {
    let token: String
    let type: String

    init?(url: URL) {
        guard url.scheme?.lowercased() == "dogswipe",
              url.host?.lowercased() == "auth",
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return nil
        }
        let queryItems = components.queryItems ?? []
        guard let token = Self.firstValue(
            named: ["token", "token_hash", "code"],
            in: queryItems
        ) else {
            return nil
        }
        self.token = token
        self.type = Self.firstValue(named: ["type"], in: queryItems) ?? "magiclink"
    }

    private static func firstValue(
        named names: [String],
        in queryItems: [URLQueryItem]
    ) -> String? {
        for name in names {
            if let value = queryItems.first(where: { $0.name == name })?.value,
               !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return value
            }
        }
        return nil
    }
}
