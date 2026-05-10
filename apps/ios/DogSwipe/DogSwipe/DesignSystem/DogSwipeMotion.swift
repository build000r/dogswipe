import SwiftUI

// MARK: - Swipe Pipeline Motion Tokens
//
// Every numeric in the Discover deck swipe gesture, the swipe-feedback
// overlay, and the HotdogCard hero overlays is hoisted here so view bodies
// stay declarative. Names are telegraphic: prefix maps to the surface
// (dsSwipe*, dsDeck*, dsCardOverlay*) and the suffix describes the role
// (Step / Base / Threshold / ExitX / ExitY / etc.).
//
// CGFloat tokens cover geometric / pixel measurements. Double tokens cover
// progress factors and animation timings. Opacities live inside the
// `DogSwipeOverlayOpacity` and `DogSwipeCardOpacity` namespaces so they are
// lookup-able from a single import surface.

extension CGFloat {
    // Deck back-card transform.
    /// Resting scale of the back card before swipe progress.
    static let dsSwipeScaleBase: CGFloat = 0.96
    /// Per-progress-unit scale delta applied to both the front and back card.
    static let dsSwipeScaleStep: CGFloat = 0.035
    /// Scale used by the card insertion transition.
    static let dsSwipeInsertionScale: CGFloat = 0.96

    // Deck back-card offset attenuation (multiplied against dsDeckBackOffset*).
    /// Back-card horizontal offset is reduced by this fraction at full progress.
    static let dsDeckBackOffsetXAttenuation: CGFloat = 0.55
    /// Back-card vertical offset is reduced by this fraction at full progress.
    static let dsDeckBackOffsetYAttenuation: CGFloat = 0.70

    // Front-card rotation math (cardRotationDegrees).
    /// Divisor applied to drag width to convert pixels into rotation degrees.
    static let dsSwipeRotationWidthDivisor: CGFloat = 18
    /// Divisor that clamps cardOffset.height before it influences rotation.
    static let dsSwipeVerticalDivisor: CGFloat = 520
    /// Vertical-bias contribution coefficient on the front card rotation.
    static let dsSwipeRotationVerticalCoefficient: CGFloat = 2.5
    /// Constant degree offset baked into the front card rotation.
    static let dsSwipeRotationBias: CGFloat = -1.5

    // Back-card rotation math (deck()).
    /// Resting rotation of the back card in degrees.
    static let dsSwipeRotationBase: CGFloat = 2.5
    /// Per-progress-unit rotation delta in degrees applied to the back card.
    static let dsSwipeRotationStep: CGFloat = 1.8

    // Activation / commit gating.
    /// Drag horizontal travel that commits a swipe and pegs progress to 1.
    static let dsSwipeCommitThreshold: CGFloat = 126
    /// Drag width past which a directional decision is "armed" visually.
    static let dsSwipeArmThreshold: CGFloat = 18
    /// Drag minimum distance before the gesture engages.
    static let dsSwipeDragMinimumDistance: CGFloat = 4
    /// Required ratio of horizontal-vs-vertical travel to qualify as a swipe.
    static let dsSwipeHorizontalDominanceRatio: CGFloat = 0.72

    // Exit trajectory.
    /// Horizontal exit translation when a swipe commits.
    static let dsSwipeExitX: CGFloat = 720
    /// Vertical exit translation for the super-like (negative = upward).
    static let dsSwipeSuperLikeExitY: CGFloat = -620
    /// Multiplier on predicted vertical lift before clamping.
    static let dsSwipeExitYLiftMultiplier: CGFloat = 0.35
    /// Maximum absolute vertical exit (used to clamp lift).
    static let dsSwipeExitYClamp: CGFloat = 180
    /// Default vertical lift used by tap-driven swipe controls.
    static let dsSwipeButtonVerticalLift: CGFloat = 12
    /// Vertical lift used by the super-like control button.
    static let dsSwipeSuperLikeButtonLift: CGFloat = -320

