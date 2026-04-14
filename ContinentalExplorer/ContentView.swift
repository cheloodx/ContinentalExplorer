import SwiftUI

// MARK: - Content View
/// Root content view that delegates to MasterPilotDashboard
struct ContentView: View {
    var body: some View {
        MasterPilotDashboard()
    }
}

#Preview {
    ContentView()
        .environmentObject(ThemeManager())
        .environmentObject(LocationService())
        .environmentObject(AlertService())
}
