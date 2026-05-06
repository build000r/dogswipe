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
        VStack(alignment: .leading, spacing: 0) {
            hero

            VStack(alignment: .leading, spacing: .dsSpace2) {
                titleRow
                Text(profile.signatureNotes)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Color.dsMuted)
                    .lineLimit(2)

                if !profile.menuHighlightLabels.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: .dsSpace2) {
                            ForEach(profile.menuHighlightLabels.prefix(4), id: \.self) { highlight in
                                DogSwipeChip(text: highlight, systemImage: chipIcon(for: highlight))
                            }
                        }
                    }
                }

                HStack(spacing: .dsSpace4) {
                    Label(String(format: "%.1f mi", profile.distanceMiles), systemImage: "mappin.circle.fill")
                    Label(ratingLabel, systemImage: "star.fill")
                    Label(profile.walkingTimeLabel, systemImage: "figure.walk")
                }
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.dsMuted)
                .lineLimit(1)
                .minimumScaleFactor(0.82)

                if let addressText = profile.addressText, !addressText.isEmpty {
                    Text(addressText)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.dsMuted)
                        .lineLimit(1)
                }
            }
            .padding(.horizontal, .dsSpace4)
            .padding(.bottom, .dsSpace4)
        }
        .dsCardSurface()
        .onChange(of: profile.id) {
            routePreviewStore.reset()
        }
    }

    private var hero: some View {
        GeometryReader { proxy in
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

                VStack(spacing: 0) {
                    HStack(alignment: .top) {
                        DogSwipeChip(text: "Popular", systemImage: "flame.fill", tint: Color.dsSurface)
                        Spacer()
                        Image(systemName: "info.circle.fill")
                            .font(.title3)
                            .foregroundStyle(Color.dsInk.opacity(0.62))
                            .frame(width: .dsInfoButtonSize, height: .dsInfoButtonSize)
                            .background(Color.dsSurface.opacity(0.92), in: Circle())
                    }
                    .padding(.dsSpace4)
                    Spacer()
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
        .aspectRatio(1.68, contentMode: .fit)
        .clipped()
        .clipShape(RoundedRectangle(cornerRadius: .dsRadius5, style: .continuous))
    }

    private var fallbackHero: some View {
        HotdogIllustrationView(profile: profile)
    }

    private var titleRow: some View {
        HStack(alignment: .top, spacing: .dsSpace3) {
            VStack(alignment: .leading, spacing: .dsSpace1) {
                Text(profile.name)
                    .font(.title3.weight(.heavy))
                    .foregroundStyle(Color.dsInk)
                Text(profile.style)
                    .font(.callout)
                    .foregroundStyle(Color.dsMuted)
            }
            Spacer()
            DogSwipeStampView(text: stampText)
        }
    }

    private var stampText: String {
        if profile.style.localizedCaseInsensitiveContains("chicago") {
            return "Chicago\nStyle"
        }
        return "Street\nPick"
    }

    private var ratingLabel: String {
        let rating = min(4.9, 3.9 + profile.craveScore)
        return String(format: "%.1f", rating)
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

    private func chipIcon(for value: String) -> String {
        let lowered = value.lowercased()
        if lowered.contains("pickle") || lowered.contains("relish") {
            return "leaf.fill"
        }
        if lowered.contains("spicy") || lowered.contains("pepper") || lowered.contains("chili") {
            return "flame.fill"
        }
        if lowered.contains("beef") || lowered.contains("dog") {
            return "fork.knife"
        }
        return "sparkle"
    }
}

#Preview {
    HotdogCardView(profile: HotdogProfile.samples[0])
        .padding()
        .dsPageBackground()
}
