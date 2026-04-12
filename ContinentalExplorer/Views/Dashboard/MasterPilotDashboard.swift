import SwiftUI
import MapKit

// MARK: - Master Pilot Dashboard
/// Root view implementing the ZStack architecture with Map layer at bottom
/// and custom HUD components using .ultraThinMaterial overlays
struct MasterPilotDashboard: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @EnvironmentObject private var locationService: LocationService
    @EnvironmentObject private var alertService: AlertService
    
    @StateObject private var navigationVM: NavigationViewModel
    @StateObject private var alertVM: AlertViewModel
    
    @State private var showSettings = false
    @State private var showOfflineMaps = false
    @State private var showAlertList = false
    @State private var selectedTab: DashboardTab = .map
    
    init() {
        let locService = LocationService()
        let altService = AlertService()
        _navigationVM = StateObject(wrappedValue: NavigationViewModel(
            locationService: locService,
            alertService: altService
        ))
        _alertVM = StateObject(wrappedValue: AlertViewModel(alertService: altService))
    }
    
    var body: some View {
        ZStack {
            // Layer 1: Background
            themeManager.backgroundColor
                .ignoresSafeArea()
            
            // Layer 2: Map
            mapLayer
            
            // Layer 3: HUD Overlays
            VStack(spacing: 0) {
                // Top HUD Bar
                topHUDBar
                
                Spacer()
                
                // Alert Banner (conditionally shown)
                if alertVM.isBannerVisible, let alert = alertVM.bannerAlert {
                    AlertBannerView(alert: alert) {
                        alertVM.dismissBanner()
                    }
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .padding(.horizontal, DesignTokens.Spacing.md)
                }
                
                Spacer()
                
                // Bottom HUD
                bottomHUDBar
            }
            
            // Layer 4: Side Controls
            sideControls
        }
        .animation(
            themeManager.isAnimationReduced ? .none : DesignTokens.Animation.spring,
            value: alertVM.isBannerVisible
        )
        .sheet(isPresented: $showSettings) {
            SettingsView()
                .environmentObject(themeManager)
        }
        .sheet(isPresented: $showOfflineMaps) {
            OfflineMapManagerView()
                .environmentObject(themeManager)
        }
        .sheet(isPresented: $showAlertList) {
            CommunityAlertView(viewModel: alertVM)
                .environmentObject(themeManager)
        }
        .onAppear {
            locationService.requestAuthorization()
        }
    }
    
    // MARK: - Map Layer
    private var mapLayer: some View {
        Map(position: $navigationVM.mapCameraPosition) {
            // User location
            UserAnnotation()
            
            // Radar annotations
            ForEach(navigationVM.mapAnnotations) { annotation in
                Annotation(annotation.title, coordinate: annotation.coordinate) {
                    MapAnnotationView(annotation: annotation)
                }
            }
        }
        .mapStyle(.standard(elevation: .realistic, emphasis: .muted, pointsOfInterest: .excludingAll, showsTraffic: navigationVM.showTrafficOverlay))
        .mapControls {
            MapCompass()
        }
        .ignoresSafeArea()
    }
    
    // MARK: - Top HUD
    private var topHUDBar: some View {
        HStack(spacing: DesignTokens.Spacing.md) {
            // Speed HUD
            SpeedHUDView(
                speed: navigationVM.currentSpeed,
                speedLimit: navigationVM.currentSpeedLimit,
                status: navigationVM.speedStatus
            )
            
            Spacer()
            
            // Navigation info
            NavigationHUDView(
                roadName: navigationVM.currentRoadName,
                eta: navigationVM.eta,
                distance: navigationVM.distanceRemaining
            )
            
            Spacer()
            
            // Connection status indicator
            connectionIndicator
        }
        .padding(.horizontal, DesignTokens.Spacing.md)
        .padding(.top, DesignTokens.Spacing.sm)
    }
    
    // MARK: - Bottom HUD
    private var bottomHUDBar: some View {
        HStack(spacing: DesignTokens.Spacing.lg) {
            // Report button
            HUDButton(icon: "exclamationmark.triangle.fill", label: "Report") {
                alertVM.presentReportSheet()
            }
            
            // Offline Maps
            HUDButton(icon: "arrow.down.circle.fill", label: "Offline") {
                showOfflineMaps = true
            }
            
            // Center on user
            HUDButton(
                icon: "location.fill",
                label: "Center",
                isActive: navigationVM.isFollowingUser
            ) {
                navigationVM.centerOnUser()
            }
            
            // Alerts list
            HUDButton(
                icon: "bell.fill",
                label: "Alerts",
                badge: alertVM.alertCount
            ) {
                showAlertList = true
            }
            
            // Settings
            HUDButton(icon: "gearshape.fill", label: "Settings") {
                showSettings = true
            }
        }
        .padding(.horizontal, DesignTokens.Spacing.lg)
        .padding(.vertical, DesignTokens.Spacing.md)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.xl))
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.xl)
                .stroke(DesignTokens.HUD.borderColor, lineWidth: DesignTokens.HUD.borderWidth)
        )
        .padding(.horizontal, DesignTokens.Spacing.md)
        .padding(.bottom, DesignTokens.Spacing.md)
    }
    
    // MARK: - Side Controls
    private var sideControls: some View {
        VStack(spacing: DesignTokens.Spacing.sm) {
            Spacer()
            
            HStack {
                Spacer()
                
                VStack(spacing: DesignTokens.Spacing.sm) {
                    // Traffic toggle
                    SideControlButton(
                        icon: "car.2.fill",
                        isActive: navigationVM.showTrafficOverlay
                    ) {
                        navigationVM.toggleTraffic()
                    }
                    
                    // Eco mode toggle
                    SideControlButton(
                        icon: themeManager.currentTheme.iconName,
                        isActive: themeManager.isEcoModeEnabled,
                        tint: .green
                    ) {
                        themeManager.toggleEcoMode()
                    }
                }
                .padding(.trailing, DesignTokens.Spacing.md)
            }
            
            Spacer()
                .frame(height: 120)
        }
    }
    
    // MARK: - Connection Indicator
    private var connectionIndicator: some View {
        HStack(spacing: DesignTokens.Spacing.xs) {
            Circle()
                .fill(Color.green)
                .frame(width: 8, height: 8)
            
            Text("LIVE")
                .font(Typography.hudLabel(size: 10))
                .foregroundStyle(DesignTokens.Colors.textSecondary)
        }
        .padding(.horizontal, DesignTokens.Spacing.sm)
        .padding(.vertical, DesignTokens.Spacing.xs)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
    }
}

