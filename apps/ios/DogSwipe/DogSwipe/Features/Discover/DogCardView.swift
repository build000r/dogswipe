import DogSwipeCore
import Foundation
import SwiftUI

struct DogCardView: View {
    let profile: DogProfile

    var body: some View {
        VStack(alignment: .leading, spacing: .dsSpace4) {
            hero

            VStack(alignment: .leading, spacing: .dsSpace3) {
                titleRow
                Text(profile.temperament)
                    .font(.body)
                    .foregroundStyle(Color.dsMuted)
                    .lineLimit(2)

                Divider()

                HStack(spacing: .dsSpace4) {
                    metric(label: "Age", value: profile.ageLabel)
                    metric(label: "Distance", value: String(format: "%.1f mi", profile.distanceMiles))
                    metric(label: "Fit", value: "\(Int(profile.compatibilityScore * 100))%")
                }
            }
            .padding(.horizontal, .dsSpace5)
            .padding(.bottom, .dsSpace5)
        }
        .dsCardSurface()
    }

    private var hero: some View {
        ZStack {
            AsyncImage(url: profile.imageURL) { phase in
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
            .frame(maxWidth: .infinity)
            .aspectRatio(0.86, contentMode: .fit)
            .clipped()

            VStack {
                Spacer()
                HStack {
                    Label(profile.shelterName, systemImage: "mappin.and.ellipse")
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
        .clipShape(RoundedRectangle(cornerRadius: .dsRadius4, style: .continuous))
    }

    private var fallbackHero: some View {
        ZStack {
            Color.dsPrimarySoft
            Image(systemName: "pawprint.fill")
                .font(.largeTitle)
                .foregroundStyle(Color.dsPrimary)
        }
    }

    private var titleRow: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: .dsSpace1) {
                Text(profile.name)
                    .font(.title.weight(.semibold))
                    .foregroundStyle(Color.dsInk)
                Text(profile.breed)
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
    DogCardView(profile: DogProfile.samples[0])
        .padding()
        .dsPageBackground()
}
