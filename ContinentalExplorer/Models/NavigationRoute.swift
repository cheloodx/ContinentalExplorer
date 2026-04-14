import Foundation
import MapKit
import CoreLocation

// MARK: - Destination
struct Destination: Identifiable, Equatable {
    let id = UUID()
    let name: String
    let address: String
    let coordinate: CLLocationCoordinate2D
    let mapItem: MKMapItem?

    static func == (lhs: Destination, rhs: Destination) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Navigation Mode
enum NavigationMode: String {
    case idle = "Idle"
    case previewing = "Preview"
    case navigating = "Navigating"
    case arrived = "Arrived"
    case rerouting = "Rerouting"
}

// MARK: - Transport Mode
enum TransportMode: String, CaseIterable {
    case car = "Car"
    case walking = "Walking"

    var iconName: String {
        switch self {
        case .car: return "car.fill"
        case .walking: return "figure.walk"
        }
    }

    var mkTransportType: MKDirectionsTransportType {
        switch self {
        case .car: return .automobile
        case .walking: return .walking
        }
    }
}