// MARK: - Dashboard Tab
enum DashboardTab: String, CaseIterable {
    case map = "Map"
    case alerts = "Alerts"
    case offline = "Offline"
    case settings = "Settings"
}

// MARK: - HUD Button
struct HUDButton: View {
    let icon: String
    let label: String
    var isActive: Bool = false
    var badge: Int = 0
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: DesignTokens.Spacing.xs) {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: icon)
                        .font(.system(size: 20))
                        .foregroundStyle(
                            isActive ? DesignTokens.Colors.primaryAccent : DesignTokens.Colors.textSecondary
                        )
                    
                    if badge > 0 {
                        Text("\(badge)")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(3)
                            .background(DesignTokens.Colors.danger)
                            .clipShape(Circle())
                            .offset(x: 8, y: -8)
                    }
                }
                
                Text(label)
                    .font(Typography.body(.xxs))
                    .foregroundStyle(
                        isActive ? DesignTokens.Colors.primaryAccent : DesignTokens.Colors.textTertiary
                    )
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Side Control Button
struct SideControlButton: View {
    let icon: String
    var isActive: Bool = false
    var tint: Color = DesignTokens.Colors.primaryAccent
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(isActive ? tint : DesignTokens.Colors.textSecondary)
                .frame(width: 44, height: 44)
                .background(.ultraThinMaterial)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(
                            isActive ? tint.opacity(0.5) : Color.clear,
                            lineWidth: 1.5
                        )
                )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    MasterPilotDashboard()
        .environmentObject(ThemeManager())
        .environmentObject(LocationService())
        .environmentObject(AlertService())
}
