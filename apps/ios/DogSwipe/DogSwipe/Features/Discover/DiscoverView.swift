import DogSwipeCore
import SwiftUI

struct DiscoverView: View {
    @ObservedObject private var orderStore: OrderStore
    @ObservedObject private var preferencesStore: CravingPreferencesStore
    @StateObject private var viewModel: DiscoverViewModel
    @State private var isSearchVisible = false
    @State private var dragTranslation: CGSize = .zero
    @State private var swipeExitOffset: CGSize = .zero
    @State private var isCommittingSwipe = false
    @State private var armedSwipeDecision: SwipeDecision?
    @State private var feedbackTrigger = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.openURL) private var openURL

    @MainActor
    init(
        orderStore: OrderStore? = nil,
        preferencesStore: CravingPreferencesStore = CravingPreferencesStore(),
        viewModel: DiscoverViewModel? = nil
    ) {
        self.orderStore = orderStore ?? OrderStore()
        self.preferencesStore = preferencesStore
        _viewModel = StateObject(
            wrappedValue: viewModel ?? DiscoverViewModel(preferencesStore: preferencesStore)
        )
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: .dsSpace3) {
                DogSwipeScreenHeader(title: "Tonight's craving", kicker: statusText) {
                    HStack(spacing: .dsSpace2) {
                        DogSwipeIconButton(
                            systemImage: "magnifyingglass",
                            accessibilityLabel: "Search menus"
                        ) {
                            withAnimation(.spring(
                                response: .dsHeaderSpringResponse,
                                dampingFraction: .dsHeaderSpringDamping
                            )) {
                                isSearchVisible.toggle()
                            }
                        }

                        DogSwipeIconButton(
                            systemImage: "arrow.counterclockwise",
                            accessibilityLabel: "Restart deck",
                            isDisabled: !viewModel.canRestartDeck || isCommittingSwipe
                        ) {
                            viewModel.resetToSamples()
                        }
                    }
                }

                if isSearchVisible {
                    menuSearchBar
                        .transition(.move(edge: .top).combined(with: .opacity))
                }

                if viewModel.availableCategories.count > 1 {
                    categoryFilter
                }

                if case .loading = viewModel.state {
                    loadingState
                } else if let profile = viewModel.currentProfile {
                    deck(profile)
                } else {
                    emptyState
                }

                if viewModel.canSwipe {
                    Text("Swipe right for hotdogs")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(Color.dsMuted)
                    controls
                }
            }
            .padding(.horizontal, .dsSpace5)
            .padding(.top, .dsSpace2)
            .padding(.bottom, .dsSpace4)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
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
            if viewModel.hasReviewedEveryHotdog {
                "All hotdogs reviewed"
            } else if viewModel.remainingCount == 0 {
                "No hotdogs ready"
            } else if viewModel.isUsingCurrentLocation {
                "\(viewModel.remainingCount) hotdogs near you"
            } else {
                "\(viewModel.remainingCount) hotdogs ready for review"
            }
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
                .minimumScaleFactor(0.8)
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
                commitSwipe(.pass, verticalLift: .dsSwipeButtonVerticalLift)
            }
            SwipeActionButton(role: .superLike) {
                commitSwipe(.superLike, verticalLift: .dsSwipeSuperLikeButtonLift)
            }
            SwipeActionButton(role: .like) {
                commitSwipe(.like, verticalLift: .dsSwipeButtonVerticalLift)
            }
            SwipeActionButton(role: .filter) {
                withAnimation(.spring(
                    response: .dsHeaderSpringResponse,
                    dampingFraction: .dsHeaderSpringDamping
                )) {
                    isSearchVisible.toggle()
                }
            }
        }
        .frame(maxWidth: .infinity)
        .disabled(!viewModel.canSwipe || isCommittingSwipe)
        .opacity(viewModel.canSwipe && !isCommittingSwipe ? 1 : 0.45)
    }

    private var categoryFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: .dsSpace2) {
                categoryPill("All", isSelected: viewModel.selectedCategory == nil) {
                    viewModel.selectCategory(nil)
                }
                ForEach(viewModel.availableCategories, id: \.self) { category in
                    categoryPill(
                        category.prefix(1).uppercased() + category.dropFirst(),
                        isSelected: viewModel.selectedCategory == category
                    ) {
                        viewModel.selectCategory(category)
                    }
                }
            }
        }
    }

    private func categoryPill(_ label: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.caption.weight(.bold))
                .foregroundStyle(isSelected ? Color.dsSurface : Color.dsInk)
                .padding(.horizontal, .dsSpace3)
                .padding(.vertical, .dsSpace2)
                .background(isSelected ? Color.dsPrimary : Color.dsSurface, in: Capsule())
                .overlay { Capsule().stroke(isSelected ? Color.clear : Color.dsDivider) }
        }
        .buttonStyle(.plain)
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
        .shadow(
            color: Color.dsShadow.opacity(DogSwipeCardOpacity.menuSearchShadow),
            radius: 8,
            x: 0,
            y: 4
        )
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
            Image(systemName: emptyStateIconName)
                .font(.largeTitle)
                .foregroundStyle(Color.dsPrimary)
            Text(emptyStateTitle)
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

    private var emptyStateIconName: String {
        viewModel.hasReviewedEveryHotdog ? "checkmark.seal.fill" : "magnifyingglass.circle.fill"
    }

    private var emptyStateTitle: String {
        viewModel.hasReviewedEveryHotdog ? "You reviewed every hotdog" : "No hotdogs ready"
    }

    private func deck(_ profile: HotdogProfile) -> some View {
        DiscoverDeckCard(
            profile: profile,
            originLocation: viewModel.currentLocation,
            dragTranslation: dragTranslation,
            swipeExitOffset: swipeExitOffset,
            progress: currentSwipeProgress,
            activeDecision: activeSwipeDecision,
            onDragChanged: handleDragChanged,
            onDragEnded: handleDragEnded,
            onLikeAction: { commitSwipe(.like, verticalLift: .dsSwipeButtonVerticalLift) },
            onPassAction: { commitSwipe(.pass, verticalLift: .dsSwipeButtonVerticalLift) }
        )
        .animation(.spring(response: .dsSwipeDragSpringResponse, dampingFraction: .dsSwipeDragSpringDamping), value: dragTranslation)
        .animation(.spring(response: .dsSwipeExitSpringResponse, dampingFraction: .dsSwipeExitSpringDamping), value: swipeExitOffset)
        .sensoryFeedback(.selection, trigger: feedbackTrigger)
    }

    private func handleDragChanged(_ value: DragGesture.Value) {
        guard viewModel.canSwipe, !isCommittingSwipe else {
            return
        }
        dragTranslation = value.translation
        updateArmedDecision(for: value.translation)
    }

    private func handleDragEnded(_ value: DragGesture.Value) {
        guard viewModel.canSwipe, !isCommittingSwipe else {
            resetSwipeState()
            return
        }
        if let decision = decision(for: value) {
            commitSwipe(decision, verticalLift: value.predictedEndTranslation.height)
        } else {
            withAnimation(.spring(
                response: .dsSwipeRecoilSpringResponse,
                dampingFraction: .dsSwipeRecoilSpringDamping
            )) {
                resetSwipeState()
            }
        }
    }

    private var cardOffset: CGSize {
        CGSize(
            width: dragTranslation.width + swipeExitOffset.width,
            height: dragTranslation.height + swipeExitOffset.height
        )
    }

    private var currentSwipeProgress: Double {
        min(1, abs(cardOffset.width) / .dsSwipeCommitThreshold)
    }

    private var activeSwipeDecision: SwipeDecision? {
        if let armedSwipeDecision {
            return armedSwipeDecision
        }
        if cardOffset.width > .dsSwipeArmThreshold {
            return .like
        }
        if cardOffset.width < -.dsSwipeArmThreshold {
            return .pass
        }
        return nil
    }

    private func decision(for value: DragGesture.Value) -> SwipeDecision? {
        let projectedWidth = value.predictedEndTranslation.width
        let actualWidth = value.translation.width
        let verticalTravel = abs(value.translation.height)
        guard max(abs(projectedWidth), abs(actualWidth)) > .dsSwipeCommitThreshold,
              abs(actualWidth) > verticalTravel * .dsSwipeHorizontalDominanceRatio else {
            return nil
        }
        return projectedWidth >= 0 ? .like : .pass
    }

    private func updateArmedDecision(for translation: CGSize) {
        let decision: SwipeDecision?
        if translation.width > .dsSwipeCommitThreshold {
            decision = .like
        } else if translation.width < -.dsSwipeCommitThreshold {
            decision = .pass
        } else {
            decision = nil
        }

        guard decision != armedSwipeDecision else {
            return
        }
        armedSwipeDecision = decision
        if decision != nil {
            feedbackTrigger += 1
        }
    }

    private func commitSwipe(_ decision: SwipeDecision, verticalLift: CGFloat) {
        guard viewModel.canSwipe, !isCommittingSwipe else {
            return
        }

        let profileSnapshot = viewModel.currentProfile

        isCommittingSwipe = true
        armedSwipeDecision = decision
        feedbackTrigger += 1

        let horizontalDirection: CGFloat
        switch decision {
        case .like, .superLike:
            horizontalDirection = 1
        case .pass:
            horizontalDirection = -1
        }

        let exitY: CGFloat
        if decision == .superLike {
            exitY = .dsSwipeSuperLikeExitY
        } else {
            exitY = min(
                .dsSwipeExitYClamp,
                max(-.dsSwipeExitYClamp, verticalLift * .dsSwipeExitYLiftMultiplier)
            )
        }

        let commitAnimation: Animation = reduceMotion
            ? .easeOut(duration: .dsSwipeReduceMotionDuration)
            : .interpolatingSpring(
                stiffness: .dsSwipeCommitSpringStiffness,
                damping: .dsSwipeCommitSpringDamping
            )
        withAnimation(commitAnimation) {
            swipeExitOffset = CGSize(
                width: horizontalDirection * .dsSwipeExitX,
                height: exitY
            )
        }

        Task { @MainActor in
            let sleepMs = reduceMotion
                ? Double.dsSwipeReduceMotionCommitSleepMs
                : Double.dsSwipeCommitSleepMs
            try? await Task.sleep(for: .milliseconds(sleepMs))
            advance(decision)
            resetSwipeState()

            if decision == .superLike, let profile = profileSnapshot {
                handleGoGetItNow(profile)
            }
        }
    }

    private func handleGoGetItNow(_ profile: HotdogProfile) {
        DogSwipeAnalytics.shared.trackOrderCTA(profileID: profile.id)
        Task {
            try? await orderStore.add(profile: profile, addOns: [])
        }
        if let url = profile.directionsURL {
            openURL(url)
        }
    }

    private func resetSwipeState() {
        dragTranslation = .zero
        swipeExitOffset = .zero
        isCommittingSwipe = false
        armedSwipeDecision = nil
    }

    private func advance(_ decision: SwipeDecision) {
        withAnimation(.spring(
            response: .dsSwipeAdvanceSpringResponse,
            dampingFraction: .dsSwipeAdvanceSpringDamping
        )) {
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
