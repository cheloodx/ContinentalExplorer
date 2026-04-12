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

// MARK: - Alert Feed Item
struct AlertFeedItem: Identifiable {
    let id: UUID
    let title: String
    let subtitle: String
    let iconName: String
    let severity: AlertSeverity
    let category: AlertFeedCategory
    let timestamp: Date
    let isNew: Bool

    enum AlertFeedCategory: String {
        case radar = "Radar"
        case community = "Community"
        case speed = "Speed"
        case system = "System"
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
    @Published var alertFeed: [AlertFeedItem] = []
    @Published var unreadAlertCount: Int = 0

    // MARK: - Private
    private var cancellables = Set<AnyCancellable>()
    private let proximityThreshold: CLLocationDistance = 5000
    private var dismissTimer: Timer?
    private let maxFeedItems = 100

    init() {
        setupNotificationListeners()
        loadSampleAlerts()
    }

    // MARK: - WebSocket Integration
    func bindToWebSocket(_ webSocketService: WebSocketService) {
        // Receive real-time community alerts
        webSocketService.alertSubject
            .receive(on: DispatchQueue.main)
            .sink { [weak self] report in
                self?.handleIncomingCommunityReport(report)
            }
            .store(in: &cancellables)

        // Receive real-time radar updates
        webSocketService.radarUpdateSubject
            .receive(on: DispatchQueue.main)
            .sink { [weak self] radar in
                self?.handleIncomingRadarUpdate(radar)
            }
            .store(in: &cancellables)

        // Handle expired alerts
        webSocketService.alertExpiredSubject
            .receive(on: DispatchQueue.main)
            .sink { [weak self] alertID in
                self?.handleAlertExpired(alertID)
            }
            .store(in: &cancellables)

        // Handle vote updates from other users
        webSocketService.voteUpdateSubject
            .receive(on: DispatchQueue.main)
            .sink { [weak self] update in
                self?.handleVoteUpdate(update)
            }
            .store(in: &cancellables)

        // Track nearby users count
        webSocketService.$nearbyUsersCount
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                // Could update UI based on nearby users
            }
            .store(in: &cancellables)
    }

    // MARK: - Incoming Real-time Data
    private func handleIncomingCommunityReport(_ report: CommunityReport) {
        // Avoid duplicates
        guard !communityReports.contains(where: { $0.id == report.id }) else { return }

        communityReports.insert(report, at: 0)
        removeExpiredReports()

        // Add to feed
        let feedItem = AlertFeedItem(
            id: report.id,
            title: report.category.rawValue,
            subtitle: report.description.isEmpty ? "Community report nearby" : report.description,
            iconName: report.category.iconName,
            severity: report.category.severity,
            category: .community,
            timestamp: report.timestamp,
            isNew: true
        )
        addToFeed(feedItem)
        unreadAlertCount += 1
    }

    private func handleIncomingRadarUpdate(_ radar: RadarAlert) {
        if let index = radarAlerts.firstIndex(where: { $0.id == radar.id }) {
            radarAlerts[index] = radar
        } else {
            radarAlerts.append(radar)

            let feedItem = AlertFeedItem(
                id: radar.id,
                title: "\(radar.type.rawValue) Radar",
                subtitle: "Speed limit: \(radar.speedLimit) km/h - \(radar.country)",
                iconName: radar.type.iconName,
                severity: .high,
                category: .radar,
                timestamp: radar.lastReported,
                isNew: true
            )
            addToFeed(feedItem)
            unreadAlertCount += 1
        }
    }

    private func handleAlertExpired(_ alertID: String) {
        guard let uuid = UUID(uuidString: alertID) else { return }
        communityReports.removeAll { $0.id == uuid }
        radarAlerts.removeAll { $0.id == uuid }

        let feedItem = AlertFeedItem(
            id: UUID(),
            title: "Alert Cleared",
            subtitle: "An alert in your area has been resolved",
            iconName: "checkmark.circle.fill",
            severity: .low,
            category: .system,
            timestamp: Date(),
            isNew: false
        )
        addToFeed(feedItem)
    }

    private func handleVoteUpdate(_ update: VoteUpdate) {
        guard let uuid = UUID(uuidString: update.reportID) else { return }
        if let index = communityReports.firstIndex(where: { $0.id == uuid }) {
            communityReports[index].upvotes = update.upvotes
            communityReports[index].downvotes = update.downvotes
        }
    }

    // MARK: - Feed Management
    private func addToFeed(_ item: AlertFeedItem) {
        alertFeed.insert(item, at: 0)
        if alertFeed.count > maxFeedItems {
            alertFeed = Array(alertFeed.prefix(maxFeedItems))
        }
    }

    func markAllFeedRead() {
        unreadAlertCount = 0
    }

    func clearFeed() {
        alertFeed.removeAll()
        unreadAlertCount = 0
    }

    // MARK: - Expired Report Cleanup
    private func removeExpiredReports() {
        communityReports.removeAll { $0.isExpired }
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
        communityReports.insert(report, at: 0)

        let feedItem = AlertFeedItem(
            id: report.id,
            title: "You reported: \(report.category.rawValue)",
            subtitle: report.description.isEmpty ? "Report submitted" : report.description,
            iconName: report.category.iconName,
            severity: report.category.severity,
            category: .community,
            timestamp: report.timestamp,
            isNew: false
        )
        addToFeed(feedItem)
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
            title: "\(alert.type.rawValue) Radar Ahead",
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
