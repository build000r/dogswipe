import Foundation

public enum CreditExplanationCopy: Sendable {

    // MARK: - Why credits stay in the neighborhood

    public static let whyNonWithdrawable =
        "Credits stay in the neighborhood. When you buy credits, " +
        "those dollars join the community pool — they don't come back out. " +
        "You spend credits on your neighbors' offerings, and when you make " +
        "something great, you earn credits from theirs. " +
        "That's the whole idea: value circulates, it doesn't get extracted."

    public static let whyNonWithdrawableShort =
        "Credits are for spending on neighbors, not cashing out. " +
        "That's by design — it keeps value in the community."

    public static let noWithdrawBannerTitle = "No cash-out, ever"

    public static let noWithdrawBannerBody =
        "Credits can't be converted back to dollars — " +
        "not by you, not by the person who made your lunch, not by anyone. " +
        "Spend them on something a neighbor made."

    // MARK: - Food hand-off

    public static let foodDisclaimerTitle = "A word about hand-offs"

    public static let foodDisclaimer =
        "Offerings on DogSwipe are made by your neighbors, " +
        "not a restaurant. The person handing you that hotdog " +
        "is responsible for what's in it — we don't inspect, " +
        "prepare, or handle any food. If you've got allergies " +
        "or dietary needs, talk to the maker before you pick up."

    public static let makerFoodAcknowledgment =
        "By posting a food offering, you confirm that you're " +
        "responsible for its safety, ingredients, and any labeling " +
        "your local laws require. DogSwipe doesn't inspect " +
        "or certify what you make — that's on you."

    // MARK: - Credit purchase

    public static let purchaseConfirmationTitle = "Add credits to your wallet"

    public static func purchaseConfirmation(creditAmount: Int, dollarAmount: Int) -> String {
        "You're adding \(creditAmount) credits to your wallet " +
        "for $\(dollarAmount). Once purchased, credits stay in the " +
        "community — no refunds to cash, no withdrawals, no exceptions. " +
        "Ready to join the neighborhood?"
    }

    public static let purchaseFinePrint =
        "Credits are purchased 1-for-1 with dollars and are " +
        "non-refundable. They can only be spent on other people's " +
        "offerings within DogSwipe."

    // MARK: - Disputes

    public static let disputeRefundNote =
        "If something goes wrong with a claim, we can refund " +
        "your credits — but never cash. Disputes are settled " +
        "within the credit system."
}
