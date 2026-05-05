import DogSwipeCore
import Foundation
import SwiftUI

struct HotdogCardView: View {
    let profile: HotdogProfile
    @Environment(\.openURL) private var openURL

    var body: some View {
        VStack(alignment: .leading, spacing: .dsSpace4) {
            hero

            VStack(alignment: .leading, spacing: .dsSpace3) {
                titleRow
                Text(profile.signatureNotes)
                    .font(.body)
                    .foregroundStyle(Color.dsMuted)
                    .lineLimit(2)

                if let addressText = profile.addressText, !addressText.isEmpty {
                    Label(addressText, systemImage: "map")
                        .font(.caption)
                        .foregroundStyle(Color.dsMuted)
                        .lineLimit(1)
                }

                Divider()

                HStack(spacing: .dsSpace4) {
                    metric(label: "Price", value: profile.priceLabel)
                    metric(label: "Distance", value: String(format: "%.1f mi", profile.distanceMiles))
                    metric(label: "Walk", value: profile.walkingTimeLabel)
                    metric(label: "Crave", value: "\(Int(profile.craveScore * 100))%")
                }

                if let directionsURL = profile.directionsURL {
                    Button {
                        openURL(directionsURL)
                    } label: {
                        Label("Directions", systemImage: "map")
                    }
                    .buttonStyle(.bordered)
                    .tint(.dsPrimary)
                }
            }
            .padding(.horizontal, .dsSpace5)
            .padding(.bottom, .dsSpace5)
        }
        .dsCardSurface()
    }

    private var hero: some View {
        ZStack {
            if let imageURL = profile.imageURL {
                AsyncImage(url: imageURL) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().scaledToFill()
                    case .failure:
                        fallbackHero
                    case .empty:
                        fallbackHero.overlay {
                            ProgressView()
                        }
                    @unknown default:
                        fallbackHero
                    }
                }
            } else {
                fallbackHero
            }

            VStack {
                Spacer()
                HStack {
                    Label(profile.vendorName, systemImage: "mappin.and.ellipse")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Color.dsSurface)
                        .padding(.horizontal, .dsSpace3)
                        .padding(.vertical, .dsSpace2)
                        .background(Color.dsInk.opacity(0.62), in: Capsule())
                    Spacer()
                }
                .padding(.dsSpace4)
            }
        }
        .frame(maxWidth: .infinity)
        .aspectRatio(0.86, contentMode: .fit)
        .clipped()
        .clipShape(RoundedRectangle(cornerRadius: .dsRadius4, style: .continuous))
    }

    private var fallbackHero: some View {
        HotdogIllustrationView(profile: profile)
    }

    private var titleRow: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: .dsSpace1) {
                Text(profile.name)
                    .font(.title.weight(.semibold))
                    .foregroundStyle(Color.dsInk)
                Text(profile.style)
                    .font(.subheadline)
                    .foregroundStyle(Color.dsMuted)
            }
            Spacer()
        }
    }

    private func metric(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: .dsSpace1) {
            Text(value)
                .font(.headline.monospacedDigit())
                .foregroundStyle(Color.dsInk)
            Text(label)
                .font(.caption)
                .foregroundStyle(Color.dsMuted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    HotdogCardView(profile: HotdogProfile.samples[0])
        .padding()
        .dsPageBackground()
}
