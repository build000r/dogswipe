import CoreGraphics
import Foundation

/// Named proportional multipliers and counts that define the cartoon hotdog
/// rendered in `HotdogIllustrationView`. Hoisting these out of the view keeps
/// the SwiftUI body declarative and makes every coefficient readable as a
/// configuration value rather than a bare magic number.
///
/// Visual output is meant to remain byte-for-byte identical to the previous
/// inline literals — names are the only change.
enum HotdogIllustrationGeometry {
    // MARK: - Frame composition

    /// Vertical nudge applied to the entire hotdog stack relative to its
    /// container, expressed as a fraction of container height.
    static let stackOffsetYRatio: CGFloat = 0.02

    // MARK: - Dog (overall) sizing

    /// Hotdog bun width as a fraction of the container width.
    static let dogWidthRatio: CGFloat = 0.92

    /// Hotdog bun height as a fraction of the container height (before cap).
    static let dogHeightRatio: CGFloat = 0.64

    /// Maximum hotdog height in points regardless of container size.
    static let dogHeightCap: CGFloat = 220

    // MARK: - Plate / shadow under the bun

    /// Plate shadow width as a fraction of dog width.
    static let plateWidthRatio: CGFloat = 0.94

    /// Plate shadow height as a fraction of dog height.
    static let plateHeightRatio: CGFloat = 0.58

    /// Plate shadow vertical offset as a fraction of dog height.
    static let plateOffsetYRatio: CGFloat = 0.22

    /// Gaussian blur radius applied to the plate shadow.
    static let plateBlurRadius: CGFloat = 6

    // MARK: - Bun

    /// Bun height as a fraction of dog height.
    static let bunHeightRatio: CGFloat = 0.72

    /// Bun vertical offset as a fraction of dog height.
    static let bunOffsetYRatio: CGFloat = 0.16

    // MARK: - Inner highlight (cream layer between bun and frank)

    /// Highlight surface alpha.
    static let highlightOpacity: CGFloat = 0.92

    /// Highlight width as a fraction of dog width.
    static let highlightWidthRatio: CGFloat = 0.84

    /// Highlight height as a fraction of dog height.
    static let highlightHeightRatio: CGFloat = 0.48

    /// Highlight vertical offset as a fraction of dog height
    /// (negative because it sits above the bun centerline).
    static let highlightOffsetYRatio: CGFloat = -0.04

    // MARK: - Frank (sausage)

    /// Frank gradient trailing-side alpha.
    static let frankTrailOpacity: CGFloat = 0.82

    /// Frank width as a fraction of dog width.
    static let frankWidthRatio: CGFloat = 0.74

    /// Frank height as a fraction of dog height.
    static let frankHeightRatio: CGFloat = 0.34

    /// Frank vertical offset as a fraction of dog height (negative = up).
    static let frankOffsetYRatio: CGFloat = -0.06

    // MARK: - Pickle strip

    /// Pickle width as a fraction of dog width.
    static let pickleWidthRatio: CGFloat = 0.58

    /// Pickle height as a fraction of dog height.
    static let pickleHeightRatio: CGFloat = 0.18

    /// Pickle horizontal offset as a fraction of dog width.
    static let pickleOffsetXRatio: CGFloat = 0.08

    /// Pickle vertical offset as a fraction of dog height (negative = up).
    static let pickleOffsetYRatio: CGFloat = -0.18

    /// Pickle stroke alpha.
    static let pickleStrokeOpacity: CGFloat = 0.52

    /// Pickle outline stroke width in points.
    static let pickleStrokeLineWidth: CGFloat = 2

    // MARK: - Mustard squiggle

    /// Mustard squiggle width as a fraction of dog width.
    static let mustardWidthRatio: CGFloat = 0.68

    /// Mustard squiggle height as a fraction of dog height.
    static let mustardHeightRatio: CGFloat = 0.24

    /// Mustard squiggle vertical offset as a fraction of dog height
    /// (negative = up).
    static let mustardOffsetYRatio: CGFloat = -0.13

    /// Stroke width for the mustard squiggle. Intentionally heavier than
    /// `.dsHotdogToppingLineWidth` (which is 5) because the squiggle is a
    /// visual focal point, not a topping accent — the hotdog reads as
    /// under-mustarded otherwise. See WG-D02 for justification.
    static let mustardLineWidth: CGFloat = 7

    /// Number of bezier segments used to draw the mustard squiggle.
    static let mustardSegmentCount: Int = 5

    /// First bezier control point x-position as a fraction of segment width.
    static let mustardFirstControlXRatio: CGFloat = 0.35

    /// Second bezier control point x-position as a fraction of segment width.
    static let mustardSecondControlXRatio: CGFloat = 0.65

    /// Modulus used to alternate mustard control points above and below the
    /// centerline.
    static let mustardWavePhaseModulus: Int = 2

    // MARK: - Topping scatter

    /// Number of topping flakes drawn over the frank.
    static let toppingScatterCount: Int = 16

    /// Corner radius applied to each topping flake.
    static let toppingCornerRadius: CGFloat = 2

    /// Topping height as a fraction of its width (gives flakes a flatter,
    /// confetti-like silhouette).
    static let toppingHeightRatio: CGFloat = 0.82

    /// Base topping size in points before per-index variation is applied.
    static let toppingBaseSize: CGFloat = 8

    /// Step in points added per `index % toppingSizeVariantModulus`.
    static let toppingSizeStep: CGFloat = 3

    /// Modulus controlling topping size variation across the scatter.
    static let toppingSizeVariantModulus: Int = 3

    /// Modulus controlling the per-flake rotation cycle.
    static let toppingRotationModulus: Int = 5

    /// Multiplier (in degrees) on the rotation index — final rotation is
    /// `Double((index % toppingRotationModulus) * toppingRotationStep)` degrees.
    static let toppingRotationStep: Int = 11

    /// Horizontal offsets (as a fraction of dog width) sampled column by column
    /// across the scatter using `index % toppingColumnOffsets.count`.
    static let toppingColumnOffsets: [CGFloat] = [
        -0.28, -0.18, -0.07, 0.04, 0.15, 0.26, 0.34, -0.34
    ]

    /// Vertical offsets (as a fraction of dog height) sampled row by row across
    /// the scatter using `(index / 2) % toppingRowOffsets.count`.
    static let toppingRowOffsets: [CGFloat] = [
        -0.19, -0.13, -0.07, -0.01, 0.04
    ]

    /// Modulus used to cycle topping colors (onion / tomato / relish / surface).
    static let toppingColorModulus: Int = 4
}
