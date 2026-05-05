import DogSwipeCore
import SwiftUI

struct HotdogIllustrationView: View {
    let profile: HotdogProfile

    var body: some View {
        ZStack {
            Color.dsPrimarySoft

            VStack {
                Spacer()

                ZStack {
                    Capsule()
                        .fill(Color.dsSurface)
                        .frame(height: .dsHotdogBunHeight)
                        .overlay {
                            Capsule()
                                .stroke(Color.dsDivider)
                        }

                    Capsule()
                        .fill(Color.dsAccent)
                        .frame(height: .dsHotdogFrankHeight)
                        .padding(.horizontal, .dsSpace8)
                        .offset(y: .dsHotdogFrankOffset)

                    toppingLine(color: .dsPrimary, yOffset: .dsHotdogPrimaryToppingOffset)
                    toppingLine(color: .dsSurface, yOffset: .dsHotdogSecondaryToppingOffset)
                }
                .padding(.horizontal, .dsSpace6)

                Spacer()
            }
        }
        .accessibilityLabel(profile.mediaAltText ?? profile.name)
    }

    private func toppingLine(color: Color, yOffset: CGFloat) -> some View {
        Capsule()
            .trim(from: 0.08, to: 0.92)
            .stroke(
                color,
                style: StrokeStyle(
                    lineWidth: .dsHotdogToppingLineWidth,
                    lineCap: .round,
                    dash: [.dsHotdogToppingDash, .dsHotdogToppingDashGap]
                )
            )
            .frame(height: .dsHotdogToppingHeight)
            .padding(.horizontal, .dsSpace8)
            .offset(y: yOffset)
    }
}

#Preview {
    HotdogIllustrationView(profile: HotdogProfile.samples[0])
}
