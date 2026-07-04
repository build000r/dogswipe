import DogSwipeCore
import SwiftUI

struct SubmissionSummaryView: View {
    let profile: HotdogProfile

    var body: some View {
        VStack(alignment: .leading, spacing: .dsSpace2) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: .dsSpace1) {
                    Text(profile.name)
                        .font(.headline)
                        .foregroundStyle(Color.dsInk)
                    Text(profile.vendorName)
                        .font(.subheadline)
                        .foregroundStyle(Color.dsMuted)
                }
                Spacer()
                DogSwipeStatusPill(
                    text: profile.availabilityStatus.displayLabel,
                    tint: profile.availabilityStatus.displayTint
                )
            }

            HStack(spacing: .dsSpace4) {
                Text(profile.creditLabel)
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(Color.dsInk)
                Text(profile.style)
                    .font(.subheadline)
                    .foregroundStyle(Color.dsMuted)
            }

            if let addressText = profile.addressText, !addressText.isEmpty {
                Label(addressText, systemImage: "map")
                    .font(.caption)
                    .foregroundStyle(Color.dsMuted)
            }

            if let menuURL = profile.menuURL {
                Label(menuURL.host ?? menuURL.absoluteString, systemImage: "menucard")
                    .font(.caption)
                    .foregroundStyle(Color.dsMuted)
            }

            if profile.menuStatus != nil {
                Label(profile.menuStatusDisplayLabel, systemImage: "checklist")
                    .font(.caption)
                    .foregroundStyle(Color.dsMuted)
            }

            if !profile.menuHighlightLabels.isEmpty {
                Label(profile.menuHighlightLabels.joined(separator: " / "), systemImage: "menucard")
                    .font(.caption)
                    .foregroundStyle(Color.dsMuted)
                    .lineLimit(1)
            }

            if let menuExcerpt = profile.menuExcerpt, !menuExcerpt.isEmpty {
                Text(menuExcerpt)
                    .font(.caption)
                    .foregroundStyle(Color.dsMuted)
                    .lineLimit(2)
            }

            if let reviewNote = profile.reviewNote, !reviewNote.isEmpty {
                Label(reviewNote, systemImage: "text.bubble")
                    .font(.caption)
                    .foregroundStyle(Color.dsMuted)
            }
        }
    }
}

private extension HotdogProfile {
    var menuStatusDisplayLabel: String {
        switch menuStatus {
        case "ok":
            "Menu refreshed"
        case "empty":
            "Menu empty"
        case "invalid_url":
            "Menu URL invalid"
        case "fetch_failed":
            "Menu unavailable"
        case "missing_url":
            "Menu URL missing"
        default:
            "Menu checked"
        }
    }
}

private extension AvailabilityStatus {
    var displayLabel: String {
        switch self {
        case .available:
            "Available"
        case .limited:
            "Limited"
        case .soldOut:
            "Sold out"
        case .pendingReview:
            "Pending"
        case .changesRequested:
            "Edits needed"
        case .rejected:
            "Rejected"
        }
    }

    var displayTint: Color {
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
