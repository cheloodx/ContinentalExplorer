import SwiftUI
import MapKit
import Combine
import CoreLocation

// MARK: - Navigation State
enum NavigationState {
    case idle
    case navigating
    case rerouting
    case arrived
}

// MARK: - Navigation View Model
@MainActor
final class NavigationViewModel: ObservableObject {

    // MARK: - Published
    @Published var navigationState: NavigationState = .idle
    @Published var mapCameraPosition: MapCameraPosition = .automatic
    @Published var currentSpeed: Int = 0
    @Published var currentSpeedLimit: Int = 0
    @Published var speedStatus: SpeedStatus = .safe
    @Published var heading: Double = 0
    @Published var eta: String = "--:--"
    @Published var distanceRemaining: String = "--"
    @Published var currentRoadName: String = "Unknown Road"
    @Published var isFollowingUser: Bool = true
    @Published var showTrafficOverlay: Bool = true
    @Published var mapAnnotations: [MapAnnotationItem] = []

    // MARK: - Private
    private var cancellables = Set<AnyCancellable>()
    private let locationService: LocationService
    private let alertService: AlertService
    private var webSocketService: WebSocketService?
    private var soundManager: AlertSoundManager?
    private var locationShareTimer: Timer?
    private let locationShareInterval: TimeInterval = 10.0

    init(
        locationService: LocationService,
        alertService: AlertService,
        webSocketService: WebSocketService? = nil,
        soundManager: AlertSoundManager? = nil
    ) {
        self.locationService = locationService
        self.alertService = alertService
        self.webSocketService = webSocketService
        self.soundManager = soundManager
        setupBindings()
        setupLocationSharing()
    }

    // MARK: - Bindings
    private func setupBindings() {
        locationService.$currentSpeed
            .map { max(0, Int($0 * 3.6)) }
            .assign(to: &$currentSpeed)

        locationService.$speedStatus
            .assign(to: &$speedStatus)

        locationService.$currentHeading
            .assign(to: &$heading)

        locationService.$currentSpeedLimit
            .assign(to: &$currentSpeedLimit)

        locationService.$currentLocation
            .compactMap { $0 }
            .sink { [weak self] location in
                self?.updateMapPosition(location: location)
                self?.alertService.updateNearbyAlerts(currentLocation: location)
            }
            .store(in: &cancellables)

        // Monitor speed status changes for sound alerts
        $speedStatus
            .removeDuplicates()
            .sink { [weak self] status in
                self?.soundManager?.speedAlert(status: status)
            }
            .store(in: &cancellables)

        // Combine radar alerts and community reports for map annotations
        Publishers.CombineLatest(
            alertService.$radarAlerts,
            alertService.$communityReports
        )
        .map { radars, reports in
            var annotations: [MapAnnotationItem] = []

            annotations += radars.map { alert in
                MapAnnotationItem(
                    id: alert.id,
                    coordinate: alert.coordinate,
                    type: .radar(alert.type),
                    title: "\(alert.type.rawValue) - \(alert.speedLimit) km/h"
                )
            }

            annotations += reports.filter { !$0.isExpired }.map { report in
                MapAnnotationItem(
                    id: report.id,
                    coordinate: report.coordinate,
                    type: .communityReport(report.category),
                    title: report.category.rawValue
                )
            }

            return annotations
        }
        .assign(to: &$mapAnnotations)
    }

    // MARK: - Location Sharing via WebSocket
    private func setupLocationSharing() {
        guard let ws = webSocketService else { return }

        locationShareTimer = Timer.scheduledTimer(withTimeInterval: locationShareInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self = self,
                      let location = self.locationService.currentLocation else { return }
                await ws.sendLocationUpdate(
                    latitude: location.coordinate.latitude,
                    longitude: location.coordinate.longitude
                )
            }
        }
    }

    // MARK: - Map Control
    private func updateMapPosition(location: CLLocation) {
        guard isFollowingUser else { return }
        mapCameraPosition = .camera(
            MapCamera(
                centerCoordinate: location.coordinate,
                distance: 1000,
                heading: heading,
                pitch: 45
            )
        )
    }

    func centerOnUser() {
        isFollowingUser = true
        if let location = locationService.currentLocation {
            updateMapPosition(location: location)
        }
    }

    func toggleTraffic() {
        showTrafficOverlay.toggle()
    }

    // MARK: - Navigation
    func startNavigation() {
        navigationState = .navigating
        locationService.requestAuthorization()
        locationService.startTracking()
    }

    func stopNavigation() {
        navigationState = .idle
        locationService.stopTracking()
        locationShareTimer?.invalidate()
        locationShareTimer = nil
    }
}

// MARK: - Map Annotation Item
struct MapAnnotationItem: Identifiable {
    let id: UUID
    let coordinate: CLLocationCoordinate2D
    let type: AnnotationType
    let title: String

    enum AnnotationType {
        case radar(RadarType)
        case communityReport(ReportCategory)
        case userLocation
        case destination
    }
}
