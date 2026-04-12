import Foundation
import CoreLocation
import Combine

// MARK: - Active Alert
struct ActiveAlert: Identifiable {
    let id: UUID
    let title: String
    let subtitle: String
    let iconName: String
    let severity: AlertSeverity
    let distance: CLLocationDistance?
    let timestamp: Date
    
    var distanceText: String {
        guard let distance = distance else { return "" }
        if distance < 1000 {
            return "\(Int(distance))m"
        }
        return String(format: "%.1fkm", distance / 1000)
    }
}

// MARK: - Alert Service
@MainActor
final class AlertService: ObservableObject {
    
    // MARK: - Published
    @Published var radarAlerts: [RadarAlert] = []
    @Published var communityReports: [CommunityReport] = []
    @Published var activeAlerts: [ActiveAlert] = []
    @Published var currentBannerAlert: ActiveAlert?
    @Published var isAlertBannerVisible: Bool = false
    
    // MARK: - Private
    private var cancellables = Set<AnyCancellable>()
    private let proximityThreshold: CLLocationDistance = 5000
    private var dismissTimer: Timer?
    
    init() {
        setupNotificationListeners()
        loadSampleAlerts()
    }
    
    // MARK: - Setup
    private func setupNotificationListeners() {
        NotificationCenter.default.publisher(for: .radarRegionEntered)
            .compactMap { $0.userInfo?["regionID"] as? String }
            .sink { [weak self] regionID in
                Task { @MainActor in
                    self?.handleRadarRegionEntered(regionID: regionID)
                }
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: .radarRegionExited)
            .compactMap { $0.userInfo?["regionID"] as? String }
            .sink { [weak self] regionID in
                Task { @MainActor in
                    self?.handleRadarRegionExited(regionID: regionID)
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Alert Processing
    func updateNearbyAlerts(currentLocation: CLLocation) {
        let nearby = radarAlerts.filter { alert in
            let alertLocation = CLLocation(
                latitude: alert.coordinate.latitude,
                longitude: alert.coordinate.longitude
            )
            return currentLocation.distance(from: alertLocation) <= proximityThreshold
        }
        
        activeAlerts = nearby.map { alert in
            let alertLocation = CLLocation(
                latitude: alert.coordinate.latitude,
                longitude: alert.coordinate.longitude
            )
            let distance = currentLocation.distance(from: alertLocation)
            
            return ActiveAlert(
                id: alert.id,
                title: "\(alert.type.rawValue) Radar",
                subtitle: "Speed limit: \(alert.speedLimit) km/h",
                iconName: alert.type.iconName,
                severity: distance < 500 ? .critical : distance < 1000 ? .high : .medium,
                distance: distance,
                timestamp: alert.lastReported
            )
        }
        .sorted { ($0.distance ?? .infinity) < ($1.distance ?? .infinity) }
        
        if let closest = activeAlerts.first, closest.distance ?? .infinity < 1000 {
            showBannerAlert(closest)
        }
    }
    
    // MARK: - Banner
    func showBannerAlert(_ alert: ActiveAlert) {
        currentBannerAlert = alert
        withAnimation(DesignTokens.Animation.spring) {
            isAlertBannerVisible = true
        }
        
        dismissTimer?.invalidate()
        dismissTimer = Timer.scheduledTimer(withTimeInterval: 8.0, repeats: false) { [weak self] _ in
            Task { @MainActor in
                self?.dismissBanner()
            }
        }
    }
    
    func dismissBanner() {
        withAnimation(DesignTokens.Animation.spring) {
            isAlertBannerVisible = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.currentBannerAlert = nil
        }
    }
    
    // MARK: - Community Reports
    func submitReport(_ report: CommunityReport) {
        communityReports.append(report)
    }
    
    func upvoteReport(_ reportID: UUID) {
        if let index = communityReports.firstIndex(where: { $0.id == reportID }) {
            communityReports[index].upvotes += 1
        }
    }
    
    func downvoteReport(_ reportID: UUID) {
        if let index = communityReports.firstIndex(where: { $0.id == reportID }) {
            communityReports[index].downvotes += 1
        }
    }
    
    // MARK: - Handlers
    private func handleRadarRegionEntered(regionID: String) {
        guard let alert = radarAlerts.first(where: { $0.id.uuidString == regionID }) else { return }
        
        let activeAlert = ActiveAlert(
            id: alert.id,
            title: "⚠️ \(alert.type.rawValue) Radar Ahead",
            subtitle: "Limit: \(alert.speedLimit) km/h",
            iconName: alert.type.iconName,
            severity: .critical,
            distance: nil,
            timestamp: Date()
        )
        showBannerAlert(activeAlert)
    }
    
    private func handleRadarRegionExited(regionID: String) {
        if currentBannerAlert?.id.uuidString == regionID {
            dismissBanner()
        }
    }
    
    // MARK: - Sample Data
    private func loadSampleAlerts() {
        radarAlerts = [
            RadarAlert(
                type: .fixed,
                coordinate: CLLocationCoordinate2D(latitude: 48.8584, longitude: 2.2945),
                speedLimit: 50,
                country: "France"
            ),
            RadarAlert(
                type: .mobile,
                coordinate: CLLocationCoordinate2D(latitude: 48.8738, longitude: 2.2950),
                speedLimit: 70,
                country: "France"
            ),
            RadarAlert(
                type: .average,
                coordinate: CLLocationCoordinate2D(latitude: 52.5163, longitude: 13.3777),
                speedLimit: 100,
                country: "Germany"
            ),
            RadarAlert(
                type: .fixed,
                coordinate: CLLocationCoordinate2D(latitude: 44.4268, longitude: 26.1025),
                speedLimit: 50,
                country: "Romania"
            ),
        ]
        
        communityReports = [
            CommunityReport(
                category: .police,
                coordinate: CLLocationCoordinate2D(latitude: 48.8600, longitude: 2.3000),
                description: "Police checkpoint near Eiffel Tower",
                reporterID: "user_001"
            ),
            CommunityReport(
                category: .hazard,
                coordinate: CLLocationCoordinate2D(latitude: 52.5200, longitude: 13.4050),
                description: "Pothole on highway exit",
                reporterID: "user_002"
            ),
        ]
    }
}
