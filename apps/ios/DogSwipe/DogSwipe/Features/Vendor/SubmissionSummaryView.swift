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
                Text(profile.availabilityStatus.displayLabel)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.dsPrimary)
            }

            HStack(spacing: .dsSpace4) {
                Text(profile.priceLabel)
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(Color.dsInk)
                Text(profile.style)
                    .font(.subheadline)
                    .foregroundStyle(Color.dsMuted)
            }

            if let menuURL = profile.menuURL {
                Label(menuURL.host ?? menuURL.absoluteString, systemImage: "menucard")
                    .font(.caption)
                    .foregroundStyle(Color.dsMuted)
            }

            if let reviewNote = profile.reviewNote, !reviewNote.isEmpty {
                Label(reviewNote, systemImage: "text.bubble")
                    .font(.caption)
                    .foregroundStyle(Color.dsMuted)
            }
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
}
