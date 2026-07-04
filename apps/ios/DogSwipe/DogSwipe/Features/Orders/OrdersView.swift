import DogSwipeCore
import SwiftUI

struct OrdersView: View {
    @ObservedObject private var orderStore: OrderStore

    @MainActor
    init(orderStore: OrderStore? = nil) {
        self.orderStore = orderStore ?? OrderStore()
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: .dsSpace5) {
                    DogSwipeScreenHeader(
                        title: "Drafts",
                        kicker: "\(orderStore.itemCount) saved \(orderStore.itemCount == 1 ? "order" : "orders")"
                    )
                    content
                }
                .padding(.horizontal, .dsSpace5)
                .padding(.top, .dsSpace2)
                .padding(.bottom, .dsSpace8)
            }
            .refreshable {
                await orderStore.load()
            }
            .task {
                if orderStore.items.isEmpty {
                    await orderStore.load()
                }
            }
            .onAppear {
                DogSwipeAnalytics.shared.trackScreenViewed(.orders)
            }
            .toolbar(.hidden, for: .navigationBar)
            .dsPageBackground()
            .accessibilityIdentifier("dogswipe.orders.screen")
        }
    }

    @ViewBuilder
    private var content: some View {
        if orderStore.isLoading && orderStore.items.isEmpty {
            loadingState
        } else if orderStore.items.isEmpty {
            emptyState
        } else {
            ordersList
        }
    }

    private var loadingState: some View {
        VStack(spacing: .dsSpace3) {
            ProgressView()
                .tint(.dsPrimary)
            Text("Loading orders")
                .font(.headline)
                .foregroundStyle(Color.dsInk)
        }
        .frame(maxWidth: .infinity, minHeight: .dsOrdersStateMinHeight)
        .dsCardSurface()
    }

    private var emptyState: some View {
        VStack(spacing: .dsSpace3) {
            Image(systemName: "bag")
                .font(.largeTitle.weight(.semibold))
                .foregroundStyle(Color.dsPrimary)
            Text("No orders yet")
                .font(.title3.weight(.heavy))
                .foregroundStyle(Color.dsInk)
            Text("Match with a local hotdog and save your first draft.")
                .font(.subheadline)
                .foregroundStyle(Color.dsMuted)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, minHeight: .dsOrdersStateMinHeight)
        .padding(.dsSpace5)
        .dsCardSurface()
    }

    private var ordersList: some View {
        VStack(alignment: .leading, spacing: .dsSpace3) {
            DogSwipeDarkSummaryCard {
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: .dsSpace1) {
                        Text("Cart total")
                            .font(.caption.weight(.heavy))
                            .tracking(1)
                            .foregroundStyle(Color.dsSurface.opacity(0.62))
                            .textCase(.uppercase)
                        Text(totalLabel)
                            .font(.system(size: .dsSummaryAmountFontSize, weight: .heavy, design: .rounded).monospacedDigit())
                    }
                    Spacer()
                    Text("Drafts only\nno payment yet")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.dsSurface.opacity(0.56))
                        .multilineTextAlignment(.trailing)
                }
            }

            DogSwipeSectionHeader(
                title: "My Orders",
                subtitle: "\(orderStore.itemCount) saved \(orderStore.itemCount == 1 ? "draft" : "drafts")",
                systemImage: "bag.fill"
            )

            if let errorMessage = orderStore.errorMessage {
                Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color.dsAccent)
            }

            ForEach(orderStore.items) { item in
                OrderCardView(item: item)
            }
        }
    }

    private var totalLabel: String {
        OrderAddOn.creditLabel(for: orderStore.items.reduce(0) { $0 + $1.totalCredits })
    }
}

private struct OrderCardView: View {
    let item: OrderItem

    var body: some View {
        VStack(alignment: .leading, spacing: .dsSpace3) {
            HStack(alignment: .top, spacing: .dsSpace3) {
                HotdogIllustrationView(profile: previewProfile)
                    .frame(width: .dsOrderThumbnailWidth, height: .dsOrderThumbnailHeight)
                    .clipShape(RoundedRectangle(cornerRadius: .dsRadius3, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: .dsRadius3, style: .continuous)
                            .stroke(Color.dsDivider)
                    }

                VStack(alignment: .leading, spacing: .dsSpace1) {
                    Text(item.hotdogName)
                        .font(.headline.weight(.heavy))
                        .foregroundStyle(Color.dsInk)
                        .lineLimit(2)
                        .minimumScaleFactor(0.82)
                    Text(item.vendorName)
                        .font(.subheadline)
                        .foregroundStyle(Color.dsMuted)
                        .lineLimit(1)
                    Text(item.addOnSummary)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.dsMuted)
                        .lineLimit(2)
                }

                Spacer(minLength: .dsSpace2)

                Text(item.totalLabel)
                    .font(.headline.weight(.heavy).monospacedDigit())
                    .foregroundStyle(Color.dsAccent)
            }

            HStack(spacing: .dsSpace2) {
                DogSwipeChip(text: item.statusLabel, systemImage: "clock.fill", tint: Color.dsPrimarySoft)
                DogSwipeChip(text: "Saved", systemImage: "bag.fill", tint: Color.dsSurface)
                Spacer(minLength: .dsSpace1)
            }
        }
        .dsCard()
    }

    private var previewProfile: HotdogProfile {
        HotdogProfile(
            id: item.profileID,
            name: item.hotdogName,
            style: item.statusLabel,
            creditCost: item.baseCreditCost,
            signatureNotes: item.addOnSummary,
            distanceMiles: 0,
            vendorName: item.vendorName,
            menuHighlights: item.addOns.map(\.name),
            craveScore: 0.5
        )
    }
}

#Preview {
    OrdersView()
}
