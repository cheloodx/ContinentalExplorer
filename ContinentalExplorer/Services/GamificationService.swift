import Foundation
import Combine

// MARK: - Gamification Service
@MainActor
final class GamificationService: ObservableObject {

    // MARK: - Published
    @Published var userProfile: UserProfile
    @Published var recentXPEvents: [XPGainEvent] = []
    @Published var showXPPopup: Bool = false
    @Published var lastXPGain: XPGainEvent?
    @Published var leaderboard: [LeaderboardEntry] = []
    @Published var weeklyChallenge: WeeklyChallenge?

    // MARK: - Private
    private var cancellables = Set<AnyCancellable>()
    private let xpMultiplier: Double = 1.0
    private let maxRecentEvents = 20

    // MARK: - XP Level Table
    private static let levelXPTable: [Int: Int] = {
        var table: [Int: Int] = [:]
        for level in 1...200 {
            table[level] = 100 + (level - 1) * 50
        }
        return table
    }()

    init(userProfile: UserProfile = UserProfile()) {
        self.userProfile = userProfile
        loadSampleData()
    }

    // MARK: - XP Management
    func awardXP(for eventType: XPEventType, multiplier: Double = 1.0) {
        let baseXP = eventType.baseXP
        let totalXP = Int(Double(baseXP) * multiplier * xpMultiplier)

        let event = XPGainEvent(
            type: eventType,
            amount: totalXP,
            timestamp: Date()
        )

        recentXPEvents.insert(event, at: 0)
        if recentXPEvents.count > maxRecentEvents {
            recentXPEvents = Array(recentXPEvents.prefix(maxRecentEvents))
        }

        userProfile.totalXP += totalXP
        userProfile.currentLevelXP += totalXP

        // Level up check
        while userProfile.currentLevelXP >= userProfile.xpToNextLevel {
            userProfile.currentLevelXP -= userProfile.xpToNextLevel
            userProfile.level += 1
            userProfile.xpToNextLevel = Self.levelXPTable[userProfile.level] ?? (100 + (userProfile.level - 1) * 50)
            userProfile.rank = DriverRank.rank(for: userProfile.level)
        }

        lastXPGain = event
        showXPPopup = true

        // Auto-dismiss popup
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            self?.showXPPopup = false
        }
    }

    // MARK: - Trip Tracking
    func completedTrip(distanceKm: Double, durationMinutes: Int, wasSafe: Bool) {
        userProfile.totalTrips += 1
        userProfile.totalDistanceKm += distanceKm

        awardXP(for: .tripCompleted)

        if wasSafe {
            awardXP(for: .safeTrip)
        }

        // Check distance milestones
        checkDistanceMilestones()
    }

    func reportSubmitted() {
        userProfile.totalReports += 1
        awardXP(for: .reportSubmitted)
        checkReportMilestones()
    }

    func reportUpvoted() {
        userProfile.totalUpvotes += 1
        awardXP(for: .reportUpvoted)
    }

    func visitedCountry(_ country: String) {
        guard !userProfile.countriesVisited.contains(country) else { return }
        userProfile.countriesVisited.append(country)
        awardXP(for: .countryVisited)
        checkCountryMilestones()
    }

    func dailyLogin() {
        let calendar = Calendar.current
        if !calendar.isDateInToday(userProfile.lastActiveDate) {
            if calendar.isDateInYesterday(userProfile.lastActiveDate) {
                userProfile.streakDays += 1
            } else {
                userProfile.streakDays = 1
            }
            userProfile.lastActiveDate = Date()
            awardXP(for: .dailyLogin, multiplier: min(Double(userProfile.streakDays), 5.0))
            checkStreakMilestones()
        }
    }

    // MARK: - Achievement Checks
    private func checkDistanceMilestones() {
        let milestones: [(Double, String)] = [
            (100, "Century Rider"),
            (500, "Road Warrior"),
            (1000, "Thousand Miler"),
            (5000, "Continental Crosser"),
            (10000, "European Legend"),
        ]

        for (distance, title) in milestones {
            if userProfile.totalDistanceKm >= distance {
                unlockAchievement(
                    type: .distanceMilestone,
                    title: title,
                    description: "Travel \(Int(distance)) km total",
                    iconName: "road.lanes",
                    xpReward: Int(distance / 10),
                    tokenReward: distance / 100
                )
            }
        }
    }

    private func checkReportMilestones() {
        let milestones: [(Int, String)] = [
            (1, "First Report"),
            (10, "Community Helper"),
            (50, "Report Master"),
            (100, "Guardian Angel"),
        ]

        for (count, title) in milestones {
            if userProfile.totalReports >= count {
                unlockAchievement(
                    type: .reportHero,
                    title: title,
                    description: "Submit \(count) community reports",
                    iconName: "exclamationmark.triangle.fill",
                    xpReward: count * 10,
                    tokenReward: Double(count) / 10
                )
            }
        }
    }

    private func checkCountryMilestones() {
        let milestones: [(Int, String)] = [
            (3, "Border Hopper"),
            (5, "Euro Traveler"),
            (10, "Continental Explorer"),
            (20, "Globe Trotter"),
        ]

        for (count, title) in milestones {
            if userProfile.countriesVisited.count >= count {
                unlockAchievement(
                    type: .countryExplorer,
                    title: title,
                    description: "Visit \(count) countries",
                    iconName: "globe.europe.africa.fill",
                    xpReward: count * 50,
                    tokenReward: Double(count) * 2
                )
            }
        }
    }

    private func checkStreakMilestones() {
        let milestones: [(Int, String)] = [
            (7, "Week Warrior"),
            (30, "Monthly Master"),
            (100, "Streak Legend"),
        ]

        for (days, title) in milestones {
            if userProfile.streakDays >= days {
                unlockAchievement(
                    type: .streakKeeper,
                    title: title,
                    description: "Maintain a \(days)-day login streak",
                    iconName: "flame.fill",
                    xpReward: days * 5,
                    tokenReward: Double(days) / 5
                )
            }
        }
    }

    private func unlockAchievement(
        type: AchievementType,
        title: String,
        description: String,
        iconName: String,
        xpReward: Int,
        tokenReward: Double
    ) {
        // Check if already unlocked
        guard !userProfile.achievements.contains(where: { $0.title == title && $0.isUnlocked }) else { return }

        // Check if exists but not unlocked
        if let index = userProfile.achievements.firstIndex(where: { $0.title == title }) {
            userProfile.achievements[index].isUnlocked = true
            userProfile.achievements[index].unlockedDate = Date()
            userProfile.achievements[index].progress = 1.0
        } else {
            let achievement = Achievement(
                type: type,
                title: title,
                description: description,
                iconName: iconName,
                xpReward: xpReward,
                tokenReward: tokenReward,
                isUnlocked: true,
                unlockedDate: Date(),
                progress: 1.0
            )
            userProfile.achievements.append(achievement)
        }

        awardXP(for: .achievementUnlocked)
        userProfile.travelTokenBalance += tokenReward
    }

    // MARK: - Sample Data
    private func loadSampleData() {
        leaderboard = [
            LeaderboardEntry(rank: 1, username: "EuroRider99", level: 42, totalXP: 25800, country: "Germany"),
            LeaderboardEntry(rank: 2, username: "RoadWarriorRO", level: 38, totalXP: 21500, country: "Romania"),
            LeaderboardEntry(rank: 3, username: "ParisNavigator", level: 35, totalXP: 19200, country: "France"),
            LeaderboardEntry(rank: 4, username: "AlpineExplorer", level: 31, totalXP: 16800, country: "Austria"),
            LeaderboardEntry(rank: 5, username: "Explorer", level: 1, totalXP: 0, country: "Romania"),
        ]

        weeklyChallenge = WeeklyChallenge(
            title: "Weekend Explorer",
            description: "Complete 5 trips this week",
            targetValue: 5,
            currentValue: 0,
            xpReward: 500,
            tokenReward: 5.0,
            expiresAt: Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
        )

        // Seed some achievements as locked targets
        let seedAchievements: [Achievement] = [
            Achievement(type: .firstTrip, title: "First Steps", description: "Complete your first trip", iconName: "figure.walk", xpReward: 50),
            Achievement(type: .distanceMilestone, title: "Century Rider", description: "Travel 100 km total", iconName: "road.lanes", xpReward: 10),
            Achievement(type: .countryExplorer, title: "Border Hopper", description: "Visit 3 countries", iconName: "globe.europe.africa.fill", xpReward: 150),
            Achievement(type: .communityHelper, title: "First Report", description: "Submit your first community report", iconName: "exclamationmark.triangle.fill", xpReward: 10),
            Achievement(type: .safeDriver, title: "Safe Journey", description: "Complete 10 trips without speeding", iconName: "shield.checkered", xpReward: 200),
            Achievement(type: .nightOwl, title: "Night Owl", description: "Complete 5 trips at night", iconName: "moon.fill", xpReward: 100),
            Achievement(type: .offlineExplorer, title: "Offline Ready", description: "Download 3 offline map regions", iconName: "arrow.down.circle.fill", xpReward: 75),
        ]
        userProfile.achievements = seedAchievements
    }
}

// MARK: - XP Gain Event
struct XPGainEvent: Identifiable {
    let id = UUID()
    let type: XPEventType
    let amount: Int
    let timestamp: Date
}

// MARK: - Leaderboard Entry
struct LeaderboardEntry: Identifiable {
    let id = UUID()
    let rank: Int
    let username: String
    let level: Int
    let totalXP: Int
    let country: String
}

// MARK: - Weekly Challenge
struct WeeklyChallenge: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let targetValue: Int
    var currentValue: Int
    let xpReward: Int
    let tokenReward: Double
    let expiresAt: Date

    var progress: Double {
        guard targetValue > 0 else { return 0 }
        return min(Double(currentValue) / Double(targetValue), 1.0)
    }

    var isComplete: Bool {
        currentValue >= targetValue
    }

    var timeRemaining: String {
        let interval = expiresAt.timeIntervalSinceNow
        if interval <= 0 { return "Expired" }
        let days = Int(interval) / 86400
        let hours = (Int(interval) % 86400) / 3600
        if days > 0 { return "\(days)d \(hours)h" }
        return "\(hours)h"
    }
}
