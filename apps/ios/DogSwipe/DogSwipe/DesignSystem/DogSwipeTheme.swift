import SwiftUI

extension Color {
    static let dsCanvas = Color(red: 0.98, green: 0.97, blue: 0.94)
    static let dsSurface = Color(red: 1.00, green: 0.99, blue: 0.97)
    static let dsInk = Color(red: 0.12, green: 0.11, blue: 0.09)
    static let dsMuted = Color(red: 0.42, green: 0.39, blue: 0.34)
    static let dsPrimary = Color(red: 0.04, green: 0.45, blue: 0.38)
    static let dsPrimarySoft = Color(red: 0.79, green: 0.91, blue: 0.86)
    static let dsAccent = Color(red: 0.86, green: 0.34, blue: 0.21)
    static let dsDivider = Color.black.opacity(0.08)
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
}

extension View {
    func dsPageBackground() -> some View {
        background(Color.dsCanvas.ignoresSafeArea())
    }

    func dsCardSurface() -> some View {
        background(Color.dsSurface)
            .clipShape(RoundedRectangle(cornerRadius: .dsRadius4, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: .dsRadius4, style: .continuous)
                    .stroke(Color.dsDivider)
            }
    }
}
