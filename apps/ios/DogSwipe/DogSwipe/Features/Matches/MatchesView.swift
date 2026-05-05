import DogSwipeCore
import SwiftUI

struct MatchesView: View {
    private let matches = MatchScorer.ranked(
        profiles: DogProfile.samples,
        preferences: DiscoveryPreferences()
    )

    var body: some View {
        NavigationStack {
            List(matches) { profile in
                HStack(spacing: .dsSpace3) {
                    Image(systemName: "pawprint.fill")
                        .foregroundStyle(Color.dsPrimary)
                    VStack(alignment: .leading, spacing: .dsSpace1) {
                        Text(profile.name)
                            .font(.headline)
                        Text(profile.shelterName)
                            .font(.subheadline)
                            .foregroundStyle(Color.dsMuted)
                    }
                    Spacer()
                    Text("\(Int(profile.compatibilityScore * 100))%")
                        .font(.headline.monospacedDigit())
                        .foregroundStyle(Color.dsPrimary)
                }
                .padding(.vertical, .dsSpace2)
            }
            .navigationTitle("Matches")
        }
    }
}

#Preview {
    MatchesView()
}
