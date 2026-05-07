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
                    DogSwipeScreenHeader(
                        title: "Review queue",
                        kicker: "\(store.pendingSubmissions.count) pending · admin"
                    ) {
                        refreshMenusButton
                    }
                    header
                    queue
                }
                .padding(.dsSpace5)
            }
            .safeAreaPadding(.bottom, .dsSpace8)
            .toolbar(.hidden, for: .navigationBar)
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
            .onAppear {
                DogSwipeAnalytics.shared.trackScreenViewed(.review)
            }
            .dsPageBackground()
            .accessibilityIdentifier("dogswipe.review.screen")
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: .dsSpace2) {
            DogSwipeSectionHeader(
                title: "Pending vendor hotdogs",
                subtitle: "Approve, reject, refresh stale menus, or send submissions back with review notes.",
                systemImage: "checkmark.seal.fill"
            )
        }
    }

    private var refreshMenusButton: some View {
        Button {
            Task {
                await store.refreshMenus()
            }
        } label: {
            Label("Refresh menus", systemImage: "arrow.triangle.2.circlepath")
        }
        .buttonStyle(.bordered)
        .disabled(store.isReviewing)
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

            TextField("Review note", text: reviewNoteBinding(for: profile), axis: .vertical)
                .lineLimit(2...4)
                .textFieldStyle(.roundedBorder)

            ViewThatFits(in: .horizontal) {
                HStack(spacing: .dsSpace3) {
                    actionButtons(profile)
                }

                VStack(alignment: .leading, spacing: .dsSpace3) {
                    actionButtons(profile)
                }
            }
        }
        .tint(.dsPrimary)
        .padding(.dsSpace4)
        .dsCardSurface()
    }

    @ViewBuilder
    private func actionButtons(_ profile: HotdogProfile) -> some View {
        Button {
            Task {
                await store.approve(profile)
            }
        } label: {
            Label("Approve", systemImage: "checkmark.seal.fill")
        }
        .buttonStyle(.borderedProminent)
        .disabled(store.isReviewing)

        Button {
            Task {
                await store.requestChanges(profile)
            }
        } label: {
            Label("Request Edits", systemImage: "arrow.uturn.backward")
        }
        .buttonStyle(.bordered)
        .disabled(store.isReviewing || store.trimmedReviewNote(for: profile).isEmpty)

        Button {
            Task {
                await store.reject(profile)
            }
        } label: {
            Label("Reject", systemImage: "xmark.seal")
        }
        .buttonStyle(.bordered)
        .disabled(store.isReviewing || store.trimmedReviewNote(for: profile).isEmpty)
    }

    private func reviewNoteBinding(for profile: HotdogProfile) -> Binding<String> {
        Binding(
            get: { store.reviewNotes[profile.id] ?? "" },
            set: { store.reviewNotes[profile.id] = $0 }
        )
    }
}

#Preview {
    AdminReviewView()
}
