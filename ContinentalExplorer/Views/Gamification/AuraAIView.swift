import SwiftUI

// MARK: - Aura AI View (Road Health Scanner)
struct AuraAIView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @ObservedObject var auraService: AuraAIService

    @State private var selectedTab: AuraTab = .scanner

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: DesignTokens.Spacing.lg) {
                    // Scanner Status Header
                    scannerHeader

                    // Tab Selector
                    tabSelector

                    // Tab Content
                    switch selectedTab {
                    case .scanner:
                        scannerContent
                    case .history:
                        historyContent
                    case .hazards:
                        hazardsContent
                    }
                }
                .padding(.horizontal, DesignTokens.Spacing.md)
                .padding(.bottom, DesignTokens.Spacing.xxl)
            }
            .background(DesignTokens.Colors.backgroundDark)
            .navigationTitle("Aura AI")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }

    // MARK: - Scanner Header
    private var scannerHeader: some View {
        VStack(spacing: DesignTokens.Spacing.md) {
            // Road Health Score Circle
            ZStack {
                Circle()
                    .stroke(DesignTokens.Colors.surfaceSecondary, lineWidth: 8)
                    .frame(width: 120, height: 120)

                Circle()
                    .trim(from: 0, to: auraService.averageRoadHealth / 5.0)
                    .stroke(
                        ratingColor(for: auraService.currentRating),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.5), value: auraService.currentRating)

                VStack(spacing: 2) {
                    Image(systemName: auraService.currentRating.iconName)
                        .font(.system(size: 24))
                        .foregroundStyle(ratingColor(for: auraService.currentRating))
                    Text(auraService.currentRating.rawValue)
                        .font(Typography.bodyMedium(.sm))
                        .foregroundStyle(DesignTokens.Colors.textPrimary)
                }
            }

            Text("Road Health")
                .font(Typography.headline(.h4))
                .foregroundStyle(DesignTokens.Colors.textPrimary)

            // Confidence
            HStack(spacing: DesignTokens.Spacing.sm) {
                Image(systemName: "brain.head.profile")
                    .foregroundStyle(DesignTokens.Colors.primaryAccent)
                Text("Confidence: \(String(format: "%.0f%%", auraService.confidenceLevel * 100))")
                    .font(Typography.body(.sm))
                    .foregroundStyle(DesignTokens.Colors.textSecondary)
            }

            // Scan Toggle
            Button {
                if auraService.isScanning {
                    auraService.stopScanning()
                } else {
                    auraService.startScanning()
                }
            } label: {
                HStack(spacing: DesignTokens.Spacing.sm) {
                    Image(systemName: auraService.isScanning ? "stop.fill" : "play.fill")
                    Text(auraService.isScanning ? "Stop Scanning" : "Start Scanning")
                        .font(Typography.bodyMedium(.md))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, DesignTokens.Spacing.xl)
                .padding(.vertical, DesignTokens.Spacing.md)
                .background(auraService.isScanning ? DesignTokens.Colors.danger : DesignTokens.Colors.primaryAccent)
                .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.pill))
            }
            .buttonStyle(.plain)

            // Emotional State
            HStack(spacing: DesignTokens.Spacing.md) {
                emotionalStateCard
                stressLevelCard
            }
        }
        .padding(DesignTokens.Spacing.lg)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.xl))
    }

    private var emotionalStateCard: some View {
        VStack(spacing: DesignTokens.Spacing.xs) {
            Image(systemName: auraService.emotionalState.iconName)
                .font(.system(size: 24))
                .foregroundStyle(emotionalColor(for: auraService.emotionalState))
            Text(auraService.emotionalState.rawValue)
                .font(Typography.bodyMedium(.sm))
                .foregroundStyle(DesignTokens.Colors.textPrimary)
            Text("Emotional State")
                .font(Typography.body(.xxs))
                .foregroundStyle(DesignTokens.Colors.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(DesignTokens.Spacing.sm)
        .background(DesignTokens.Colors.surfacePrimary)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.md))
    }

    private var stressLevelCard: some View {
        VStack(spacing: DesignTokens.Spacing.xs) {
            Text(String(format: "%.0f%%", auraService.stressLevel * 100))
                .font(Typography.headline(.h3))
                .foregroundStyle(stressColor)
            Text("Stress Level")
                .font(Typography.body(.xxs))
                .foregroundStyle(DesignTokens.Colors.textTertiary)

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(DesignTokens.Colors.surfaceSecondary)
                        .frame(height: 4)
                    RoundedRectangle(cornerRadius: 3)
                        .fill(stressColor)
                        .frame(width: geometry.size.width * auraService.stressLevel, height: 4)
                }
            }
            .frame(height: 4)
        }
        .frame(maxWidth: .infinity)
        .padding(DesignTokens.Spacing.sm)
        .background(DesignTokens.Colors.surfacePrimary)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.md))
    }

    // MARK: - Tab Selector
    private var tabSelector: some View {
        HStack(spacing: DesignTokens.Spacing.xs) {
            ForEach(AuraTab.allCases, id: \.self) { tab in
                Button {
                    withAnimation(DesignTokens.Animation.spring) {
                        selectedTab = tab
                    }
                } label: {
                    HStack(spacing: DesignTokens.Spacing.xs) {
                        Image(systemName: tab.iconName)
                        Text(tab.rawValue)
                    }
                    .font(Typography.bodyMedium(.sm))
                    .foregroundStyle(selectedTab == tab ? .white : DesignTokens.Colors.textTertiary)
                    .padding(.horizontal, DesignTokens.Spacing.md)
                    .padding(.vertical, DesignTokens.Spacing.sm)
                    .background(selectedTab == tab ? DesignTokens.Colors.primaryAccent : Color.clear)
                    .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.pill))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(DesignTokens.Spacing.xs)
        .background(DesignTokens.Colors.surfacePrimary)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.pill))
    }

    // MARK: - Scanner Content
    private var scannerContent: some View {
        VStack(spacing: DesignTokens.Spacing.md) {
            // Summary Stats
            HStack(spacing: DesignTokens.Spacing.md) {
                ScanStatCard(
                    icon: "waveform.path",
                    value: "\(auraService.scanHistory.count)",
                    label: "Scans",
                    color: DesignTokens.Colors.primaryAccent
                )
                ScanStatCard(
                    icon: "exclamationmark.triangle.fill",
                    value: "\(auraService.hazardCount)",
                    label: "Hazards",
                    color: DesignTokens.Colors.warning
                )
                ScanStatCard(
                    icon: "gauge.medium",
                    value: String(format: "%.1f", auraService.averageRoadHealth),
                    label: "Avg Health",
                    color: DesignTokens.Colors.success
                )
            }

            // Latest Scan
            if let latest = auraService.scanHistory.first {
                LatestScanCard(result: latest)
            }
        }
    }

    // MARK: - History Content
    private var historyContent: some View {
        VStack(spacing: DesignTokens.Spacing.sm) {
            if auraService.scanHistory.isEmpty {
                emptyState(icon: "waveform.path", message: "No scans yet. Start scanning to analyze road conditions.")
            } else {
                ForEach(auraService.scanHistory.prefix(20)) { result in
                    ScanHistoryRow(result: result)
                }
            }
        }
    }

    // MARK: - Hazards Content
    private var hazardsContent: some View {
        VStack(spacing: DesignTokens.Spacing.sm) {
            if auraService.detectedHazards.isEmpty {
                emptyState(icon: "checkmark.shield.fill", message: "No hazards detected. Roads are looking clear!")
            } else {
                ForEach(auraService.detectedHazards) { hazard in
                    HazardRow(hazard: hazard)
                }
            }
        }
    }

    // MARK: - Empty State
    private func emptyState(icon: String, message: String) -> some View {
        VStack(spacing: DesignTokens.Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 40))
                .foregroundStyle(DesignTokens.Colors.textTertiary)
            Text(message)
                .font(Typography.body(.sm))
                .foregroundStyle(DesignTokens.Colors.textTertiary)
                .multilineTextAlignment(.center)
        }
        .padding(DesignTokens.Spacing.xxl)
    }

    // MARK: - Helpers
    private func ratingColor(for rating: RoadHealthRating) -> Color {
        switch rating {
        case .excellent: return DesignTokens.Colors.success
        case .good: return DesignTokens.Colors.info
        case .fair: return DesignTokens.Colors.warning
        case .poor, .dangerous: return DesignTokens.Colors.danger
        }
    }

    private func emotionalColor(for state: DrivingEmotionalState) -> Color {
        switch state {
        case .calm: return DesignTokens.Colors.success
        case .alert: return DesignTokens.Colors.info
        case .focused: return DesignTokens.Colors.warning
        case .stressed: return DesignTokens.Colors.danger
        }
    }

    private var stressColor: Color {
        if auraService.stressLevel > 0.7 { return DesignTokens.Colors.danger }
        if auraService.stressLevel > 0.4 { return DesignTokens.Colors.warning }
        return DesignTokens.Colors.success
    }
}

