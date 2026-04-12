import SwiftUI

// MARK: - Nearby Users Indicator
/// HUD overlay showing the count of active nearby users
struct NearbyUsersIndicator: View {
    @EnvironmentObject private var webSocketService: WebSocketService

    var body: some View {
        if webSocketService.nearbyUsersCount > 0 {
            HStack(spacing: DesignTokens.Spacing.xs) {
                Image(systemName: "person.2.fill")
                    .font(.system(size: 11))

                Text("\(webSocketService.nearbyUsersCount)")
                    .font(Typography.hudLabel(size: 11))
            }
            .foregroundStyle(DesignTokens.Colors.primaryAccent)
            .padding(.horizontal, DesignTokens.Spacing.sm)
            .padding(.vertical, DesignTokens.Spacing.xs)
            .background(.ultraThinMaterial)
            .clipShape(Capsule())
        }
    }
}