    // Front-card committed-swipe shadow.
    /// Shadow radius scaled by progress for the committed front card.
    static let dsSwipeShadowRadius: CGFloat = 26
    /// Shadow Y offset scaled by progress for the committed front card.
    static let dsSwipeShadowOffsetY: CGFloat = 16

    // Feedback overlay (SwipeFeedbackOverlay).
    /// Stamp rotation magnitude in degrees (sign flips per side).
    static let dsSwipeOverlayRotation: CGFloat = 10
    /// Resting scale of the YUM/NAH/MUST stamp.
    static let dsSwipeOverlayBaseScale: CGFloat = 0.82
    /// Per-progress scale delta applied to the stamp.
    static let dsSwipeOverlayProgressScale: CGFloat = 0.22
    /// Stamp capsule stroke width.
    static let dsSwipeOverlayStrokeWidth: CGFloat = 2
}

extension Double {
    // Spring + animation timings.
    static let dsSwipeDragSpringResponse: Double = 0.26
    static let dsSwipeDragSpringDamping: Double = 0.78
    static let dsSwipeExitSpringResponse: Double = 0.24
    static let dsSwipeExitSpringDamping: Double = 0.84
    static let dsSwipeRecoilSpringResponse: Double = 0.26
    static let dsSwipeRecoilSpringDamping: Double = 0.68
    static let dsSwipeAdvanceSpringResponse: Double = 0.28
    static let dsSwipeAdvanceSpringDamping: Double = 0.86
    static let dsSwipeCommitSpringStiffness: Double = 220
    static let dsSwipeCommitSpringDamping: Double = 24
    static let dsSwipeReduceMotionDuration: Double = 0.16

    // Header / search bar spring (DogSwipeIconButton + search toggle).
    static let dsHeaderSpringResponse: Double = 0.24
    static let dsHeaderSpringDamping: Double = 0.88

    // Commit -> advance hand-off delays.
    static let dsSwipeCommitSleepMs: Double = 190
    static let dsSwipeReduceMotionCommitSleepMs: Double = 120

    // Front-card progress effects.
    static let dsSwipeShadowOpacity: Double = 0.26
}

// MARK: - Overlay Opacity Tokens
//
// The swipe-feedback overlay uses a fast pile of alpha levels; expose them as
// a namespaced enum so the grammar is "DogSwipeOverlayOpacity.heavy" rather
// than a bare 0.92 in a view.

enum DogSwipeOverlayOpacity {
    /// Stamp pill background — almost opaque but lets surface tint bleed.
    static let surfaceHeavy: Double = 0.92
    /// Stamp capsule stroke alpha.
    static let stroke: Double = 0.72
    /// Top stop of the swipe gradient (multiplied by progress).
    static let gradientLeading: Double = 0.28
    /// Mid stop of the swipe gradient (multiplied by progress).
    static let gradientTrailing: Double = 0.06
}

// MARK: - Card Surface Opacity Tokens
//
// HotdogCardView and the deck back-plate scatter `.opacity(0.x)` literals
// across hero overlays, gradients, and stamp pills. Hoisting them prevents
// per-card drift.

enum DogSwipeCardOpacity {
    /// Back-card resting fill alpha (deck back plate).
    static let deckBack: Double = 0.76
    /// Hero status pill / inline stamp surface alpha.
    static let heroPill: Double = 0.88
    /// Inline stamp pill background and signature note copy alpha.
    static let heroBody: Double = 0.92
    /// Hero footer drop-shadow alpha.
    static let heroShadow: Double = 0.32
    /// Hero gradient mid stop alpha.
    static let heroGradientMid: Double = 0.32
    /// Hero gradient bottom stop alpha.
    static let heroGradientBottom: Double = 0.62
    /// Menu search bar shadow alpha multiplier on Color.dsShadow.
    static let menuSearchShadow: Double = 0.65
}
