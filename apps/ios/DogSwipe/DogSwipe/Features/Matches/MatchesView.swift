import DogSwipeCore
import SwiftUI

struct MatchesView: View {
    @ObservedObject private var orderStore: OrderStore
    @StateObject private var viewModel: MatchesViewModel
    private let onKeepSwiping: () -> Void

    @MainActor
    init(
        orderStore: OrderStore? = nil,
        preferencesStore: CravingPreferencesStore = CravingPreferencesStore(),
        viewModel: MatchesViewModel? = nil,
        onKeepSwiping: @escaping () -> Void = {}
    ) {
        self.orderStore = orderStore ?? OrderStore()
        self.onKeepSwiping = onKeepSwiping
        _viewModel = StateObject(
            wrappedValue: viewModel ?? MatchesViewModel(preferencesStore: preferencesStore)
        )
    }

    var body: some View {
        NavigationStack {
            Group {
                if case .loading = viewModel.state {
                    loadingState
                } else if viewModel.matches.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        VStack(spacing: .dsSpace4) {
                            MatchDetailView(
                                profile: viewModel.matches[0],
                                orderStore: orderStore,
                                onKeepSwiping: onKeepSwiping
                            )
                            Color.clear
                                .frame(height: .dsMatchSavedListTopClearance)
                            savedMatches
                        }
                        .padding(.horizontal, .dsSpace5)
                        .padding(.top, .dsSpace5)
                        .padding(.bottom, .dsSpace8)
                    }
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .dsPageBackground()
            .accessibilityIdentifier("dogswipe.matches.screen")
            .task {
                if case .idle = viewModel.state {
                    await viewModel.load()
                }
            }
            .onAppear {
                DogSwipeAnalytics.shared.trackScreenViewed(.matches)
            }
        }
    }

    private var loadingState: some View {
        VStack(spacing: .dsSpace4) {
            ProgressView()
                .tint(.dsPrimary)
            Text("Loading saved bites")
                .font(.headline)
                .foregroundStyle(Color.dsInk)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .dsPageBackground()
    }

    private var emptyState: some View {
        VStack(spacing: .dsSpace3) {
            DogSwipeBrandHeader(activeTab: .favorites, cartCount: orderStore.itemCount)
            VStack(spacing: .dsSpace3) {
                Image(systemName: "heart")
                    .font(.largeTitle)
                    .foregroundStyle(Color.dsAccent)
                Text("No saved bites yet")
                    .font(.title3.weight(.heavy))
                    .foregroundStyle(Color.dsInk)
                Text("Like a local hotdog from Discover and it lands here.")
                    .font(.subheadline)
                    .foregroundStyle(Color.dsMuted)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.dsSpace6)
            .dsCardSurface()
        }
        .padding(.dsSpace5)
        .dsPageBackground()
    }

    private var savedMatches: some View {
        VStack(alignment: .leading, spacing: .dsSpace3) {
            DogSwipeSectionHeader(
                title: "Saved hotdogs",
                subtitle: viewModel.isUsingCurrentLocation
                    ? "Ranked by your current walk."
                    : "Ready when the craving hits.",
                systemImage: "heart.fill"
            )

            ForEach(viewModel.matches.dropFirst()) { profile in
                MatchRowView(
                    profile: profile,
                    originLocation: viewModel.currentLocation
                )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    MatchesView()
}

private struct MatchDetailView: View {
    let profile: HotdogProfile
    @ObservedObject var orderStore: OrderStore
    let onKeepSwiping: () -> Void
    @State private var selectedAddOns: Set<OrderAddOn> = []
    @State private var confirmedItemID: String?
    @State private var isAddingOrder = false
    @State private var orderError: String?
    private let addOnColumns = [
        GridItem(.flexible(), spacing: .dsSpace2),
        GridItem(.flexible(), spacing: .dsSpace2)
    ]

    var body: some View {
        VStack(spacing: .dsSpace3) {
            VStack(spacing: .dsSpace1) {
                Text("It's a Match!")
                    .font(.system(size: .dsMatchTitleFontSize, weight: .heavy, design: .rounded))
                    .foregroundStyle(Color.dsInk)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.74)

                Text("\(profile.name) is all yours")
                    .font(.headline)
                    .foregroundStyle(Color.dsMuted)
            }

            HotdogIllustrationView(profile: profile)
                .frame(height: .dsMatchHeroHeight)
                .clipShape(RoundedRectangle(cornerRadius: .dsRadius5, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: .dsRadius5, style: .continuous)
                        .stroke(Color.dsDivider)
                }

            VStack(alignment: .leading, spacing: .dsSpace3) {
                HStack(alignment: .firstTextBaseline, spacing: .dsSpace3) {
                    Text(profile.name)
                        .font(.title2.weight(.heavy))
                        .foregroundStyle(Color.dsInk)
                        .minimumScaleFactor(0.76)
                    Spacer()
                    Text(profile.priceLabel)
                        .font(.title3.weight(.heavy).monospacedDigit())
                        .foregroundStyle(Color.dsAccent)
                }

                Text(profile.signatureNotes)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Color.dsMuted)
                    .fixedSize(horizontal: false, vertical: true)

                DogSwipeChipGrid {
                    DogSwipeChip(text: "Mild", systemImage: "flame")
                    DogSwipeChip(text: "All-Beef", systemImage: "fork.knife")
                    DogSwipeChip(text: "Crunchy", systemImage: "leaf.fill")
                    DogSwipeChip(text: "Popular", systemImage: "flame.fill")
                }

                VStack(alignment: .leading, spacing: .dsSpace3) {
                    Text("Make it yours")
                        .font(.headline.weight(.heavy))
                        .foregroundStyle(Color.dsInk)

                    LazyVGrid(columns: addOnColumns, alignment: .leading, spacing: .dsSpace2) {
                        ForEach(OrderAddOn.matchDefaults) { addOn in
                            addOnButton(addOn)
                        }
                    }
                }

                DogSwipePrimaryButton(
                    title: orderButtonTitle,
                    price: orderTotalLabel
                ) {
                    Task {
                        await addOrder()
                    }
                }
                .disabled(isAddingOrder)

                if let orderError {
                    Label(orderError, systemImage: "exclamationmark.triangle.fill")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Color.dsAccent)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .accessibilityIdentifier("dogswipe.order.error")
                }

                if let confirmationText {
                    Label(confirmationText, systemImage: "bag.fill")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Color.dsRelish)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .accessibilityIdentifier("dogswipe.order.confirmation")
                }

                Button("Keep Swiping") {
                    DogSwipeAnalytics.shared.trackMatchKeepSwiping(profileID: profile.id)
                    onKeepSwiping()
                }
                .font(.subheadline.weight(.bold))
                .foregroundStyle(Color.dsMuted)
                .frame(maxWidth: .infinity)
                .padding(.top, .dsSpace1)
            }
            .padding(.dsSpace4)
            .dsCardSurface()
        }
    }

