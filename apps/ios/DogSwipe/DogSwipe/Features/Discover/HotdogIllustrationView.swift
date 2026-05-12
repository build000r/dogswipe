import DogSwipeCore
import SwiftUI

struct HotdogIllustrationView: View {
    let profile: HotdogProfile

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                LinearGradient(
                    colors: [Color.dsSurface, Color.dsPrimarySoft.opacity(0.54)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                hotdog(width: proxy.size.width, height: proxy.size.height)
                    .rotationEffect(.degrees(-7))
                    .offset(y: proxy.size.height * HotdogIllustrationGeometry.stackOffsetYRatio)
            }
        }
        .accessibilityLabel(profile.mediaAltText ?? profile.name)
    }

    private func hotdog(width: CGFloat, height: CGFloat) -> some View {
        let dogWidth = width * HotdogIllustrationGeometry.dogWidthRatio
        let dogHeight = min(height * HotdogIllustrationGeometry.dogHeightRatio, HotdogIllustrationGeometry.dogHeightCap)

        return ZStack {
            Capsule()
                .fill(Color.dsBun.opacity(0.20))
                .frame(
                    width: dogWidth * HotdogIllustrationGeometry.plateWidthRatio,
                    height: dogHeight * HotdogIllustrationGeometry.plateHeightRatio
                )
                .offset(
                    x: .dsHotdogPlateOffsetX,
                    y: dogHeight * HotdogIllustrationGeometry.plateOffsetYRatio
                )
                .blur(radius: HotdogIllustrationGeometry.plateBlurRadius)

            Capsule()
                .fill(
                    LinearGradient(
                        colors: [Color.dsBunLight, Color.dsBun],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: dogWidth, height: dogHeight * HotdogIllustrationGeometry.bunHeightRatio)
                .offset(y: dogHeight * HotdogIllustrationGeometry.bunOffsetYRatio)

            Capsule()
                .fill(Color.dsSurface.opacity(HotdogIllustrationGeometry.highlightOpacity))
                .frame(
                    width: dogWidth * HotdogIllustrationGeometry.highlightWidthRatio,
                    height: dogHeight * HotdogIllustrationGeometry.highlightHeightRatio
                )
                .offset(y: dogHeight * HotdogIllustrationGeometry.highlightOffsetYRatio)

            Capsule()
                .fill(
                    LinearGradient(
                        colors: [Color.dsAccent, Color.dsTomato.opacity(HotdogIllustrationGeometry.frankTrailOpacity)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(
                    width: dogWidth * HotdogIllustrationGeometry.frankWidthRatio,
                    height: dogHeight * HotdogIllustrationGeometry.frankHeightRatio
                )
                .offset(y: dogHeight * HotdogIllustrationGeometry.frankOffsetYRatio)

            Capsule()
                .fill(Color.dsPickle)
                .frame(
                    width: dogWidth * HotdogIllustrationGeometry.pickleWidthRatio,
                    height: dogHeight * HotdogIllustrationGeometry.pickleHeightRatio
                )
                .offset(
                    x: dogWidth * HotdogIllustrationGeometry.pickleOffsetXRatio,
                    y: dogHeight * HotdogIllustrationGeometry.pickleOffsetYRatio
                )
                .overlay {
                    Capsule().stroke(
                        Color.dsSurface.opacity(HotdogIllustrationGeometry.pickleStrokeOpacity),
                        lineWidth: HotdogIllustrationGeometry.pickleStrokeLineWidth
                    )
                }

            toppingScatter(width: dogWidth, height: dogHeight)

            MustardSquiggle()
                .stroke(
                    Color.dsPrimary,
                    style: StrokeStyle(lineWidth: HotdogIllustrationGeometry.mustardLineWidth, lineCap: .round)
                )
                .frame(
                    width: dogWidth * HotdogIllustrationGeometry.mustardWidthRatio,
                    height: dogHeight * HotdogIllustrationGeometry.mustardHeightRatio
                )
                .offset(y: dogHeight * HotdogIllustrationGeometry.mustardOffsetYRatio)
        }
        .frame(width: width, height: height)
    }

    private func toppingScatter(width: CGFloat, height: CGFloat) -> some View {
        ZStack {
            ForEach(0..<HotdogIllustrationGeometry.toppingScatterCount, id: \.self) { index in
                RoundedRectangle(cornerRadius: HotdogIllustrationGeometry.toppingCornerRadius, style: .continuous)
                    .fill(toppingColor(for: index))
                    .frame(
                        width: toppingSize(for: index),
                        height: toppingSize(for: index) * HotdogIllustrationGeometry.toppingHeightRatio
                    )
                    .rotationEffect(.degrees(Double((index % HotdogIllustrationGeometry.toppingRotationModulus) * HotdogIllustrationGeometry.toppingRotationStep)))
                    .offset(
                        x: toppingX(for: index, width: width),
                        y: toppingY(for: index, height: height)
                    )
            }
        }
    }

    private func toppingColor(for index: Int) -> Color {
        switch index % HotdogIllustrationGeometry.toppingColorModulus {
        case 0:
            Color.dsOnion
        case 1:
            Color.dsTomato
        case 2:
            Color.dsRelish
        default:
            Color.dsSurface
        }
    }

    private func toppingSize(for index: Int) -> CGFloat {
        HotdogIllustrationGeometry.toppingBaseSize
            + CGFloat(index % HotdogIllustrationGeometry.toppingSizeVariantModulus) * HotdogIllustrationGeometry.toppingSizeStep
    }

    private func toppingX(for index: Int, width: CGFloat) -> CGFloat {
        let columns = HotdogIllustrationGeometry.toppingColumnOffsets
        return width * columns[index % columns.count]
    }

    private func toppingY(for index: Int, height: CGFloat) -> CGFloat {
        let rows = HotdogIllustrationGeometry.toppingRowOffsets
        return height * rows[(index / 2) % rows.count]
    }
}

private struct MustardSquiggle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let segmentCount = HotdogIllustrationGeometry.mustardSegmentCount
        let step = rect.width / CGFloat(segmentCount)
        path.move(to: CGPoint(x: rect.minX, y: rect.midY))

        for index in 0..<segmentCount {
            let startX = rect.minX + CGFloat(index) * step
            let endX = startX + step
            let controlY = index.isMultiple(of: HotdogIllustrationGeometry.mustardWavePhaseModulus)
                ? rect.minY
                : rect.maxY
            path.addCurve(
                to: CGPoint(x: endX, y: rect.midY),
                control1: CGPoint(
                    x: startX + step * HotdogIllustrationGeometry.mustardFirstControlXRatio,
                    y: controlY
                ),
                control2: CGPoint(
                    x: startX + step * HotdogIllustrationGeometry.mustardSecondControlXRatio,
                    y: controlY
                )
            )
        }

        return path
    }
}

#Preview {
    HotdogIllustrationView(profile: HotdogProfile.samples[0])
}
