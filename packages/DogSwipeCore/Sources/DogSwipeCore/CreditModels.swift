import Foundation

public struct CreditAccount: Codable, Equatable, Sendable {
    public let userID: String
    public let lifetimePurchased: Int
    public let lifetimeEarned: Int
    public let lifetimeSpent: Int
    public let createdAt: String
    public let updatedAt: String

    public var balance: Int {
        lifetimePurchased + lifetimeEarned - lifetimeSpent
    }

    public var balanceLabel: String {
        "\(balance) credits"
    }

    public init(
        userID: String,
        lifetimePurchased: Int,
        lifetimeEarned: Int,
        lifetimeSpent: Int,
        createdAt: String,
        updatedAt: String
    ) {
        self.userID = userID
        self.lifetimePurchased = lifetimePurchased
        self.lifetimeEarned = lifetimeEarned
        self.lifetimeSpent = lifetimeSpent
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    enum CodingKeys: String, CodingKey {
        case userID = "user_id"
        case lifetimePurchased = "lifetime_purchased"
        case lifetimeEarned = "lifetime_earned"
        case lifetimeSpent = "lifetime_spent"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

public struct WalletResponse: Codable, Equatable, Sendable {
    public let account: CreditAccount
    public let entries: [CreditLedgerEntry]

    public init(account: CreditAccount, entries: [CreditLedgerEntry] = []) {
        self.account = account
        self.entries = entries
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        account = try c.decode(CreditAccount.self, forKey: .account)
        entries = try c.decodeIfPresent([CreditLedgerEntry].self, forKey: .entries) ?? []
    }

    enum CodingKeys: String, CodingKey {
        case account
        case entries
    }
}

public enum CreditLedgerEntryType: String, Codable, Equatable, Sendable {
    case purchase
    case spend
    case earn
    case refundCredit = "refund_credit"
    case adminAdjustment = "admin_adjustment"

    public var label: String {
        switch self {
        case .purchase: "Purchase"
        case .spend: "Spent"
        case .earn: "Earned"
        case .refundCredit: "Refund"
        case .adminAdjustment: "Adjustment"
        }
    }
}

public struct CreditLedgerEntry: Identifiable, Codable, Equatable, Sendable {
    public let id: String
    public let userID: String
    public let entryType: CreditLedgerEntryType
    public let amount: Int
    public let balanceAfter: Int
    public let orderRef: String?
    public let purchaseRef: String?
    public let reason: String?
    public let createdAt: String

    public var amountLabel: String {
        switch entryType {
        case .spend:
            return "-\(amount)"
        case .purchase, .earn, .refundCredit, .adminAdjustment:
            return "+\(amount)"
        }
    }

    public init(
        id: String,
        userID: String,
        entryType: CreditLedgerEntryType,
        amount: Int,
        balanceAfter: Int,
        orderRef: String? = nil,
        purchaseRef: String? = nil,
        reason: String? = nil,
        createdAt: String
    ) {
        self.id = id
        self.userID = userID
        self.entryType = entryType
        self.amount = amount
        self.balanceAfter = balanceAfter
        self.orderRef = orderRef
        self.purchaseRef = purchaseRef
        self.reason = reason
        self.createdAt = createdAt
    }

    enum CodingKeys: String, CodingKey {
        case id
        case userID = "user_id"
        case entryType = "entry_type"
        case amount
        case balanceAfter = "balance_after"
        case orderRef = "order_ref"
        case purchaseRef = "purchase_ref"
        case reason
        case createdAt = "created_at"
    }
}

public struct CreditPurchaseRequest: Codable, Equatable, Sendable {
    public let amountCents: Int

    public init(amountCents: Int) {
        self.amountCents = amountCents
    }

    enum CodingKeys: String, CodingKey {
        case amountCents = "amount_cents"
    }
}

public struct CreditPurchaseResponse: Codable, Equatable, Sendable {
    public let checkoutSessionID: String
    public let checkoutURL: String
    public let amountCents: Int
    public let credits: Int

    public init(
        checkoutSessionID: String,
        checkoutURL: String,
        amountCents: Int,
        credits: Int
    ) {
        self.checkoutSessionID = checkoutSessionID
        self.checkoutURL = checkoutURL
        self.amountCents = amountCents
        self.credits = credits
    }

    enum CodingKeys: String, CodingKey {
        case checkoutSessionID = "checkout_session_id"
        case checkoutURL = "checkout_url"
        case amountCents = "amount_cents"
        case credits
    }
}
