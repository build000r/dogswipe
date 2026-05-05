import DogSwipeCore
import Foundation
import SwiftUI

struct HotdogCardView: View {
    let profile: HotdogProfile
    let originLocation: DiscoveryLocation?
    @StateObject private var routePreviewStore: RoutePreviewStore
    @Environment(\.openURL) private var openURL

    init(
        profile: HotdogProfile,
        originLocation: DiscoveryLocation? = nil,
        routePreviewStore: RoutePreviewStore? = nil
    ) {
        self.profile = profile
        self.originLocation = originLocation
        _routePreviewStore = StateObject(
            wrappedValue: routePreviewStore ?? RoutePreviewStore()
        )
    }

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

                if !profile.menuHighlightLabels.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: .dsSpace2) {
                            Image(systemName: "menucard")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(Color.dsPrimary)

                            ForEach(profile.menuHighlightLabels.prefix(4), id: \.self) { highlight in
                                menuHighlightChip(highlight)
                            }
                        }
                    }
                }

                Divider()

                HStack(spacing: .dsSpace4) {
                    metric(label: "Price", value: profile.priceLabel)
                    metric(label: "Distance", value: String(format: "%.1f mi", profile.distanceMiles))
                    metric(label: "Walk", value: profile.walkingTimeLabel)
                    metric(label: "Crave", value: "\(Int(profile.craveScore * 100))%")
                }

                routeActions
                RoutePreviewStatusView(state: routePreviewStore.state)
            }
            .padding(.horizontal, .dsSpace5)
            .padding(.bottom, .dsSpace5)
        }
        .dsCardSurface()
        .onChange(of: profile.id) {
            routePreviewStore.reset()
        }
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

    @ViewBuilder
    private var routeActions: some View {
        if routePreviewStore.canPreview(profile: profile, origin: originLocation)
            || profile.directionsURL != nil {
            HStack(spacing: .dsSpace3) {
                if routePreviewStore.canPreview(profile: profile, origin: originLocation) {
                    Button {
                        Task {
                            await routePreviewStore.preview(
                                profile: profile,
                                origin: originLocation
                            )
                        }
                    } label: {
                        Label("Live walk", systemImage: "figure.walk")
                    }
                    .buttonStyle(.bordered)
                    .tint(.dsPrimary)
                    .disabled(routePreviewStore.state == .loading)
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
        }
    }

    private func menuHighlightChip(_ value: String) -> some View {
        Text(value)
            .font(.caption.weight(.semibold))
            .foregroundStyle(Color.dsInk)
            .lineLimit(1)
            .padding(.horizontal, .dsSpace2)
            .padding(.vertical, .dsSpace1)
            .background(Color.dsPrimarySoft, in: Capsule())
    }
}

#Preview {
    HotdogCardView(profile: HotdogProfile.samples[0])
        .padding()
        .dsPageBackground()
}
