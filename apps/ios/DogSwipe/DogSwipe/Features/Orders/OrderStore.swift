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
}

struct OrderItem: Identifiable, Equatable {
    let id: UUID
    let profileID: String
    let hotdogName: String
    let vendorName: String
    let basePriceDollars: Double
    let addOns: [OrderAddOn]

    var totalDollars: Double {
        addOns.reduce(basePriceDollars) { total, addOn in
            total + addOn.priceDollars
        }
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
}

@MainActor
final class OrderStore: ObservableObject {
    @Published private(set) var items: [OrderItem] = []

    var itemCount: Int {
        items.count
    }

    var latestItem: OrderItem? {
        items.last
    }

    @discardableResult
    func add(profile: HotdogProfile, addOns: [OrderAddOn]) -> OrderItem {
        let item = OrderItem(
            id: UUID(),
            profileID: profile.id,
            hotdogName: profile.name,
            vendorName: profile.vendorName,
            basePriceDollars: profile.priceDollars,
            addOns: addOns
        )
        items.append(item)
        return item
    }
}
