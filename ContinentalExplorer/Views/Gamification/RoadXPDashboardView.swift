import SwiftUI

// MARK: - Road XP Dashboard View
struct RoadXPDashboardView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @ObservedObject var gamificationService: GamificationService

    @State private var selectedTab: XPTab = .overview

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: DesignTokens.Spacing.lg) {
                    // Profile Header
                    profileHeader

                    // Tab Selector
                    tabSelector

                    // Tab Content
                    switch selectedTab {
                    case .overview:
                        overviewContent
                    case .achievements:
                        achievementsContent
                    case .leaderboard:
                        leaderboardContent
                    }
                }
                .padding(.horizontal, DesignTokens.Spacing.md)
                .padding(.bottom, DesignTokens.Spacing.xxl)
            }
            .background(DesignTokens.Colors.backgroundDark)
            .navigationTitle("Road XP")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }

    // MARK: - Profile Header
    private var profileHeader: some View {
        VStack(spacing: DesignTokens.Spacing.md) {
            // Avatar and Level
            ZStack {
                Circle()
                    .stroke(DesignTokens.Colors.primaryAccent, lineWidth: 3)
                    .frame(width: 80, height: 80)

                Image(systemName: gamificationService.userProfile.rank.iconName)
                    .font(.system(size: 32))
                    .foregroundStyle(DesignTokens.Colors.primaryAccent)
            }

            Text(gamificationService.userProfile.displayName)
                .font(Typography.headline(.h3))
                .foregroundStyle(DesignTokens.Colors.textPrimary)

            HStack(spacing: DesignTokens.Spacing.sm) {
                Image(systemName: gamificationService.userProfile.rank.iconName)
                    .foregroundStyle(DesignTokens.Colors.secondaryAccent)
                Text(gamificationService.userProfile.rank.rawValue)
                    .font(Typography.bodyMedium(.sm))
                    .foregroundStyle(DesignTokens.Colors.secondaryAccent)
                Text("•")
                    .foregroundStyle(DesignTokens.Colors.textTertiary)
                Text("Level \(gamificationService.userProfile.level)")
                    .font(Typography.bodyMedium(.sm))
                    .foregroundStyle(DesignTokens.Colors.textSecondary)
            }

            // XP Progress Bar
            VStack(spacing: DesignTokens.Spacing.xs) {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(DesignTokens.Colors.surfaceSecondary)
                            .frame(height: 8)

                        RoundedRectangle(cornerRadius: 4)
                            .fill(
                                LinearGradient(
                                    colors: [DesignTokens.Colors.primaryAccent, DesignTokens.Colors.secondaryAccent],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geometry.size.width * gamificationService.userProfile.levelProgress, height: 8)
                    }
                }
                .frame(height: 8)

                HStack {
                    Text("\(gamificationService.userProfile.currentLevelXP) XP")
                        .font(Typography.body(.xs))
                        .foregroundStyle(DesignTokens.Colors.textTertiary)
                    Spacer()
                    Text("\(gamificationService.userProfile.xpToNextLevel) XP")
                        .font(Typography.body(.xs))
                        .foregroundStyle(DesignTokens.Colors.textTertiary)
                }
            }

            // Stats Row
            HStack(spacing: DesignTokens.Spacing.lg) {
                StatBubble(value: "\(gamificationService.userProfile.totalTrips)", label: "Trips")
                StatBubble(value: gamificationService.userProfile.formattedDistance, label: "Distance")
                StatBubble(value: "\(gamificationService.userProfile.countriesVisited.count)", label: "Countries")
                StatBubble(value: "\(gamificationService.userProfile.streakDays)d", label: "Streak")
            }
        }
        .padding(DesignTokens.Spacing.lg)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.xl))
    }

    // MARK: - Tab Selector
    private var tabSelector: some View {
        HStack(spacing: DesignTokens.Spacing.xs) {
            ForEach(XPTab.allCases, id: \.self) { tab in
                Button {
                    withAnimation(DesignTokens.Animation.spring) {
                        selectedTab = tab
                    }
                } label: {
                    Text(tab.rawValue)
                        .font(Typography.bodyMedium(.sm))
                        .foregroundStyle(selectedTab == tab ? .white : DesignTokens.Colors.textTertiary)
                        .padding(.horizontal, DesignTokens.Spacing.md)
                        .padding(.vertical, DesignTokens.Spacing.sm)
                        .background(selectedTab == tab ? DesignTokens.Colors.primaryAccent : Color.clear)
                        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.pill))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(DesignTokens.Spacing.xs)
        .background(DesignTokens.Colors.surfacePrimary)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.pill))
    }

    // MARK: - Overview Content
    private var overviewContent: some View {
        VStack(spacing: DesignTokens.Spacing.md) {
            // Weekly Challenge
            if let challenge = gamificationService.weeklyChallenge {
                WeeklyChallengeCard(challenge: challenge)
            }

            // Recent XP Events
            if !gamificationService.recentXPEvents.isEmpty {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                    Text("Recent Activity")
                        .font(Typography.headline(.h5))
                        .foregroundStyle(DesignTokens.Colors.textPrimary)

                    ForEach(gamificationService.recentXPEvents.prefix(5)) { event in
                        XPEventRow(event: event)
                    }
                }
                .padding(DesignTokens.Spacing.md)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.lg))
            }

            // Quick Stats
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                Text("Statistics")
                    .font(Typography.headline(.h5))
                    .foregroundStyle(DesignTokens.Colors.textPrimary)

                HStack {
                    QuickStatCard(icon: "trophy.fill", value: "\(gamificationService.userProfile.achievements.filter { $0.isUnlocked }.count)", label: "Achievements", color: DesignTokens.Colors.secondaryAccent)
                    QuickStatCard(icon: "exclamationmark.triangle.fill", value: "\(gamificationService.userProfile.totalReports)", label: "Reports", color: DesignTokens.Colors.warning)
                }
                HStack {
                    QuickStatCard(icon: "hand.thumbsup.fill", value: "\(gamificationService.userProfile.totalUpvotes)", label: "Upvotes", color: DesignTokens.Colors.success)
                    QuickStatCard(icon: "star.fill", value: "\(gamificationService.userProfile.totalXP)", label: "Total XP", color: DesignTokens.Colors.primaryAccent)
                }
            }
        }
    }

    // MARK: - Achievements Content
    private var achievementsContent: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            let unlocked = gamificationService.userProfile.achievements.filter { $0.isUnlocked }
            let locked = gamificationService.userProfile.achievements.filter { !$0.isUnlocked }

            if !unlocked.isEmpty {
                Text("Unlocked (\(unlocked.count))")
                    .font(Typography.headline(.h5))
                    .foregroundStyle(DesignTokens.Colors.textPrimary)

                ForEach(unlocked) { achievement in
                    AchievementRow(achievement: achievement, isUnlocked: true)
                }
            }

            if !locked.isEmpty {
                Text("Locked (\(locked.count))")
                    .font(Typography.headline(.h5))
                    .foregroundStyle(DesignTokens.Colors.textTertiary)

                ForEach(locked) { achievement in
                    AchievementRow(achievement: achievement, isUnlocked: false)
                }
            }
        }
    }

    // MARK: - Leaderboard Content
    private var leaderboardContent: some View {
        VStack(spacing: DesignTokens.Spacing.sm) {
            ForEach(gamificationService.leaderboard) { entry in
                LeaderboardRow(entry: entry, isCurrentUser: entry.username == gamificationService.userProfile.username)
            }
        }
    }
}

