import SwiftUI

// MARK: - Navigation HUD View
/// Displays current road name, ETA, and remaining distance
/// Uses glassmorphic .ultraThinMaterial background
struct NavigationHUDView: View {
    let roadName: String
    let eta: String
    let distance: String
    
    var body: some View {
        VStack(spacing: DesignTokens.Spacing.xs) {
            // Road name
            Text(roadName)
                .font(Typography.bodySemiBold(.sm))
                .foregroundStyle(DesignTokens.Colors.textPrimary)
                .lineLimit(1)
            
            HStack(spacing: DesignTokens.Spacing.md) {
                // ETA
                HStack(spacing: DesignTokens.Spacing.xs) {
                    Image(systemName: "clock.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(DesignTokens.Colors.primaryAccent)
                    
                    Text(eta)
                        .font(Typography.hudLabel(size: 13))
                        .foregroundStyle(DesignTokens.Colors.textSecondary)
                }
                
                // Divider
                Rectangle()
                    .fill(DesignTokens.Colors.textTertiary.opacity(0.3))
                    .frame(width: 1, height: 14)
                
                // Distance
                HStack(spacing: DesignTokens.Spacing.xs) {
                    Image(systemName: "arrow.triangle.turn.up.right.diamond.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(DesignTokens.Colors.secondaryAccent)
                    
                    Text(distance)
                        .font(Typography.hudLabel(size: 13))
                        .foregroundStyle(DesignTokens.Colors.textSecondary)
                }
            }
        }
        .padding(.horizontal, DesignTokens.Spacing.md)
        .padding(.vertical, DesignTokens.Spacing.sm)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.md))
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.md)
                .stroke(DesignTokens.HUD.borderColor, lineWidth: DesignTokens.HUD.borderWidth)
        )
    }
}

#Preview {
    ZStack {
        Color(hex: "#101223").ignoresSafeArea()
        
        NavigationHUDView(
            roadName: "Autobahn A9 → München",
            eta: "2h 15m",
            distance: "185 km"
        )
    }
}