// MARK: - Aura Tab
enum AuraTab: String, CaseIterable {
    case scanner = "Scanner"
    case history = "History"
    case hazards = "Hazards"

    var iconName: String {
        switch self {
        case .scanner: return "waveform.path"
        case .history: return "clock.fill"
        case .hazards: return "exclamationmark.triangle.fill"
        }
    }
}

// MARK: - Sub Components
struct ScanStatCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: DesignTokens.Spacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(color)
            Text(value)
                .font(Typography.headline(.h4))
                .foregroundStyle(DesignTokens.Colors.textPrimary)
            Text(label)
                .font(Typography.body(.xxs))
                .foregroundStyle(DesignTokens.Colors.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(DesignTokens.Spacing.md)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.md))
    }
}

struct LatestScanCard: View {
    let result: RoadScanResult

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            HStack {
                Text("Latest Scan")
                    .font(Typography.headline(.h5))
                    .foregroundStyle(DesignTokens.Colors.textPrimary)
                Spacer()
                Text(result.confidencePercentage)
                    .font(Typography.body(.xs))
                    .foregroundStyle(DesignTokens.Colors.textTertiary)
            }

            HStack(spacing: DesignTokens.Spacing.md) {
                Image(systemName: result.rating.iconName)
                    .font(.system(size: 28))
                    .foregroundStyle(ratingColor(for: result.rating))

                VStack(alignment: .leading, spacing: 2) {
                    Text(result.rating.rawValue)
                        .font(Typography.bodyMedium(.md))
                        .foregroundStyle(DesignTokens.Colors.textPrimary)
                    if !result.roadName.isEmpty {
                        Text(result.roadName)
                            .font(Typography.body(.sm))
                            .foregroundStyle(DesignTokens.Colors.textSecondary)
                    }
                    Text("Surface: \(result.surfaceType)")
                        .font(Typography.body(.xs))
                        .foregroundStyle(DesignTokens.Colors.textTertiary)
                }
            }