// MARK: - XP Tab
enum XPTab: String, CaseIterable {
    case overview = "Overview"
    case achievements = "Achievements"
    case leaderboard = "Leaderboard"
}

// MARK: - Sub Components
struct StatBubble: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: DesignTokens.Spacing.xs) {
            Text(value)
                .font(Typography.headline(.h4))
                .foregroundStyle(DesignTokens.Colors.textPrimary)
            Text(label)
                .font(Typography.body(.xxs))
                .foregroundStyle(DesignTokens.Colors.textTertiary)
        }
    }
}

struct WeeklyChallengeCard: View {
    let challenge: WeeklyChallenge

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            HStack {
                Image(systemName: "flame.fill")
                    .foregroundStyle(DesignTokens.Colors.secondaryAccent)
                Text(challenge.title)
                    .font(Typography.headline(.h5))
                    .foregroundStyle(DesignTokens.Colors.textPrimary)
                Spacer()
                Text(challenge.timeRemaining)
                    .font(Typography.body(.xs))
                    .foregroundStyle(DesignTokens.Colors.textTertiary)
            }

            Text(challenge.description)
                .font(Typography.body(.sm))
                .foregroundStyle(DesignTokens.Colors.textSecondary)

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(DesignTokens.Colors.surfaceSecondary)
                        .frame(height: 6)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(DesignTokens.Colors.secondaryAccent)
                        .frame(width: geometry.size.width * challenge.progress, height: 6)
                }
            }
            .frame(height: 6)

            HStack {
                Text("\(challenge.currentValue)/\(challenge.targetValue)")
                    .font(Typography.body(.xs))
                    .foregroundStyle(DesignTokens.Colors.textTertiary)
                Spacer()
                Text("+\(challenge.xpReward) XP • +\(String(format: "%.0f", challenge.tokenReward)) CT")
                    .font(Typography.body(.xs))
                    .foregroundStyle(DesignTokens.Colors.primaryAccent)
            }
        }
        .padding(DesignTokens.Spacing.md)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.lg))
    }
}

