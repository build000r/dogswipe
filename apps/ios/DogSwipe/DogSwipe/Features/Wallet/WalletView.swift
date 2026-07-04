import DogSwipeCore
import SwiftUI

struct WalletView: View {
    @StateObject private var store: WalletStore
    @Environment(\.openURL) private var openURL

    @MainActor
    init(store: WalletStore? = nil) {
        _store = StateObject(wrappedValue: store ?? WalletStore())
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: .dsSpace5) {
                    DogSwipeScreenHeader(
                        title: "Wallet",
                        kicker: store.account != nil ? store.balanceLabel : "Loading…"
                    )

                    if store.isLoading && store.account == nil {
                        loadingState
                    } else if let account = store.account {
                        balanceCard(account)
                        lifetimeStats(account)
                        buyCreditsSection
                        disclaimerSection
                        if !store.entries.isEmpty {
                            ledgerSection
                        }
                    } else if let error = store.errorMessage {
                        errorState(error)
                    }
                }
                .padding(.horizontal, .dsSpace5)
                .padding(.top, .dsSpace2)
                .padding(.bottom, .dsSpace8)
            }
            .refreshable {
                await store.load()
            }
            .task {
                if store.account == nil {
                    await store.load()
                }
            }
            .onAppear {
                DogSwipeAnalytics.shared.trackScreenViewed(.wallet)
            }
            .onChange(of: store.purchaseURL) {
                if let url = store.purchaseURL {
                    openURL(url)
                    store.clearPurchaseURL()
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .dsPageBackground()
            .accessibilityIdentifier("dogswipe.wallet.screen")
        }
    }

    private var loadingState: some View {
        VStack(spacing: .dsSpace3) {
            ProgressView()
                .tint(.dsPrimary)
            Text("Loading wallet")
                .font(.headline)
                .foregroundStyle(Color.dsInk)
        }
        .frame(maxWidth: .infinity, minHeight: 200)
        .dsCardSurface()
    }

    private func errorState(_ message: String) -> some View {
        VStack(spacing: .dsSpace3) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.largeTitle)
                .foregroundStyle(Color.dsAccent)
            Text(message)
                .font(.headline)
                .foregroundStyle(Color.dsInk)
            Button("Try again") {
                Task { await store.load() }
            }
            .buttonStyle(.borderedProminent)
            .tint(.dsPrimary)
        }
        .frame(maxWidth: .infinity, minHeight: 200)
        .dsCardSurface()
    }

    private func balanceCard(_ account: CreditAccount) -> some View {
        DogSwipeDarkSummaryCard {
            VStack(spacing: .dsSpace2) {
                Text("Balance")
                    .font(.caption.weight(.heavy))
                    .tracking(1)
                    .foregroundStyle(Color.dsSurface.opacity(0.62))
                    .textCase(.uppercase)
                Text("\(account.balance)")
                    .font(.system(size: 48, weight: .heavy, design: .rounded).monospacedDigit())
                    .foregroundStyle(Color.dsSurface)
                Text("credits")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.dsSurface.opacity(0.70))
            }
            .frame(maxWidth: .infinity)
        }
    }

    private func lifetimeStats(_ account: CreditAccount) -> some View {
        HStack(spacing: .dsSpace3) {
            statPill(label: "Purchased", value: account.lifetimePurchased, icon: "creditcard.fill")
            statPill(label: "Earned", value: account.lifetimeEarned, icon: "star.fill")
            statPill(label: "Spent", value: account.lifetimeSpent, icon: "bag.fill")
        }
    }

    private func statPill(label: String, value: Int, icon: String) -> some View {
        VStack(spacing: .dsSpace1) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(Color.dsPrimary)
            Text("\(value)")
                .font(.headline.weight(.heavy).monospacedDigit())
                .foregroundStyle(Color.dsInk)
            Text(label)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(Color.dsMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, .dsSpace3)
        .dsCardSurface()
    }

    private var buyCreditsSection: some View {
        VStack(alignment: .leading, spacing: .dsSpace3) {
            DogSwipeSectionHeader(
                title: CreditExplanationCopy.purchaseConfirmationTitle,
                subtitle: CreditExplanationCopy.purchaseFinePrint,
                systemImage: "plus.circle.fill"
            )

            HStack(spacing: .dsSpace3) {
                buyButton(label: "10 credits", cents: 1000)
                buyButton(label: "25 credits", cents: 2500)
                buyButton(label: "50 credits", cents: 5000)
            }
        }
    }

    private func buyButton(label: String, cents: Int) -> some View {
        Button {
            Task { await store.purchaseCredits(amountCents: cents) }
        } label: {
            VStack(spacing: .dsSpace1) {
                Text(label)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color.dsInk)
                Text("$\(cents / 100)")
                    .font(.caption2.weight(.semibold).monospacedDigit())
                    .foregroundStyle(Color.dsMuted)
            }
            .frame(maxWidth: .infinity, minHeight: 56)
            .background(Color.dsPrimarySoft, in: RoundedRectangle(cornerRadius: .dsRadius3, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: .dsRadius3, style: .continuous)
                    .stroke(Color.dsPrimary.opacity(0.3))
            }
        }
        .buttonStyle(.plain)
    }

    private var disclaimerSection: some View {
        VStack(alignment: .leading, spacing: .dsSpace2) {
            Label(CreditExplanationCopy.noWithdrawBannerTitle, systemImage: "lock.fill")
                .font(.caption.weight(.heavy))
                .foregroundStyle(Color.dsAccent)
            Text(CreditExplanationCopy.whyNonWithdrawableShort)
                .font(.caption)
                .foregroundStyle(Color.dsMuted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.dsSpace3)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.dsOnion.opacity(0.5), in: RoundedRectangle(cornerRadius: .dsRadius3, style: .continuous))
    }

    private var ledgerSection: some View {
        VStack(alignment: .leading, spacing: .dsSpace3) {
            DogSwipeSectionHeader(
                title: "Activity",
                subtitle: "\(store.entries.count) transactions",
                systemImage: "list.bullet"
            )

            ForEach(store.entries) { entry in
                ledgerRow(entry)
            }
        }
    }

    private func ledgerRow(_ entry: CreditLedgerEntry) -> some View {
        HStack(spacing: .dsSpace3) {
            Image(systemName: ledgerIcon(for: entry.entryType))
                .font(.body.weight(.semibold))
                .foregroundStyle(ledgerColor(for: entry.entryType))
                .frame(width: .dsSpace6, height: .dsSpace6)

            VStack(alignment: .leading, spacing: 2) {
                Text(entry.entryType.label)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Color.dsInk)
                if let reason = entry.reason, !reason.isEmpty {
                    Text(reason)
                        .font(.caption)
                        .foregroundStyle(Color.dsMuted)
                        .lineLimit(1)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(entry.amountLabel)
                    .font(.subheadline.weight(.heavy).monospacedDigit())
                    .foregroundStyle(ledgerColor(for: entry.entryType))
                Text("\(entry.balanceAfter) bal")
                    .font(.caption2.weight(.semibold).monospacedDigit())
                    .foregroundStyle(Color.dsMuted)
            }
        }
        .dsCard()
    }

    private func ledgerIcon(for type: CreditLedgerEntryType) -> String {
        switch type {
        case .purchase: "creditcard.fill"
        case .spend: "bag.fill"
        case .earn: "star.fill"
        case .refundCredit: "arrow.uturn.left.circle.fill"
        case .adminAdjustment: "wrench.fill"
        }
    }

    private func ledgerColor(for type: CreditLedgerEntryType) -> Color {
        switch type {
        case .purchase, .earn, .refundCredit: .dsRelish
        case .spend: .dsAccent
        case .adminAdjustment: .dsMuted
        }
    }
}

#Preview {
    WalletView()
}
