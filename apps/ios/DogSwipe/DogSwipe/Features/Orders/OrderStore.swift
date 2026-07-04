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
}

@MainActor
final class OrderStore: ObservableObject {
    @Published private(set) var items: [OrderItem] = []
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?

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

    private func upsert(_ item: OrderItem) {
        if let existingIndex = items.firstIndex(where: { $0.id == item.id }) {
            items.remove(at: existingIndex)
        }
        items.insert(item, at: 0)
    }
}
