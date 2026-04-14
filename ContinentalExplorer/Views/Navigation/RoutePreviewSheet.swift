import SwiftUI
import MapKit

// MARK: - Route Preview Sheet (Destination selected, before navigation starts)
struct RoutePreviewSheet: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @ObservedObject var navigationVM: NavigationViewModel
    @ObservedObject var routeService: RouteService
    let onStartNavigation: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Drag Handle
            RoundedRectangle(cornerRadius: 2.5)
                .fill(DesignTokens.Colors.textTertiary.opacity(0.4))
                .frame(width: 40, height: 5)
                .padding(.top, DesignTokens.Spacing.sm)

            // Destination Info
            destinationHeader

            Divider()
                .background(DesignTokens.Colors.surfaceElevated)

            // Transport Mode Selector
            transportModeSelector

            // Route Options
            if routeService.isCalculating {
                ProgressView("Calculating routes...")
                    .tint(DesignTokens.Colors.primaryAccent)
                    .padding(.vertical, DesignTokens.Spacing.xl)
            } else {
                routeOptionsList
            }

            // Start Navigation Button
            startButton

            Spacer().frame(height: DesignTokens.Spacing.md)
        }
        .background(DesignTokens.Colors.surfacePrimary)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.xl))
    }

    // MARK: - Header
    private var destinationHeader: some View {
        HStack(spacing: DesignTokens.Spacing.md) {
            Image(systemName: "mappin.circle.fill")
                .font(.system(size: 28))
                .foregroundStyle(DesignTokens.Colors.danger)

            VStack(alignment: .leading, spacing: 2) {
                Text(navigationVM.destination?.name ?? "Destination")
                    .font(Typography.headline(.h5))
                    .foregroundStyle(DesignTokens.Colors.textPrimary)
                    .lineLimit(1)

                Text(navigationVM.destination?.address ?? "")
                    .font(Typography.body(.sm))
                    .foregroundStyle(DesignTokens.Colors.textTertiary)
                    .lineLimit(1)
            }

            Spacer()

            Button(action: onDismiss) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(DesignTokens.Colors.textTertiary)
            }
        }
        .padding(DesignTokens.Spacing.md)
    }

    // MARK: - Transport Mode
    private var transportModeSelector: some View {
        HStack(spacing: DesignTokens.Spacing.md) {
            ForEach(TransportMode.allCases, id: \.self) { mode in
                Button {
                    navigationVM.transportMode = mode
                    Task { await navigationVM.startRouteCalculation() }
                } label: {
                    HStack(spacing: DesignTokens.Spacing.xs) {
                        Image(systemName: mode.iconName)
                            .font(.system(size: 16))
                        Text(mode.rawValue)
                            .font(Typography.bodyMedium(.sm))
                    }
                    .foregroundStyle(
                        navigationVM.transportMode == mode ?
                            DesignTokens.Colors.primaryAccent :
                            DesignTokens.Colors.textTertiary
                    )
                    .padding(.horizontal, DesignTokens.Spacing.md)
                    .padding(.vertical, DesignTokens.Spacing.sm)
                    .background(
                        navigationVM.transportMode == mode ?
                            DesignTokens.Colors.primaryAccent.opacity(0.15) :
                            DesignTokens.Colors.surfaceSecondary
                    )
                    .clipShape(Capsule())
                }
            }
            Spacer()
        }
        .padding(.horizontal, DesignTokens.Spacing.md)
        .padding(.vertical, DesignTokens.Spacing.sm)
    }

    // MARK: - Route Options
    private var routeOptionsList: some View {
        ScrollView {
            VStack(spacing: DesignTokens.Spacing.sm) {
                ForEach(routeService.calculatedRoutes) { route in
                    RouteOptionCard(
                        route: route,
                        isSelected: routeService.selectedRoute?.id == route.id
                    ) {
                        routeService.selectRoute(route)
                    }
                }
            }
            .padding(.horizontal, DesignTokens.Spacing.md)
            .padding(.vertical, DesignTokens.Spacing.sm)
        }
        .frame(maxHeight: 200)
    }

    // MARK: - Start Button
    private var startButton: some View {
        Button(action: onStartNavigation) {
            HStack(spacing: DesignTokens.Spacing.sm) {
                Image(systemName: "location.north.fill")
                    .font(.system(size: 18, weight: .bold))
                Text("Start Navigation")
                    .font(Typography.headline(.h5))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, DesignTokens.Spacing.md)
            .background(DesignTokens.Colors.primaryAccent)
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.md))
        }
        .disabled(routeService.selectedRoute == nil || routeService.isCalculating)
        .opacity(routeService.selectedRoute == nil ? 0.5 : 1)
        .padding(.horizontal, DesignTokens.Spacing.md)
        .padding(.top, DesignTokens.Spacing.sm)
    }
}

// MARK: - Route Option Card
struct RouteOptionCard: View {
    let route: CalculatedRoute
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: DesignTokens.Spacing.md) {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                    Text(route.name)
                        .font(Typography.bodyMedium(.md))
                        .foregroundStyle(DesignTokens.Colors.textPrimary)

                    Text("via \(route.route.name)")
                        .font(Typography.body(.sm))
                        .foregroundStyle(DesignTokens.Colors.textTertiary)
                        .lineLimit(1)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: DesignTokens.Spacing.xs) {
                    Text(route.formattedETA)
                        .font(Typography.headline(.h5))
                        .foregroundStyle(
                            isSelected ? DesignTokens.Colors.primaryAccent : DesignTokens.Colors.textPrimary
                        )

                    Text(route.formattedDistance)
                        .font(Typography.body(.sm))
                        .foregroundStyle(DesignTokens.Colors.textTertiary)
                }
            }
            .padding(DesignTokens.Spacing.md)
            .background(
                isSelected ?
                    DesignTokens.Colors.primaryAccent.opacity(0.1) :
                    DesignTokens.Colors.surfaceSecondary
            )
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.md))
            .overlay(
                RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.md)
                    .stroke(
                        isSelected ? DesignTokens.Colors.primaryAccent : Color.clear,
                        lineWidth: 1.5
                    )
            )
        }
        .buttonStyle(.plain)
    }
}
