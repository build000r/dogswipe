import Foundation

struct AuthDeepLink: Equatable, Sendable {
    let token: String
    let type: String

    init?(url: URL, allowedUniversalLinkHosts: Set<String> = []) {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              Self.isNativeAuthURL(components)
                || Self.isUniversalAuthURL(
                    components,
                    allowedHosts: allowedUniversalLinkHosts
                ) else {
            return nil
        }
        let queryItems = Self.authQueryItems(from: components)
        guard let token = Self.firstValue(
            named: ["token", "token_hash", "code"],
            in: queryItems
        ) else {
            return nil
        }
        self.token = token
        self.type = Self.firstValue(named: ["type"], in: queryItems) ?? "magiclink"
    }

    private static func isNativeAuthURL(_ components: URLComponents) -> Bool {
        components.scheme?.lowercased() == "dogswipe"
            && components.host?.lowercased() == "auth"
    }

    private static func isUniversalAuthURL(
        _ components: URLComponents,
        allowedHosts: Set<String>
    ) -> Bool {
        guard components.scheme?.lowercased() == "https",
              let host = components.host?.lowercased(),
              normalizedHosts(allowedHosts).contains(host) else {
            return false
        }
        return ["/auth", "/auth/callback"].contains(components.path.lowercased())
    }

    private static func normalizedHosts(_ hosts: Set<String>) -> Set<String> {
        Set(
            hosts
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
                .filter { !$0.isEmpty }
        )
    }

    private static func authQueryItems(from components: URLComponents) -> [URLQueryItem] {
        var queryItems = components.queryItems ?? []
        if let fragment = components.fragment {
            let fragmentQuery = fragment.hasPrefix("?") ? String(fragment.dropFirst()) : fragment
            let fragmentComponents = URLComponents(
                string: "https://dogswipe.invalid?\(fragmentQuery)"
            )
            queryItems.append(contentsOf: fragmentComponents?.queryItems ?? [])
        }
        return queryItems
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
