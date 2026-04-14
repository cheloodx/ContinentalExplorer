import SwiftUI

// MARK: - User Profile View
struct UserProfileView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @ObservedObject var gamificationService: GamificationService
    @ObservedObject var tokenService: TravelTokenService
    @ObservedObject var auraService: AuraAIService

    @State private var showRoadXP = false
    @State private var showAuraAI = false
    @State private var showTokenWallet = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: DesignTokens.Spacing.lg) {
                    // Profile Card
                    profileCard

                    // Quick Access Cards
                    quickAccessSection

                    // Stats Grid
                    statsGrid

                    // Recent Achievements
                    recentAchievements
                }
                .padding(.horizontal, DesignTokens.Spacing.md)
                .padding(.bottom, DesignTokens.Spacing.xxl)
            }
            .background(DesignTokens.Colors.backgroundDark)
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .sheet(isPresented: $showRoadXP) {
                RoadXPDashboardView(gamificationService: gamificationService)
            }
            .sheet(isPresented: $showAuraAI) {
                AuraAIView(auraService: auraService)
            }
            .sheet(isPresented: $showTokenWallet) {
                TravelTokenView(tokenService: tokenService)
            }
        }
    }

    // MARK: - Profile Card
    private var profileCard: some View {
        VStack(spacing: DesignTokens.Spacing.md) {
            // Avatar
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [DesignTokens.Colors.primaryAccent, DesignTokens.Colors.secondaryAccent],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 90, height: 90)

                Image(systemName: gamificationService.userProfile.rank.iconName)
                    .font(.system(size: 36))
                    .foregroundStyle(.white)

                // Level Badge
                Text("\(gamificationService.userProfile.level)")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(DesignTokens.Colors.primaryAccent)
                    .clipShape(Capsule())
                    .offset(x: 32, y: 32)
            }

            Text(gamificationService.userProfile.displayName)
                .font(Typography.headline(.h3))
                .foregroundStyle(DesignTokens.Colors.textPrimary)

            HStack(spacing: DesignTokens.Spacing.sm) {
                Image(systemName: gamificationService.userProfile.rank.iconName)
                    .foregroundStyle(DesignTokens.Colors.secondaryAccent)
                Text(gamificationService.userProfile.rank.rawValue)
                    .font(Typography.bodyMedium(.md))
                    .foregroundStyle(DesignTokens.Colors.secondaryAccent)
            }

            // XP Progress
            VStack(spacing: DesignTokens.Spacing.xs) {
                HStack {
                    Text("Level \(gamificationService.userProfile.level)")
                        .font(Typography.bodyMedium(.sm))
                        .foregroundStyle(DesignTokens.Colors.textPrimary)
                    Spacer()
                    Text("Level \(gamificationService.userProfile.level + 1)")
                        .font(Typography.body(.sm))
                        .foregroundStyle(DesignTokens.Colors.textTertiary)
                }

                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(DesignTokens.Colors.surfaceSecondary)
                            .frame(height: 10)
                        RoundedRectangle(cornerRadius: 6)
                            .fill(
                                LinearGradient(
                                    colors: [DesignTokens.Colors.primaryAccent, DesignTokens.Colors.secondaryAccent],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geometry.size.width * gamificationService.userProfile.levelProgress, height: 10)
                    }
                }
                .frame(height: 10)

                Text("\(gamificationService.userProfile.currentLevelXP) / \(gamificationService.userProfile.xpToNextLevel) XP")
                    .font(Typography.body(.xs))
                    .foregroundStyle(DesignTokens.Colors.textTertiary)
            }

            // Token Balance
            HStack(spacing: DesignTokens.Spacing.sm) {
                Image(systemName: "bitcoinsign.circle.fill")
                    .foregroundStyle(DesignTokens.Colors.secondaryAccent)
                Text(tokenService.formattedBalance)
                    .font(Typography.headline(.h4))
                    .foregroundStyle(DesignTokens.Colors.secondaryAccent)
            }
        }
        .padding(DesignTokens.Spacing.lg)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.xl))
    }

    // MARK: - Quick Access Section
    private var quickAccessSection: some View {
        HStack(spacing: DesignTokens.Spacing.md) {
            QuickAccessCard(
                icon: "star.fill",
                title: "Road XP",
                subtitle: "Level \(gamificationService.userProfile.level)",
                color: DesignTokens.Colors.primaryAccent
            ) {
                showRoadXP = true
            }

            QuickAccessCard(
                icon: "brain.head.profile",
                title: "Aura AI",
                subtitle: auraService.isScanning ? "Active" : "Idle",
                color: DesignTokens.Colors.success
            ) {
                showAuraAI = true
            }

            QuickAccessCard(
                icon: "bitcoinsign.circle.fill",
                title: "Tokens",
                subtitle: tokenService.formattedBalance,
                color: DesignTokens.Colors.secondaryAccent
            ) {
                showTokenWallet = true
            }
        }
    }

    // MARK: - Stats Grid
    private var statsGrid: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            Text("Statistics")
                .font(Typography.headline(.h5))
                .foregroundStyle(DesignTokens.Colors.textPrimary)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: DesignTokens.Spacing.sm) {
                ProfileStatCard(icon: "car.fill", value: "\(gamificationService.userProfile.totalTrips)", label: "Total Trips")
                ProfileStatCard(icon: "road.lanes", value: gamificationService.userProfile.formattedDistance, label: "Distance")
                ProfileStatCard(icon: "globe.europe.africa.fill", value: "\(gamificationService.userProfile.countriesVisited.count)", label: "Countries")
                ProfileStatCard(icon: "exclamationmark.triangle.fill", value: "\(gamificationService.userProfile.totalReports)", label: "Reports")
                ProfileStatCard(icon: "hand.thumbsup.fill", value: "\(gamificationService.userProfile.totalUpvotes)", label: "Upvotes")
                ProfileStatCard(icon: "flame.fill", value: "\(gamificationService.userProfile.streakDays)d", label: "Streak")
            }
        }
    }

    // MARK: - Recent Achievements
    private var recentAchievements: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            HStack {
                Text("Achievements")
                    .font(Typography.headline(.h5))
                    .foregroundStyle(DesignTokens.Colors.textPrimary)
                Spacer()
                Button {
                    showRoadXP = true
                } label: {
                    Text("See All")
                        .font(Typography.body(.sm))
                        .foregroundStyle(DesignTokens.Colors.primaryAccent)
                }
                .buttonStyle(.plain)
            }

            let unlockedCount = gamificationService.userProfile.achievements.filter { $0.isUnlocked }.count
            let totalCount = gamificationService.userProfile.achievements.count

            HStack(spacing: DesignTokens.Spacing.sm) {
                Text("\(unlockedCount)/\(totalCount) Unlocked")
                    .font(Typography.body(.sm))
                    .foregroundStyle(DesignTokens.Colors.textTertiary)
                Spacer()
            }

            // Show first few achievements
            ForEach(gamificationService.userProfile.achievements.prefix(4)) { achievement in
                HStack(spacing: DesignTokens.Spacing.md) {
                    Image(systemName: achievement.iconName)
                        .font(.system(size: 18))
                        .foregroundStyle(achievement.isUnlocked ? DesignTokens.Colors.secondaryAccent : DesignTokens.Colors.textTertiary)
                        .frame(width: 36, height: 36)
                        .background(achievement.isUnlocked ? DesignTokens.Colors.secondaryAccent.opacity(0.15) : DesignTokens.Colors.surfaceSecondary)
                        .clipShape(Circle())

                    VStack(alignment: .leading, spacing: 2) {
                        Text(achievement.title)
                            .font(Typography.bodyMedium(.sm))
                            .foregroundStyle(achievement.isUnlocked ? DesignTokens.Colors.textPrimary : DesignTokens.Colors.textTertiary)
                        Text(achievement.description)
                            .font(Typography.body(.xs))
                            .foregroundStyle(DesignTokens.Colors.textTertiary)
                    }

                    Spacer()

                    if achievement.isUnlocked {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(DesignTokens.Colors.success)
                    }
                }
                .padding(DesignTokens.Spacing.sm)
                .background(DesignTokens.Colors.surfacePrimary)
                .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.md))
                .opacity(achievement.isUnlocked ? 1.0 : 0.5)
            }
        }
    }
}

// MARK: - Sub Components
struct QuickAccessCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: DesignTokens.Spacing.sm) {
                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundStyle(color)
                Text(title)
                    .font(Typography.bodyMedium(.sm))
                    .foregroundStyle(DesignTokens.Colors.textPrimary)
                Text(subtitle)
                    .font(Typography.body(.xxs))
                    .foregroundStyle(DesignTokens.Colors.textTertiary)
            }
            .frame(maxWidth: .infinity)
            .padding(DesignTokens.Spacing.md)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.lg))
        }
        .buttonStyle(.plain)
    }
}

struct ProfileStatCard: View {
    let icon: String
    let value: String
    let label: String

    var body: some View {
        HStack(spacing: DesignTokens.Spacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(DesignTokens.Colors.primaryAccent)

            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(Typography.headline(.h5))
                    .foregroundStyle(DesignTokens.Colors.textPrimary)
                Text(label)
                    .font(Typography.body(.xxs))
                    .foregroundStyle(DesignTokens.Colors.textTertiary)
            }

            Spacer()
        }
        .padding(DesignTokens.Spacing.sm)
        .background(DesignTokens.Colors.surfacePrimary)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.md))
    }
}
