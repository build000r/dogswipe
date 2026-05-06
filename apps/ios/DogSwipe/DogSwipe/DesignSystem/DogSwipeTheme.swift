import SwiftUI

extension Color {
    static let dsCanvas = Color(red: 0.98, green: 0.97, blue: 0.94)
    static let dsSurface = Color(red: 1.00, green: 0.99, blue: 0.97)
    static let dsInk = Color(red: 0.12, green: 0.11, blue: 0.09)
    static let dsMuted = Color(red: 0.42, green: 0.39, blue: 0.34)
    static let dsPrimary = Color(red: 0.94, green: 0.68, blue: 0.02)
    static let dsPrimarySoft = Color(red: 0.99, green: 0.92, blue: 0.72)
    static let dsAccent = Color(red: 0.86, green: 0.34, blue: 0.21)
    static let dsRelish = Color(red: 0.23, green: 0.58, blue: 0.29)
    static let dsPickle = Color(red: 0.38, green: 0.52, blue: 0.17)
    static let dsTomato = Color(red: 0.78, green: 0.16, blue: 0.10)
    static let dsOnion = Color(red: 0.98, green: 0.95, blue: 0.84)
    static let dsBun = Color(red: 0.86, green: 0.52, blue: 0.18)
    static let dsBunLight = Color(red: 0.99, green: 0.76, blue: 0.36)
    static let dsDivider = Color.black.opacity(0.08)
    static let dsShadow = Color(red: 0.21, green: 0.16, blue: 0.09).opacity(0.16)
}

extension CGFloat {
    static let dsSpace1: CGFloat = 4
    static let dsSpace2: CGFloat = 8
    static let dsSpace3: CGFloat = 12
    static let dsSpace4: CGFloat = 16
    static let dsSpace5: CGFloat = 20
    static let dsSpace6: CGFloat = 24
    static let dsSpace8: CGFloat = 32
    static let dsRadius2: CGFloat = 8
    static let dsRadius3: CGFloat = 12
    static let dsRadius4: CGFloat = 16
    static let dsRadius5: CGFloat = 22
    static let dsHotdogBunHeight: CGFloat = 118
    static let dsHotdogFrankHeight: CGFloat = 58
    static let dsHotdogFrankOffset: CGFloat = -2
    static let dsHotdogToppingHeight: CGFloat = 20
    static let dsHotdogPrimaryToppingOffset: CGFloat = -10
    static let dsHotdogSecondaryToppingOffset: CGFloat = 4
    static let dsHotdogToppingLineWidth: CGFloat = 5
    static let dsHotdogToppingDash: CGFloat = 10
    static let dsHotdogToppingDashGap: CGFloat = 9
    static let dsCardHeroAspectRatio: CGFloat = 2.05
    static let dsBrandLogoFontSize: CGFloat = 34
    static let dsBrandIconFrame: CGFloat = 40
    static let dsBrandBadgeSize: CGFloat = 18
    static let dsBrandBadgeOffsetX: CGFloat = 2
    static let dsBrandBadgeOffsetY: CGFloat = 1
    static let dsHeaderTabHeight: CGFloat = 26
    static let dsWaveHeight: CGFloat = 22
    static let dsInfoButtonSize: CGFloat = 34
    static let dsPrimaryButtonHeight: CGFloat = 56
    static let dsStampSize: CGFloat = 72
    static let dsSectionIconSize: CGFloat = 32
    static let dsDiscoverDeckHeight: CGFloat = 440
    static let dsDeckBackOffsetX: CGFloat = 34
    static let dsDeckBackOffsetY: CGFloat = 20
    static let dsHotdogPlateOffsetX: CGFloat = 8
    static let dsMatchTitleFontSize: CGFloat = 36
    static let dsMatchHeroHeight: CGFloat = 210
    static let dsMatchAddOnWidth: CGFloat = 118
    static let dsMatchAddOnHeight: CGFloat = 52
    static let dsMatchThumbnailWidth: CGFloat = 72
    static let dsMatchThumbnailHeight: CGFloat = 58
}

extension View {
    func dsPageBackground() -> some View {
        background(Color.dsCanvas.ignoresSafeArea())
    }

    func dsCardSurface() -> some View {
        background(Color.dsSurface)
            .clipShape(RoundedRectangle(cornerRadius: .dsRadius5, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: .dsRadius5, style: .continuous)
                    .stroke(Color.dsDivider)
            }
            .shadow(color: Color.dsShadow, radius: 16, x: 0, y: 10)
    }
}
