import SwiftUI
import CoreLocation

// MARK: - Community Alert View
/// Shows list of community reports and allows submitting new ones
struct CommunityAlertView: View {
    @ObservedObject var viewModel: AlertViewModel
    @EnvironmentObject private var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                themeManager.backgroundColor
                    .ignoresSafeArea()
                
                ScrollView {
                    LazyVStack(spacing: DesignTokens.Spacing.md) {
                        // Quick report buttons
                        quickReportSection
                        
                        // Active reports
                        if !viewModel.communityReports.isEmpty {
                            reportsSection
                        } else {
                            emptyState
                        }
                    }
                    .padding(DesignTokens.Spacing.md)
                }
            }
            .navigationTitle("Community Alerts")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(DesignTokens.Colors.primaryAccent)
                }
            }
            .toolbarBackground(themeManager.surfaceColor, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }
    
    // MARK: - Quick Report Section
    private var quickReportSection: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            Text("Quick Report")
                .font(Typography.headline(.h5))
                .foregroundStyle(DesignTokens.Colors.textPrimary)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: DesignTokens.Spacing.sm) {
                ForEach(ReportCategory.allCases, id: \.rawValue) { category in
                    QuickReportButton(category: category) {
                        viewModel.presentReportSheet(category: category)
                    }
                }
            }
        }
        .padding(DesignTokens.Spacing.md)
        .background(DesignTokens.Colors.surfacePrimary)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.lg))
    }
    
    // MARK: - Reports Section
    private var reportsSection: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            Text("Active Reports")
                .font(Typography.headline(.h5))
                .foregroundStyle(DesignTokens.Colors.textPrimary)
            
            ForEach(viewModel.communityReports) { report in
                CommunityReportCard(
                    report: report,
                    onUpvote: { viewModel.upvote(report.id) },
                    onDownvote: { viewModel.downvote(report.id) }
                )
            }
        }
    }
    
    // MARK: - Empty State
    private var emptyState: some View {
        VStack(spacing: DesignTokens.Spacing.md) {
            Image(systemName: "checkmark.shield.fill")
                .font(.system(size: 48))
                .foregroundStyle(DesignTokens.Colors.success)
            
            Text("All Clear!")
                .font(Typography.headline(.h4))
                .foregroundStyle(DesignTokens.Colors.textPrimary)
            
            Text("No community reports in your area.\nBe the first to report!")
                .font(Typography.body(.sm))
                .foregroundStyle(DesignTokens.Colors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, DesignTokens.Spacing.xxxl)
    }
}

// MARK: - Quick Report Button
struct QuickReportButton: View {
    let category: ReportCategory
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: DesignTokens.Spacing.xs) {
                Image(systemName: category.iconName)
                    .font(.system(size: 22))
                    .foregroundStyle(severityColor)
                
                Text(category.rawValue)
                    .font(Typography.body(.xxs))
                    .foregroundStyle(DesignTokens.Colors.textSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, DesignTokens.Spacing.sm)
            .background(severityColor.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.sm))
        }
        .buttonStyle(.plain)
    }
    
    private var severityColor: Color {
        switch category.severity {
        case .low: return DesignTokens.Colors.info
        case .medium: return DesignTokens.Colors.warning
        case .high: return DesignTokens.Colors.secondaryAccent
        case .critical: return DesignTokens.Colors.danger
        }
    }
}

// MARK: - Community Report Card
struct CommunityReportCard: View {
    let report: CommunityReport
    let onUpvote: () -> Void
    let onDownvote: () -> Void
    
    var body: some View {
        HStack(spacing: DesignTokens.Spacing.md) {
            // Category icon
            Image(systemName: report.category.iconName)
                .font(.system(size: 24))
                .foregroundStyle(categoryColor)
                .frame(width: 44, height: 44)
                .background(categoryColor.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.sm))
            
            // Report info
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xxs) {
                Text(report.category.rawValue)
                    .font(Typography.bodySemiBold(.sm))
                    .foregroundStyle(DesignTokens.Colors.textPrimary)
                
                if !report.description.isEmpty {
                    Text(report.description)
                        .font(Typography.body(.xs))
                        .foregroundStyle(DesignTokens.Colors.textSecondary)
                        .lineLimit(2)
                }
                
                Text(report.timestamp, style: .relative)
                    .font(Typography.body(.xxs))
                    .foregroundStyle(DesignTokens.Colors.textTertiary)
            }
            
            Spacer()
            
            // Vote buttons
            VStack(spacing: DesignTokens.Spacing.xs) {
                Button(action: onUpvote) {
                    Image(systemName: "hand.thumbsup.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(DesignTokens.Colors.success)
                }
                
                Text("\(report.upvotes - report.downvotes)")
                    .font(Typography.hudLabel(size: 12))
                    .foregroundStyle(DesignTokens.Colors.textSecondary)
                
                Button(action: onDownvote) {
                    Image(systemName: "hand.thumbsdown.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(DesignTokens.Colors.danger)
                }
            }
            .buttonStyle(.plain)
        }
        .padding(DesignTokens.Spacing.md)
        .background(DesignTokens.Colors.surfacePrimary)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.md))
    }
    
    private var categoryColor: Color {
        switch report.category.severity {
        case .low: return DesignTokens.Colors.info
        case .medium: return DesignTokens.Colors.warning
        case .high: return DesignTokens.Colors.secondaryAccent
        case .critical: return DesignTokens.Colors.danger
        }
    }
}
