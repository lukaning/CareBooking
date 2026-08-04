import CoreLocation
import Foundation

/// Lightweight when-in-use location helper for onboarding.
@Observable
final class LocationManager: NSObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()

    var authorizationStatus: CLAuthorizationStatus
    var coordinate: CLLocationCoordinate2D?
    var addressLine: String?
    var isResolving = false
    var didFail = false

    /// Design fallback when GPS/geocode is unavailable.
    static let sampleAddress = "102 Centre Boulevard / Suite B, San Francisco"
    static let sampleCoordinate = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)

    var isAuthorized: Bool {
        switch authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse: true
        default: false
        }
    }

    override init() {
        authorizationStatus = manager.authorizationStatus
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    func requestWhenInUse() {
        manager.requestWhenInUseAuthorization()
    }

    func refreshIfAuthorized() {
        guard isAuthorized else { return }
        isResolving = true
        manager.requestLocation()
    }

    func useSampleLocation() {
        coordinate = Self.sampleCoordinate
        addressLine = Self.sampleAddress
        isResolving = false
        didFail = false
    }

    // MARK: - CLLocationManagerDelegate

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        if isAuthorized {
            isResolving = true
            manager.requestLocation()
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        coordinate = location.coordinate
        reverseGeocode(location)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        didFail = true
        isResolving = false
        // Keep UI usable in simulator / denied-hardware cases.
        if coordinate == nil {
            useSampleLocation()
        }
    }

    private func reverseGeocode(_ location: CLLocation) {
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, _ in
            guard let self else { return }
            defer { self.isResolving = false }
            guard let place = placemarks?.first else {
                if self.addressLine == nil {
                    self.useSampleLocation()
                }
                return
            }

            var parts: [String] = []
            if let number = place.subThoroughfare, let street = place.thoroughfare {
                parts.append("\(number) \(street)")
            } else if let street = place.thoroughfare {
                parts.append(street)
            }
            if let sub = place.subLocality {
                parts.append(sub)
            }
            if let city = place.locality {
                parts.append(city)
            }
            let joined = parts.joined(separator: ", ")
            self.addressLine = joined.isEmpty ? Self.sampleAddress : joined
            self.didFail = false
        }
    }
}
