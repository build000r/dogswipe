import Foundation

public enum ReviewDirection: String, Codable, Equatable, Sendable {
    case giverReviewsReceiver = "giver_reviews_receiver"
    case receiverReviewsGiver = "receiver_reviews_giver"
}

public struct DogSwipeReview: Identifiable, Codable, Equatable, Sendable {
    public let id: String
    public let orderID: String
    public let raterUserID: String
    public let rateeUserID: String
    public let direction: ReviewDirection
    public let rating: Int
    public let text: String?
    public let createdAt: String

    public init(
        id: String,
        orderID: String,
        raterUserID: String,
        rateeUserID: String,
        direction: ReviewDirection,
        rating: Int,
        text: String? = nil,
        createdAt: String
    ) {
        self.id = id
        self.orderID = orderID
        self.raterUserID = raterUserID
        self.rateeUserID = rateeUserID
        self.direction = direction
        self.rating = rating
        self.text = text
        self.createdAt = createdAt
    }

    public var starsLabel: String {
        String(repeating: "★", count: rating) + String(repeating: "☆", count: 5 - rating)
    }

    enum CodingKeys: String, CodingKey {
        case id
        case orderID = "order_id"
        case raterUserID = "rater_user_id"
        case rateeUserID = "ratee_user_id"
        case direction
        case rating
        case text
        case createdAt = "created_at"
    }
}

public struct ReviewCreateRequest: Codable, Equatable, Sendable {
    public let orderID: String
    public let rateeUserID: String
    public let direction: ReviewDirection
    public let rating: Int
    public let text: String?

    public init(
        orderID: String,
        rateeUserID: String,
        direction: ReviewDirection,
        rating: Int,
        text: String? = nil
    ) {
        self.orderID = orderID
        self.rateeUserID = rateeUserID
        self.direction = direction
        self.rating = rating
        self.text = text
    }

    enum CodingKeys: String, CodingKey {
        case orderID = "order_id"
        case rateeUserID = "ratee_user_id"
        case direction
        case rating
        case text
    }
}

public struct ReviewResponse: Codable, Equatable, Sendable {
    public let review: DogSwipeReview

    public init(review: DogSwipeReview) {
        self.review = review
    }
}
