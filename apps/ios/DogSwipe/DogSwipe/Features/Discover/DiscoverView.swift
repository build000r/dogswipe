import DogSwipeCore
import SwiftUI

struct DiscoverView: View {
    @ObservedObject private var preferencesStore: CravingPreferencesStore
    @StateObject private var viewModel: DiscoverViewModel

    @MainActor
    init(
        preferencesStore: CravingPreferencesStore = CravingPreferencesStore(),
        viewModel: DiscoverViewModel? = nil
    ) {
        self.preferencesStore = preferencesStore
        _viewModel = StateObject(
            wrappedValue: viewModel ?? DiscoverViewModel(preferencesStore: preferencesStore)
        )
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: .dsSpace5) {
                header

                if case .loading = viewModel.state {
                    loadingState
                } else if let profile = viewModel.currentProfile {
                    HotdogCardView(profile: profile)
                        .transition(.scale.combined(with: .opacity))
                } else {
                    emptyState
                }

                controls
            }
            .padding(.horizontal, .dsSpace5)
            .padding(.vertical, .dsSpace4)
            .navigationTitle("DogSwipe")
            .toolbarTitleDisplayMode(.inline)
            .dsPageBackground()
            .task {
                if case .idle = viewModel.state {
                    await viewModel.load()
                }
            }
            .onChange(of: preferencesStore.preferences) {
                viewModel.applyPreferences()
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: .dsSpace2) {
            Text("Best nearby bite")
                .font(.title2.weight(.semibold))
                .foregroundStyle(Color.dsInk)

            Text(statusText)
                .font(.subheadline)
                .foregroundStyle(Color.dsMuted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var statusText: String {
        switch viewModel.state {
        case .idle, .loading:
            "Refreshing local hotdogs"
        case .ready:
            viewModel.isUsingCurrentLocation
                ? "\(viewModel.remainingCount) hotdogs near you"
                : "\(viewModel.remainingCount) hotdogs ready for review"
        case .failed:
            "Showing saved local picks"
        }
    }

    private var controls: some View {
        HStack(spacing: .dsSpace5) {
            SwipeActionButton(role: .pass) {
                advance(.pass)
            }
            SwipeActionButton(role: .superLike) {
                advance(.superLike)
            }
            SwipeActionButton(role: .like) {
                advance(.like)
            }
        }
        .frame(maxWidth: .infinity)
        .disabled(!viewModel.canSwipe)
        .opacity(viewModel.canSwipe ? 1 : 0.45)
    }

    private var loadingState: some View {
        VStack(spacing: .dsSpace3) {
            ProgressView()
                .tint(.dsPrimary)
            Text("Loading hotdogs")
                .font(.headline)
                .foregroundStyle(Color.dsInk)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .dsCardSurface()
    }

    private var emptyState: some View {
        VStack(spacing: .dsSpace3) {
            Image(systemName: "checkmark.seal.fill")
                .font(.largeTitle)
                .foregroundStyle(Color.dsPrimary)
            Text("You reviewed every hotdog")
                .font(.headline)
                .foregroundStyle(Color.dsInk)
            Button("Start over") {
                viewModel.resetToSamples()
            }
            .buttonStyle(.borderedProminent)
            .tint(.dsPrimary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .dsCardSurface()
    }

    private func advance(_ decision: SwipeDecision) {
        withAnimation(.spring(response: 0.28, dampingFraction: 0.86)) {
            viewModel.record(decision)
        }
    }
}

#Preview {
    DiscoverView()
}
