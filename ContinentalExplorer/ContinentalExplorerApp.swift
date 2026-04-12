import SwiftUI

@main
struct ContinentalExplorerApp: App {
    @StateObject private var themeManager = ThemeManager()
    @StateObject private var locationService = LocationService()
    @StateObject private var alertService = AlertService()
    
    let persistenceController = PersistenceController.shared
    
    var body: some Scene {
        WindowGroup {
            MasterPilotDashboard()
                .environmentObject(themeManager)
                .environmentObject(locationService)
                .environmentObject(alertService)
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .preferredColorScheme(.dark)
        }
    }
}
