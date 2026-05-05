import Foundation

public enum SwipeDecision: String, Codable, Equatable, Sendable {
    case like
    case pass
    case superLike = "super_like"

    public var isPositive: Bool {
        switch self {
        case .like, .superLike:
            true
        case .pass:
            false
        }
    }
}

public struct SwipeEvent: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public let profileID: String
    public let decision: SwipeDecision
    public let createdAt: Date

    public init(
        id: UUID = UUID(),
        profileID: String,
        decision: SwipeDecision,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.profileID = profileID
        self.decision = decision
        self.createdAt = createdAt
    }
}

public struct SwipeRequest: Codable, Equatable, Sendable {
    public let profileID: String
    public let decision: SwipeDecision

    public init(profileID: String, decision: SwipeDecision) {
        self.profileID = profileID
        self.decision = decision
    }

    enum CodingKeys: String, CodingKey {
        case profileID = "profile_id"
        case decision
    }
}

public struct SwipeResponse: Codable, Equatable, Sendable {
    public let profileID: String
    public let decision: SwipeDecision
    public let matched: Bool

    public init(profileID: String, decision: SwipeDecision, matched: Bool) {
        self.profileID = profileID
        self.decision = decision
        self.matched = matched
    }

    enum CodingKeys: String, CodingKey {
        case profileID = "profile_id"
        case decision
        case matched
    }
}
