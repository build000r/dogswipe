import CoreLocation
import Foundation

struct VendorCoordinate: Equatable, Sendable {
    let latitude: Double
    let longitude: Double
}

@MainActor
protocol VendorAddressGeocoding {
    func coordinate(for address: String) async throws -> VendorCoordinate
}

@MainActor
final class CoreLocationVendorAddressGeocoder: VendorAddressGeocoding {
    private let geocoder: CLGeocoder

    init(geocoder: CLGeocoder = CLGeocoder()) {
        self.geocoder = geocoder
    }

    func coordinate(for address: String) async throws -> VendorCoordinate {
        let placemarks = try await geocoder.geocodeAddressString(address)
        guard let coordinate = placemarks.first?.location?.coordinate else {
            throw VendorAddressGeocodingError.noCoordinate
        }
        return VendorCoordinate(
            latitude: coordinate.latitude,
            longitude: coordinate.longitude
        )
    }
}

private enum VendorAddressGeocodingError: LocalizedError {
    case noCoordinate

    var errorDescription: String? {
        "Pickup address could not be located."
    }
}
