import SwiftUI
import Combine

@main
struct ContinentalExplorerApp: App {
    @StateObject private var themeManager = ThemeManager()
    @StateObject private var locationService = LocationService()
    @StateObject private var alertService = AlertService()
    @StateObject private var webSocketService = WebSocketService()
    @StateObject private var soundManager = AlertSoundManager()
    @StateObject private var navigationVM: NavigationViewModel
    @StateObject private var alertVM: AlertViewModel

    let persistenceController = PersistenceController.shared

    init() {
        let locService = LocationService()
        let altService = AlertService()
        let routeService = RouteService()
        let voiceService = VoiceGuidanceService()
        let wsService = WebSocketService()
        let sndManager = AlertSoundManager()

        _locationService = StateObject(wrappedValue: locService)
        _alertService = StateObject(wrappedValue: altService)
        _webSocketService = StateObject(wrappedValue: wsService)
        _soundManager = StateObject(wrappedValue: sndManager)
        _navigationVM = StateObject(wrappedValue: NavigationViewModel(
            locationService: locService,
            alertService: altService,
            routeService: routeService,
            voiceService: voiceService,
            webSocketService: wsService,
            soundManager: sndManager
        ))
        _alertVM = StateObject(wrappedValue: AlertViewModel(alertService: altService))
    }

    var body: some Scene {
        WindowGroup {
            MasterPilotDashboard()
                .environmentObject(themeManager)
                .environmentObject(locationService)
                .environmentObject(alertService)
                .environmentObject(webSocketService)
                .environmentObject(soundManager)
                .environmentObject(navigationVM)
                .environmentObject(alertVM)
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .preferredColorScheme(.dark)
                .onAppear {
                    setupWebSocketConnection()
                }
        }
    }

    private func setupWebSocketConnection() {
        let wsURL = "wss://continental-explorer-api.example.com/ws"
        webSocketService.connect(to: wsURL)
        alertService.bindToWebSocket(webSocketService)
    }
}
