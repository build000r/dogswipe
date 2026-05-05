import DogSwipeCore
import SwiftUI

struct MatchesView: View {
    @StateObject private var viewModel: MatchesViewModel

    @MainActor
    init(viewModel: MatchesViewModel? = nil) {
        _viewModel = StateObject(wrappedValue: viewModel ?? MatchesViewModel())
    }

    var body: some View {
        NavigationStack {
            Group {
                if case .loading = viewModel.state {
                    ProgressView()
                        .tint(.dsPrimary)
                } else if viewModel.matches.isEmpty {
                    ContentUnavailableView("No matches yet", systemImage: "heart")
                } else {
                    List(viewModel.matches) { profile in
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
                }
            }
            .navigationTitle("Matches")
            .task {
                if case .idle = viewModel.state {
                    await viewModel.load()
                }
            }
        }
    }
}

#Preview {
    MatchesView()
}
