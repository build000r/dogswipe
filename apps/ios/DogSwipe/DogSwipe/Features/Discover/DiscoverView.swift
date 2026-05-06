import DogSwipeCore
import SwiftUI

struct DiscoverView: View {
    @ObservedObject private var preferencesStore: CravingPreferencesStore
    @StateObject private var viewModel: DiscoverViewModel
    @State private var isSearchVisible = false

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
            VStack(spacing: .dsSpace3) {
                DogSwipeBrandHeader(activeTab: .discover)
                if isSearchVisible {
                    menuSearchBar
                        .transition(.move(edge: .top).combined(with: .opacity))
                }

                if case .loading = viewModel.state {
                    loadingState
                } else if let profile = viewModel.currentProfile {
                    deck(profile)
                } else {
                    emptyState
                }

                Text("Swipe right for dogs")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Color.dsMuted)
                controls
            }
            .padding(.horizontal, .dsSpace5)
            .padding(.top, .dsSpace2)
            .padding(.bottom, .dsSpace4)
            .toolbar(.hidden, for: .navigationBar)
            .dsPageBackground()
            .accessibilityIdentifier("dogswipe.discover.screen")
            .task {
                if case .idle = viewModel.state {
                    await viewModel.load()
                }
            }
            .onAppear {
                DogSwipeAnalytics.shared.trackScreenViewed(.discover)
            }
            .onChange(of: preferencesStore.preferences) {
                viewModel.applyPreferences()
            }
        }
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

    private var statusPill: some View {
        HStack(spacing: .dsSpace2) {
            Image(systemName: "location.fill")
                .foregroundStyle(Color.dsAccent)
            Text(statusText)
                .lineLimit(1)
                .minimumScaleFactor(0.82)
            Spacer(minLength: .dsSpace2)
            Text("Best nearby bite")
                .foregroundStyle(Color.dsInk)
        }
        .font(.caption.weight(.bold))
        .foregroundStyle(Color.dsMuted)
        .padding(.horizontal, .dsSpace3)
        .padding(.vertical, .dsSpace2)
        .background(Color.dsSurface, in: Capsule())
        .overlay {
            Capsule().stroke(Color.dsDivider)
        }
    }

    private var controls: some View {
        HStack(spacing: .dsSpace4) {
            SwipeActionButton(role: .rewind) {
                viewModel.resetToSamples()
            }
            SwipeActionButton(role: .pass) {
                advance(.pass)
            }
            SwipeActionButton(role: .superLike) {
                advance(.superLike)
            }
            SwipeActionButton(role: .like) {
                advance(.like)
            }
            SwipeActionButton(role: .filter) {
                withAnimation(.spring(response: 0.24, dampingFraction: 0.88)) {
                    isSearchVisible.toggle()
                }
            }
        }
        .frame(maxWidth: .infinity)
        .disabled(!viewModel.canSwipe)
        .opacity(viewModel.canSwipe ? 1 : 0.45)
    }

    private var menuSearchBar: some View {
        HStack(spacing: .dsSpace2) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(Color.dsMuted)
                .frame(width: .dsSpace6, height: .dsSpace6)

            TextField("Chili, mustard, snap", text: $viewModel.menuQuery)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .submitLabel(.search)
                .onSubmit {
                    Task {
                        await viewModel.searchMenu()
                    }
                }

            if viewModel.hasMenuQuery {
                Button {
                    Task {
                        await viewModel.clearMenuQuery()
                    }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .frame(width: .dsSpace8, height: .dsSpace8)
                }
                .buttonStyle(.plain)
                .foregroundStyle(Color.dsMuted)
                .accessibilityLabel("Clear menu search")
            }

            Button {
                Task {
                    await viewModel.searchMenu()
                }
            } label: {
                Image(systemName: "arrow.forward.circle.fill")
                    .frame(width: .dsSpace8, height: .dsSpace8)
            }
            .buttonStyle(.plain)
            .foregroundStyle(Color.dsPrimary)
            .accessibilityLabel("Search menu")
            .disabled(viewModel.state == .loading)
        }
        .font(.subheadline)
        .padding(.horizontal, .dsSpace3)
        .padding(.vertical, .dsSpace2)
        .background(Color.dsSurface, in: RoundedRectangle(cornerRadius: .dsRadius4, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: .dsRadius4, style: .continuous)
                .stroke(Color.dsDivider)
        }
        .shadow(color: Color.dsShadow.opacity(0.65), radius: 8, x: 0, y: 4)
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

    private func deck(_ profile: HotdogProfile) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: .dsRadius5, style: .continuous)
                .fill(Color.dsSurface.opacity(0.76))
                .overlay {
                    RoundedRectangle(cornerRadius: .dsRadius5, style: .continuous)
                        .stroke(Color.dsDivider)
                }
                .offset(x: .dsDeckBackOffsetX, y: .dsDeckBackOffsetY)
                .rotationEffect(.degrees(2.5))

            HotdogCardView(
                profile: profile,
                originLocation: viewModel.currentLocation
            )
            .rotationEffect(.degrees(-1.5))
            .transition(.scale.combined(with: .opacity))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .frame(height: .dsDiscoverDeckHeight)
    }

    private func advance(_ decision: SwipeDecision) {
        withAnimation(.spring(response: 0.28, dampingFraction: 0.86)) {
            if let profile = viewModel.record(decision) {
                DogSwipeAnalytics.shared.trackDiscoverySwipe(
                    decision: decision.rawValue,
                    profileID: profile.id
                )
            }
        }
    }
}

#Preview {
    DiscoverView()
}
