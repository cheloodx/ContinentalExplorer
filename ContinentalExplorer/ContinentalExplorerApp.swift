import SwiftUI
import Combine

@main
struct ContinentalExplorerApp: App {
    @StateObject private var themeManager = ThemeManager()
    @StateObject private var locationService = LocationService()
    @StateObject private var alertService = AlertService()
    @StateObject private var webSocketService = WebSocketService()
    @StateObject private var soundManager = AlertSoundManager()

    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            MasterPilotDashboard()
                .environmentObject(themeManager)
                .environmentObject(locationService)
                .environmentObject(alertService)
                .environmentObject(webSocketService)
                .environmentObject(soundManager)
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .preferredColorScheme(.dark)
                .onAppear {
                    setupWebSocketConnection()
                }
        }
    }

    private func setupWebSocketConnection() {
        // Connect to WebSocket server
        // In production, this URL would come from a config or environment variable
        let wsURL = "wss://continental-explorer-api.example.com/ws"
        webSocketService.connect(to: wsURL)

        // Bind WebSocket streams to alert service
        alertService.bindToWebSocket(webSocketService)
    }
}
