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
                        title: "My Orders",
                        kicker: "\(orderStore.itemCount) \(orderStore.itemCount == 1 ? "order" : "orders")"
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
            summaryCard

            if let confirmation = orderStore.claimConfirmation {
                claimConfirmationBanner(confirmation)
            }

            DogSwipeSectionHeader(
                title: "My Orders",
                subtitle: orderSubtitle,
                systemImage: "bag.fill"
            )

            if let errorMessage = orderStore.errorMessage {
                Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color.dsAccent)
            }

            ForEach(orderStore.items) { item in
                OrderCardView(
                    item: item,
                    isClaiming: orderStore.claimingOrderID == item.id,
                    isConfirming: orderStore.confirmingOrderID == item.id,
                    onClaim: { Task { await orderStore.claim(item) } },
                    onConfirmReady: { Task { await orderStore.confirmReady(item) } },
                    onConfirmHandoff: { Task { await orderStore.confirmHandoff(item) } }
                )
            }
        }
    }

    private var summaryCard: some View {
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
                if orderStore.draftCount > 0 {
                    Text("\(orderStore.draftCount) \(orderStore.draftCount == 1 ? "draft" : "drafts") ready to claim")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.dsSurface.opacity(0.56))
                        .multilineTextAlignment(.trailing)
                }
            }
        }
    }

    private func claimConfirmationBanner(_ confirmation: ClaimConfirmation) -> some View {
        HStack(spacing: .dsSpace3) {
            Image(systemName: "checkmark.circle.fill")
                .font(.title2)
                .foregroundStyle(Color.dsRelish)
            VStack(alignment: .leading, spacing: 2) {
                Text("\(confirmation.orderName) claimed!")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Color.dsInk)
                Text("\(confirmation.creditsDebited) credits debited · Balance: \(confirmation.newBalance)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.dsMuted)
            }
            Spacer()
            Button {
                orderStore.claimConfirmation = nil
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(Color.dsMuted)
            }
        }
        .padding(.dsSpace3)
        .background(Color.dsRelish.opacity(0.12), in: RoundedRectangle(cornerRadius: .dsRadius3, style: .continuous))
    }

    private var orderSubtitle: String {
        let drafts = orderStore.draftCount
        let claimed = orderStore.itemCount - drafts
        if claimed == 0 {
            return "\(drafts) \(drafts == 1 ? "draft" : "drafts")"
        }
        if drafts == 0 {
            return "\(claimed) claimed"
        }
        return "\(drafts) \(drafts == 1 ? "draft" : "drafts"), \(claimed) claimed"
    }

    private var totalLabel: String {
        OrderAddOn.creditLabel(for: orderStore.items.reduce(0) { $0 + $1.totalCredits })
    }
}

private struct OrderCardView: View {
    let item: OrderItem
    var isClaiming: Bool = false
    var isConfirming: Bool = false
    var onClaim: (() -> Void)?
    var onConfirmReady: (() -> Void)?
    var onConfirmHandoff: (() -> Void)?

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

            if !item.isDraft {
                fulfillmentRow
            }

