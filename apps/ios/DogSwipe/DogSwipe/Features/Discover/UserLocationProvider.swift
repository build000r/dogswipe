import CoreLocation
import DogSwipeCore
import Foundation

@MainActor
protocol UserLocationProviding {
    func currentLocation() async -> DiscoveryLocation?
}

@MainActor
final class CoreLocationUserLocationProvider: NSObject, UserLocationProviding {
    private let manager: CLLocationManager
    private var authorizationContinuation: CheckedContinuation<CLAuthorizationStatus, Never>?
    private var locationContinuation: CheckedContinuation<DiscoveryLocation?, Never>?

    override init() {
        manager = CLLocationManager()
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    func currentLocation() async -> DiscoveryLocation? {
        let status = await authorizationStatus()
        guard status == .authorizedWhenInUse || status == .authorizedAlways else {
            return nil
        }
        if let cachedLocation = manager.location {
            return DiscoveryLocation(
                latitude: cachedLocation.coordinate.latitude,
                longitude: cachedLocation.coordinate.longitude
            )
        }
        return await requestLocation()
    }

    private func authorizationStatus() async -> CLAuthorizationStatus {
        switch manager.authorizationStatus {
        case .notDetermined:
            return await withCheckedContinuation { continuation in
                authorizationContinuation = continuation
                manager.requestWhenInUseAuthorization()
            }
        default:
            return manager.authorizationStatus
        }
    }

    private func requestLocation() async -> DiscoveryLocation? {
        await withCheckedContinuation { continuation in
            locationContinuation = continuation
            manager.requestLocation()
        }
    }

    private func finishAuthorization(_ status: CLAuthorizationStatus) {
        authorizationContinuation?.resume(returning: status)
        authorizationContinuation = nil
    }

    private func finishLocation(_ location: DiscoveryLocation?) {
        locationContinuation?.resume(returning: location)
        locationContinuation = nil
    }
}

struct ScreenshotUserLocationProvider: UserLocationProviding {
    func currentLocation() async -> DiscoveryLocation? {
        DiscoveryLocation(latitude: 43.6532, longitude: -79.3832)
    }
}

enum UserLocationProviderFactory {
    @MainActor
    static func defaultProvider() -> UserLocationProviding {
        AppEnvironment.isScreenshotMode
            ? ScreenshotUserLocationProvider()
            : CoreLocationUserLocationProvider()
    }
}

extension CoreLocationUserLocationProvider: CLLocationManagerDelegate {
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            finishAuthorization(manager.authorizationStatus)
        }
    }

    nonisolated func locationManager(
        _ manager: CLLocationManager,
        didUpdateLocations locations: [CLLocation]
    ) {
        let location = locations.last.map {
            DiscoveryLocation(
                latitude: $0.coordinate.latitude,
                longitude: $0.coordinate.longitude
            )
        }
        Task { @MainActor in
            finishLocation(location)
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            finishLocation(nil)
        }
    }
}
