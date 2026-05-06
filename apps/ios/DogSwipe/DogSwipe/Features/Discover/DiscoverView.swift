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
                DogSwipeBrandHeader(activeTab: .discover, cartCount: orderStore.itemCount)
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
                commitSwipe(.pass, verticalLift: 12)
            }
            SwipeActionButton(role: .superLike) {
                commitSwipe(.superLike, verticalLift: -320)
            }
            SwipeActionButton(role: .like) {
                commitSwipe(.like, verticalLift: 12)
            }
            SwipeActionButton(role: .filter) {
                withAnimation(.spring(response: 0.24, dampingFraction: 0.88)) {
                    isSearchVisible.toggle()
                }
            }
        }
        .frame(maxWidth: .infinity)
        .disabled(!viewModel.canSwipe || isCommittingSwipe)
        .opacity(viewModel.canSwipe && !isCommittingSwipe ? 1 : 0.45)
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
        let swipeProgress = currentSwipeProgress
        let activeDecision = activeSwipeDecision

        return ZStack {
            RoundedRectangle(cornerRadius: .dsRadius5, style: .continuous)
                .fill(Color.dsSurface.opacity(0.76))
                .overlay {
                    RoundedRectangle(cornerRadius: .dsRadius5, style: .continuous)
                        .stroke(Color.dsDivider)
                }
                .scaleEffect(0.96 + (0.035 * swipeProgress))
                .offset(
                    x: .dsDeckBackOffsetX * (1 - (0.55 * swipeProgress)),
                    y: .dsDeckBackOffsetY * (1 - (0.70 * swipeProgress))
                )
                .rotationEffect(.degrees(2.5 - (1.8 * swipeProgress)))

            HotdogCardView(
                profile: profile,
                originLocation: viewModel.currentLocation
            )
            .id(profile.id)
            .overlay {
                SwipeFeedbackOverlay(decision: activeDecision, progress: swipeProgress)
            }
            .scaleEffect(1 - (0.035 * swipeProgress))
            .rotationEffect(.degrees(cardRotationDegrees))
            .offset(cardOffset)
            .shadow(
                color: feedbackColor(for: activeDecision).opacity(0.26 * swipeProgress),
                radius: 26 * swipeProgress,
                x: 0,
                y: 16 * swipeProgress
            )
            .contentShape(RoundedRectangle(cornerRadius: .dsRadius5, style: .continuous))
            .gesture(cardDragGesture)
            .transition(.asymmetric(
                insertion: .scale(scale: 0.96).combined(with: .opacity),
                removal: .opacity
            ))
            .accessibilityAction(named: "Like") {
                commitSwipe(.like, verticalLift: 12)
            }
            .accessibilityAction(named: "Pass") {
                commitSwipe(.pass, verticalLift: 12)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .frame(height: .dsDiscoverDeckHeight)
        .animation(.spring(response: 0.26, dampingFraction: 0.78), value: dragTranslation)
        .animation(.spring(response: 0.24, dampingFraction: 0.84), value: swipeExitOffset)
        .sensoryFeedback(.selection, trigger: feedbackTrigger)
    }

    private var cardDragGesture: some Gesture {
        DragGesture(minimumDistance: 4, coordinateSpace: .local)
            .onChanged { value in
                guard viewModel.canSwipe, !isCommittingSwipe else {
                    return
                }
                dragTranslation = value.translation
                updateArmedDecision(for: value.translation)
            }
            .onEnded { value in
                guard viewModel.canSwipe, !isCommittingSwipe else {
                    resetSwipeState()
                    return
                }
                if let decision = decision(for: value) {
                    commitSwipe(decision, verticalLift: value.predictedEndTranslation.height)
                } else {
                    withAnimation(.spring(response: 0.26, dampingFraction: 0.68)) {
                        resetSwipeState()
                    }
                }
            }
    }

    private var cardOffset: CGSize {
        CGSize(
            width: dragTranslation.width + swipeExitOffset.width,
            height: dragTranslation.height + swipeExitOffset.height
        )
    }

    private var cardRotationDegrees: Double {
        let width = cardOffset.width
        let verticalBias = min(1, max(-1, cardOffset.height / 520))
        return Double((width / 18) + (verticalBias * 2.5) - 1.5)
    }

    private var currentSwipeProgress: Double {
        min(1, abs(cardOffset.width) / .dsSwipeCommitThreshold)
    }

    private var activeSwipeDecision: SwipeDecision? {
        if let armedSwipeDecision {
            return armedSwipeDecision
        }
        if cardOffset.width > 18 {
            return .like
        }
        if cardOffset.width < -18 {
            return .pass
        }
        return nil
    }

    private func decision(for value: DragGesture.Value) -> SwipeDecision? {
        let projectedWidth = value.predictedEndTranslation.width
        let actualWidth = value.translation.width
        let verticalTravel = abs(value.translation.height)
        guard max(abs(projectedWidth), abs(actualWidth)) > .dsSwipeCommitThreshold,
              abs(actualWidth) > verticalTravel * 0.72 else {
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
            exitY = -620
        } else {
            exitY = min(180, max(-180, verticalLift * 0.35))
        }

        withAnimation(reduceMotion ? .easeOut(duration: 0.16) : .interpolatingSpring(stiffness: 220, damping: 24)) {
            swipeExitOffset = CGSize(width: horizontalDirection * 720, height: exitY)
        }

        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(reduceMotion ? 120 : 190))
            advance(decision)
            resetSwipeState()
        }
    }

    private func resetSwipeState() {
        dragTranslation = .zero
        swipeExitOffset = .zero
        isCommittingSwipe = false
        armedSwipeDecision = nil
    }

    private func feedbackColor(for decision: SwipeDecision?) -> Color {
        switch decision {
        case .like:
            .dsRelish
        case .pass:
            .dsAccent
        case .superLike:
            .dsPrimary
        case nil:
            .clear
        }
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

private struct SwipeFeedbackOverlay: View {
    let decision: SwipeDecision?
    let progress: Double

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    color.opacity(0.28 * progress),
                    color.opacity(0.06 * progress),
                    .clear
                ],
                startPoint: alignment == .leading ? .leading : .trailing,
                endPoint: alignment == .leading ? .trailing : .leading
            )
            .clipShape(RoundedRectangle(cornerRadius: .dsRadius5, style: .continuous))

            VStack {
                HStack {
                    if alignment == .trailing {
                        Spacer()
                    }
                    Label(labelText, systemImage: systemImage)
                        .font(.title2.weight(.heavy))
                        .foregroundStyle(color)
                        .padding(.horizontal, .dsSpace4)
                        .padding(.vertical, .dsSpace3)
                        .background(Color.dsSurface.opacity(0.92), in: Capsule())
                        .overlay {
                            Capsule().stroke(color.opacity(0.72), lineWidth: 2)
                        }
                        .rotationEffect(.degrees(alignment == .leading ? -10 : 10))
                        .scaleEffect(0.82 + (0.22 * progress))
                        .opacity(progress)
                        .accessibilityHidden(true)
                    if alignment == .leading {
                        Spacer()
                    }
                }
                Spacer()
            }
            .padding(.dsSpace5)
        }
        .allowsHitTesting(false)
        .opacity(decision == nil ? 0 : 1)
    }

    private var alignment: HorizontalAlignment {
        decision == .pass ? .trailing : .leading
    }

    private var labelText: String {
        switch decision {
        case .like:
            "YUM"
        case .pass:
            "NOPE"
        case .superLike:
            "HIT"
        case nil:
            ""
        }
    }

    private var systemImage: String {
        switch decision {
        case .like:
            "heart.fill"
        case .pass:
            "xmark"
        case .superLike:
            "fork.knife.circle.fill"
        case nil:
            "circle"
        }
    }

    private var color: Color {
        switch decision {
        case .like:
            .dsRelish
        case .pass:
            .dsAccent
        case .superLike:
            .dsPrimary
        case nil:
            .clear
        }
    }
}

private extension CGFloat {
    static let dsSwipeCommitThreshold: CGFloat = 126
}

#Preview {
    DiscoverView()
}
