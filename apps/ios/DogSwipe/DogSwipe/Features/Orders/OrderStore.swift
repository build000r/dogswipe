import Combine
import DogSwipeCore
import Foundation

struct OrderAddOn: Identifiable, Hashable {
    let id: String
    let name: String
    let priceDollars: Double

    var priceLabel: String {
        Self.priceLabel(for: priceDollars)
    }

    static let matchDefaults = [
        OrderAddOn(id: "bacon", name: "Bacon", priceDollars: 1.00),
        OrderAddOn(id: "jalapenos", name: "Jalapenos", priceDollars: 0.75),
        OrderAddOn(id: "cheese-sauce", name: "Cheese Sauce", priceDollars: 1.25),
        OrderAddOn(id: "extra-pickle", name: "Extra Pickle", priceDollars: 0.50)
    ]

    static func priceLabel(for amount: Double) -> String {
        String(format: "$%.2f", amount)
    }

    init(id: String, name: String, priceDollars: Double) {
        self.id = id
        self.name = name
        self.priceDollars = priceDollars
    }

    init(orderAddOn: DogSwipeOrderAddOn) {
        self.init(
            id: orderAddOn.id,
            name: orderAddOn.name,
            priceDollars: orderAddOn.priceDollars
        )
    }
}

struct OrderItem: Identifiable, Equatable {
    let id: String
    let profileID: String
    let hotdogName: String
    let vendorName: String
    let basePriceDollars: Double
    let addOns: [OrderAddOn]
    let totalDollars: Double
    let status: String
    let createdAt: String

    init(order: DogSwipeOrder) {
        self.id = order.id
        self.profileID = order.profileID
        self.hotdogName = order.hotdogName
        self.vendorName = order.vendorName
        self.basePriceDollars = order.basePriceDollars
        self.addOns = order.addOns.map(OrderAddOn.init(orderAddOn:))
        self.totalDollars = order.totalDollars
        self.status = order.status
        self.createdAt = order.createdAt
    }

    var totalLabel: String {
        OrderAddOn.priceLabel(for: totalDollars)
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
