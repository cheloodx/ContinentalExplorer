import SwiftUI

// MARK: - Eco-Voyager View
/// OLED-optimized dark mode with reduced animations to save CPU cycles
/// Uses Color.black background and minimal visual effects
struct EcoVoyagerView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: DesignTokens.Spacing.lg) {
                        // Eco mode status
                        ecoStatusCard
                        
                        // Benefits
                        benefitsSection
                        
                        // Mode selector
                        modeSelector
                    }
                    .padding(DesignTokens.Spacing.md)
                }
            }
            .navigationTitle("Eco-Voyager")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(DesignTokens.Colors.primaryAccent)
                }
            }
            .toolbarBackground(.black, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }
    
    // MARK: - Status Card
    private var ecoStatusCard: some View {
        VStack(spacing: DesignTokens.Spacing.md) {
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.1))
                    .frame(width: 80, height: 80)
                
                Image(systemName: "leaf.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(.green)
            }
            
            Text(themeManager.isEcoModeEnabled ? "Eco Mode Active" : "Eco Mode Inactive")
                .font(Typography.headline(.h3))
                .foregroundStyle(.white)
            
            Text("Optimized for OLED displays.\nReduced animations save battery.")
                .font(Typography.body(.sm))
                .foregroundStyle(DesignTokens.Colors.textSecondary)
                .multilineTextAlignment(.center)
            
            Button {
                themeManager.toggleEcoMode()
            } label: {
                Text(themeManager.isEcoModeEnabled ? "Disable Eco Mode" : "Enable Eco Mode")
                    .font(Typography.bodySemiBold(.md))
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, DesignTokens.Spacing.md)
                    .background(.green)
                    .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.md))
            }
        }
        .padding(DesignTokens.Spacing.lg)
        .background(Color(white: 0.06))
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.lg))
    }
    
    // MARK: - Benefits
    private var benefitsSection: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            Text("Benefits")
                .font(Typography.headline(.h5))
                .foregroundStyle(.white)
            
            EcoBenefitRow(icon: "battery.100.bolt", title: "Battery Savings", description: "Up to 40% longer battery life on OLED screens")
            EcoBenefitRow(icon: "cpu", title: "Reduced CPU Usage", description: "Minimal animations reduce processor workload")
            EcoBenefitRow(icon: "eye", title: "Night Driving", description: "True black reduces eye strain in dark conditions")
            EcoBenefitRow(icon: "thermometer.snowflake", title: "Less Heat", description: "Lower power consumption means a cooler device")
        }
    }
    
    // MARK: - Mode Selector
    private var modeSelector: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            Text("Theme Mode")
                .font(Typography.headline(.h5))
                .foregroundStyle(.white)
            
            ForEach(ThemeMode.allCases, id: \.rawValue) { mode in
                ThemeModeCard(
                    mode: mode,
                    isSelected: themeManager.currentTheme == mode
                ) {
                    themeManager.setTheme(mode)
                }
            }
        }
    }
}

// MARK: - Eco Benefit Row
struct EcoBenefitRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: DesignTokens.Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(.green)
                .frame(width: 36, height: 36)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(Typography.bodySemiBold(.sm))
                    .foregroundStyle(.white)
                
                Text(description)
                    .font(Typography.body(.xs))
                    .foregroundStyle(DesignTokens.Colors.textSecondary)
            }
        }
        .padding(DesignTokens.Spacing.sm)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(white: 0.06))
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.sm))
    }
}

// MARK: - Theme Mode Card
struct ThemeModeCard: View {
    let mode: ThemeMode
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: DesignTokens.Spacing.md) {
                Image(systemName: mode.iconName)
                    .font(.system(size: 20))
                    .foregroundStyle(isSelected ? DesignTokens.Colors.primaryAccent : DesignTokens.Colors.textSecondary)
                    .frame(width: 36, height: 36)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(mode.rawValue)
                        .font(Typography.bodySemiBold(.sm))
                        .foregroundStyle(.white)
                    
                    Text(modeDescription)
                        .font(Typography.body(.xs))
                        .foregroundStyle(DesignTokens.Colors.textSecondary)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(DesignTokens.Colors.primaryAccent)
                }
            }
            .padding(DesignTokens.Spacing.md)
            .background(isSelected ? DesignTokens.Colors.primaryAccent.opacity(0.1) : Color(white: 0.06))
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.md))
            .overlay(
                RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.md)
                    .stroke(isSelected ? DesignTokens.Colors.primaryAccent.opacity(0.3) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
    
    private var modeDescription: String {
        switch mode {
        case .dark: return "Standard dark theme with rich colors"
        case .oled: return "True black for OLED displays"
        case .eco: return "Maximum battery savings mode"
        }
    }
}

#Preview {
    EcoVoyagerView()
        .environmentObject(ThemeManager())
}
