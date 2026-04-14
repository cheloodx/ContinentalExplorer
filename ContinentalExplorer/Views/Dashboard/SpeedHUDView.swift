import SwiftUI

// MARK: - Speed HUD View
/// Displays current speed with glassmorphic material overlay
/// Changes color based on speed status (safe/warning/danger)
struct SpeedHUDView: View {
    let speed: Int
    let speedLimit: Int
    let status: SpeedStatus
    
    @EnvironmentObject private var themeManager: ThemeManager
    
    private var statusColor: Color {
        switch status {
        case .safe: return DesignTokens.Colors.speedSafe
        case .warning: return DesignTokens.Colors.speedWarning
        case .danger: return DesignTokens.Colors.speedDanger
        }
    }
    
    private var glowColor: Color {
        switch status {
        case .safe: return DesignTokens.Colors.speedSafe.opacity(0.3)
        case .warning: return DesignTokens.Colors.speedWarning.opacity(0.4)
        case .danger: return DesignTokens.Colors.speedDanger.opacity(0.5)
        }
    }
    
    var body: some View {
        VStack(spacing: DesignTokens.Spacing.xxs) {
            // Speed value
            Text("\(speed)")
                .font(Typography.hudDisplay(size: 48))
                .foregroundStyle(statusColor)
                .contentTransition(.numericText())
            
            // Unit label
            Text("km/h")
                .font(Typography.hudLabel(size: 11))
                .foregroundStyle(DesignTokens.Colors.textTertiary)
            
            // Speed limit indicator
            if speedLimit > 0 {
                speedLimitBadge
            }
        }
        .frame(width: 100, height: 110)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.lg))
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.lg)
                .stroke(statusColor.opacity(0.3), lineWidth: 1)
        )
        .shadow(color: glowColor, radius: 12, x: 0, y: 4)
        .animation(
            themeManager.isAnimationReduced ? .none : DesignTokens.Animation.spring,
            value: status
        )
    }
    
    // MARK: - Speed Limit Badge
    private var speedLimitBadge: some View {
        HStack(spacing: DesignTokens.Spacing.xxs) {
            Circle()
                .stroke(DesignTokens.Colors.danger, lineWidth: 2)
                .frame(width: 18, height: 18)
                .overlay(
                    Text("\(speedLimit)")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundStyle(DesignTokens.Colors.textPrimary)
                )
            
            Text("LIMIT")
                .font(Typography.hudLabel(size: 8))
                .foregroundStyle(DesignTokens.Colors.textTertiary)
        }
        .padding(.top, DesignTokens.Spacing.xxs)
    }
}

#Preview {
    ZStack {
        Color(hex: "#101223").ignoresSafeArea()
        
        HStack(spacing: 20) {
            SpeedHUDView(speed: 85, speedLimit: 120, status: .safe)
            SpeedHUDView(speed: 108, speedLimit: 120, status: .warning)
            SpeedHUDView(speed: 135, speedLimit: 120, status: .danger)
        }
    }
    .environmentObject(ThemeManager())
}
