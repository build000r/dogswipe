import DogSwipeCore
import SwiftUI

/// Renders one deck slot: the back-card placeholder behind the active
/// `HotdogCardView`, plus the swipe-feedback overlay, drag transform,
/// shadow, and accessibility actions for the front card.
///
/// All transform numerics route through `DogSwipeMotion` tokens. The host
/// (`DiscoverView`) owns gesture state; this view consumes the derived
/// `dragTranslation`, `swipeExitOffset`, and `progress` values and exposes
/// `onDragChanged` / `onDragEnded` callbacks to the parent.
struct DiscoverDeckCard: View {
    let profile: HotdogProfile
    let originLocation: DiscoveryLocation?
    let dragTranslation: CGSize
    let swipeExitOffset: CGSize
    let progress: Double
    let activeDecision: SwipeDecision?
    let onDragChanged: (DragGesture.Value) -> Void
    let onDragEnded: (DragGesture.Value) -> Void
    let onLikeAction: () -> Void
    let onPassAction: () -> Void

    var body: some View {
        ZStack {
            backCard
            frontCard
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Card layers

    private var backCard: some View {
        RoundedRectangle(cornerRadius: .dsRadius5, style: .continuous)
            .fill(Color.dsSurface.opacity(DogSwipeCardOpacity.deckBack))
            .overlay {
                RoundedRectangle(cornerRadius: .dsRadius5, style: .continuous)
                    .stroke(Color.dsDivider)
            }
            .scaleEffect(
                CGFloat.dsSwipeScaleBase + (CGFloat.dsSwipeScaleStep * CGFloat(progress))
            )
            .offset(
                x: .dsDeckBackOffsetX
                    * (1 - (CGFloat.dsDeckBackOffsetXAttenuation * CGFloat(progress))),
                y: .dsDeckBackOffsetY
                    * (1 - (CGFloat.dsDeckBackOffsetYAttenuation * CGFloat(progress)))
            )
            .rotationEffect(.degrees(
                Double(CGFloat.dsSwipeRotationBase)
                    - (Double(CGFloat.dsSwipeRotationStep) * progress)
            ))
    }

    private var frontCard: some View {
        HotdogCardView(
            profile: profile,
            originLocation: originLocation
        )
        .id(profile.id)
        .overlay {
            SwipeFeedbackOverlay(decision: activeDecision, progress: progress)
        }
        .scaleEffect(1 - (CGFloat.dsSwipeScaleStep * CGFloat(progress)))
        .rotationEffect(.degrees(cardRotationDegrees))
        .offset(cardOffset)
        .shadow(
            color: shadowColor.opacity(Double.dsSwipeShadowOpacity * progress),
            radius: CGFloat.dsSwipeShadowRadius * CGFloat(progress),
            x: 0,
            y: CGFloat.dsSwipeShadowOffsetY * CGFloat(progress)
        )
        .contentShape(RoundedRectangle(cornerRadius: .dsRadius5, style: .continuous))
        .gesture(
            DragGesture(
                minimumDistance: .dsSwipeDragMinimumDistance,
                coordinateSpace: .local
            )
            .onChanged(onDragChanged)
            .onEnded(onDragEnded)
        )
        .transition(.asymmetric(
            insertion: .scale(scale: .dsSwipeInsertionScale).combined(with: .opacity),
            removal: .opacity
        ))
        .accessibilityAction(named: "Like", onLikeAction)
        .accessibilityAction(named: "Pass", onPassAction)
    }

    // MARK: - Derived geometry

    private var cardOffset: CGSize {
        CGSize(
            width: dragTranslation.width + swipeExitOffset.width,
            height: dragTranslation.height + swipeExitOffset.height
        )
    }

    private var cardRotationDegrees: Double {
        let width = cardOffset.width
        let verticalBias = min(1, max(-1, cardOffset.height / .dsSwipeVerticalDivisor))
        return Double(
            (width / .dsSwipeRotationWidthDivisor)
                + (verticalBias * .dsSwipeRotationVerticalCoefficient)
                + .dsSwipeRotationBias
        )
    }

    private var shadowColor: Color {
        switch activeDecision {
        case .like:
            .dsRelish
        case .pass:
            .dsAccent
        case .superLike:
            .dsSuper
        case nil:
            .clear
        }
    }
}