            statusRow
        }
        .dsCard()
    }

    @ViewBuilder
    private var fulfillmentRow: some View {
        HStack(spacing: .dsSpace2) {
            Label(item.fulfillmentLabel, systemImage: item.isDelivery ? "shippingbox.fill" : "figure.walk")
                .font(.caption.weight(.bold))
                .foregroundStyle(Color.dsInk)

            if let address = item.deliveryAddress, item.isDelivery {
                Text(address)
                    .font(.caption)
                    .foregroundStyle(Color.dsMuted)
                    .lineLimit(1)
            }

            if item.availableFrom != nil || item.availableUntil != nil {
                Spacer()
                Label(pickupWindowLabel, systemImage: "clock.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.dsPrimary)
            }
        }
    }

    private var pickupWindowLabel: String {
        let formatter = ISO8601DateFormatter()
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "h:mm a"

        var parts: [String] = []
        if let from = item.availableFrom, let date = formatter.date(from: from) {
            parts.append(timeFormatter.string(from: date))
        }
        if let until = item.availableUntil, let date = formatter.date(from: until) {
            parts.append(timeFormatter.string(from: date))
        }
        guard !parts.isEmpty else { return "Anytime" }
        return parts.joined(separator: " – ")
    }

    @ViewBuilder
    private var statusRow: some View {
        HStack(spacing: .dsSpace2) {
            if item.isDraft {
                DogSwipeChip(text: "Draft", systemImage: "pencil.circle.fill", tint: Color.dsPrimarySoft)
                Spacer(minLength: .dsSpace1)
                claimButton
            } else if item.isClaimed {
                DogSwipeChip(text: "Claimed", systemImage: "checkmark.seal.fill", tint: Color.dsRelish.opacity(0.15))
                Spacer(minLength: .dsSpace1)
                confirmReadyButton
            } else if item.isReady {
                DogSwipeChip(text: "Ready", systemImage: "checkmark.circle.fill", tint: Color.dsRelish.opacity(0.15))
                Spacer(minLength: .dsSpace1)
                confirmHandoffButton
            } else if item.isHandedOff || item.isDelivered {
                DogSwipeChip(
                    text: item.isDelivered ? "Delivered" : "Handed Off",
                    systemImage: item.isDelivered ? "shippingbox.fill" : "hand.thumbsup.fill",
                    tint: Color.dsRelish.opacity(0.15)
                )
                handoffProgress
                Spacer(minLength: .dsSpace1)
                if !item.bothConfirmed {
                    confirmHandoffButton
                }
            } else if item.isCompleted {
                DogSwipeChip(text: "Completed", systemImage: "star.fill", tint: Color.dsRelish.opacity(0.22))
                Spacer(minLength: .dsSpace1)
            } else {
                DogSwipeChip(text: item.statusLabel, systemImage: "clock.fill", tint: Color.dsPrimarySoft)
                Spacer(minLength: .dsSpace1)
            }
        }
    }

    @ViewBuilder
    private var handoffProgress: some View {
        HStack(spacing: 4) {
            Image(systemName: item.makerHandoffConfirmedAt != nil ? "checkmark.circle.fill" : "circle")
                .font(.caption2)
                .foregroundStyle(item.makerHandoffConfirmedAt != nil ? Color.dsRelish : Color.dsMuted)
            Image(systemName: item.claimerHandoffConfirmedAt != nil ? "checkmark.circle.fill" : "circle")
                .font(.caption2)
                .foregroundStyle(item.claimerHandoffConfirmedAt != nil ? Color.dsRelish : Color.dsMuted)
        }
    }

    private var claimButton: some View {
        Button {
            onClaim?()
        } label: {
            HStack(spacing: .dsSpace1) {
                if isClaiming {
                    ProgressView()
                        .controlSize(.mini)
                        .tint(.white)
                } else {
                    Image(systemName: "creditcard.fill")
                        .font(.caption2)
                }
                Text(isClaiming ? "Claiming…" : "Claim · \(item.totalLabel)")
                    .font(.caption.weight(.bold))
            }
            .padding(.horizontal, .dsSpace3)
            .padding(.vertical, .dsSpace2)
            .foregroundStyle(.white)
            .background(Color.dsAccent, in: Capsule())
        }
        .buttonStyle(.plain)
        .disabled(isClaiming)
    }

    private var confirmReadyButton: some View {
        Button {
            onConfirmReady?()
        } label: {
            HStack(spacing: .dsSpace1) {
                if isConfirming {
                    ProgressView()
                        .controlSize(.mini)
                        .tint(.white)
                } else {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption2)
                }
                Text(isConfirming ? "Confirming…" : "Mark Ready")
                    .font(.caption.weight(.bold))
            }
            .padding(.horizontal, .dsSpace3)
            .padding(.vertical, .dsSpace2)
            .foregroundStyle(.white)
            .background(Color.dsPrimary, in: Capsule())
        }
        .buttonStyle(.plain)
        .disabled(isConfirming)
    }

    private var confirmHandoffButton: some View {
        Button {
            onConfirmHandoff?()
        } label: {
            HStack(spacing: .dsSpace1) {
                if isConfirming {
                    ProgressView()
                        .controlSize(.mini)
                        .tint(.white)
                } else {
                    Image(systemName: "hand.thumbsup.fill")
                        .font(.caption2)
                }
                Text(isConfirming ? "Confirming…" : "Confirm Hand-off")
                    .font(.caption.weight(.bold))
            }
            .padding(.horizontal, .dsSpace3)
            .padding(.vertical, .dsSpace2)
            .foregroundStyle(.white)
            .background(Color.dsRelish, in: Capsule())
        }
        .buttonStyle(.plain)
        .disabled(isConfirming)
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
