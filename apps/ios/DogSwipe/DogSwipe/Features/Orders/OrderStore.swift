import Combine
import DogSwipeCore
import Foundation

struct OrderAddOn: Identifiable, Hashable {
    let id: String
    let name: String
    let creditCost: Int

    var creditLabel: String {
        Self.creditLabel(for: creditCost)
    }

    static let matchDefaults = [
        OrderAddOn(id: "bacon", name: "Bacon", creditCost: 2),
        OrderAddOn(id: "jalapenos", name: "Jalapenos", creditCost: 1),
        OrderAddOn(id: "cheese-sauce", name: "Cheese Sauce", creditCost: 2),
        OrderAddOn(id: "extra-pickle", name: "Extra Pickle", creditCost: 1)
    ]

    static func creditLabel(for amount: Int) -> String {
        "\(amount) credits"
    }

    init(id: String, name: String, creditCost: Int) {
        self.id = id
        self.name = name
        self.creditCost = creditCost
    }

    init(orderAddOn: DogSwipeOrderAddOn) {
        self.init(
            id: orderAddOn.id,
            name: orderAddOn.name,
            creditCost: orderAddOn.creditCost
        )
    }
}

struct OrderItem: Identifiable, Equatable {
    let id: String
    let profileID: String
    let hotdogName: String
    let vendorName: String
    let baseCreditCost: Int
    let addOns: [OrderAddOn]
    let totalCredits: Int
    let status: String
    let createdAt: String
    let fulfillmentMode: String
    let availableFrom: String?
    let availableUntil: String?
    let deliveryAddress: String?
    let makerReadyConfirmedAt: String?
    let makerHandoffConfirmedAt: String?
    let claimerHandoffConfirmedAt: String?
    let completedAt: String?

    init(order: DogSwipeOrder) {
        self.id = order.id
        self.profileID = order.profileID
        self.hotdogName = order.hotdogName
        self.vendorName = order.vendorName
        self.baseCreditCost = order.baseCreditCost
        self.addOns = order.addOns.map(OrderAddOn.init(orderAddOn:))
        self.totalCredits = order.totalCredits
        self.status = order.status
        self.createdAt = order.createdAt
        self.fulfillmentMode = order.fulfillmentMode
        self.availableFrom = order.availableFrom
        self.availableUntil = order.availableUntil
        self.deliveryAddress = order.deliveryAddress
        self.makerReadyConfirmedAt = order.makerReadyConfirmedAt
        self.makerHandoffConfirmedAt = order.makerHandoffConfirmedAt
        self.claimerHandoffConfirmedAt = order.claimerHandoffConfirmedAt
        self.completedAt = order.completedAt
    }

    var totalLabel: String {
        OrderAddOn.creditLabel(for: totalCredits)
    }

    var addOnSummary: String {
        guard !addOns.isEmpty else {
            return "No add-ons"
        }
        return addOns.map(\.name).joined(separator: ", ")
    }

    var statusLabel: String {
        status
            .split(separator: "_")
            .map { word in
                word.prefix(1).uppercased() + String(word.dropFirst())
            }
            .joined(separator: " ")
    }

    var isDraft: Bool { status == "draft" }
    var isClaimed: Bool { status == "claimed" }
    var isReady: Bool { status == "ready" }
    var isHandedOff: Bool { status == "handed_off" }
    var isDelivered: Bool { status == "delivered" }
    var isCompleted: Bool { status == "completed" }
    var isPickup: Bool { fulfillmentMode == "pickup" }
    var isDelivery: Bool { fulfillmentMode == "delivery" }

    var fulfillmentLabel: String {
        isDelivery ? "Delivery" : "Pickup"
    }

    var needsHandoffConfirmation: Bool {
        isReady || isHandedOff || isDelivered
    }

    var bothConfirmed: Bool {
        makerHandoffConfirmedAt != nil && claimerHandoffConfirmedAt != nil
    }
}

