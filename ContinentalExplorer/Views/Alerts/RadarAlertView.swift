import SwiftUI

// MARK: - Radar Alert View
/// Detailed radar alert card shown in the alerts list
struct RadarAlertView: View {
    let alert: RadarAlert
    let distance: CLLocationDistance?
    
    private var typeColor: Color {
        switch alert.type {
        case .fixed: return DesignTokens.Colors.radarFixed
        case .mobile: return DesignTokens.Colors.radarMobile
        case .average: return DesignTokens.Colors.radarAverage
        case .redLight: return DesignTokens.Colors.danger
        case .section: return DesignTokens.Colors.warning
        }
    }
    
    var body: some View {
        HStack(spacing: DesignTokens.Spacing.md) {
            // Radar type icon
            ZStack {
                RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.sm)
                    .fill(typeColor.opacity(0.15))
                    .frame(width: 48, height: 48)
                
                Image(systemName: alert.type.iconName)
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(typeColor)
            }
            
            // Info
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xxs) {
                Text(alert.type.rawValue)
                    .font(Typography.bodySemiBold(.sm))
                    .foregroundStyle(DesignTokens.Colors.textPrimary)
                
                HStack(spacing: DesignTokens.Spacing.sm) {
                    // Speed limit
                    Label("\(alert.speedLimit) km/h", systemImage: "gauge.with.needle.fill")
                        .font(Typography.body(.xs))
                        .foregroundStyle(DesignTokens.Colors.textSecondary)
                    
                    // Country
                    Text(alert.country)
                        .font(Typography.body(.xs))
                        .foregroundStyle(DesignTokens.Colors.textTertiary)
                }
            }
            
            Spacer()
            
            // Distance
            VStack(alignment: .trailing, spacing: DesignTokens.Spacing.xxs) {
                if let distance = distance {
                    Text(formatDistance(distance))
                        .font(Typography.hudLabel(size: 14))
                        .foregroundStyle(typeColor)
                }
                
                // Verification badge
                if alert.isVerified {
                    HStack(spacing: 2) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 10))
                        Text("Verified")
                            .font(Typography.body(.xxs))
                    }
                    .foregroundStyle(DesignTokens.Colors.success)
                }
            }
        }
        .padding(DesignTokens.Spacing.md)
        .background(DesignTokens.Colors.surfacePrimary)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.md))
    }
    
    private func formatDistance(_ distance: CLLocationDistance) -> String {
        if distance < 1000 {
            return "\(Int(distance))m"
        }
        return String(format: "%.1f km", distance / 1000)
    }
}

import CoreLocation

#Preview {
    ZStack {
        Color(hex: "#101223").ignoresSafeArea()
        
        VStack(spacing: 12) {
            RadarAlertView(
                alert: RadarAlert(
                    type: .fixed,
                    coordinate: CLLocationCoordinate2D(latitude: 48.8584, longitude: 2.2945),
                    speedLimit: 50,
                    country: "France"
                ),
                distance: 450
            )
            
            RadarAlertView(
                alert: RadarAlert(
                    type: .mobile,
                    coordinate: CLLocationCoordinate2D(latitude: 52.5200, longitude: 13.4050),
                    speedLimit: 100,
                    isVerified: false,
                    country: "Germany"
                ),
                distance: 2300
            )
        }
        .padding()
    }
}
