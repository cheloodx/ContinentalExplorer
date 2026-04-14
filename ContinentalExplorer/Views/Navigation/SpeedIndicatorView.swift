import SwiftUI

// MARK: - Speed Indicator (Waze-style circular speed display)
struct SpeedIndicatorView: View {
    let speed: Int
    let speedLimit: Int
    let status: SpeedStatus

    var body: some View {
        ZStack {
            // Outer ring
            Circle()
                .stroke(ringColor.opacity(0.3), lineWidth: 3)
                .frame(width: 64, height: 64)

            Circle()
                .fill(.ultraThinMaterial)
                .frame(width: 60, height: 60)

            VStack(spacing: 0) {
                Text("\(speed)")
                    .font(Typography.hudDisplay(size: 22))
                    .foregroundStyle(speedColor)

                Text("km/h")
                    .font(Typography.body(.xxs))
                    .foregroundStyle(DesignTokens.Colors.textTertiary)
            }

            // Speed limit badge
            if speedLimit > 0 {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Text("\(speedLimit)")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(4)
                            .background(status == .danger ? DesignTokens.Colors.danger : DesignTokens.Colors.surfaceElevated)
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(Color.white.opacity(0.3), lineWidth: 0.5)
                            )
                    }
                }
                .frame(width: 64, height: 64)
            }
        }
    }

    private var speedColor: Color {
        switch status {
        case .safe: return DesignTokens.Colors.textPrimary
        case .warning: return DesignTokens.Colors.speedWarning
        case .danger: return DesignTokens.Colors.speedDanger
        }
    }

    private var ringColor: Color {
        switch status {
        case .safe: return DesignTokens.Colors.success
        case .warning: return DesignTokens.Colors.warning
        case .danger: return DesignTokens.Colors.danger
        }
    }
}
