import SwiftUI

// MARK: - Live Alert Feed View
/// Real-time animated feed showing incoming alerts with live updates
struct LiveAlertFeedView: View {
    @ObservedObject var viewModel: AlertViewModel
    @EnvironmentObject private var themeManager: ThemeManager
    @EnvironmentObject private var webSocketService: WebSocketService
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                themeManager.backgroundColor
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Connection status bar
                    connectionStatusBar

                    if viewModel.alertFeed.isEmpty {
                        emptyFeedState
                    } else {
                        feedList
                    }
                }
            }
            .navigationTitle("Live Feed")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Clear") {
                        viewModel.clearFeed()
                    }
                    .foregroundStyle(DesignTokens.Colors.textSecondary)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(DesignTokens.Colors.primaryAccent)
                }
            }
            .toolbarBackground(themeManager.surfaceColor, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .onAppear {
                viewModel.markFeedRead()
            }
        }
    }

    // MARK: - Connection Status Bar
    private var connectionStatusBar: some View {
        HStack(spacing: DesignTokens.Spacing.sm) {
            Circle()
                .fill(connectionColor)
                .frame(width: 8, height: 8)

            Text(webSocketService.connectionState.statusText)
                .font(Typography.body(.xs))
                .foregroundStyle(DesignTokens.Colors.textSecondary)

            Spacer()

            if webSocketService.connectionState.isConnected {
                HStack(spacing: DesignTokens.Spacing.xxs) {
                    Text("\(webSocketService.latencyMs)ms")
                        .font(Typography.hudLabel(size: 10))
                        .foregroundStyle(DesignTokens.Colors.textTertiary)

                    ConnectionQualityBars(quality: webSocketService.connectionQuality)
                }
            }

            if webSocketService.nearbyUsersCount > 0 {
                HStack(spacing: DesignTokens.Spacing.xxs) {
                    Image(systemName: "person.2.fill")
                        .font(.system(size: 10))
                    Text("\(webSocketService.nearbyUsersCount)")
                        .font(Typography.hudLabel(size: 10))
                }
                .foregroundStyle(DesignTokens.Colors.primaryAccent)
            }
        }
        .padding(.horizontal, DesignTokens.Spacing.md)
        .padding(.vertical, DesignTokens.Spacing.sm)
        .background(DesignTokens.Colors.surfacePrimary)
    }

    // MARK: - Feed List
    private var feedList: some View {
        ScrollView {
            LazyVStack(spacing: DesignTokens.Spacing.sm) {
                ForEach(viewModel.recentFeed) { item in
                    AlertFeedCard(item: item)
                        .transition(.asymmetric(
                            insertion: .move(edge: .top).combined(with: .opacity),
                            removal: .opacity
                        ))
                }
            }
            .padding(DesignTokens.Spacing.md)
            .animation(
                themeManager.isAnimationReduced ? .none : .spring(response: 0.4),
                value: viewModel.alertFeed.count
            )
        }
    }

    // MARK: - Empty State
    private var emptyFeedState: some View {
        VStack(spacing: DesignTokens.Spacing.md) {
            Spacer()

            Image(systemName: "antenna.radiowaves.left.and.right")
                .font(.system(size: 48))
                .foregroundStyle(DesignTokens.Colors.primaryAccent.opacity(0.5))

            Text("Listening for Alerts")
                .font(Typography.headline(.h4))
                .foregroundStyle(DesignTokens.Colors.textPrimary)

            Text("Real-time alerts from the community\nwill appear here as they happen.")
                .font(Typography.body(.sm))
                .foregroundStyle(DesignTokens.Colors.textSecondary)
                .multilineTextAlignment(.center)

            if !webSocketService.connectionState.isConnected {
                Button {
                    webSocketService.manualReconnect()
                } label: {
                    Label("Reconnect", systemImage: "arrow.clockwise")
                        .font(Typography.bodySemiBold(.sm))
                        .foregroundStyle(.white)
                        .padding(.horizontal, DesignTokens.Spacing.lg)
                        .padding(.vertical, DesignTokens.Spacing.sm)
                        .background(DesignTokens.Colors.primaryAccent)
                        .clipShape(Capsule())
                }
            }

            Spacer()
        }
        .padding(DesignTokens.Spacing.md)
    }

    private var connectionColor: Color {
        switch webSocketService.connectionState {
        case .connected: return DesignTokens.Colors.success
        case .connecting, .reconnecting: return DesignTokens.Colors.warning
        default: return DesignTokens.Colors.danger
        }
    }
}

// MARK: - Alert Feed Card
struct AlertFeedCard: View {
    let item: AlertFeedItem

    var body: some View {
        HStack(spacing: DesignTokens.Spacing.md) {
            // Icon
            ZStack {
                Circle()
                    .fill(severityColor.opacity(0.15))
                    .frame(width: 40, height: 40)

                Image(systemName: item.iconName)
                    .font(.system(size: 18))
                    .foregroundStyle(severityColor)
            }

            // Content
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xxs) {
                HStack {
                    Text(item.title)
                        .font(Typography.bodySemiBold(.sm))
                        .foregroundStyle(DesignTokens.Colors.textPrimary)

                    if item.isNew {
                        Text("NEW")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(DesignTokens.Colors.primaryAccent)
                            .clipShape(Capsule())
                    }

                    Spacer()

                    Text(item.category.rawValue)
                        .font(Typography.body(.xxs))
                        .foregroundStyle(DesignTokens.Colors.textTertiary)
                }

                Text(item.subtitle)
                    .font(Typography.body(.xs))
                    .foregroundStyle(DesignTokens.Colors.textSecondary)
                    .lineLimit(2)

                Text(item.timestamp, style: .relative)
                    .font(Typography.body(.xxs))
                    .foregroundStyle(DesignTokens.Colors.textTertiary)
            }
        }
        .padding(DesignTokens.Spacing.md)
        .background(DesignTokens.Colors.surfacePrimary)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.md))
    }

    private var severityColor: Color {
        switch item.severity {
        case .low: return DesignTokens.Colors.info
        case .medium: return DesignTokens.Colors.warning
        case .high: return DesignTokens.Colors.secondaryAccent
        case .critical: return DesignTokens.Colors.danger
        }
    }
}

// MARK: - Connection Quality Bars
struct ConnectionQualityBars: View {
    let quality: ConnectionQuality

    var body: some View {
        HStack(spacing: 1.5) {
            ForEach(1...4, id: \.self) { bar in
                RoundedRectangle(cornerRadius: 1)
                    .fill(bar <= quality.barCount ? barColor : DesignTokens.Colors.textTertiary.opacity(0.3))
                    .frame(width: 3, height: CGFloat(bar * 3 + 4))
            }
        }
    }

    private var barColor: Color {
        switch quality {
        case .excellent: return DesignTokens.Colors.success
        case .good: return DesignTokens.Colors.success
        case .fair: return DesignTokens.Colors.warning
        case .poor: return DesignTokens.Colors.danger
        case .none: return DesignTokens.Colors.textTertiary
        }
    }
}
