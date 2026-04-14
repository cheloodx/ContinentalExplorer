import SwiftUI
import MapKit

// MARK: - Master Pilot Dashboard (Waze/Professional Style)
struct MasterPilotDashboard: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @EnvironmentObject private var locationService: LocationService
    @EnvironmentObject private var alertService: AlertService
    @EnvironmentObject private var webSocketService: WebSocketService
    @EnvironmentObject private var soundManager: AlertSoundManager

    @EnvironmentObject private var navigationVM: NavigationViewModel
    @EnvironmentObject private var alertVM: AlertViewModel
    @StateObject private var searchService = PlacesSearchService()
    @StateObject private var mapStyleManager = MapStyleManager()

    @State private var showSearch = false
    @State private var showSettings = false
    @State private var showReportSheet = false
    @State private var showLiveFeed = false
    @State private var showMapStylePicker = false
    @State private var showConnectionStatus = false
    @State private var showOfflineMaps = false

    var body: some View {
        ZStack {
            // Layer 1: Map
            mapLayer
                .ignoresSafeArea()

            // Layer 2: Overlays based on navigation mode
            switch navigationVM.navigationMode {
            case .idle:
                idleModeOverlay
            case .previewing:
                previewModeOverlay
            case .navigating, .rerouting:
                navigationModeOverlay
            case .arrived:
                arrivedOverlay
            }

            // Alert Banner
            if alertVM.isBannerVisible, let alert = alertVM.bannerAlert {
                VStack {
                    AlertBannerView(alert: alert) {
                        alertVM.dismissBanner()
                    }
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .padding(.horizontal, DesignTokens.Spacing.md)
                    .padding(.top, 100)
                    Spacer()
                }
            }
        }
        .animation(
            themeManager.isAnimationReduced ? .none : DesignTokens.Animation.spring,
            value: navigationVM.navigationMode == .idle
        )
        .sheet(isPresented: $showSettings) {
            SettingsView()
                .environmentObject(themeManager)
                .environmentObject(soundManager)
        }
        .sheet(isPresented: $showReportSheet) {
            ReportSubmissionSheet(viewModel: alertVM)
                .environmentObject(themeManager)
                .environmentObject(locationService)
        }
        .sheet(isPresented: $showLiveFeed) {
            LiveAlertFeedView(viewModel: alertVM)
                .environmentObject(themeManager)
                .environmentObject(webSocketService)
        }
        .sheet(isPresented: $showConnectionStatus) {
            ConnectionStatusView()
                .environmentObject(themeManager)
                .environmentObject(webSocketService)
        }
        .sheet(isPresented: $showOfflineMaps) {
            OfflineMapManagerView()
                .environmentObject(themeManager)
        }
        .onAppear {
            locationService.requestAuthorization()
        }
    }

    // MARK: - Map Layer
    private var mapLayer: some View {
        Map(position: $navigationVM.mapCameraPosition) {
            UserAnnotation()

            // Route polyline
            if let route = navigationVM.routePolyline {
                MapPolyline(route.polyline)
                    .stroke(DesignTokens.Colors.primaryAccent, lineWidth: 6)
            }

            // Annotations
            ForEach(navigationVM.mapAnnotations) { annotation in
                Annotation(annotation.title, coordinate: annotation.coordinate) {
                    MapAnnotationView(annotation: annotation)
                }
            }

            // Destination pin
            if let dest = navigationVM.destination {
                Annotation(dest.name, coordinate: dest.coordinate) {
                    DestinationPinView()
                }
            }
        }
        .mapStyle(mapStyleManager.mapStyle)
        .mapControls {
            MapCompass()
        }
    }

    // MARK: - IDLE Mode (Default - search bar + FABs)
    private var idleModeOverlay: some View {
        ZStack {
            VStack(spacing: 0) {
                if showSearch {
                    SearchBarView(
                        searchService: searchService,
                        onSelectResult: { result in
                            let dest = Destination(
                                name: result.title,
                                address: result.subtitle,
                                coordinate: result.coordinate,
                                mapItem: result.mapItem
                            )
                            navigationVM.setDestination(dest)
                            showSearch = false
                            Task { await navigationVM.startRouteCalculation() }
                        },
                        onDismiss: { showSearch = false }
                    )
                    .transition(.move(edge: .top).combined(with: .opacity))
                } else {
                    // Waze-style top search bar
                    wazeSearchBar
                }

                Spacer()
            }

            // Speed indicator (bottom left)
            VStack {
                Spacer()
                HStack {
                    SpeedIndicatorView(
                        speed: navigationVM.currentSpeed,
                        speedLimit: navigationVM.currentSpeedLimit,
                        status: navigationVM.speedStatus
                    )
                    .padding(.leading, DesignTokens.Spacing.md)
                    Spacer()
                }
                .padding(.bottom, 100)
            }

            // Right side FABs
            rightSideFABs

            // Bottom bar
            VStack {
                Spacer()
                bottomBar
            }
        }
        .animation(DesignTokens.Animation.spring, value: showSearch)
    }

    // MARK: - Waze Search Bar
    private var wazeSearchBar: some View {
        Button {
            showSearch = true
        } label: {
            HStack(spacing: DesignTokens.Spacing.sm) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 16))
                    .foregroundStyle(DesignTokens.Colors.textTertiary)

                Text("Where to?")
                    .font(Typography.bodyMedium(.md))
                    .foregroundStyle(DesignTokens.Colors.textTertiary)

                Spacer()

                // Connection indicator
                Circle()
                    .fill(connectionColor)
                    .frame(width: 8, height: 8)
            }
            .padding(.horizontal, DesignTokens.Spacing.md)
            .padding(.vertical, DesignTokens.Spacing.sm + 4)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.xl))
            .shadow(color: .black.opacity(0.15), radius: 8, y: 2)
        }
        .buttonStyle(.plain)
        .padding(.horizontal, DesignTokens.Spacing.md)
        .padding(.top, DesignTokens.Spacing.sm)
    }

    // MARK: - Right Side FABs
    private var rightSideFABs: some View {
        VStack {
            Spacer()

            HStack {
                Spacer()

                VStack(spacing: DesignTokens.Spacing.sm) {
                    // Map style
                    FloatingActionButton(
                        icon: mapStyleManager.currentStyle.iconName,
                        size: 44
                    ) {
                        mapStyleManager.cycleStyle()
                    }

                    // Traffic toggle
                    FloatingActionButton(
                        icon: "car.2.fill",
                        isActive: mapStyleManager.showTraffic,
                        size: 44
                    ) {
                        mapStyleManager.showTraffic.toggle()
                    }

                    // Center on user
                    FloatingActionButton(
                        icon: "location.fill",
                        isActive: navigationVM.isFollowingUser,
                        tint: DesignTokens.Colors.primaryAccent,
                        size: 48
                    ) {
                        navigationVM.recenterMap()
                    }
                }
                .padding(.trailing, DesignTokens.Spacing.md)
            }

            Spacer()
                .frame(height: 100)
        }
    }

    // MARK: - Bottom Bar (Waze-style)
    private var bottomBar: some View {
        HStack(spacing: DesignTokens.Spacing.xl) {
            // Report
            BottomBarButton(icon: "exclamationmark.triangle.fill", label: "Report") {
                showReportSheet = true
            }

            // Live feed
            BottomBarButton(
                icon: "antenna.radiowaves.left.and.right",
                label: "Live",
                badge: alertVM.unreadAlertCount
            ) {
                showLiveFeed = true
            }

            // Offline maps
            BottomBarButton(icon: "arrow.down.circle.fill", label: "Offline") {
                showOfflineMaps = true
            }

            // Settings
            BottomBarButton(icon: "gearshape.fill", label: "More") {
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
        .shadow(color: .black.opacity(0.15), radius: 8, y: -2)
        .padding(.horizontal, DesignTokens.Spacing.md)
        .padding(.bottom, DesignTokens.Spacing.md)
    }

    // MARK: - Preview Mode (Route selected, before starting)
    private var previewModeOverlay: some View {
        VStack {
            Spacer()

            RoutePreviewSheet(
                navigationVM: navigationVM,
                routeService: navigationVM.routeService,
                onStartNavigation: {
                    navigationVM.startNavigation()
                },
                onDismiss: {
                    navigationVM.stopNavigation()
                }
            )
            .transition(.move(edge: .bottom))
        }
        .animation(DesignTokens.Animation.spring, value: navigationVM.navigationMode == .previewing)
    }

    // MARK: - Navigation Mode (Active turn-by-turn)
    private var navigationModeOverlay: some View {
        ZStack {
            NavigationModeView(
                navigationVM: navigationVM,
                routeService: navigationVM.routeService,
                voiceService: navigationVM.voiceService
            )

            // Speed indicator
            VStack {
                Spacer()
                HStack {
                    SpeedIndicatorView(
                        speed: navigationVM.currentSpeed,
                        speedLimit: navigationVM.currentSpeedLimit,
                        status: navigationVM.speedStatus
                    )
                    .padding(.leading, DesignTokens.Spacing.md)
                    Spacer()
                }
                .padding(.bottom, 120)
            }

            // Report button during navigation
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    FloatingActionButton(
                        icon: "exclamationmark.triangle.fill",
                        tint: DesignTokens.Colors.warning,
                        size: 48
                    ) {
                        showReportSheet = true
                    }
                    .padding(.trailing, DesignTokens.Spacing.md)
                }
                .padding(.bottom, 120)
            }
        }
    }

    // MARK: - Arrived Overlay
    private var arrivedOverlay: some View {
        VStack {
            Spacer()

            VStack(spacing: DesignTokens.Spacing.md) {
                Image(systemName: "flag.checkered")
                    .font(.system(size: 40))
                    .foregroundStyle(DesignTokens.Colors.success)

                Text("You have arrived!")
                    .font(Typography.headline(.h3))
                    .foregroundStyle(DesignTokens.Colors.textPrimary)

                Text(navigationVM.destination?.name ?? "")
                    .font(Typography.body(.md))
                    .foregroundStyle(DesignTokens.Colors.textSecondary)

                Button {
                    navigationVM.stopNavigation()
                } label: {
                    Text("Done")
                        .font(Typography.headline(.h5))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, DesignTokens.Spacing.md)
                        .background(DesignTokens.Colors.primaryAccent)
                        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.md))
                }
            }
            .padding(DesignTokens.Spacing.lg)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.xl))
            .padding(.horizontal, DesignTokens.Spacing.lg)
            .padding(.bottom, DesignTokens.Spacing.xxl)
        }
    }

    // MARK: - Helpers
    private var connectionColor: Color {
        switch webSocketService.connectionState {
        case .connected: return DesignTokens.Colors.success
        case .connecting, .reconnecting: return DesignTokens.Colors.warning
        default: return DesignTokens.Colors.danger
        }
    }
}

