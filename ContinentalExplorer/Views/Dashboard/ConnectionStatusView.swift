import SwiftUI

// MARK: - Connection Status View
/// Detailed connection status panel showing WebSocket state, latency, and quality
struct ConnectionStatusView: View {
    @EnvironmentObject private var webSocketService: WebSocketService
    @EnvironmentObject private var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                themeManager.backgroundColor
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: DesignTokens.Spacing.lg) {
                        // Main Status Card
                        mainStatusCard

                        // Stats Grid
                        statsGrid

                        // Connection Controls
                        connectionControls

                        // Connection Log
                        connectionInfo
                    }
                    .padding(DesignTokens.Spacing.md)
                }
            }
            .navigationTitle("Connection")
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

    // MARK: - Main Status Card
    private var mainStatusCard: some View {
        VStack(spacing: DesignTokens.Spacing.md) {
            // Status icon
            ZStack {
                Circle()
                    .fill(statusColor.opacity(0.15))
                    .frame(width: 80, height: 80)

                Image(systemName: webSocketService.connectionState.statusIcon)
                    .font(.system(size: 36))
                    .foregroundStyle(statusColor)

                if webSocketService.connectionState.isConnected {
                    Circle()
                        .stroke(statusColor.opacity(0.3), lineWidth: 2)
                        .frame(width: 90, height: 90)
                        .scaleEffect(pulseAnimation ? 1.2 : 1.0)
                        .opacity(pulseAnimation ? 0 : 1)
                        .animation(
                            .easeInOut(duration: 1.5).repeatForever(autoreverses: false),
                            value: pulseAnimation
                        )
                }
            }
            .onAppear { pulseAnimation = true }

            Text(webSocketService.connectionState.statusText)
                .font(Typography.headline(.h3))
                .foregroundStyle(DesignTokens.Colors.textPrimary)

            Text(webSocketService.connectionQuality.rawValue)
                .font(Typography.body(.sm))
                .foregroundStyle(DesignTokens.Colors.textSecondary)

            ConnectionQualityBars(quality: webSocketService.connectionQuality)
                .scaleEffect(1.5)
        }
        .padding(DesignTokens.Spacing.xl)
        .frame(maxWidth: .infinity)
        .background(DesignTokens.Colors.surfacePrimary)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.xl))
    }

    @State private var pulseAnimation = false

    // MARK: - Stats Grid
    private var statsGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: DesignTokens.Spacing.sm) {
            StatCard(
                title: "Latency",
                value: "\(webSocketService.latencyMs)ms",
                icon: "timer",
                color: latencyColor
            )

            StatCard(
                title: "Messages",
                value: "\(webSocketService.messageCount)",
                icon: "envelope.fill",
                color: DesignTokens.Colors.primaryAccent
            )

            StatCard(
                title: "Nearby Users",
                value: "\(webSocketService.nearbyUsersCount)",
                icon: "person.2.fill",
                color: DesignTokens.Colors.info
            )

            StatCard(
                title: "Quality",
                value: webSocketService.connectionQuality.rawValue,
                icon: "chart.bar.fill",
                color: qualityColor
            )
        }
    }

    // MARK: - Connection Controls
    private var connectionControls: some View {
        VStack(spacing: DesignTokens.Spacing.sm) {
            if webSocketService.connectionState.isConnected {
                Button {
                    webSocketService.disconnect()
                } label: {
                    Label("Disconnect", systemImage: "wifi.slash")
                        .font(Typography.bodySemiBold(.md))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, DesignTokens.Spacing.md)
                        .background(DesignTokens.Colors.danger)
                        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.lg))
                }
            } else {
                Button {
                    webSocketService.manualReconnect()
                } label: {
                    Label("Reconnect", systemImage: "arrow.clockwise")
                        .font(Typography.bodySemiBold(.md))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, DesignTokens.Spacing.md)
                        .background(DesignTokens.Colors.primaryAccent)
                        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.lg))
                }
            }

            Toggle(isOn: $webSocketService.isAutoReconnectEnabled) {
                Text("Auto-Reconnect")
                    .font(Typography.body(.sm))
                    .foregroundStyle(DesignTokens.Colors.textPrimary)
            }
            .tint(DesignTokens.Colors.primaryAccent)
            .padding(DesignTokens.Spacing.md)
            .background(DesignTokens.Colors.surfacePrimary)
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.md))
        }
    }

    // MARK: - Connection Info
    private var connectionInfo: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            Text("Connection Details")
                .font(Typography.headline(.h5))
                .foregroundStyle(DesignTokens.Colors.textPrimary)

            InfoRow(label: "Protocol", value: "WebSocket (wss://)")
            InfoRow(label: "Heartbeat", value: "Every 15s")
            InfoRow(label: "Reconnect Strategy", value: "Exponential Backoff")
            InfoRow(label: "Max Retries", value: "10")
            InfoRow(label: "Pending Messages", value: "Queued while offline")
        }
        .padding(DesignTokens.Spacing.md)
        .background(DesignTokens.Colors.surfacePrimary)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.lg))
    }

    // MARK: - Computed
    private var statusColor: Color {
        switch webSocketService.connectionState {
        case .connected: return DesignTokens.Colors.success
        case .connecting, .reconnecting: return DesignTokens.Colors.warning
        default: return DesignTokens.Colors.danger
        }
    }

    private var latencyColor: Color {
        switch webSocketService.latencyMs {
        case 0..<50: return DesignTokens.Colors.success
        case 50..<150: return DesignTokens.Colors.success
        case 150..<300: return DesignTokens.Colors.warning
        default: return DesignTokens.Colors.danger
        }
    }

    private var qualityColor: Color {
        switch webSocketService.connectionQuality {
        case .excellent, .good: return DesignTokens.Colors.success
        case .fair: return DesignTokens.Colors.warning
        case .poor, .none: return DesignTokens.Colors.danger
        }
    }
}

// MARK: - Stat Card
struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: DesignTokens.Spacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(color)

            Text(value)
                .font(Typography.headline(.h4))
                .foregroundStyle(DesignTokens.Colors.textPrimary)

            Text(title)
                .font(Typography.body(.xxs))
                .foregroundStyle(DesignTokens.Colors.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(DesignTokens.Spacing.md)
        .background(DesignTokens.Colors.surfacePrimary)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.md))
    }
}

// MARK: - Info Row
struct InfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(Typography.body(.sm))
                .foregroundStyle(DesignTokens.Colors.textSecondary)
            Spacer()
            Text(value)
                .font(Typography.bodySemiBold(.sm))
                .foregroundStyle(DesignTokens.Colors.textPrimary)
        }
    }
}
