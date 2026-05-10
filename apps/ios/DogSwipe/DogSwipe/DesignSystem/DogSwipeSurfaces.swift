import SwiftUI

extension View {
    /// Canonical interactive-card surface: ds-spacing inner padding + dsCardSurface chrome.
    func dsCard(padding: CGFloat = .dsSpace4) -> some View {
        self.padding(padding).dsCardSurface()
    }
}

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

struct DogSwipeScreenHeader<Right: View>: View {
    let title: String
    let kicker: String?
    @ViewBuilder let right: () -> Right

    init(
        title: String,
        kicker: String? = nil,
        @ViewBuilder right: @escaping () -> Right
    ) {
        self.title = title
        self.kicker = kicker
        self.right = right
    }

    var body: some View {
        HStack(alignment: .bottom, spacing: .dsSpace3) {
            VStack(alignment: .leading, spacing: .dsSpace1) {
                if let kicker, !kicker.isEmpty {
                    Text(kicker.uppercased())
                        .font(.caption2.weight(.heavy))
                        .tracking(1.1)
                        .foregroundStyle(Color.dsMuted)
                        .lineLimit(1)
                        .minimumScaleFactor(0.76)
                }

                Text(title)
                    .font(.system(size: .dsScreenTitleFontSize, weight: .heavy, design: .rounded))
                    .foregroundStyle(Color.dsInk)
                    .lineLimit(2)
                    .minimumScaleFactor(0.76)
                    .accessibilityAddTraits(.isHeader)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            right()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

extension DogSwipeScreenHeader where Right == EmptyView {
    init(title: String, kicker: String? = nil) {
        self.init(title: title, kicker: kicker) {
            EmptyView()
        }
    }
}

struct DogSwipeIconButton: View {
    let systemImage: String
    let accessibilityLabel: String
    var isDisabled = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.subheadline.weight(.heavy))
                .foregroundStyle(Color.dsInk)
                .frame(width: .dsIconButtonSize, height: .dsIconButtonSize)
                .background(Color.dsInk.opacity(0.06), in: Circle())
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.38 : 1)
        .accessibilityLabel(accessibilityLabel)
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

struct DogSwipeStatusPill: View {
    let text: String
    var tint: Color = .dsRelish
    var size: Size = .small

    enum Size {
        case small
        case medium
    }

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(tint)
                .frame(width: .dsStatusDotSize, height: .dsStatusDotSize)
            Text(text)
                .lineLimit(1)
                .minimumScaleFactor(0.76)
        }
        .font(size == .medium ? .caption.weight(.bold) : .caption2.weight(.bold))
        .foregroundStyle(tint)
        .padding(.horizontal, size == .medium ? .dsSpace3 : .dsSpace2)
        .padding(.vertical, size == .medium ? .dsSpace2 : .dsSpace1)
        .background(tint.opacity(0.14), in: Capsule())
        .overlay {
            Capsule().stroke(tint.opacity(0.16))
        }
    }
}

struct DogSwipeDarkSummaryCard<Content: View>: View {
    @ViewBuilder let content: () -> Content

    var body: some View {
        content()
            .padding(.dsSpace4)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.dsInk, in: RoundedRectangle(cornerRadius: .dsRadius5, style: .continuous))
            .foregroundStyle(Color.dsSurface)
            .shadow(color: Color.dsShadow.opacity(0.72), radius: 16, x: 0, y: 10)
    }
}

struct DogSwipeCraveMeter: View {
    let score: Double
    var showsLabel = true
    var dark = false

    private var normalizedScore: Double {
        min(1, max(0, score))
    }

    private var scoreText: String {
        "\(Int((normalizedScore * 100).rounded()))"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: .dsSpace1) {
            if showsLabel {
                HStack {
                    Text("Crave")
                    Spacer()
                    Text(scoreText)
                        .monospacedDigit()
                }
                .font(.caption2.weight(.heavy))
                .tracking(0.7)
                .textCase(.uppercase)
                .foregroundStyle(dark ? Color.dsSurface.opacity(0.68) : Color.dsMuted)
            }

            GeometryReader { proxy in
                Capsule()
                    .fill(dark ? Color.dsSurface.opacity(0.18) : Color.dsInk.opacity(0.10))
                    .overlay(alignment: .leading) {
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [.dsPrimary, .dsAccent],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: proxy.size.width * normalizedScore)
                    }
            }
            .frame(height: .dsCraveMeterHeight)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Crave score \(scoreText)")
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