// MARK: - Floating Action Button
struct FloatingActionButton: View {
    let icon: String
    var isActive: Bool = false
    var tint: Color = DesignTokens.Colors.textSecondary
    var size: CGFloat = 44
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: size * 0.36, weight: .medium))
                .foregroundStyle(isActive ? tint : DesignTokens.Colors.textSecondary)
                .frame(width: size, height: size)
                .background(.ultraThinMaterial)
                .clipShape(Circle())
                .shadow(color: .black.opacity(0.15), radius: 4, y: 2)
                .overlay(
                    Circle()
                        .stroke(
                            isActive ? tint.opacity(0.4) : Color.clear,
                            lineWidth: 1.5
                        )
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Bottom Bar Button
struct BottomBarButton: View {
    let icon: String
    let label: String
    var badge: Int = 0
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: DesignTokens.Spacing.xs) {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: icon)
                        .font(.system(size: 20))
                        .foregroundStyle(DesignTokens.Colors.textSecondary)

                    if badge > 0 {
                        Text("\(badge)")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(3)
                            .background(DesignTokens.Colors.danger)
                            .clipShape(Circle())
                            .offset(x: 8, y: -6)
                    }
                }

                Text(label)
                    .font(Typography.body(.xxs))
                    .foregroundStyle(DesignTokens.Colors.textTertiary)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Destination Pin
struct DestinationPinView: View {
    var body: some View {
        VStack(spacing: 0) {
            Image(systemName: "mappin.circle.fill")
                .font(.system(size: 32))
                .foregroundStyle(DesignTokens.Colors.danger)
                .background(
                    Circle()
                        .fill(.white)
                        .frame(width: 24, height: 24)
                )

            Image(systemName: "arrowtriangle.down.fill")
                .font(.system(size: 10))
                .foregroundStyle(DesignTokens.Colors.danger)
                .offset(y: -4)
        }
    }
}

// MARK: - Preview
#Preview {
    let locService = LocationService()
    let altService = AlertService()
    MasterPilotDashboard()
        .environmentObject(ThemeManager())
        .environmentObject(locService)
        .environmentObject(altService)
        .environmentObject(WebSocketService())
        .environmentObject(AlertSoundManager())
        .environmentObject(NavigationViewModel(locationService: locService, alertService: altService))
        .environmentObject(AlertViewModel(alertService: altService))
}