struct XPEventRow: View {
    let event: XPGainEvent

    var body: some View {
        HStack(spacing: DesignTokens.Spacing.sm) {
            Image(systemName: event.type.iconName)
                .font(.system(size: 16))
                .foregroundStyle(DesignTokens.Colors.primaryAccent)
                .frame(width: 32, height: 32)
                .background(DesignTokens.Colors.primaryAccent.opacity(0.15))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(event.type.rawValue)
                    .font(Typography.bodyMedium(.sm))
                    .foregroundStyle(DesignTokens.Colors.textPrimary)
            }

            Spacer()

            Text("+\(event.amount) XP")
                .font(Typography.bodyMedium(.sm))
                .foregroundStyle(DesignTokens.Colors.success)
        }
    }
}

struct QuickStatCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        HStack(spacing: DesignTokens.Spacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(color)

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

struct AchievementRow: View {
    let achievement: Achievement
    let isUnlocked: Bool

    var body: some View {
        HStack(spacing: DesignTokens.Spacing.md) {
            Image(systemName: achievement.iconName)
                .font(.system(size: 24))
                .foregroundStyle(isUnlocked ? DesignTokens.Colors.secondaryAccent : DesignTokens.Colors.textTertiary)
                .frame(width: 44, height: 44)
                .background(isUnlocked ? DesignTokens.Colors.secondaryAccent.opacity(0.15) : DesignTokens.Colors.surfaceSecondary)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(achievement.title)
                    .font(Typography.bodyMedium(.md))
                    .foregroundStyle(isUnlocked ? DesignTokens.Colors.textPrimary : DesignTokens.Colors.textTertiary)
                Text(achievement.description)
                    .font(Typography.body(.sm))
                    .foregroundStyle(DesignTokens.Colors.textTertiary)
            }

            Spacer()

            if isUnlocked {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(DesignTokens.Colors.success)
            } else {
                Text("+\(achievement.xpReward) XP")
                    .font(Typography.body(.xs))
                    .foregroundStyle(DesignTokens.Colors.textTertiary)
            }
        }
        .padding(DesignTokens.Spacing.md)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.md))
        .opacity(isUnlocked ? 1.0 : 0.6)
    }
}

struct LeaderboardRow: View {
    let entry: LeaderboardEntry
    let isCurrentUser: Bool

    var body: some View {
        HStack(spacing: DesignTokens.Spacing.md) {
            Text("#\(entry.rank)")
                .font(Typography.headline(.h4))
                .foregroundStyle(entry.rank <= 3 ? DesignTokens.Colors.secondaryAccent : DesignTokens.Colors.textTertiary)
                .frame(width: 40)

            VStack(alignment: .leading, spacing: 2) {
                Text(entry.username)
                    .font(Typography.bodyMedium(.md))
                    .foregroundStyle(isCurrentUser ? DesignTokens.Colors.primaryAccent : DesignTokens.Colors.textPrimary)
                Text("Level \(entry.level) • \(entry.country)")
                    .font(Typography.body(.xs))
                    .foregroundStyle(DesignTokens.Colors.textTertiary)
            }

            Spacer()

            Text("\(entry.totalXP) XP")
                .font(Typography.bodyMedium(.sm))
                .foregroundStyle(DesignTokens.Colors.textSecondary)
        }
        .padding(DesignTokens.Spacing.md)
        .background(isCurrentUser ? DesignTokens.Colors.primaryAccent.opacity(0.1) : .ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.md))
    }
}