struct ClaimConfirmation: Equatable {
    let orderName: String
    let creditsDebited: Int
    let newBalance: Int
}

@MainActor
final class OrderStore: ObservableObject {
    @Published private(set) var items: [OrderItem] = []
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var claimingOrderID: String?
    @Published private(set) var confirmingOrderID: String?
    @Published var claimConfirmation: ClaimConfirmation?

    private let apiClient: DogSwipeAPIClient

    init(apiClient: DogSwipeAPIClient = AppEnvironment.apiClient()) {
        self.apiClient = apiClient
    }

    var itemCount: Int {
        items.count
    }

    var latestItem: OrderItem? {
        items.first
    }

    var draftCount: Int {
        items.filter { $0.status == "draft" }.count
    }

    func load() async {
        isLoading = true
        defer {
            isLoading = false
        }

        do {
            items = try await apiClient.orders().map(OrderItem.init(order:))
            errorMessage = nil
        } catch {
            errorMessage = "Orders could not load."
        }
    }

    @discardableResult
    func add(profile: HotdogProfile, addOns: [OrderAddOn]) async throws -> OrderItem {
        do {
            let order = try await apiClient.createOrder(
                profileID: profile.id,
                addOnIDs: addOns.map(\.id)
            )
            let item = OrderItem(order: order)
            upsert(item)
            errorMessage = nil
            return item
        } catch {
            errorMessage = "Could not save order."
            throw error
        }
    }

    func claim(_ item: OrderItem) async {
        claimingOrderID = item.id
        errorMessage = nil
        do {
            let order = try await apiClient.claimOrder(orderID: item.id)
            let claimed = OrderItem(order: order)
            upsert(claimed)
            let wallet = try? await apiClient.wallet()
            claimConfirmation = ClaimConfirmation(
                orderName: claimed.hotdogName,
                creditsDebited: claimed.totalCredits,
                newBalance: wallet?.account.balance ?? 0
            )
        } catch let error as DogSwipeAPIError {
            switch error {
            case .invalidResponseStatus(409):
                errorMessage = "Not enough credits. Visit Wallet to buy more."
            case .invalidResponseStatus(403):
                errorMessage = "You cannot claim your own offering."
            default:
                errorMessage = "Could not claim order."
            }
        } catch {
            errorMessage = "Could not claim order."
        }
        claimingOrderID = nil
    }

    func confirmReady(_ item: OrderItem) async {
        confirmingOrderID = item.id
        errorMessage = nil
        do {
            let order = try await apiClient.confirmOrderReady(orderID: item.id)
            upsert(OrderItem(order: order))
        } catch let error as DogSwipeAPIError {
            switch error {
            case .invalidResponseStatus(403):
                errorMessage = "Only the maker can mark an order ready."
            case .invalidResponseStatus(409):
                errorMessage = "This order cannot be marked ready."
            default:
                errorMessage = "Could not confirm order."
            }
        } catch {
            errorMessage = "Could not confirm order."
        }
        confirmingOrderID = nil
    }

    func confirmHandoff(_ item: OrderItem) async {
        confirmingOrderID = item.id
        errorMessage = nil
        do {
            let order = try await apiClient.confirmOrderHandoff(orderID: item.id)
            upsert(OrderItem(order: order))
        } catch let error as DogSwipeAPIError {
            switch error {
            case .invalidResponseStatus(403):
                errorMessage = "Only order participants can confirm hand-off."
            case .invalidResponseStatus(409):
                errorMessage = "Hand-off cannot be confirmed for this order."
            default:
                errorMessage = "Could not confirm hand-off."
            }
        } catch {
            errorMessage = "Could not confirm hand-off."
        }
        confirmingOrderID = nil
    }

    private func upsert(_ item: OrderItem) {
        if let existingIndex = items.firstIndex(where: { $0.id == item.id }) {
            items.remove(at: existingIndex)
        }
        items.insert(item, at: 0)
    }
}
