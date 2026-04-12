import Foundation
import CoreLocation
import Combine
import MapKit

// MARK: - Location Service
@MainActor
final class LocationService: NSObject, ObservableObject {
    
    // MARK: - Published Properties
    @Published var currentLocation: CLLocation?
    @Published var currentSpeed: CLLocationSpeed = 0
    @Published var currentHeading: CLLocationDirection = 0
    @Published var currentSpeedLimit: Int = 0
    @Published var speedStatus: SpeedStatus = .safe
    @Published var isAuthorized: Bool = false
    @Published var mapRegion: MKCoordinateRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 48.8566, longitude: 2.3522),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    @Published var nearbyRadarAlerts: [RadarAlert] = []
    @Published var activeGeoFences: [CLCircularRegion] = []
    
    // MARK: - Private
    private let locationManager = CLLocationManager()
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Configuration
    private let speedWarningThreshold: Double = 0.9
    private let radarDetectionRadius: CLLocationDistance = 2000
    
    override init() {
        super.init()
        setupLocationManager()
    }
    
    // MARK: - Setup
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        locationManager.activityType = .automotiveNavigation
        locationManager.distanceFilter = 5
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.pausesLocationUpdatesAutomatically = false
        locationManager.showsBackgroundLocationIndicator = true
    }
    
    // MARK: - Public Methods
    func requestAuthorization() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    func startTracking() {
        locationManager.startUpdatingLocation()
        locationManager.startUpdatingHeading()
    }
    
    func stopTracking() {
        locationManager.stopUpdatingLocation()
        locationManager.stopUpdatingHeading()
    }
    
    // MARK: - Geo-Fencing
    func registerRadarGeoFence(for alert: RadarAlert) {
        let region = CLCircularRegion(
            center: alert.coordinate,
            radius: radarDetectionRadius,
            identifier: alert.id.uuidString
        )
        region.notifyOnEntry = true
        region.notifyOnExit = true
        locationManager.startMonitoring(for: region)
        activeGeoFences.append(region)
    }
    
    func removeAllGeoFences() {
        for region in locationManager.monitoredRegions {
            locationManager.stopMonitoring(for: region)
        }
        activeGeoFences.removeAll()
    }
    
    // MARK: - Speed Analysis
    private func updateSpeedStatus() {
        guard currentSpeedLimit > 0 else {
            speedStatus = .safe
            return
        }
        
        let speedKmh = currentSpeed * 3.6
        let limitDouble = Double(currentSpeedLimit)
        
        if speedKmh > limitDouble {
            speedStatus = .danger
        } else if speedKmh > limitDouble * speedWarningThreshold {
            speedStatus = .warning
        } else {
            speedStatus = .safe
        }
    }
    
    // MARK: - Distance Calculation
    func distance(to coordinate: CLLocationCoordinate2D) -> CLLocationDistance? {
        guard let current = currentLocation else { return nil }
        let target = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        return current.distance(from: target)
    }
    
    var speedInKmh: Int {
        max(0, Int(currentSpeed * 3.6))
    }
}

// MARK: - CLLocationManagerDelegate
extension LocationService: CLLocationManagerDelegate {
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        Task { @MainActor in
            self.currentLocation = location
            self.currentSpeed = max(0, location.speed)
            self.mapRegion = MKCoordinateRegion(
                center: location.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            )
            self.updateSpeedStatus()
        }
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        Task { @MainActor in
            self.currentHeading = newHeading.trueHeading
        }
    }
    
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            switch manager.authorizationStatus {
            case .authorizedWhenInUse, .authorizedAlways:
                self.isAuthorized = true
                self.startTracking()
            case .denied, .restricted:
                self.isAuthorized = false
            case .notDetermined:
                self.isAuthorized = false
            @unknown default:
                self.isAuthorized = false
            }
        }
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        guard let circularRegion = region as? CLCircularRegion else { return }
        Task { @MainActor in
            NotificationCenter.default.post(
                name: .radarRegionEntered,
                object: nil,
                userInfo: ["regionID": circularRegion.identifier]
            )
        }
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        guard let circularRegion = region as? CLCircularRegion else { return }
        Task { @MainActor in
            NotificationCenter.default.post(
                name: .radarRegionExited,
                object: nil,
                userInfo: ["regionID": circularRegion.identifier]
            )
        }
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let radarRegionEntered = Notification.Name("radarRegionEntered")
    static let radarRegionExited = Notification.Name("radarRegionExited")
}
