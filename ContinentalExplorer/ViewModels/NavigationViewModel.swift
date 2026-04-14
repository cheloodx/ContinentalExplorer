import SwiftUI
import MapKit
import Combine
import CoreLocation

// MARK: - Navigation View Model
@MainActor
final class NavigationViewModel: ObservableObject {

    // MARK: - Navigation State
    @Published var navigationMode: NavigationMode = .idle
    @Published var destination: Destination?
    @Published var transportMode: TransportMode = .car
    @Published var mapCameraPosition: MapCameraPosition = .automatic

    // MARK: - Speed & Location
    @Published var currentSpeed: Int = 0
    @Published var currentSpeedLimit: Int = 0
    @Published var speedStatus: SpeedStatus = .safe
    @Published var heading: Double = 0
    @Published var isFollowingUser: Bool = true
    @Published var currentRoadName: String = ""

    // MARK: - Route Info
    @Published var eta: String = "--:--"
    @Published var distanceRemaining: String = "--"
    @Published var timeRemaining: String = "--"
    @Published var arrivalTime: String = "--:--"

    // MARK: - Map
    @Published var showTrafficOverlay: Bool = true
    @Published var mapAnnotations: [MapAnnotationItem] = []
    @Published var routePolyline: MKRoute?

    // MARK: - Services
    let locationService: LocationService
    let alertService: AlertService
    let routeService: RouteService
    let voiceService: VoiceGuidanceService
    var webSocketService: WebSocketService?
    var soundManager: AlertSoundManager?

    // MARK: - Private
    private var cancellables = Set<AnyCancellable>()
    private var locationShareTimer: Timer?
    private let locationShareInterval: TimeInterval = 10.0
    private var earlyWarningAnnounced: Bool = false
    private var imminentTurnAnnounced: Bool = false

    init(
        locationService: LocationService,
        alertService: AlertService,
        routeService: RouteService = RouteService(),
        voiceService: VoiceGuidanceService = VoiceGuidanceService(),
        webSocketService: WebSocketService? = nil,
        soundManager: AlertSoundManager? = nil
    ) {
        self.locationService = locationService
        self.alertService = alertService
        self.routeService = routeService
        self.voiceService = voiceService
        self.webSocketService = webSocketService
        self.soundManager = soundManager
        setupBindings()
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
                self?.handleLocationUpdate(location)
            }
            .store(in: &cancellables)

        $speedStatus
            .removeDuplicates()
            .sink { [weak self] status in
                self?.soundManager?.speedAlert(status: status)
                if status == .danger {
                    self?.voiceService.speakSpeedWarning()
                }
            }
            .store(in: &cancellables)

        // Route updates
        routeService.$selectedRoute
            .compactMap { $0 }
            .sink { [weak self] route in
                self?.routePolyline = route.route
                self?.eta = route.arrivalTime
                self?.distanceRemaining = route.formattedDistance
                self?.timeRemaining = route.formattedETA
                self?.arrivalTime = route.arrivalTime
            }
            .store(in: &cancellables)

        routeService.$hasArrived
            .filter { $0 }
            .sink { [weak self] _ in
                self?.handleArrival()
            }
            .store(in: &cancellables)

        // Map annotations from alerts
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

        // Reset voice announcement flags when step changes
        routeService.$currentStepIndex
            .removeDuplicates()
            .sink { [weak self] _ in
                self?.earlyWarningAnnounced = false
                self?.imminentTurnAnnounced = false
            }
            .store(in: &cancellables)

        // Navigation step voice guidance
        routeService.$currentStepIndex
            .combineLatest(routeService.$distanceToNextStep)
            .sink { [weak self] stepIndex, distance in
                guard let self = self,
                      self.navigationMode == .navigating,
                      let step = self.routeService.currentStep else { return }
                let distStr = distance < 1000 ? "\(Int(distance)) meters" : String(format: "%.1f kilometers", distance / 1000)
                // Announce once at <500m (early warning) and once at <200m (imminent turn)
                if distance < 500 && !self.earlyWarningAnnounced {
                    self.earlyWarningAnnounced = true
                    self.voiceService.speakNavigationStep(
                        instruction: step.instruction,
                        distance: distStr
                    )
                } else if distance < 200 && !self.imminentTurnAnnounced {
                    self.imminentTurnAnnounced = true
                    self.voiceService.speakNavigationStep(
                        instruction: step.instruction,
                        distance: distStr
                    )
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - Location Updates
    private func handleLocationUpdate(_ location: CLLocation) {
        alertService.updateNearbyAlerts(currentLocation: location)

        if isFollowingUser {
            let pitch: Double = navigationMode == .navigating ? 60 : 45
            let distance: Double = navigationMode == .navigating ? 600 : 1000
            mapCameraPosition = .camera(
                MapCamera(
                    centerCoordinate: location.coordinate,
                    distance: distance,
                    heading: heading,
                    pitch: pitch
                )
            )
        }

        if navigationMode == .navigating {
            routeService.updateNavigation(currentLocation: location)
            // Update remaining distance/time
            if let route = routeService.selectedRoute {
                let stepsLeft = route.steps.suffix(from: routeService.currentStepIndex)
                let remainDist = stepsLeft.reduce(0.0) { $0 + $1.distance }
                distanceRemaining = remainDist < 1000 ?
                    "\(Int(remainDist)) m" :
                    String(format: "%.1f km", remainDist / 1000)
            }
        }
    }

    // MARK: - Navigation Control
    func setDestination(_ dest: Destination) {
        destination = dest
        navigationMode = .previewing
    }

    func startRouteCalculation() async {
        guard let dest = destination,
              let currentLoc = locationService.currentLocation else { return }
        await routeService.calculateRoute(
            from: currentLoc.coordinate,
            to: dest.coordinate,
            transportType: transportMode.mkTransportType
        )
    }

    func startNavigation() {
        guard routeService.selectedRoute != nil else { return }
        navigationMode = .navigating
        isFollowingUser = true
        locationService.startTracking()
        voiceService.speak("Starting navigation")
        setupLocationSharing()
    }

    func stopNavigation() {
        navigationMode = .idle
        destination = nil
        routeService.clearRoute()
        routePolyline = nil
        voiceService.speak("Navigation ended")
        locationShareTimer?.invalidate()
        locationShareTimer = nil
    }

    func recenterMap() {
        isFollowingUser = true
        if let location = locationService.currentLocation {
            handleLocationUpdate(location)
        }
    }

    func toggleTraffic() {
        showTrafficOverlay.toggle()
    }

    // MARK: - Arrival
    private func handleArrival() {
        navigationMode = .arrived
        voiceService.speakArrival()
        soundManager?.triggerHaptic(.success)
    }

    // MARK: - Location Sharing
    private func setupLocationSharing() {
        locationShareTimer?.invalidate()
        locationShareTimer = nil
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
}
