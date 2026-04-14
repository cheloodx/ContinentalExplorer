import Foundation

// MARK: - User Profile
struct UserProfile: Codable, Identifiable {
    let id: UUID
    var username: String
    var displayName: String
    var avatarURL: String?
    var level: Int
    var totalXP: Int
    var currentLevelXP: Int
    var xpToNextLevel: Int
    var rank: DriverRank
    var totalDistanceKm: Double
    var totalTrips: Int
    var totalReports: Int
    var totalUpvotes: Int
    var countriesVisited: [String]
    var achievements: [Achievement]
    var travelTokenBalance: Double
    var joinedDate: Date
    var streakDays: Int
    var lastActiveDate: Date

    init(
        id: UUID = UUID(),
        username: String = "Explorer",
        displayName: String = "Continental Explorer",
        avatarURL: String? = nil,
        level: Int = 1,
        totalXP: Int = 0,
        currentLevelXP: Int = 0,
        xpToNextLevel: Int = 100,
        rank: DriverRank = .rookie,
        totalDistanceKm: Double = 0,
        totalTrips: Int = 0,
        totalReports: Int = 0,
        totalUpvotes: Int = 0,
        countriesVisited: [String] = [],
        achievements: [Achievement] = [],
        travelTokenBalance: Double = 0,
        joinedDate: Date = Date(),
        streakDays: Int = 0,
        lastActiveDate: Date = Date()
    ) {
        self.id = id
        self.username = username
        self.displayName = displayName
        self.avatarURL = avatarURL
        self.level = level
        self.totalXP = totalXP
        self.currentLevelXP = currentLevelXP
        self.xpToNextLevel = xpToNextLevel
        self.rank = rank
        self.totalDistanceKm = totalDistanceKm
        self.totalTrips = totalTrips
        self.totalReports = totalReports
        self.totalUpvotes = totalUpvotes
        self.countriesVisited = countriesVisited
        self.achievements = achievements
        self.travelTokenBalance = travelTokenBalance
        self.joinedDate = joinedDate
        self.streakDays = streakDays
        self.lastActiveDate = lastActiveDate
    }

    var levelProgress: Double {
        guard xpToNextLevel > 0 else { return 1.0 }
        return Double(currentLevelXP) / Double(xpToNextLevel)
    }

    var formattedDistance: String {
        if totalDistanceKm >= 1000 {
            return String(format: "%.0fk km", totalDistanceKm / 1000)
        }
        return String(format: "%.0f km", totalDistanceKm)
    }
}

// MARK: - Driver Rank
enum DriverRank: String, Codable, CaseIterable {
    case rookie = "Rookie"
    case explorer = "Explorer"
    case navigator = "Navigator"
    case pathfinder = "Pathfinder"
    case trailblazer = "Trailblazer"
    case legend = "Legend"

    var iconName: String {
        switch self {
        case .rookie: return "star"
        case .explorer: return "star.fill"
        case .navigator: return "star.leadinghalf.filled"
        case .pathfinder: return "star.circle.fill"
        case .trailblazer: return "flame.fill"
        case .legend: return "crown.fill"
        }
    }

    var minLevel: Int {
        switch self {
        case .rookie: return 1
        case .explorer: return 5
        case .navigator: return 15
        case .pathfinder: return 30
        case .trailblazer: return 50
        case .legend: return 100
        }
    }

    static func rank(for level: Int) -> DriverRank {
        for rank in DriverRank.allCases.reversed() {
            if level >= rank.minLevel { return rank }
        }
        return .rookie
    }
}

// MARK: - Achievement
struct Achievement: Codable, Identifiable {
    let id: UUID
    let type: AchievementType
    let title: String
    let description: String
    let iconName: String
    let xpReward: Int
    let tokenReward: Double
    var isUnlocked: Bool
    var unlockedDate: Date?
    var progress: Double

    init(
        id: UUID = UUID(),
        type: AchievementType,
        title: String,
        description: String,
        iconName: String,
        xpReward: Int,
        tokenReward: Double = 0,
        isUnlocked: Bool = false,
        unlockedDate: Date? = nil,
        progress: Double = 0
    ) {
        self.id = id
        self.type = type
        self.title = title
        self.description = description
        self.iconName = iconName
        self.xpReward = xpReward
        self.tokenReward = tokenReward
        self.isUnlocked = isUnlocked
        self.unlockedDate = unlockedDate
        self.progress = progress
    }
}

// MARK: - Achievement Type
enum AchievementType: String, Codable, CaseIterable {
    case firstTrip = "First Trip"
    case distanceMilestone = "Distance Milestone"
    case countryExplorer = "Country Explorer"
    case communityHelper = "Community Helper"
    case speedMaster = "Speed Master"
    case nightOwl = "Night Owl"
    case weekendWarrior = "Weekend Warrior"
    case streakKeeper = "Streak Keeper"
    case reportHero = "Report Hero"
    case safeDriver = "Safe Driver"
    case offlineExplorer = "Offline Explorer"
    case socialButterfly = "Social Butterfly"

    var category: String {
        switch self {
        case .firstTrip, .distanceMilestone, .countryExplorer:
            return "Exploration"
        case .communityHelper, .reportHero, .socialButterfly:
            return "Community"
        case .speedMaster, .safeDriver, .nightOwl:
            return "Driving"
        case .weekendWarrior, .streakKeeper, .offlineExplorer:
            return "Dedication"
        }
    }
}

// MARK: - XP Event
enum XPEventType: String, CaseIterable {
    case tripCompleted = "Trip Completed"
    case reportSubmitted = "Report Submitted"
    case reportUpvoted = "Report Upvoted"
    case achievementUnlocked = "Achievement Unlocked"
    case dailyLogin = "Daily Login"
    case countryVisited = "Country Visited"
    case safeTrip = "Safe Trip"
    case offlineMapDownloaded = "Offline Map Downloaded"

    var baseXP: Int {
        switch self {
        case .tripCompleted: return 50
        case .reportSubmitted: return 15
        case .reportUpvoted: return 5
        case .achievementUnlocked: return 100
        case .dailyLogin: return 10
        case .countryVisited: return 200
        case .safeTrip: return 25
        case .offlineMapDownloaded: return 10
        }
    }

    var iconName: String {
        switch self {
        case .tripCompleted: return "flag.checkered"
        case .reportSubmitted: return "exclamationmark.triangle.fill"
        case .reportUpvoted: return "hand.thumbsup.fill"
        case .achievementUnlocked: return "trophy.fill"
        case .dailyLogin: return "calendar.badge.checkmark"
        case .countryVisited: return "globe.europe.africa.fill"
        case .safeTrip: return "shield.checkered"
        case .offlineMapDownloaded: return "arrow.down.circle.fill"
        }
    }
}
