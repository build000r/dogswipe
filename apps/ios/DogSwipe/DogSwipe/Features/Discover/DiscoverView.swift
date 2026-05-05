import DogSwipeCore
import SwiftUI

struct DiscoverView: View {
    @State private var allProfiles = DogProfile.samples
    @State private var deck = SwipeDeckState(profiles: DogProfile.samples)

    var body: some View {
        NavigationStack {
            VStack(spacing: .dsSpace5) {
                header

                if let profile = deck.currentProfile {
                    DogCardView(profile: profile)
                        .transition(.scale.combined(with: .opacity))
                } else {
                    emptyState
                }

                controls
            }
            .padding(.horizontal, .dsSpace5)
            .padding(.vertical, .dsSpace4)
            .navigationTitle("DogSwipe")
            .toolbarTitleDisplayMode(.inline)
            .dsPageBackground()
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: .dsSpace2) {
            Text("Best nearby fit")
                .font(.title2.weight(.semibold))
                .foregroundStyle(Color.dsInk)

            Text("\(deck.remainingCount) profiles ready for review")
                .font(.subheadline)
                .foregroundStyle(Color.dsMuted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var controls: some View {
        HStack(spacing: .dsSpace5) {
            SwipeActionButton(role: .pass) {
                advance(.pass)
            }
            SwipeActionButton(role: .superLike) {
                advance(.superLike)
            }
            SwipeActionButton(role: .like) {
                advance(.like)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var emptyState: some View {
        VStack(spacing: .dsSpace3) {
            Image(systemName: "checkmark.seal.fill")
                .font(.largeTitle)
                .foregroundStyle(Color.dsPrimary)
            Text("You reviewed every profile")
                .font(.headline)
                .foregroundStyle(Color.dsInk)
            Button("Start over") {
                allProfiles = DogProfile.samples
                deck = SwipeDeckState(profiles: allProfiles)
            }
            .buttonStyle(.borderedProminent)
            .tint(.dsPrimary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .dsCardSurface()
    }

    private func advance(_ decision: SwipeDecision) {
        withAnimation(.spring(response: 0.28, dampingFraction: 0.86)) {
            _ = deck.record(decision)
        }
    }
}

#Preview {
    DiscoverView()
}