    private var orderTotalLabel: String {
        OrderAddOn.priceLabel(
            for: selectedAddOns.reduce(profile.priceDollars) { total, addOn in
                total + addOn.priceDollars
            }
        )
    }

    private var orderButtonTitle: String {
        if isAddingOrder {
            return "Adding..."
        }
        return confirmedItemID == nil ? "Add to Order" : "Added to Order"
    }

    private var confirmationText: String? {
        guard let confirmedItemID,
              let item = orderStore.items.first(where: { $0.id == confirmedItemID }) else {
            return nil
        }
        return "Added to order: \(item.hotdogName) - \(item.totalLabel)"
    }

    private func addOnButton(_ addOn: OrderAddOn) -> some View {
        let isSelected = selectedAddOns.contains(addOn)

        return Button {
            if isSelected {
                selectedAddOns.remove(addOn)
            } else {
                selectedAddOns.insert(addOn)
            }
            confirmedItemID = nil
            orderError = nil
        } label: {
            VStack(spacing: .dsSpace1) {
                Text(addOn.name)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color.dsInk)
                    .lineLimit(1)
                Text("+ \(addOn.priceLabel)")
                    .font(.caption2.weight(.semibold).monospacedDigit())
                    .foregroundStyle(Color.dsMuted)
            }
            .frame(maxWidth: .infinity, minHeight: .dsMatchAddOnHeight)
            .background(isSelected ? Color.dsPrimarySoft : Color.dsSurface, in: Capsule())
            .overlay {
                Capsule().stroke(isSelected ? Color.dsPrimary : Color.dsDivider)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(addOn.name)
        .accessibilityValue(isSelected ? "Selected" : "Not selected")
    }

    private func addOrder() async {
        guard !isAddingOrder else {
            return
        }
        isAddingOrder = true
        defer {
            isAddingOrder = false
        }
        orderError = nil
        DogSwipeAnalytics.shared.trackOrderCTA(profileID: profile.id)
        let selected = OrderAddOn.matchDefaults.filter { selectedAddOns.contains($0) }
        do {
            let item = try await orderStore.add(profile: profile, addOns: selected)
            confirmedItemID = item.id
        } catch {
            orderError = "Could not save order. Try again."
        }
    }
}

private struct MatchRowView: View {
    let profile: HotdogProfile
    let originLocation: DiscoveryLocation?

    @StateObject private var routePreviewStore = RoutePreviewStore()
    @Environment(\.openURL) private var openURL

    var body: some View {
        VStack(alignment: .leading, spacing: .dsSpace2) {
            HStack(spacing: .dsSpace3) {
                HotdogIllustrationView(profile: profile)
                    .frame(width: .dsMatchThumbnailWidth, height: .dsMatchThumbnailHeight)
                    .clipShape(RoundedRectangle(cornerRadius: .dsRadius3, style: .continuous))
                VStack(alignment: .leading, spacing: .dsSpace1) {
                    Text(profile.name)
                        .font(.headline.weight(.heavy))
                    Text(profile.vendorName)
                        .font(.subheadline)
                        .foregroundStyle(Color.dsMuted)
                    Text("\(String(format: "%.1f mi", profile.distanceMiles)) • \(profile.walkingTimeLabel) walk")
                        .font(.caption)
                        .foregroundStyle(Color.dsMuted)
                }
                Spacer()
                Text(profile.priceLabel)
                    .font(.headline.monospacedDigit())
                    .foregroundStyle(Color.dsPrimary)
                routeButtons
            }
            RoutePreviewStatusView(state: routePreviewStore.state)
        }
        .padding(.dsSpace4)
        .dsCardSurface()
        .onChange(of: profile.id) {
            routePreviewStore.reset()
        }
    }

    @ViewBuilder
    private var routeButtons: some View {
        HStack(spacing: .dsSpace2) {
            if routePreviewStore.canPreview(profile: profile, origin: originLocation) {
                Button {
                    Task {
                        await routePreviewStore.preview(
                            profile: profile,
                            origin: originLocation
                        )
                    }
                } label: {
                    Image(systemName: "figure.walk")
                }
                .buttonStyle(.borderless)
                .tint(.dsPrimary)
                .disabled(routePreviewStore.state == .loading)
                .accessibilityLabel("Preview walk")
            }

            if let directionsURL = profile.directionsURL {
                Button {
                    openURL(directionsURL)
                } label: {
                    Image(systemName: "map")
                }
                .buttonStyle(.borderless)
                .tint(.dsPrimary)
                .accessibilityLabel("Directions")
            }
        }
    }
}
