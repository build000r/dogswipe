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
                    ProgressView()
                        .tint(.dsPrimary)
                } else if viewModel.matches.isEmpty {
                    ContentUnavailableView("No saved bites yet", systemImage: "heart")
                } else {
                    List(viewModel.matches) { profile in
                        MatchRowView(
                            profile: profile,
                            originLocation: viewModel.currentLocation
                        )
                    }
                }
            }
            .navigationTitle("Matches")
            .accessibilityIdentifier("dogswipe.matches.screen")
            .task {
                if case .idle = viewModel.state {
                    await viewModel.load()
                }
            }
        }
    }
}

#Preview {
    MatchesView()
}

private struct MatchRowView: View {
    let profile: HotdogProfile
    let originLocation: DiscoveryLocation?

    @StateObject private var routePreviewStore = RoutePreviewStore()
    @Environment(\.openURL) private var openURL

    var body: some View {
        VStack(alignment: .leading, spacing: .dsSpace2) {
            HStack(spacing: .dsSpace3) {
                Image(systemName: "fork.knife.circle.fill")
                    .foregroundStyle(Color.dsPrimary)
                VStack(alignment: .leading, spacing: .dsSpace1) {
                    Text(profile.name)
                        .font(.headline)
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
        .padding(.vertical, .dsSpace2)
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