            if !result.hazards.isEmpty {
                HStack(spacing: DesignTokens.Spacing.xs) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(DesignTokens.Colors.warning)
                    Text(result.hazards.joined(separator: ", "))
                        .font(Typography.body(.sm))
                        .foregroundStyle(DesignTokens.Colors.warning)
                }
            }
        }
        .padding(DesignTokens.Spacing.md)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.lg))
    }

    private func ratingColor(for rating: RoadHealthRating) -> Color {
        switch rating {
        case .excellent: return DesignTokens.Colors.success
        case .good: return DesignTokens.Colors.info
        case .fair: return DesignTokens.Colors.warning
        case .poor, .dangerous: return DesignTokens.Colors.danger
        }
    }
}

struct ScanHistoryRow: View {
    let result: RoadScanResult

    private var timeAgo: String {
        let interval = Date().timeIntervalSince(result.timestamp)
        if interval < 60 { return "Just now" }
        if interval < 3600 { return "\(Int(interval / 60))m ago" }
        return "\(Int(interval / 3600))h ago"
    }

    var body: some View {
        HStack(spacing: DesignTokens.Spacing.md) {
            Image(systemName: result.rating.iconName)
                .font(.system(size: 20))
                .foregroundStyle(ratingColor(for: result.rating))
                .frame(width: 36, height: 36)
                .background(ratingColor(for: result.rating).opacity(0.15))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(result.rating.rawValue)
                    .font(Typography.bodyMedium(.sm))
                    .foregroundStyle(DesignTokens.Colors.textPrimary)
                if !result.roadName.isEmpty {
                    Text(result.roadName)
                        .font(Typography.body(.xs))
                        .foregroundStyle(DesignTokens.Colors.textTertiary)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(result.confidencePercentage)
                    .font(Typography.body(.xs))
                    .foregroundStyle(DesignTokens.Colors.textTertiary)
                Text(timeAgo)
                    .font(Typography.body(.xxs))
                    .foregroundStyle(DesignTokens.Colors.textTertiary)
            }
        }
        .padding(DesignTokens.Spacing.sm)
        .background(DesignTokens.Colors.surfacePrimary)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.md))
    }

    private func ratingColor(for rating: RoadHealthRating) -> Color {
        switch rating {
        case .excellent: return DesignTokens.Colors.success
        case .good: return DesignTokens.Colors.info
        case .fair: return DesignTokens.Colors.warning
        case .poor, .dangerous: return DesignTokens.Colors.danger
        }
    }
}

struct HazardRow: View {
    let hazard: DetectedHazard

    var body: some View {
        HStack(spacing: DesignTokens.Spacing.md) {
            Image(systemName: hazard.type.iconName)
                .font(.system(size: 20))
                .foregroundStyle(DesignTokens.Colors.warning)
                .frame(width: 36, height: 36)
                .background(DesignTokens.Colors.warning.opacity(0.15))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(hazard.type.rawValue)
                    .font(Typography.bodyMedium(.sm))
                    .foregroundStyle(DesignTokens.Colors.textPrimary)
                Text(hazard.roadName)
                    .font(Typography.body(.xs))
                    .foregroundStyle(DesignTokens.Colors.textTertiary)
            }

            Spacer()

            Text(String(format: "%.0f%%", hazard.confidence * 100))
                .font(Typography.body(.xs))
                .foregroundStyle(DesignTokens.Colors.textTertiary)
        }
        .padding(DesignTokens.Spacing.sm)
        .background(DesignTokens.Colors.surfacePrimary)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.md))
    }
}
