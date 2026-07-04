import DogSwipeCore
import Foundation

@MainActor
final class WalletStore: ObservableObject {
    @Published private(set) var account: CreditAccount?
    @Published private(set) var entries: [CreditLedgerEntry] = []
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var purchaseURL: URL?

    private let apiClient: DogSwipeAPIClient

    init(apiClient: DogSwipeAPIClient = AppEnvironment.apiClient()) {
        self.apiClient = apiClient
    }

    var balance: Int {
        account?.balance ?? 0
    }

    var balanceLabel: String {
        "\(balance) credits"
    }

    func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let response = try await apiClient.wallet()
            account = response.account
            entries = response.entries
            errorMessage = nil
        } catch {
            errorMessage = "Could not load wallet."
        }
    }

    func purchaseCredits(amountCents: Int) async {
        do {
            let response = try await apiClient.purchaseCredits(amountCents: amountCents)
            if let url = URL(string: response.checkoutURL) {
                purchaseURL = url
            }
        } catch {
            errorMessage = "Could not start purchase."
        }
    }

    func clearPurchaseURL() {
        purchaseURL = nil
    }
}
