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
                if !profile.menuHighlightLabels.isEmpty {
                    DogSwipeChipGrid {
                        ForEach(profile.menuHighlightLabels.prefix(4), id: \.self) { highlight in
                            DogSwipeChip(text: highlight, systemImage: chipIcon(for: highlight))
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

                routeControls
            }
            .padding(.horizontal, .dsSpace4)
            .padding(.top, .dsSpace3)
            .padding(.bottom, .dsSpace4)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
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
                        Text(profile.priceLabel)
                            .font(.title3.weight(.heavy).monospacedDigit())
                            .foregroundStyle(Color.dsSurface)
                            .padding(.horizontal, .dsSpace3)
                            .padding(.vertical, .dsSpace2)
                            .background(Color.dsInk, in: RoundedRectangle(cornerRadius: .dsRadius3, style: .continuous))
                        Spacer()
                        DogSwipeStatusPill(
                            text: profile.availabilityStatus.cardLabel,
                            tint: profile.availabilityStatus.cardTint
                        )
                        .background(Color.dsSurface.opacity(0.88), in: Capsule())
                    }
                    .padding(.dsSpace4)
                    Spacer(minLength: .dsSpace8)

                    heroFooter
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
        .frame(maxWidth: .infinity, minHeight: .dsHeroMinimumHeight, maxHeight: .infinity)
        .clipped()
        .clipShape(
            UnevenRoundedRectangle(
                topLeadingRadius: .dsRadius5,
                bottomLeadingRadius: 0,
                bottomTrailingRadius: 0,
                topTrailingRadius: .dsRadius5,
                style: .continuous
            )
        )
    }

    private var heroFooter: some View {
        VStack(alignment: .leading, spacing: .dsSpace1) {
            Text(profile.vendorName.uppercased())
                .font(.caption2.weight(.heavy))
                .tracking(1.1)
                .foregroundStyle(Color.dsSurface.opacity(0.88))
                .lineLimit(1)

            HStack(alignment: .firstTextBaseline, spacing: .dsSpace2) {
                Text(profile.name)
                    .font(.title2.weight(.heavy))
                    .foregroundStyle(Color.dsSurface)
                    .lineLimit(2)
                    .minimumScaleFactor(0.82)
                inlineStampBadge
            }

            Text(profile.signatureNotes)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.dsSurface.opacity(0.92))
                .lineLimit(2)
                .padding(.top, .dsSpace1)
        }
        .shadow(color: .black.opacity(0.32), radius: 6, x: 0, y: 2)
        .padding(.horizontal, .dsSpace4)
        .padding(.top, .dsSpace8)
        .padding(.bottom, .dsSpace4)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [
                    .black.opacity(0.0),
                    .black.opacity(0.32),
                    .black.opacity(0.62)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }

    private var inlineStampBadge: some View {
        Text(inlineStampText)
            .font(.caption2.weight(.heavy))
            .tracking(0.6)
            .foregroundStyle(Color.dsInk)
            .padding(.horizontal, .dsSpace2)
            .padding(.vertical, .dsSpace1)
            .background(Color.dsSurface.opacity(0.92), in: Capsule())
            .fixedSize()
    }

    private var inlineStampText: String {
        if profile.style.localizedCaseInsensitiveContains("chicago") {
            return "CHICAGO"
        }
        return "STREET PICK"
    }

    private var fallbackHero: some View {
        HotdogIllustrationView(profile: profile)
    }

    private var ratingLabel: String {
        let rating = min(4.9, 3.9 + profile.craveScore)
        return String(format: "%.1f", rating)
    }

    @ViewBuilder
    private var routeControls: some View {
        if routePreviewStore.canPreview(profile: profile, origin: originLocation)
            || profile.directionsURL != nil {
            VStack(alignment: .leading, spacing: .dsSpace2) {
                RoutePreviewStatusView(state: routePreviewStore.state)
                routeActions
            }
            .padding(.top, .dsSpace1)
        }
    }

    private var routeActions: some View {
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

private extension AvailabilityStatus {
    var cardLabel: String {
        switch self {
        case .available:
            "Available now"
        case .limited:
            "Limited"
        case .soldOut:
            "Sold out"
        case .pendingReview:
            "Pending review"
        case .changesRequested:
            "Changes requested"
        case .rejected:
            "Rejected"
        }
    }

    var cardTint: Color {
        switch self {
        case .available:
            .dsRelish
        case .limited, .changesRequested:
            .dsPrimary
        case .soldOut:
            .dsMuted
        case .pendingReview:
            .dsSuper
        case .rejected:
            .dsTomato
        }
    }
}

#Preview {
    HotdogCardView(profile: HotdogProfile.samples[0])
        .padding()
        .dsPageBackground()
}
