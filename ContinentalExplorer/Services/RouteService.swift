import Foundation
import MapKit
import Combine

// MARK: - Route Step
struct RouteStep: Identifiable {
    let id = UUID()
    let instruction: String
    let distance: CLLocationDistance
    let polyline: MKPolyline
    let maneuverType: ManeuverType
    let streetName: String

    var formattedDistance: String {
        if distance < 1000 {
            return "\(Int(distance)) m"
        } else {
            return String(format: "%.1f km", distance / 1000)
        }
    }
}

// MARK: - Maneuver Type
enum ManeuverType: String {
    case straight = "arrow.up"
    case turnLeft = "arrow.turn.up.left"
    case turnRight = "arrow.turn.up.right"
    case slightLeft = "arrow.up.left"
    case slightRight = "arrow.up.right"
    case uTurn = "arrow.uturn.down"
    case merge = "arrow.merge"
    case exitHighway = "arrow.up.right"
    case roundabout = "arrow.triangle.capsulepath"
    case arrive = "flag.checkered"
    case depart = "location.fill"

    var displayName: String {
        switch self {
        case .straight: return "Continue straight"
        case .turnLeft: return "Turn left"
        case .turnRight: return "Turn right"
        case .slightLeft: return "Keep left"
        case .slightRight: return "Keep right"
        case .uTurn: return "Make a U-turn"
        case .merge: return "Merge"
        case .exitHighway: return "Take exit"
        case .roundabout: return "Roundabout"
        case .arrive: return "Arrive"
        case .depart: return "Depart"
        }
    }
}

// MARK: - Calculated Route
struct CalculatedRoute: Identifiable {
    let id = UUID()
    let route: MKRoute
    let steps: [RouteStep]
    let totalDistance: CLLocationDistance
    let totalTime: TimeInterval
    let name: String

    var formattedDistance: String {
        if totalDistance < 1000 {
            return "\(Int(totalDistance)) m"
        } else {
            return String(format: "%.1f km", totalDistance / 1000)
        }
    }

    var formattedETA: String {
        let hours = Int(totalTime) / 3600
        let minutes = (Int(totalTime) % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)min"
        } else {
            return "\(minutes) min"
        }
    }

    var arrivalTime: String {
        let arrival = Date().addingTimeInterval(totalTime)
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: arrival)
    }
}

// MARK: - Route Service
@MainActor
final class RouteService: ObservableObject {
    @Published var calculatedRoutes: [CalculatedRoute] = []
    @Published var selectedRoute: CalculatedRoute?
    @Published var isCalculating: Bool = false
    @Published var currentStepIndex: Int = 0
    @Published var distanceToNextStep: CLLocationDistance = 0
    @Published var hasArrived: Bool = false

    private let rerouteThreshold: CLLocationDistance = 50

    func calculateRoute(
        from source: CLLocationCoordinate2D,
        to destination: CLLocationCoordinate2D,
        transportType: MKDirectionsTransportType = .automobile
    ) async {
        isCalculating = true
        calculatedRoutes = []
        selectedRoute = nil
        currentStepIndex = 0
        hasArrived = false

        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: source))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: destination))
        request.transportType = transportType
        request.requestsAlternateRoutes = true

        let directions = MKDirections(request: request)

        do {
            let response = try await directions.calculate()
            calculatedRoutes = response.routes.enumerated().map { index, route in
                let steps = route.steps.filter { !$0.instructions.isEmpty }.map { step in
                    RouteStep(
                        instruction: step.instructions,
                        distance: step.distance,
                        polyline: step.polyline,
                        maneuverType: classifyManeuver(instruction: step.instructions),
                        streetName: step.instructions
                    )
                }
                return CalculatedRoute(
                    route: route,
                    steps: steps,
                    totalDistance: route.distance,
                    totalTime: route.expectedTravelTime,
                    name: index == 0 ? "Fastest Route" : "Alternative \(index)"
                )
            }
            if let first = calculatedRoutes.first {
                selectedRoute = first
            }
        } catch {
            calculatedRoutes = []
        }
        isCalculating = false
    }

    func selectRoute(_ route: CalculatedRoute) {
        selectedRoute = route
        currentStepIndex = 0
    }

    func updateNavigation(currentLocation: CLLocation) {
        guard let route = selectedRoute else { return }
        let steps = route.steps
        guard currentStepIndex < steps.count else {
            hasArrived = true
            return
        }

        let currentStep = steps[currentStepIndex]
        let stepEndPoint = currentStep.polyline.points()[currentStep.polyline.pointCount - 1].coordinate
        let distToEnd = currentLocation.distance(
            from: CLLocation(latitude: stepEndPoint.latitude, longitude: stepEndPoint.longitude)
        )
        distanceToNextStep = distToEnd

        if distToEnd < 30 && currentStepIndex < steps.count - 1 {
            currentStepIndex += 1
        }

        // Check arrival
        let lastCoord = route.route.polyline.points()[route.route.polyline.pointCount - 1]
        let distToEnd2 = currentLocation.distance(
            from: CLLocation(
                latitude: lastCoord.coordinate.latitude,
                longitude: lastCoord.coordinate.longitude
            )
        )
        if distToEnd2 < 50 {
            hasArrived = true
        }
    }

    var currentStep: RouteStep? {
        guard let route = selectedRoute,
              currentStepIndex < route.steps.count else { return nil }
        return route.steps[currentStepIndex]
    }

    var nextStep: RouteStep? {
        guard let route = selectedRoute,
              currentStepIndex + 1 < route.steps.count else { return nil }
        return route.steps[currentStepIndex + 1]
    }

    var formattedDistanceToNext: String {
        if distanceToNextStep < 1000 {
            return "\(Int(distanceToNextStep)) m"
        } else {
            return String(format: "%.1f km", distanceToNextStep / 1000)
        }
    }

    func clearRoute() {
        calculatedRoutes = []
        selectedRoute = nil
        currentStepIndex = 0
        distanceToNextStep = 0
        hasArrived = false
    }

    // MARK: - Private
    private func classifyManeuver(instruction: String) -> ManeuverType {
        let lower = instruction.lowercased()
        if lower.contains("turn left") || lower.contains("left onto") {
            return .turnLeft
        } else if lower.contains("turn right") || lower.contains("right onto") {
            return .turnRight
        } else if lower.contains("slight left") || lower.contains("keep left") {
            return .slightLeft
        } else if lower.contains("slight right") || lower.contains("keep right") {
            return .slightRight
        } else if lower.contains("u-turn") {
            return .uTurn
        } else if lower.contains("merge") {
            return .merge
        } else if lower.contains("exit") {
            return .exitHighway
        } else if lower.contains("roundabout") {
            return .roundabout
        } else if lower.contains("arrive") || lower.contains("destination") {
            return .arrive
        } else if lower.contains("depart") || lower.contains("head") {
            return .depart
        }
        return .straight
    }
}
