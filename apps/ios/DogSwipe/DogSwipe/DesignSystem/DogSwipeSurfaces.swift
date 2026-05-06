import SwiftUI

enum DogSwipeHeaderTab: String, CaseIterable {
    case discover = "Discover"
    case nearYou = "Near You"
    case favorites = "Favorites"
    case myOrders = "My Orders"

    var index: Int {
        Self.allCases.firstIndex(of: self) ?? 0
    }
}

struct DogSwipeBrandHeader: View {
    let activeTab: DogSwipeHeaderTab
    var cartCount: Int = 0

    var body: some View {
        VStack(spacing: .dsSpace3) {
            HStack(alignment: .center) {
                Image(systemName: "person.crop.circle")
                    .font(.title2.weight(.medium))
                    .foregroundStyle(Color.dsInk)
                    .frame(width: .dsBrandIconFrame, height: .dsBrandIconFrame)

                Spacer()

                VStack(spacing: .dsSpace1) {
                    Text("DogSwipe")
                        .font(.system(size: .dsBrandLogoFontSize, weight: .heavy, design: .rounded))
                        .foregroundStyle(Color.dsAccent)
                        .shadow(color: Color.dsPrimary.opacity(0.72), radius: 0, x: -2, y: 2)
                    Text("Street Vendor Pack")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.dsMuted)
                }

                Spacer()

                ZStack(alignment: .topTrailing) {
                    Image(systemName: "bag")
                        .font(.title2.weight(.medium))
                        .foregroundStyle(Color.dsInk)
                        .frame(width: .dsBrandIconFrame, height: .dsBrandIconFrame)

                    if cartCount > 0 {
                        Text("\(min(cartCount, 9))")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(Color.dsSurface)
                            .frame(width: .dsBrandBadgeSize, height: .dsBrandBadgeSize)
                            .background(Color.dsAccent, in: Circle())
                            .offset(x: .dsBrandBadgeOffsetX, y: .dsBrandBadgeOffsetY)
                            .accessibilityLabel("\(cartCount) items in order")
                    }
                }
                .accessibilityLabel(cartCount == 1 ? "1 item in order" : "\(cartCount) items in order")
            }

            HStack {
                ForEach(DogSwipeHeaderTab.allCases, id: \.self) { tab in
                    Text(tab.rawValue)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(tab == activeTab ? Color.dsAccent : Color.dsInk)
                        .frame(maxWidth: .infinity)
                        .lineLimit(1)
                        .minimumScaleFactor(0.78)
                }
            }
            .frame(height: .dsHeaderTabHeight)

            DogSwipeWavyDivider(activeIndex: activeTab.index)
                .frame(height: .dsWaveHeight)
        }
    }
}

struct DogSwipeWavyDivider: View {
    let activeIndex: Int
    private let tabCount = DogSwipeHeaderTab.allCases.count

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .topLeading) {
                DogSwipeWaveShape()
                    .stroke(Color.dsPrimary, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                    .frame(height: proxy.size.height)

                Circle()
                    .fill(Color.dsPrimary)
                    .frame(width: .dsBrandBadgeSize, height: .dsBrandBadgeSize)
                    .position(x: dotX(in: proxy.size.width), y: proxy.size.height * 0.48)
            }
        }
    }

    private func dotX(in width: CGFloat) -> CGFloat {
        let slot = width / CGFloat(max(tabCount, 1))
        return slot * (CGFloat(activeIndex) + 0.5)
    }
}

private struct DogSwipeWaveShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let midY = rect.midY
        path.move(to: CGPoint(x: rect.minX - 8, y: midY))

        let segment = rect.width / 3
        for index in 0..<3 {
            let startX = CGFloat(index) * segment
            let endX = startX + segment
            let controlY = index.isMultiple(of: 2) ? midY - 14 : midY + 14
            path.addCurve(
                to: CGPoint(x: endX, y: midY),
                control1: CGPoint(x: startX + segment * 0.32, y: controlY),
                control2: CGPoint(x: startX + segment * 0.68, y: controlY)
            )
        }

        return path
    }
}

struct DogSwipeChip: View {
    let text: String
    var systemImage: String?
    var tint: Color = .dsPrimarySoft

    var body: some View {
        Label {
            Text(text)
                .lineLimit(1)
                .minimumScaleFactor(0.82)
        } icon: {
            if let systemImage {
                Image(systemName: systemImage)
            }
        }
        .font(.caption.weight(.bold))
        .foregroundStyle(Color.dsInk)
        .padding(.horizontal, .dsSpace3)
        .padding(.vertical, .dsSpace2)
        .background(tint, in: Capsule())
        .overlay {
            Capsule().stroke(Color.dsDivider)
        }
    }
}

struct DogSwipeChipGrid<Content: View>: View {
    private let content: () -> Content
    private let columns = [
        GridItem(.adaptive(minimum: .dsChipMinimumWidth), spacing: .dsSpace2, alignment: .leading)
    ]

    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }

    var body: some View {
        LazyVGrid(columns: columns, alignment: .leading, spacing: .dsSpace2) {
            content()
        }
    }
}

struct DogSwipePrimaryButton: View {
    let title: String
    let price: String?
    let action: () -> Void

    init(title: String, price: String? = nil, action: @escaping () -> Void = {}) {
        self.title = title
        self.price = price
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: .dsSpace3) {
                Spacer()
                Text(title)
                if let price {
                    Text(price)
                        .monospacedDigit()
                }
                Image(systemName: "arrow.right")
                Spacer()
            }
            .font(.headline.weight(.bold))
            .foregroundStyle(Color.dsInk)
            .frame(height: .dsPrimaryButtonHeight)
            .background(Color.dsPrimary, in: Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityValue(price ?? "")
        .shadow(color: Color.dsPrimary.opacity(0.28), radius: 12, x: 0, y: 8)
    }
}

struct DogSwipeStampView: View {
    let text: String

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.dsDivider, style: StrokeStyle(lineWidth: 2, dash: [4, 4]))
            Text(text.uppercased())
                .font(.caption2.weight(.heavy))
                .multilineTextAlignment(.center)
                .foregroundStyle(Color.dsMuted.opacity(0.68))
                .padding(.dsSpace2)
        }
        .frame(width: .dsStampSize, height: .dsStampSize)
    }
}

struct DogSwipeSectionHeader: View {
    let title: String
    let subtitle: String
    var systemImage: String = "fork.knife.circle.fill"

    var body: some View {
        HStack(alignment: .top, spacing: .dsSpace3) {
            Image(systemName: systemImage)
                .font(.title3.weight(.semibold))
                .foregroundStyle(Color.dsAccent)
                .frame(width: .dsSectionIconSize, height: .dsSectionIconSize)
                .background(Color.dsPrimarySoft, in: Circle())

            VStack(alignment: .leading, spacing: .dsSpace1) {
                Text(title)
                    .font(.title3.weight(.heavy))
                    .foregroundStyle(Color.dsInk)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(Color.dsMuted)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
