import SwiftUI
import MapKit

// MARK: - Navigation Mode View (Active turn-by-turn)
struct NavigationModeView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @ObservedObject var navigationVM: NavigationViewModel
    @ObservedObject var routeService: RouteService
    @ObservedObject var voiceService: VoiceGuidanceService

    var body: some View {
        VStack(spacing: 0) {
            // Turn Direction Banner (top)
            turnDirectionBanner

            Spacer()

            // Bottom Navigation Bar
            bottomNavigationBar
        }
    }

    // MARK: - Turn Direction Banner
    private var turnDirectionBanner: some View {
        VStack(spacing: 0) {
            if let step = routeService.currentStep {
                HStack(spacing: DesignTokens.Spacing.md) {
                    // Maneuver Icon
                    Image(systemName: step.maneuverType.rawValue)
                        .font(.system(size: 32, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 56, height: 56)
                        .background(DesignTokens.Colors.primaryAccent)
                        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.md))

                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                        Text(routeService.formattedDistanceToNext)
                            .font(Typography.headline(.h2))
                            .foregroundStyle(DesignTokens.Colors.textPrimary)

                        Text(step.instruction)
                            .font(Typography.bodyMedium(.md))
                            .foregroundStyle(DesignTokens.Colors.textSecondary)
                            .lineLimit(2)
                    }

                    Spacer()
                }
                .padding(DesignTokens.Spacing.md)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.lg))
                .shadow(color: .black.opacity(0.2), radius: 8, y: 2)
                .padding(.horizontal, DesignTokens.Spacing.md)
                .padding(.top, DesignTokens.Spacing.sm)

                // Next step preview
                if let nextStep = routeService.nextStep {
                    HStack(spacing: DesignTokens.Spacing.sm) {
                        Text("Then")
                            .font(Typography.body(.sm))
                            .foregroundStyle(DesignTokens.Colors.textTertiary)

                        Image(systemName: nextStep.maneuverType.rawValue)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(DesignTokens.Colors.primaryAccent)

                        Text(nextStep.instruction)
                            .font(Typography.body(.sm))
                            .foregroundStyle(DesignTokens.Colors.textSecondary)
                            .lineLimit(1)

                        Spacer()
                    }
                    .padding(.horizontal, DesignTokens.Spacing.lg + 4)
                    .padding(.vertical, DesignTokens.Spacing.xs)
                }
            }
        }
    }

    // MARK: - Bottom Navigation Bar
    private var bottomNavigationBar: some View {
        HStack(spacing: DesignTokens.Spacing.lg) {
            // ETA
            VStack(spacing: 2) {
                Text(navigationVM.arrivalTime)
                    .font(Typography.headline(.h4))
                    .foregroundStyle(DesignTokens.Colors.primaryAccent)
                Text("ETA")
                    .font(Typography.body(.xxs))
                    .foregroundStyle(DesignTokens.Colors.textTertiary)
            }

            Divider()
                .frame(height: 30)

            // Distance
            VStack(spacing: 2) {
                Text(navigationVM.distanceRemaining)
                    .font(Typography.headline(.h4))
                    .foregroundStyle(DesignTokens.Colors.textPrimary)
                Text("Distance")
                    .font(Typography.body(.xxs))
                    .foregroundStyle(DesignTokens.Colors.textTertiary)
            }

            Divider()
                .frame(height: 30)

            // Time
            VStack(spacing: 2) {
                Text(navigationVM.timeRemaining)
                    .font(Typography.headline(.h4))
                    .foregroundStyle(DesignTokens.Colors.textPrimary)
                Text("Time")
                    .font(Typography.body(.xxs))
                    .foregroundStyle(DesignTokens.Colors.textTertiary)
            }

            Spacer()

            // Voice toggle
            Button {
                voiceService.toggle()
            } label: {
                Image(systemName: voiceService.isEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(
                        voiceService.isEnabled ? DesignTokens.Colors.primaryAccent : DesignTokens.Colors.textTertiary
                    )
                    .frame(width: 40, height: 40)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
            }

            // Stop navigation
            Button {
                navigationVM.stopNavigation()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 40, height: 40)
                    .background(DesignTokens.Colors.danger)
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, DesignTokens.Spacing.lg)
        .padding(.vertical, DesignTokens.Spacing.md)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.xl))
        .shadow(color: .black.opacity(0.2), radius: 8, y: -2)
        .padding(.horizontal, DesignTokens.Spacing.md)
        .padding(.bottom, DesignTokens.Spacing.md)
    }
}
