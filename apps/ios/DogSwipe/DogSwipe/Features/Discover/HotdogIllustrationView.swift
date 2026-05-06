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
                    .offset(y: proxy.size.height * 0.02)
            }
        }
        .accessibilityLabel(profile.mediaAltText ?? profile.name)
    }

    private func hotdog(width: CGFloat, height: CGFloat) -> some View {
        let dogWidth = width * 0.92
        let dogHeight = min(height * 0.64, 220)

        return ZStack {
            Capsule()
                .fill(Color.dsBun.opacity(0.20))
                .frame(width: dogWidth * 0.94, height: dogHeight * 0.58)
                    .offset(x: .dsHotdogPlateOffsetX, y: dogHeight * 0.22)
                .blur(radius: 6)

            Capsule()
                .fill(
                    LinearGradient(
                        colors: [Color.dsBunLight, Color.dsBun],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: dogWidth, height: dogHeight * 0.72)
                .offset(y: dogHeight * 0.16)

            Capsule()
                .fill(Color.dsSurface.opacity(0.92))
                .frame(width: dogWidth * 0.84, height: dogHeight * 0.48)
                .offset(y: -dogHeight * 0.04)

            Capsule()
                .fill(
                    LinearGradient(
                        colors: [Color.dsAccent, Color.dsTomato.opacity(0.82)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: dogWidth * 0.74, height: dogHeight * 0.34)
                .offset(y: -dogHeight * 0.06)

            Capsule()
                .fill(Color.dsPickle)
                .frame(width: dogWidth * 0.58, height: dogHeight * 0.18)
                .offset(x: dogWidth * 0.08, y: -dogHeight * 0.18)
                .overlay {
                    Capsule().stroke(Color.dsSurface.opacity(0.52), lineWidth: 2)
                }

            toppingScatter(width: dogWidth, height: dogHeight)

            MustardSquiggle()
                .stroke(Color.dsPrimary, style: StrokeStyle(lineWidth: 7, lineCap: .round))
                .frame(width: dogWidth * 0.68, height: dogHeight * 0.24)
                .offset(y: -dogHeight * 0.13)
        }
        .frame(width: width, height: height)
    }

    private func toppingScatter(width: CGFloat, height: CGFloat) -> some View {
        ZStack {
            ForEach(0..<16, id: \.self) { index in
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(toppingColor(for: index))
                    .frame(width: toppingSize(for: index), height: toppingSize(for: index) * 0.82)
                    .rotationEffect(.degrees(Double((index % 5) * 11)))
                    .offset(
                        x: toppingX(for: index, width: width),
                        y: toppingY(for: index, height: height)
                    )
            }
        }
    }

    private func toppingColor(for index: Int) -> Color {
        switch index % 4 {
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
        CGFloat(8 + (index % 3) * 3)
    }

    private func toppingX(for index: Int, width: CGFloat) -> CGFloat {
        let columns: [CGFloat] = [-0.28, -0.18, -0.07, 0.04, 0.15, 0.26, 0.34, -0.34]
        return width * columns[index % columns.count]
    }

    private func toppingY(for index: Int, height: CGFloat) -> CGFloat {
        let rows: [CGFloat] = [-0.19, -0.13, -0.07, -0.01, 0.04]
        return height * rows[(index / 2) % rows.count]
    }
}

private struct MustardSquiggle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let step = rect.width / 5
        path.move(to: CGPoint(x: rect.minX, y: rect.midY))

        for index in 0..<5 {
            let startX = rect.minX + CGFloat(index) * step
            let endX = startX + step
            let controlY = index.isMultiple(of: 2) ? rect.minY : rect.maxY
            path.addCurve(
                to: CGPoint(x: endX, y: rect.midY),
                control1: CGPoint(x: startX + step * 0.35, y: controlY),
                control2: CGPoint(x: startX + step * 0.65, y: controlY)
            )
        }

        return path
    }
}

#Preview {
    HotdogIllustrationView(profile: HotdogProfile.samples[0])
}
