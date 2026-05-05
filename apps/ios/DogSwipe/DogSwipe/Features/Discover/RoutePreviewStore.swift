import DogSwipeCore
import Foundation
import MapKit

struct RouteEstimate: Equatable, Sendable {
    let walkingTimeMinutes: Int
    let distanceMiles: Double

    var walkingTimeLabel: String {
        "\(walkingTimeMinutes) min"
    }

    var distanceLabel: String {
        String(format: "%.1f mi", distanceMiles)
    }
}

protocol RouteEstimating: Sendable {
    func walkingRoute(
        from origin: DiscoveryLocation,
        to profile: HotdogProfile
    ) async throws -> RouteEstimate
}

enum RoutePreviewState: Equatable {
    case idle
    case loading
    case ready(RouteEstimate)
    case failed(String)
}

enum RoutePreviewError: Error {
    case missingDestination
    case noRoute
}

@MainActor
final class RoutePreviewStore: ObservableObject {
    @Published private(set) var state: RoutePreviewState = .idle

    private let routeEstimator: any RouteEstimating
    private var activeProfileID: String?

    init(routeEstimator: any RouteEstimating = MapKitRouteEstimator()) {
        self.routeEstimator = routeEstimator
    }

    func reset() {
        activeProfileID = nil
        state = .idle
    }

    func canPreview(profile: HotdogProfile, origin: DiscoveryLocation?) -> Bool {
        origin != nil && profile.latitude != nil && profile.longitude != nil
    }

    func preview(profile: HotdogProfile, origin: DiscoveryLocation?) async {
        let requestProfileID = profile.id
        activeProfileID = requestProfileID
        guard let origin else {
            state = .failed("Current location is unavailable.")
            return
        }
        guard profile.latitude != nil, profile.longitude != nil else {
            state = .failed("Route preview needs vendor coordinates.")
            return
        }
        state = .loading
        do {
            let estimate = try await routeEstimator.walkingRoute(from: origin, to: profile)
            guard activeProfileID == requestProfileID else {
                return
            }
            state = .ready(estimate)
        } catch {
            guard activeProfileID == requestProfileID else {
                return
            }
            state = .failed("Live walking route is unavailable.")
        }
    }
}

struct MapKitRouteEstimator: RouteEstimating {
    func walkingRoute(
        from origin: DiscoveryLocation,
        to profile: HotdogProfile
    ) async throws -> RouteEstimate {
        guard let latitude = profile.latitude, let longitude = profile.longitude else {
            throw RoutePreviewError.missingDestination
        }

        let request = MKDirections.Request()
        request.source = MKMapItem(
            placemark: MKPlacemark(
                coordinate: CLLocationCoordinate2D(
                    latitude: origin.latitude,
                    longitude: origin.longitude
                )
            )
        )
        request.destination = MKMapItem(
            placemark: MKPlacemark(
                coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            )
        )
        request.transportType = .walking

        let response = try await MKDirections(request: request).calculate()
        guard let route = response.routes.min(by: { lhs, rhs in
            lhs.expectedTravelTime < rhs.expectedTravelTime
        }) else {
            throw RoutePreviewError.noRoute
        }

        return RouteEstimate(
            walkingTimeMinutes: max(1, Int((route.expectedTravelTime / 60).rounded())),
            distanceMiles: route.distance / 1_609.344
        )
    }
}
