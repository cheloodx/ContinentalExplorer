import SwiftUI
import MapKit

// MARK: - Map Display Style
enum MapDisplayStyle: String, CaseIterable {
    case standard = "Standard"
    case satellite = "Satellite"
    case hybrid = "Hybrid"
    case terrain = "Terrain"

    var iconName: String {
        switch self {
        case .standard: return "map.fill"
        case .satellite: return "globe.americas.fill"
        case .hybrid: return "square.stack.3d.up.fill"
        case .terrain: return "mountain.2.fill"
        }
    }
}

// MARK: - Map Style Manager
@MainActor
final class MapStyleManager: ObservableObject {
    @Published var currentStyle: MapDisplayStyle = .standard
    @Published var showTraffic: Bool = true
    @Published var showPointsOfInterest: Bool = false
    @Published var show3DBuildings: Bool = true
    @Published var isNightMode: Bool = false

    var mapStyle: MapStyle {
        switch currentStyle {
        case .standard:
            return .standard(
                elevation: show3DBuildings ? .realistic : .flat,
                emphasis: .muted,
                pointsOfInterest: showPointsOfInterest ? .all : .excludingAll,
                showsTraffic: showTraffic
            )
        case .satellite:
            return .imagery(elevation: show3DBuildings ? .realistic : .flat)
        case .hybrid:
            return .hybrid(
                elevation: show3DBuildings ? .realistic : .flat,
                pointsOfInterest: showPointsOfInterest ? .all : .excludingAll,
                showsTraffic: showTraffic
            )
        case .terrain:
            return .standard(
                elevation: .realistic,
                emphasis: .automatic,
                pointsOfInterest: showPointsOfInterest ? .all : .excludingAll,
                showsTraffic: showTraffic
            )
        }
    }

    func cycleStyle() {
        let allStyles = MapDisplayStyle.allCases
        guard let currentIndex = allStyles.firstIndex(of: currentStyle) else { return }
        let nextIndex = (currentIndex + 1) % allStyles.count
        currentStyle = allStyles[nextIndex]
    }
}
