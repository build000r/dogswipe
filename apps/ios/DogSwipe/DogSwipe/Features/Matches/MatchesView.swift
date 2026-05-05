import DogSwipeCore
import SwiftUI

struct MatchesView: View {
    @StateObject private var viewModel: MatchesViewModel
    @Environment(\.openURL) private var openURL

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
                        .padding(.vertical, .dsSpace2)
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
