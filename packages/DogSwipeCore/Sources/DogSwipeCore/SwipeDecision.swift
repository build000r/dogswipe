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
