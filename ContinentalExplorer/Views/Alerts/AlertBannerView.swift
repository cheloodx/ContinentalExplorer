import SwiftUI

// MARK: - Alert Banner View
/// Proximity-triggered banner displayed when entering radar/alert zones
/// Uses glassmorphic material with severity-based color coding
struct AlertBannerView: View {
    let alert: ActiveAlert
    let onDismiss: () -> Void
    
    @State private var isExpanded = false
    
    private var severityColor: Color {
        switch alert.severity {
        case .low: return DesignTokens.Colors.info
        case .medium: return DesignTokens.Colors.warning
        case .high: return DesignTokens.Colors.secondaryAccent
        case .critical: return DesignTokens.Colors.danger
        }
    }
    
    private var severityGlow: Color {
        severityColor.opacity(0.4)
    }
    
    var body: some View {
        HStack(spacing: DesignTokens.Spacing.md) {
            // Alert icon with pulse
            alertIcon
            
            // Alert info
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xxs) {
                Text(alert.title)
                    .font(Typography.bodySemiBold(.sm))
                    .foregroundStyle(DesignTokens.Colors.textPrimary)
                    .lineLimit(1)
                
                HStack(spacing: DesignTokens.Spacing.sm) {
                    Text(alert.subtitle)
                        .font(Typography.body(.xs))
                        .foregroundStyle(DesignTokens.Colors.textSecondary)
                    
                    if !alert.distanceText.isEmpty {
                        Text("•")
                            .foregroundStyle(DesignTokens.Colors.textTertiary)
                        
                        Text(alert.distanceText)
                            .font(Typography.hudLabel(size: 12))
                            .foregroundStyle(severityColor)
                    }
                }
            }
            
            Spacer()
            
            // Dismiss button
            Button(action: onDismiss) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(DesignTokens.Colors.textTertiary)
            }
            .buttonStyle(.plain)
        }
        .padding(DesignTokens.Spacing.md)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.lg))
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.lg)
                .stroke(severityColor.opacity(0.4), lineWidth: 1)
        )
        .shadow(color: severityGlow, radius: 16, x: 0, y: 4)
    }
    
    // MARK: - Alert Icon
    private var alertIcon: some View {
        ZStack {
            Circle()
                .fill(severityColor.opacity(0.15))
                .frame(width: 44, height: 44)
            
            Image(systemName: alert.iconName)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(severityColor)
        }
        .overlay(
            Circle()
                .stroke(severityColor.opacity(0.3), lineWidth: 1.5)
                .scaleEffect(isExpanded ? 1.3 : 1.0)
                .opacity(isExpanded ? 0 : 1)
                .animation(
                    .easeOut(duration: 1.2).repeatForever(autoreverses: false),
                    value: isExpanded
                )
        )
        .onAppear {
            isExpanded = true
        }
    }
}

#Preview {
    ZStack {
        Color(hex: "#101223").ignoresSafeArea()
        
        VStack(spacing: 16) {
            AlertBannerView(
                alert: ActiveAlert(
                    id: UUID(),
                    title: "Fixed Radar Ahead",
                    subtitle: "Speed limit: 50 km/h",
                    iconName: "camera.fill",
                    severity: .critical,
                    distance: 350,
                    timestamp: Date()
                ),
                onDismiss: {}
            )
            
            AlertBannerView(
                alert: ActiveAlert(
                    id: UUID(),
                    title: "Police Checkpoint",
                    subtitle: "Community report",
                    iconName: "shield.checkered",
                    severity: .medium,
                    distance: 1200,
                    timestamp: Date()
                ),
                onDismiss: {}
            )
        }
        .padding()
    }
}
