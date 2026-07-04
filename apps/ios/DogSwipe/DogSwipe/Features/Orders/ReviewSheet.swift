import DogSwipeCore
import SwiftUI

struct ReviewSheet: View {
    let orderID: String
    let hotdogName: String
    let vendorName: String
    @ObservedObject var orderStore: OrderStore
    @Environment(\.dismiss) private var dismiss

    @State private var rating: Int = 0
    @State private var reviewText: String = ""
    @State private var isSubmitting = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: .dsSpace5) {
                    header
                    starPicker
                    textSection
                    submitButton
                }
                .padding(.horizontal, .dsSpace5)
                .padding(.top, .dsSpace5)
                .padding(.bottom, .dsSpace8)
            }
            .navigationTitle("Leave a Review")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .dsPageBackground()
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: .dsSpace2) {
            Text(hotdogName)
                .font(.title3.weight(.heavy))
                .foregroundStyle(Color.dsInk)
            Text("from \(vendorName)")
                .font(.subheadline)
                .foregroundStyle(Color.dsMuted)
        }
    }

    private var starPicker: some View {
        VStack(alignment: .leading, spacing: .dsSpace2) {
            Text("Rating")
                .font(.caption.weight(.heavy))
                .tracking(1)
                .foregroundStyle(Color.dsMuted)
                .textCase(.uppercase)

            HStack(spacing: .dsSpace2) {
                ForEach(1...5, id: \.self) { star in
                    Button {
                        rating = star
                    } label: {
                        Image(systemName: star <= rating ? "star.fill" : "star")
                            .font(.title)
                            .foregroundStyle(star <= rating ? Color.dsPrimary : Color.dsMuted.opacity(0.4))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(star) star\(star == 1 ? "" : "s")")
                }
            }
            .padding(.vertical, .dsSpace2)
        }
    }

    private var textSection: some View {
        VStack(alignment: .leading, spacing: .dsSpace2) {
            Text("Comments (optional)")
                .font(.caption.weight(.heavy))
                .tracking(1)
                .foregroundStyle(Color.dsMuted)
                .textCase(.uppercase)

            TextField("How was your experience?", text: $reviewText, axis: .vertical)
                .lineLimit(3...6)
                .textFieldStyle(.roundedBorder)
        }
    }

    private var submitButton: some View {
        Button {
            Task { await submit() }
        } label: {
            HStack {
                if isSubmitting {
                    ProgressView()
                        .controlSize(.small)
                        .tint(.white)
                }
                Text(isSubmitting ? "Submitting…" : "Submit Review")
                    .font(.headline.weight(.bold))
            }
            .frame(maxWidth: .infinity, minHeight: 48)
            .foregroundStyle(.white)
            .background(rating > 0 ? Color.dsPrimary : Color.dsMuted, in: RoundedRectangle(cornerRadius: .dsRadius3, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(rating == 0 || isSubmitting)

        if let error = orderStore.errorMessage {
            Text(error)
                .font(.caption.weight(.bold))
                .foregroundStyle(Color.dsAccent)
        }
    }

    private func submit() async {
        isSubmitting = true
        let request = ReviewCreateRequest(
            orderID: orderID,
            rateeUserID: vendorName,
            direction: .giverReviewsReceiver,
            rating: rating,
            text: reviewText.isEmpty ? nil : reviewText
        )
        await orderStore.submitReview(request: request)
        isSubmitting = false
        if orderStore.hasReviewed(orderID: orderID) {
            dismiss()
        }
    }
}
