import DogSwipeCore
import SwiftUI

struct AdminReviewView: View {
    @ObservedObject private var store: AdminReviewStore

    @MainActor
    init(store: AdminReviewStore? = nil) {
        self.store = store ?? AdminReviewStore()
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: .dsSpace5) {
                    header
                    queue
                }
                .padding(.dsSpace5)
            }
            .navigationTitle("Review")
            .toolbar {
                if store.isReviewing {
                    ToolbarItem(placement: .topBarTrailing) {
                        ProgressView()
                            .controlSize(.small)
                    }
                }
            }
            .refreshable {
                await store.load()
            }
            .task {
                if store.pendingSubmissions.isEmpty {
                    await store.load()
                }
            }
            .dsPageBackground()
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: .dsSpace2) {
            Text("Pending vendor hotdogs")
                .font(.title2.weight(.semibold))
                .foregroundStyle(Color.dsInk)
            Text("Approve reviewed submissions into local discovery.")
                .font(.subheadline)
                .foregroundStyle(Color.dsMuted)
        }
    }

    private var queue: some View {
        VStack(alignment: .leading, spacing: .dsSpace3) {
            if store.pendingSubmissions.isEmpty {
                Text("No submissions waiting for review.")
                    .font(.subheadline)
                    .foregroundStyle(Color.dsMuted)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.dsSpace5)
                    .dsCardSurface()
            } else {
                ForEach(store.pendingSubmissions) { profile in
                    reviewRow(profile)
                }
            }

            if let message = store.reviewMessage {
                Text(message)
                    .font(.footnote)
                    .foregroundStyle(Color.dsMuted)
            }
        }
    }

    private func reviewRow(_ profile: HotdogProfile) -> some View {
        VStack(alignment: .leading, spacing: .dsSpace4) {
            SubmissionSummaryView(profile: profile)

            Button {
                Task {
                    await store.approve(profile)
                }
            } label: {
                Label("Approve", systemImage: "checkmark.seal.fill")
            }
            .buttonStyle(.borderedProminent)
            .disabled(store.isReviewing)
        }
        .tint(.dsPrimary)
        .padding(.dsSpace4)
        .dsCardSurface()
    }
}

#Preview {
    AdminReviewView()
}
