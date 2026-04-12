import SwiftUI
import Combine
import CoreLocation

// MARK: - Alert View Model
@MainActor
final class AlertViewModel: ObservableObject {

    // MARK: - Published
    @Published var activeAlerts: [ActiveAlert] = []
    @Published var bannerAlert: ActiveAlert?
    @Published var isBannerVisible: Bool = false
    @Published var selectedCategory: ReportCategory?
    @Published var isReportSheetPresented: Bool = false
    @Published var communityReports: [CommunityReport] = []
    @Published var alertFeed: [AlertFeedItem] = []
    @Published var unreadAlertCount: Int = 0
    @Published var isSubmittingReport: Bool = false
    @Published var reportSubmissionStatus: ReportSubmissionStatus = .idle

    // MARK: - Report Submission Status
    enum ReportSubmissionStatus: Equatable {
        case idle
        case submitting
        case success
        case failed(String)
    }

    // MARK: - Private
    private let alertService: AlertService
    private var webSocketService: WebSocketService?
    private var soundManager: AlertSoundManager?
    private var cancellables = Set<AnyCancellable>()

    init(alertService: AlertService, webSocketService: WebSocketService? = nil, soundManager: AlertSoundManager? = nil) {
        self.alertService = alertService
        self.webSocketService = webSocketService
        self.soundManager = soundManager
        setupBindings()
        setupWebSocketBindings()
    }

    // MARK: - Bindings
    private func setupBindings() {
        alertService.$activeAlerts
            .assign(to: &$activeAlerts)

        alertService.$currentBannerAlert
            .assign(to: &$bannerAlert)

        alertService.$isAlertBannerVisible
            .assign(to: &$isBannerVisible)

        alertService.$communityReports
            .assign(to: &$communityReports)

        alertService.$alertFeed
            .assign(to: &$alertFeed)

        alertService.$unreadAlertCount
            .assign(to: &$unreadAlertCount)
    }

    private func setupWebSocketBindings() {
        guard let ws = webSocketService else { return }

        // Play sound when new community alert arrives
        ws.alertSubject
            .receive(on: DispatchQueue.main)
            .sink { [weak self] report in
                self?.soundManager?.alertReceived(severity: report.category.severity)
            }
            .store(in: &cancellables)

        // Play sound when new radar update arrives
        ws.radarUpdateSubject
            .receive(on: DispatchQueue.main)
            .sink { [weak self] radar in
                self?.soundManager?.radarDetected(type: radar.type)
            }
            .store(in: &cancellables)

        // Handle report acknowledgement from server
        ws.reportAckSubject
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.reportSubmissionStatus = .success
                self?.soundManager?.reportSubmitted()
                // Reset after delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    self?.reportSubmissionStatus = .idle
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - Actions
    func dismissBanner() {
        alertService.dismissBanner()
    }

    func presentReportSheet(category: ReportCategory? = nil) {
        selectedCategory = category
        isReportSheetPresented = true
    }

    func submitReport(
        category: ReportCategory,
        description: String,
        coordinate: CLLocationCoordinate2D
    ) {
        let report = CommunityReport(
            category: category,
            coordinate: coordinate,
            description: description,
            reporterID: UUID().uuidString
        )

        // Submit locally
        alertService.submitReport(report)
        isReportSheetPresented = false
        reportSubmissionStatus = .submitting
        isSubmittingReport = true

        // Submit via WebSocket for real-time broadcast
        if let ws = webSocketService {
            Task {
                await ws.submitReport(report)
                isSubmittingReport = false
                // If no ack comes within 3 seconds, mark as success anyway (optimistic)
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
                    if self?.reportSubmissionStatus == .submitting {
                        self?.reportSubmissionStatus = .success
                        self?.soundManager?.reportSubmitted()
                    }
                }
            }
        } else {
            isSubmittingReport = false
            reportSubmissionStatus = .success
            soundManager?.reportSubmitted()
        }
    }

    func upvote(_ reportID: UUID) {
        alertService.upvoteReport(reportID)
        soundManager?.triggerHaptic(.selection)

        // Send via WebSocket
        if let ws = webSocketService {
            Task {
                await ws.sendVote(reportID: reportID.uuidString, isUpvote: true)
            }
        }
    }

    func downvote(_ reportID: UUID) {
        alertService.downvoteReport(reportID)
        soundManager?.triggerHaptic(.selection)

        // Send via WebSocket
        if let ws = webSocketService {
            Task {
                await ws.sendVote(reportID: reportID.uuidString, isUpvote: false)
            }
        }
    }

    func markFeedRead() {
        alertService.markAllFeedRead()
    }

    func clearFeed() {
        alertService.clearFeed()
    }

    // MARK: - Computed
    var sortedAlerts: [ActiveAlert] {
        activeAlerts.sorted { $0.severity > $1.severity }
    }

    var alertCount: Int {
        activeAlerts.count
    }

    var hasActiveAlerts: Bool {
        !activeAlerts.isEmpty
    }

    var recentFeed: [AlertFeedItem] {
        Array(alertFeed.prefix(20))
    }
}
