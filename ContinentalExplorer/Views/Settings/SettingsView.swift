import SwiftUI

// MARK: - Settings View
struct SettingsView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @EnvironmentObject private var soundManager: AlertSoundManager
    @EnvironmentObject private var webSocketService: WebSocketService
    @Environment(\.dismiss) private var dismiss

    @State private var speedAlerts: Bool = true
    @State private var radarAlerts: Bool = true
    @State private var communityReports: Bool = true
    @State private var detectionRadius: Double = 2000
    @State private var unitSystem: UnitSystem = .metric
    @State private var autoDownloadUpdates: Bool = true
    @State private var showEcoMode: Bool = false
    @State private var showConnectionStatus: Bool = false

    var body: some View {
        NavigationStack {
            ZStack {
                themeManager.backgroundColor
                    .ignoresSafeArea()

                Form {
                    // Navigation Section
                    Section("Navigation") {
                        Toggle("Speed Alerts", isOn: $speedAlerts)
                        Toggle("Radar Alerts", isOn: $radarAlerts)
                        Toggle("Community Reports", isOn: $communityReports)

                        VStack(alignment: .leading) {
                            Text("Detection Radius: \(Int(detectionRadius))m")
                                .font(Typography.body(.sm))
                            Slider(value: $detectionRadius, in: 500...5000, step: 100)
                                .tint(DesignTokens.Colors.primaryAccent)
                        }

                        Picker("Unit System", selection: $unitSystem) {
                            ForEach(UnitSystem.allCases, id: \.self) { system in
                                Text(system.rawValue).tag(system)
                            }
                        }
                    }

                    // Sound & Haptics Section
                    Section("Sound & Haptics") {
                        Toggle("Alert Sounds", isOn: $soundManager.isSoundEnabled)
                        Toggle("Haptic Feedback", isOn: $soundManager.isHapticEnabled)

                        VStack(alignment: .leading) {
                            Text("Volume: \(Int(soundManager.volume * 100))%")
                                .font(Typography.body(.sm))
                            Slider(value: $soundManager.volume, in: 0...1, step: 0.1)
                                .tint(DesignTokens.Colors.primaryAccent)
                        }
                    }

                    // Offline Maps Section
                    Section("Offline Maps") {
                        Toggle("Auto-Download Updates", isOn: $autoDownloadUpdates)
                    }

                    // Connection Section
                    Section("Connection") {
                        Button {
                            showConnectionStatus = true
                        } label: {
                            HStack {
                                Label("Connection Status", systemImage: "wifi")
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12))
                                    .foregroundStyle(DesignTokens.Colors.textTertiary)
                            }
                        }
                    }

                    // Appearance Section
                    Section("Appearance") {
                        Button {
                            showEcoMode = true
                        } label: {
                            HStack {
                                Label("Eco-Voyager Mode", systemImage: "leaf.fill")
                                    .foregroundStyle(.green)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12))
                                    .foregroundStyle(DesignTokens.Colors.textTertiary)
                            }
                        }

                        Picker("Theme", selection: $themeManager.currentTheme) {
                            ForEach(ThemeMode.allCases, id: \.self) { theme in
                                Text(theme.rawValue).tag(theme)
                            }
                        }
                    }

                    // About Section
                    Section("About") {
                        HStack {
                            Text("Version")
                            Spacer()
                            Text("1.0.0 (Sprint 2)")
                                .foregroundStyle(DesignTokens.Colors.textSecondary)
                        }
                        HStack {
                            Text("Build")
                            Spacer()
                            Text("2026.04.12")
                                .foregroundStyle(DesignTokens.Colors.textSecondary)
                        }
                    }
                }
                .scrollContentBackground(.hidden)
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
            .sheet(isPresented: $showConnectionStatus) {
                ConnectionStatusView()
                    .environmentObject(themeManager)
                    .environmentObject(webSocketService)
            }
        }
    }
}

// MARK: - Unit System
enum UnitSystem: String, CaseIterable {
    case metric = "Metric (km/h)"
    case imperial = "Imperial (mph)"
}
