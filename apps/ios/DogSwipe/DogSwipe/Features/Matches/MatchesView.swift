import DogSwipeCore
import SwiftUI

struct MatchesView: View {
    @StateObject private var viewModel: MatchesViewModel

    @MainActor
    init(
        preferencesStore: CravingPreferencesStore = CravingPreferencesStore(),
        viewModel: MatchesViewModel? = nil
    ) {
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
                            MatchDetailView(profile: viewModel.matches[0])
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
        VStack(spacing: .dsSpace3) {
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
        VStack(spacing: .dsSpace4) {
            DogSwipeBrandHeader(activeTab: .favorites)
            VStack(spacing: .dsSpace3) {
                Image(systemName: "heart")
                    .font(.largeTitle)
                    .foregroundStyle(Color.dsAccent)
                Text("No saved bites yet")
                    .font(.title3.weight(.heavy))
                    .foregroundStyle(Color.dsInk)
                Text("Like a local dog from Discover and it lands here.")
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
                title: "Saved dogs",
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

    var body: some View {
        VStack(spacing: .dsSpace4) {
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

            VStack(alignment: .leading, spacing: .dsSpace4) {
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

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: .dsSpace2) {
                        DogSwipeChip(text: "Mild", systemImage: "flame")
                        DogSwipeChip(text: "All-Beef", systemImage: "fork.knife")
                        DogSwipeChip(text: "Crunchy", systemImage: "leaf.fill")
                        DogSwipeChip(text: "Popular", systemImage: "flame.fill")
                    }
                }

                VStack(alignment: .leading, spacing: .dsSpace3) {
                    Text("Make it yours")
                        .font(.headline.weight(.heavy))
                        .foregroundStyle(Color.dsInk)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: .dsSpace3) {
                            addOn("Bacon", price: "+ $1.00")
                            addOn("Jalapenos", price: "+ $0.75")
                            addOn("Cheese Sauce", price: "+ $1.25")
                            addOn("Extra Pickle", price: "+ $0.50")
                        }
                    }
                }

                DogSwipePrimaryButton(title: "Add to Order", price: profile.priceLabel) {
                    DogSwipeAnalytics.shared.trackOrderCTA(profileID: profile.id)
                }

                Button("Keep Swiping") {
                    DogSwipeAnalytics.shared.trackMatchKeepSwiping(profileID: profile.id)
                }
                .font(.subheadline.weight(.bold))
                .foregroundStyle(Color.dsMuted)
                .frame(maxWidth: .infinity)
                .padding(.top, .dsSpace1)
            }
            .padding(.dsSpace5)
            .dsCardSurface()
        }
    }

    private func addOn(_ title: String, price: String) -> some View {
        VStack(spacing: .dsSpace1) {
            Text(title)
                .font(.caption.weight(.bold))
                .foregroundStyle(Color.dsInk)
                .lineLimit(1)
            Text(price)
                .font(.caption2.weight(.semibold).monospacedDigit())
                .foregroundStyle(Color.dsMuted)
        }
        .frame(width: .dsMatchAddOnWidth, height: .dsMatchAddOnHeight)
        .background(Color.dsSurface, in: Capsule())
        .overlay {
            Capsule().stroke(Color.dsDivider)
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
