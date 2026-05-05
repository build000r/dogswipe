import SwiftUI

struct RoutePreviewStatusView: View {
    let state: RoutePreviewState

    var body: some View {
        switch state {
        case .idle:
            EmptyView()
        case .loading:
            Label("Checking route", systemImage: "location.magnifyingglass")
                .font(.caption.weight(.medium))
                .foregroundStyle(Color.dsMuted)
        case .ready(let estimate):
            Label(
                "\(estimate.walkingTimeLabel) route, \(estimate.distanceLabel)",
                systemImage: "figure.walk"
            )
            .font(.caption.weight(.medium))
            .foregroundStyle(Color.dsPrimary)
        case .failed(let message):
            Label(message, systemImage: "exclamationmark.triangle")
                .font(.caption.weight(.medium))
                .foregroundStyle(Color.dsAccent)
        }
    }
}
