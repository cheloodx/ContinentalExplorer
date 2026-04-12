import SwiftUI

// MARK: - Settings View
struct SettingsView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var alertRadius: Double = 2000
    @State private var showSpeedAlerts: Bool = true
    @State private var showRadarAlerts: Bool = true
    @State private var showCommunityReports: Bool = true
    @State private var alertSoundEnabled: Bool = true
    @State private var hapticFeedback: Bool = true
    @State private var autoDownloadUpdates: Bool = false
    @State private var showEcoMode: Bool = false
    @State private var unitSystem: UnitSystem = .metric
    
    var body: some View {
        NavigationStack {
            ZStack {
                themeManager.backgroundColor
                    .ignoresSafeArea()
                
                List {
                    // Navigation
                    navigationSection
                    
                    // Alerts
                    alertsSection
                    
                    // Offline Maps
                    offlineSection
                    
                    // Appearance
                    appearanceSection
                    
                    // About
                    aboutSection
                }
                .scrollContentBackground(.hidden)
                .listStyle(.insetGrouped)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(DesignTokens.Colors.primaryAccent)
                }
            }
            .toolbarBackground(themeManager.surfaceColor, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .sheet(isPresented: $showEcoMode) {
                EcoVoyagerView()
                    .environmentObject(themeManager)
            }
        }
    }
    
    // MARK: - Navigation Section
    private var navigationSection: some View {
        Section {
            Picker("Units", selection: $unitSystem) {
                ForEach(UnitSystem.allCases, id: \.self) { unit in
                    Text(unit.rawValue).tag(unit)
                }
            }
            .listRowBackground(DesignTokens.Colors.surfacePrimary)
        } header: {
            Text("Navigation")
                .foregroundStyle(DesignTokens.Colors.primaryAccent)
        }
    }
    
    // MARK: - Alerts Section
    private var alertsSection: some View {
        Section {
            Toggle("Speed Alerts", isOn: $showSpeedAlerts)
                .tint(DesignTokens.Colors.primaryAccent)
                .listRowBackground(DesignTokens.Colors.surfacePrimary)
            
            Toggle("Radar Alerts", isOn: $showRadarAlerts)
                .tint(DesignTokens.Colors.primaryAccent)
                .listRowBackground(DesignTokens.Colors.surfacePrimary)
            
            Toggle("Community Reports", isOn: $showCommunityReports)
                .tint(DesignTokens.Colors.primaryAccent)
                .listRowBackground(DesignTokens.Colors.surfacePrimary)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Detection Radius: \(Int(alertRadius))m")
                    .font(Typography.body(.sm))
                
                Slider(value: $alertRadius, in: 500...5000, step: 500)
                    .tint(DesignTokens.Colors.primaryAccent)
            }
            .listRowBackground(DesignTokens.Colors.surfacePrimary)
            
            Toggle("Alert Sound", isOn: $alertSoundEnabled)
                .tint(DesignTokens.Colors.primaryAccent)
                .listRowBackground(DesignTokens.Colors.surfacePrimary)
            
            Toggle("Haptic Feedback", isOn: $hapticFeedback)
                .tint(DesignTokens.Colors.primaryAccent)
                .listRowBackground(DesignTokens.Colors.surfacePrimary)
        } header: {
            Text("Alerts")
                .foregroundStyle(DesignTokens.Colors.primaryAccent)
        }
    }
    
    // MARK: - Offline Section
    private var offlineSection: some View {
        Section {
            Toggle("Auto-download Updates", isOn: $autoDownloadUpdates)
                .tint(DesignTokens.Colors.primaryAccent)
                .listRowBackground(DesignTokens.Colors.surfacePrimary)
        } header: {
            Text("Offline Maps")
                .foregroundStyle(DesignTokens.Colors.primaryAccent)
        }
    }
    
    // MARK: - Appearance Section
    private var appearanceSection: some View {
        Section {
            Button {
                showEcoMode = true
            } label: {
                HStack {
                    Label("Eco-Voyager Mode", systemImage: "leaf.fill")
                        .foregroundStyle(DesignTokens.Colors.textPrimary)
                    
                    Spacer()
                    
                    if themeManager.isEcoModeEnabled {
                        Text("Active")
                            .font(Typography.body(.xs))
                            .foregroundStyle(.green)
                    }
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(DesignTokens.Colors.textTertiary)
                }
            }
            .listRowBackground(DesignTokens.Colors.surfacePrimary)
            
            Picker("Theme", selection: $themeManager.currentTheme) {
                ForEach(ThemeMode.allCases, id: \.self) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .listRowBackground(DesignTokens.Colors.surfacePrimary)
        } header: {
            Text("Appearance")
                .foregroundStyle(DesignTokens.Colors.primaryAccent)
        }
    }
    
    // MARK: - About Section
    private var aboutSection: some View {
        Section {
            HStack {
                Text("Version")
                    .foregroundStyle(DesignTokens.Colors.textPrimary)
                Spacer()
                Text("1.0.0 (Sprint 1)")
                    .foregroundStyle(DesignTokens.Colors.textSecondary)
            }
            .listRowBackground(DesignTokens.Colors.surfacePrimary)
            
            HStack {
                Text("Build")
                    .foregroundStyle(DesignTokens.Colors.textPrimary)
                Spacer()
                Text("1")
                    .foregroundStyle(DesignTokens.Colors.textSecondary)
            }
            .listRowBackground(DesignTokens.Colors.surfacePrimary)
        } header: {
            Text("About")
                .foregroundStyle(DesignTokens.Colors.primaryAccent)
        }
    }
}

// MARK: - Unit System
enum UnitSystem: String, CaseIterable {
    case metric = "Metric (km/h)"
    case imperial = "Imperial (mph)"
}

#Preview {
    SettingsView()
        .environmentObject(ThemeManager())
}
