import DogSwipeCore
import SwiftUI

/// Style descriptor for the YUM / NAH / MUST swipe stamp.
///
/// One enum collapses what used to be four parallel switches on
/// `SwipeDecision?` (alignment, label text, system image, color). The view
/// body switches on `SwipeOverlayStyle` exactly once via `style(for:)` and
/// reads the four facets from a single value, so adding a future decision
/// case (e.g. `.skip`) only adds one switch arm here, not four.
struct SwipeOverlayStyle: Equatable {
    let alignment: HorizontalAlignment
    let label: String
    let symbol: String
    let color: Color

    /// Returns `nil` when no decision is armed — the overlay then collapses
    /// to a fully-transparent shell while preserving layout.
    static func style(for decision: SwipeDecision?) -> SwipeOverlayStyle? {
        switch decision {
        case .like:
            SwipeOverlayStyle(
                alignment: .leading,
                label: "YUM",
                symbol: "heart.fill",
                color: .dsRelish
            )
        case .pass:
            SwipeOverlayStyle(
                alignment: .trailing,
                label: "NAH",
                symbol: "xmark",
                color: .dsAccent
            )
        case .superLike:
            SwipeOverlayStyle(
                alignment: .leading,
                label: "MUST",
                symbol: "star.fill",
                color: .dsSuper
            )
        case nil:
            nil
        }
    }
}

/// Stamp + gradient overlay that confirms the armed swipe decision while
/// the user drags. All numeric inputs route through DogSwipeMotion tokens.
struct SwipeFeedbackOverlay: View {
    let decision: SwipeDecision?
    let progress: Double

    var body: some View {
        ZStack {
            if let style = SwipeOverlayStyle.style(for: decision) {
                gradient(for: style)
                stamp(for: style)
            }
        }
        .allowsHitTesting(false)
        .opacity(decision == nil ? 0 : 1)
    }

    private func gradient(for style: SwipeOverlayStyle) -> some View {
        LinearGradient(
            colors: [
                style.color.opacity(DogSwipeOverlayOpacity.gradientLeading * progress),
                style.color.opacity(DogSwipeOverlayOpacity.gradientTrailing * progress),
                .clear
            ],
            startPoint: style.alignment == .leading ? .leading : .trailing,
            endPoint: style.alignment == .leading ? .trailing : .leading
        )
        .clipShape(RoundedRectangle(cornerRadius: .dsRadius5, style: .continuous))
    }

    private func stamp(for style: SwipeOverlayStyle) -> some View {
        VStack {
            HStack {
                if style.alignment == .trailing {
                    Spacer()
                }
                Label(style.label, systemImage: style.symbol)
                    .font(.title2.weight(.heavy))
                    .foregroundStyle(style.color)
                    .padding(.horizontal, .dsSpace4)
                    .padding(.vertical, .dsSpace3)
                    .background(
                        Color.dsSurface.opacity(DogSwipeOverlayOpacity.surfaceHeavy),
                        in: Capsule()
                    )
                    .overlay {
                        Capsule().stroke(
                            style.color.opacity(DogSwipeOverlayOpacity.stroke),
                            lineWidth: .dsSwipeOverlayStrokeWidth
                        )
                    }
                    .rotationEffect(.degrees(
                        style.alignment == .leading
                            ? -Double(CGFloat.dsSwipeOverlayRotation)
                            : Double(CGFloat.dsSwipeOverlayRotation)
                    ))
                    .scaleEffect(
                        CGFloat.dsSwipeOverlayBaseScale
                            + (CGFloat.dsSwipeOverlayProgressScale * CGFloat(progress))
                    )
                    .opacity(progress)
                    .accessibilityHidden(true)
                if style.alignment == .leading {
                    Spacer()
                }
            }
            Spacer()
        }
        .padding(.dsSpace5)
    }
}
