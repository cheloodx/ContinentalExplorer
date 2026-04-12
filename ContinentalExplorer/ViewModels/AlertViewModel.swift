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
    
    // MARK: - Private
    private let alertService: AlertService
    private var cancellables = Set<AnyCancellable>()
    
    init(alertService: AlertService) {
        self.alertService = alertService
        setupBindings()
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
        alertService.submitReport(report)
        isReportSheetPresented = false
    }
    
    func upvote(_ reportID: UUID) {
        alertService.upvoteReport(reportID)
    }
    
    func downvote(_ reportID: UUID) {
        alertService.downvoteReport(reportID)
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
}
