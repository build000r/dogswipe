import DogSwipeCore
import SwiftUI

struct VendorView: View {
    @ObservedObject private var store: VendorSubmissionStore

    @MainActor
    init(store: VendorSubmissionStore? = nil) {
        self.store = store ?? VendorSubmissionStore()
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: .dsSpace5) {
                    submissionSection
                    submissionsSection
                }
                .padding(.dsSpace5)
            }
            .navigationTitle("Vendor")
            .toolbar {
                if store.isSyncing {
                    ToolbarItem(placement: .topBarTrailing) {
                        ProgressView()
                            .controlSize(.small)
                    }
                }
            }
            .task {
                if store.submissions.isEmpty {
                    await store.load()
                }
            }
            .dsPageBackground()
        }
    }

    private var submissionSection: some View {
        VStack(alignment: .leading, spacing: .dsSpace4) {
            VStack(alignment: .leading, spacing: .dsSpace2) {
                Text(store.isEditing ? "Revise hotdog" : "Submit a hotdog")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(Color.dsInk)
                Text(store.isEditing ? "Send the updated listing back to review." : "Send a menu item for review before it enters discovery.")
                    .font(.subheadline)
                    .foregroundStyle(Color.dsMuted)
            }

            field("Hotdog name", text: $store.name, icon: "fork.knife")
            field("Style", text: $store.style, icon: "tag")

            ViewThatFits(in: .horizontal) {
                HStack(spacing: .dsSpace3) {
                    numericField("Price", text: $store.price, icon: "dollarsign.circle")
                    numericField("Distance", text: $store.distance, icon: "location")
                }

                VStack(spacing: .dsSpace3) {
                    numericField("Price", text: $store.price, icon: "dollarsign.circle")
                    numericField("Distance", text: $store.distance, icon: "location")
                }
            }

            field("Vendor name", text: $store.vendorName, icon: "storefront")
            field("Signature notes", text: $store.signatureNotes, icon: "text.quote")
            field("Image URL", text: $store.imageURL, icon: "photo")
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
            field("Menu URL", text: $store.menuURL, icon: "menucard")
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
            field("Image description", text: $store.mediaAltText, icon: "captions.bubble")

            HStack(spacing: .dsSpace3) {
                Button {
                    Task {
                        await store.submit()
                    }
                } label: {
                    Label(
                        store.isEditing ? "Resubmit" : "Submit",
                        systemImage: "tray.and.arrow.up.fill"
                    )
                }
                .buttonStyle(.borderedProminent)
                .disabled(!store.canSubmit || store.isSyncing)

                if store.isEditing {
                    Button {
                        store.cancelEditing()
                    } label: {
                        Label("Cancel", systemImage: "xmark")
                    }
                    .buttonStyle(.bordered)
                    .disabled(store.isSyncing)
                }
            }

            if let message = store.message {
                Text(message)
                    .font(.footnote)
                    .foregroundStyle(Color.dsMuted)
            }
        }
        .tint(.dsPrimary)
        .padding(.dsSpace5)
        .dsCardSurface()
    }

    private var submissionsSection: some View {
        VStack(alignment: .leading, spacing: .dsSpace3) {
            Text("Your submissions")
                .font(.title2.weight(.semibold))
                .foregroundStyle(Color.dsInk)

            if store.submissions.isEmpty {
                Text("No vendor hotdogs submitted yet.")
                    .font(.subheadline)
                    .foregroundStyle(Color.dsMuted)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.dsSpace5)
                    .dsCardSurface()
            } else {
                ForEach(store.submissions) { profile in
                    submissionRow(profile)
                }
            }
        }
    }

    private func submissionRow(_ profile: HotdogProfile) -> some View {
        VStack(alignment: .leading, spacing: .dsSpace3) {
            SubmissionSummaryView(profile: profile)

            if profile.canBeEditedByVendor {
                Button {
                    store.edit(profile)
                } label: {
                    Label("Edit", systemImage: "pencil")
                }
                .buttonStyle(.bordered)
                .disabled(store.isSyncing)
            }
        }
        .padding(.dsSpace4)
        .dsCardSurface()
    }

    private func field(
        _ title: String,
        text: Binding<String>,
        icon: String
    ) -> some View {
        TextField(text: text) {
            Label(title, systemImage: icon)
        }
    }

    private func numericField(
        _ title: String,
        text: Binding<String>,
        icon: String
    ) -> some View {
        field(title, text: text, icon: icon)
            .keyboardType(.decimalPad)
    }
}

#Preview {
    VendorView()
}

private extension HotdogProfile {
    var canBeEditedByVendor: Bool {
        availabilityStatus == .changesRequested || availabilityStatus == .pendingReview
    }
}
