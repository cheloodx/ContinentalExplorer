import SwiftUI
import Combine
import CoreLocation

// MARK: - Report Submission Status
enum ReportSubmissionStatus: Equatable {
    case idle
    case submitting
    case success
    case failed(String)
}

// MARK: - Alert View Model
@MainActor
final class AlertViewModel: ObservableObject {
    @Published var communityReports: [CommunityReport] = []
    @Published var radarAlerts: [RadarAlert] = []
    @Published var isBannerVisible: Bool = false
    @Published var bannerAlert: CommunityReport?
    @Published var alertCount: Int = 0
    @Published var reportStatus: ReportSubmissionStatus = .idle
    @Published var alertFeed: [AlertFeedItem] = []
    @Published var unreadAlertCount: Int = 0

    private let alertService: AlertService
    private var soundManager: AlertSoundManager?
    private var webSocketService: WebSocketService?
    private var cancellables = Set<AnyCancellable>()

    init(
        alertService: AlertService,
        soundManager: AlertSoundManager? = nil,
        webSocketService: WebSocketService? = nil
    ) {
        self.alertService = alertService
        self.soundManager = soundManager
        self.webSocketService = webSocketService
        setupBindings()
    }

    private func setupBindings() {
        alertService.$communityReports
            .assign(to: &$communityReports)

        alertService.$radarAlerts
            .assign(to: &$radarAlerts)

        alertService.$communityReports
            .map { $0.count }
            .assign(to: &$alertCount)

        alertService.$alertFeed
            .assign(to: &$alertFeed)

        alertService.$alertFeed
            .map { feed in feed.filter { !$0.isRead }.count }
            .assign(to: &$unreadAlertCount)
    }

    func showBanner(for report: CommunityReport) {
        bannerAlert = report
        isBannerVisible = true
        soundManager?.alertReceived(severity: report.category.severity)

        DispatchQueue.main.asyncAfter(deadline: .now() + 5) { [weak self] in
            self?.dismissBanner()
        }
    }

    func dismissBanner() {
        isBannerVisible = false
        bannerAlert = nil
    }

    func submitReport(
        category: ReportCategory,
        description: String,
        coordinate: CLLocationCoordinate2D
    ) async {
        reportStatus = .submitting
        if let ws = webSocketService {
            await ws.submitReport(
                category: category.rawValue,
                latitude: coordinate.latitude,
                longitude: coordinate.longitude,
                description: description
            )
            reportStatus = .success
            soundManager?.reportSubmitted()
        } else {
            let report = CommunityReport(
                category: category,
                coordinate: coordinate,
                description: description,
                reporterID: "local-user"
            )
            alertService.addReport(report)
            reportStatus = .success
            soundManager?.reportSubmitted()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            self?.reportStatus = .idle
        }
    }

    func upvote(_ report: CommunityReport) {
        alertService.upvoteReport(report.id)
        soundManager?.triggerHaptic(.light)
    }

    func downvote(_ report: CommunityReport) {
        alertService.downvoteReport(report.id)
        soundManager?.triggerHaptic(.light)
    }

    func markFeedRead() {
        alertService.markAllFeedRead()
    }

    func clearFeed() {
        alertService.clearFeed()
    }
}

// MARK: - AlertFeedItem (if not already in AlertService)
struct AlertFeedItem: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let iconName: String
    let severity: AlertSeverity
    let timestamp: Date
    var isRead: Bool = false

    var timeAgo: String {
        let interval = Date().timeIntervalSince(timestamp)
        if interval < 60 { return "Just now" }
        if interval < 3600 { return "\(Int(interval / 60))m ago" }
        return "\(Int(interval / 3600))h ago"
    }
}
