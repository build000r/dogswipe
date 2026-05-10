import CoreGraphics
import SwiftUI
import XCTest
@testable import DogSwipe

/// Token-level guards for the design-system extensions introduced or
/// renamed by the WG-D wave (WG-D01..D04). Every refactored hotspot that
/// surfaced a tokenized constant gets a direct sanity assertion here so
/// CRAP stays under 20 — i.e., any future drift in the token values
/// triggers a failed test rather than a silently broken UI.
final class DesignSystemTokenTests: XCTestCase {
    // MARK: - Color.dsDivider / Double.dsDividerOpacity

    func testDividerOpacityIsRoutedThroughNamedDouble() {
        // Direct assertion on the named alpha source-of-truth.
        XCTAssertEqual(Double.dsDividerOpacity, 0.08, accuracy: 1e-9)
        // The hairline divider must build off `dsInk * dsDividerOpacity`.
        // We assert equality to the same recipe used by the production
        // token; if either side drifts, this fails.
        XCTAssertEqual(Color.dsDivider, Color.dsInk.opacity(.dsDividerOpacity))
    }

    // MARK: - Swipe gesture thresholds

    func testSwipeThresholdsAreOrderedAndPositive() {
        XCTAssertGreaterThan(CGFloat.dsSwipeArmThreshold, 0)
        XCTAssertGreaterThan(CGFloat.dsSwipeCommitThreshold, 0)
        XCTAssertGreaterThan(
            CGFloat.dsSwipeCommitThreshold,
            CGFloat.dsSwipeArmThreshold,
            "Commit threshold must be larger than the arm threshold so the"
                + " swipe arms before it commits."
        )
        XCTAssertGreaterThan(CGFloat.dsSwipeDragMinimumDistance, 0)
        XCTAssertLessThan(
            CGFloat.dsSwipeDragMinimumDistance,
            CGFloat.dsSwipeArmThreshold,
            "Drag must engage before any decision is armed."
        )
    }

    // MARK: - HotdogIllustrationGeometry ratio sanity

    func testHotdogIllustrationGeometryRatiosAreProportional() {
        // Every *Ratio constant on the geometry namespace must lie in
        // (-1, 1) — they are all proportional offsets / fractions, never
        // absolute pixel measurements.
        let ratios: [(String, CGFloat)] = [
            ("stackOffsetYRatio", HotdogIllustrationGeometry.stackOffsetYRatio),
            ("dogWidthRatio", HotdogIllustrationGeometry.dogWidthRatio),
            ("dogHeightRatio", HotdogIllustrationGeometry.dogHeightRatio),
            ("plateWidthRatio", HotdogIllustrationGeometry.plateWidthRatio),
            ("plateHeightRatio", HotdogIllustrationGeometry.plateHeightRatio),
            ("plateOffsetYRatio", HotdogIllustrationGeometry.plateOffsetYRatio),
            ("bunHeightRatio", HotdogIllustrationGeometry.bunHeightRatio),
            ("bunOffsetYRatio", HotdogIllustrationGeometry.bunOffsetYRatio),
            ("highlightWidthRatio", HotdogIllustrationGeometry.highlightWidthRatio),
            ("highlightHeightRatio", HotdogIllustrationGeometry.highlightHeightRatio),
            ("highlightOffsetYRatio", HotdogIllustrationGeometry.highlightOffsetYRatio),
            ("frankWidthRatio", HotdogIllustrationGeometry.frankWidthRatio),
            ("frankHeightRatio", HotdogIllustrationGeometry.frankHeightRatio),
            ("frankOffsetYRatio", HotdogIllustrationGeometry.frankOffsetYRatio),
            ("pickleWidthRatio", HotdogIllustrationGeometry.pickleWidthRatio),
            ("pickleHeightRatio", HotdogIllustrationGeometry.pickleHeightRatio),
            ("pickleOffsetXRatio", HotdogIllustrationGeometry.pickleOffsetXRatio),
            ("pickleOffsetYRatio", HotdogIllustrationGeometry.pickleOffsetYRatio),
            ("mustardWidthRatio", HotdogIllustrationGeometry.mustardWidthRatio),
            ("mustardHeightRatio", HotdogIllustrationGeometry.mustardHeightRatio),
            ("mustardOffsetYRatio", HotdogIllustrationGeometry.mustardOffsetYRatio),
            ("toppingHeightRatio", HotdogIllustrationGeometry.toppingHeightRatio)
        ]
        for (name, value) in ratios {
            XCTAssertGreaterThan(value, -1, "\(name) below -1: \(value)")
            XCTAssertLessThan(value, 1, "\(name) above 1: \(value)")
        }
    }

    // MARK: - HotdogIllustrationGeometry topping scatter

    func testHotdogIllustrationGeometryToppingScatterIsNonEmpty() {
        XCTAssertGreaterThan(HotdogIllustrationGeometry.toppingScatterCount, 0)
        XCTAssertFalse(HotdogIllustrationGeometry.toppingColumnOffsets.isEmpty)
        XCTAssertFalse(HotdogIllustrationGeometry.toppingRowOffsets.isEmpty)
        XCTAssertGreaterThan(HotdogIllustrationGeometry.toppingSizeVariantModulus, 0)
        XCTAssertGreaterThan(HotdogIllustrationGeometry.toppingRotationModulus, 0)
        XCTAssertGreaterThan(HotdogIllustrationGeometry.toppingColorModulus, 0)
        // Column / row offsets are also proportional fractions.
        for offset in HotdogIllustrationGeometry.toppingColumnOffsets {
            XCTAssertGreaterThan(offset, -1)
            XCTAssertLessThan(offset, 1)
        }
        for offset in HotdogIllustrationGeometry.toppingRowOffsets {
            XCTAssertGreaterThan(offset, -1)
            XCTAssertLessThan(offset, 1)
        }
    }

    // MARK: - Overlay alpha sanity

    func testOverlayOpacityTokensAreNormalisedAlphas() {
        let alphas: [(String, Double)] = [
            ("surfaceHeavy", DogSwipeOverlayOpacity.surfaceHeavy),
            ("stroke", DogSwipeOverlayOpacity.stroke),
            ("gradientLeading", DogSwipeOverlayOpacity.gradientLeading),
            ("gradientTrailing", DogSwipeOverlayOpacity.gradientTrailing)
        ]
        for (name, alpha) in alphas {
            XCTAssertGreaterThanOrEqual(alpha, 0, "\(name) below 0: \(alpha)")
            XCTAssertLessThanOrEqual(alpha, 1, "\(name) above 1: \(alpha)")
        }
    }

    func testCardOpacityTokensAreNormalisedAlphas() {
        let alphas: [(String, Double)] = [
            ("deckBack", DogSwipeCardOpacity.deckBack),
            ("heroPill", DogSwipeCardOpacity.heroPill),
            ("heroBody", DogSwipeCardOpacity.heroBody),
            ("heroShadow", DogSwipeCardOpacity.heroShadow),
            ("heroGradientMid", DogSwipeCardOpacity.heroGradientMid),
            ("heroGradientBottom", DogSwipeCardOpacity.heroGradientBottom),
            ("menuSearchShadow", DogSwipeCardOpacity.menuSearchShadow)
        ]
        for (name, alpha) in alphas {
            XCTAssertGreaterThanOrEqual(alpha, 0, "\(name) below 0: \(alpha)")
            XCTAssertLessThanOrEqual(alpha, 1, "\(name) above 1: \(alpha)")
        }
    }
}
