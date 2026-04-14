import XCTest
@testable import ContinentalExplorer

final class Sprint4Tests: XCTestCase {

    // MARK: - UserProfile Tests

    func testUserProfileDefaults() {
        let profile = UserProfile()
        XCTAssertEqual(profile.username, "Explorer")
        XCTAssertEqual(profile.level, 1)
        XCTAssertEqual(profile.totalXP, 0)
        XCTAssertEqual(profile.rank, .rookie)
        XCTAssertEqual(profile.totalTrips, 0)
        XCTAssertEqual(profile.streakDays, 0)
    }

    func testUserProfileLevelProgress() {
        let profile = UserProfile(currentLevelXP: 50, xpToNextLevel: 100)
        XCTAssertEqual(profile.levelProgress, 0.5, accuracy: 0.01)
    }

    func testUserProfileLevelProgressZeroDivision() {
        let profile = UserProfile(currentLevelXP: 50, xpToNextLevel: 0)
        XCTAssertEqual(profile.levelProgress, 1.0)
    }

    func testUserProfileFormattedDistance() {
        let short = UserProfile(totalDistanceKm: 500)
        XCTAssertEqual(short.formattedDistance, "500 km")

        let long = UserProfile(totalDistanceKm: 2500)
        XCTAssertEqual(long.formattedDistance, "3k km")
    }

    func testUserProfileCodable() throws {
        let profile = UserProfile(username: "TestUser", level: 5, totalXP: 500)
        let data = try JSONEncoder().encode(profile)
        let decoded = try JSONDecoder().decode(UserProfile.self, from: data)
        XCTAssertEqual(decoded.username, "TestUser")
        XCTAssertEqual(decoded.level, 5)
        XCTAssertEqual(decoded.totalXP, 500)
    }

    // MARK: - Driver Rank Tests

    func testDriverRankForLevel() {
        XCTAssertEqual(DriverRank.rank(for: 1), .rookie)
        XCTAssertEqual(DriverRank.rank(for: 5), .explorer)
        XCTAssertEqual(DriverRank.rank(for: 15), .navigator)
        XCTAssertEqual(DriverRank.rank(for: 30), .pathfinder)
        XCTAssertEqual(DriverRank.rank(for: 50), .trailblazer)
        XCTAssertEqual(DriverRank.rank(for: 100), .legend)
    }

    func testDriverRankMinLevels() {
        XCTAssertEqual(DriverRank.rookie.minLevel, 1)
        XCTAssertEqual(DriverRank.legend.minLevel, 100)
    }

    func testDriverRankIconNames() {
        for rank in DriverRank.allCases {
            XCTAssertFalse(rank.iconName.isEmpty)
        }
    }

    // MARK: - Achievement Tests

    func testAchievementCreation() {
        let achievement = Achievement(
            type: .firstTrip,
            title: "First Steps",
            description: "Complete your first trip",
            iconName: "figure.walk",
            xpReward: 50
        )
        XCTAssertEqual(achievement.type, .firstTrip)
        XCTAssertEqual(achievement.title, "First Steps")
        XCTAssertFalse(achievement.isUnlocked)
        XCTAssertEqual(achievement.progress, 0)
    }

    func testAchievementTypeCategories() {
        XCTAssertEqual(AchievementType.firstTrip.category, "Exploration")
        XCTAssertEqual(AchievementType.communityHelper.category, "Community")
        XCTAssertEqual(AchievementType.safeDriver.category, "Driving")
        XCTAssertEqual(AchievementType.streakKeeper.category, "Dedication")
    }

    func testAchievementCodable() throws {
        let achievement = Achievement(
            type: .distanceMilestone,
            title: "Century Rider",
            description: "Travel 100 km",
            iconName: "road.lanes",
            xpReward: 10,
            isUnlocked: true,
            progress: 1.0
        )
        let data = try JSONEncoder().encode(achievement)
        let decoded = try JSONDecoder().decode(Achievement.self, from: data)
        XCTAssertEqual(decoded.title, "Century Rider")
        XCTAssertTrue(decoded.isUnlocked)
    }

    // MARK: - XP Event Type Tests

    func testXPEventTypeBaseXP() {
        XCTAssertEqual(XPEventType.tripCompleted.baseXP, 50)
        XCTAssertEqual(XPEventType.reportSubmitted.baseXP, 15)
        XCTAssertEqual(XPEventType.countryVisited.baseXP, 200)
        XCTAssertEqual(XPEventType.dailyLogin.baseXP, 10)
    }

    func testXPEventTypeIconNames() {
        for event in XPEventType.allCases {
            XCTAssertFalse(event.iconName.isEmpty)
        }
    }

    // MARK: - TravelToken Tests

    func testTravelTokenCreation() {
        let token = TravelToken(amount: 5.0, type: .earned, description: "Trip completed")
        XCTAssertEqual(token.amount, 5.0)
        XCTAssertEqual(token.type, .earned)
        XCTAssertTrue(token.isPositive)
        XCTAssertEqual(token.formattedAmount, "+5.0 CT")
    }

    func testTravelTokenSpent() {
        let token = TravelToken(amount: 10.0, type: .spent, description: "Redeemed item")
        XCTAssertFalse(token.isPositive)
        XCTAssertEqual(token.formattedAmount, "-10.0 CT")
    }

    func testTravelTokenCodable() throws {
        let token = TravelToken(amount: 3.5, type: .bonus, description: "Welcome bonus")
        let data = try JSONEncoder().encode(token)
        let decoded = try JSONDecoder().decode(TravelToken.self, from: data)
        XCTAssertEqual(decoded.amount, 3.5)
        XCTAssertEqual(decoded.type, .bonus)
        XCTAssertEqual(decoded.description, "Welcome bonus")
    }

    func testTokenTransactionTypeIcons() {
        for type in TokenTransactionType.allCases {
            XCTAssertFalse(type.iconName.isEmpty)
        }
    }

    // MARK: - Road Health Rating Tests

    func testRoadHealthRatingScores() {
        XCTAssertEqual(RoadHealthRating.excellent.score, 5)
        XCTAssertEqual(RoadHealthRating.good.score, 4)
        XCTAssertEqual(RoadHealthRating.fair.score, 3)
        XCTAssertEqual(RoadHealthRating.poor.score, 2)
        XCTAssertEqual(RoadHealthRating.dangerous.score, 1)
    }

    func testRoadHealthRatingIcons() {
        for rating in RoadHealthRating.allCases {
            XCTAssertFalse(rating.iconName.isEmpty)
        }
    }

    // MARK: - Road Scan Result Tests

    func testRoadScanResultCreation() {
        let result = RoadScanResult(
            rating: .good,
            confidence: 0.92,
            latitude: 48.8566,
            longitude: 2.3522,
            roadName: "Champs-Élysées"
        )
        XCTAssertEqual(result.rating, .good)
        XCTAssertEqual(result.confidencePercentage, "92%")
        XCTAssertEqual(result.roadName, "Champs-Élysées")
    }

    func testRoadScanResultCodable() throws {
        let result = RoadScanResult(
            rating: .fair,
            hazards: ["Pothole", "Crack"],
            confidence: 0.85,
            latitude: 52.52,
            longitude: 13.40
        )
        let data = try JSONEncoder().encode(result)
        let decoded = try JSONDecoder().decode(RoadScanResult.self, from: data)
        XCTAssertEqual(decoded.rating, .fair)
        XCTAssertEqual(decoded.hazards.count, 2)
    }

    // MARK: - Gamification Service Tests

    @MainActor
    func testGamificationServiceInit() {
        let service = GamificationService()
        XCTAssertEqual(service.userProfile.level, 1)
        XCTAssertFalse(service.userProfile.achievements.isEmpty)
        XCTAssertFalse(service.leaderboard.isEmpty)
        XCTAssertNotNil(service.weeklyChallenge)
    }

    @MainActor
    func testAwardXP() {
        let service = GamificationService()
        let initialXP = service.userProfile.totalXP
        service.awardXP(for: .tripCompleted)
        XCTAssertEqual(service.userProfile.totalXP, initialXP + XPEventType.tripCompleted.baseXP)
        XCTAssertEqual(service.recentXPEvents.count, 1)
    }

    @MainActor
    func testLevelUp() {
        let profile = UserProfile(level: 1, totalXP: 0, currentLevelXP: 90, xpToNextLevel: 100)
        let service = GamificationService(userProfile: profile)
        service.awardXP(for: .tripCompleted) // +50 XP, should level up
        XCTAssertEqual(service.userProfile.level, 2)
    }

    @MainActor
    func testCompletedTrip() {
        let service = GamificationService()
        service.completedTrip(distanceKm: 50.0, durationMinutes: 45, wasSafe: true)
        XCTAssertEqual(service.userProfile.totalTrips, 1)
        XCTAssertEqual(service.userProfile.totalDistanceKm, 50.0, accuracy: 0.1)
        // Should have at least 2 XP events: tripCompleted + safeTrip
        XCTAssertGreaterThanOrEqual(service.recentXPEvents.count, 2)
    }

    @MainActor
    func testReportSubmitted() {
        let service = GamificationService()
        service.reportSubmitted()
        XCTAssertEqual(service.userProfile.totalReports, 1)
        XCTAssertGreaterThanOrEqual(service.recentXPEvents.count, 1)
    }

    @MainActor
    func testVisitCountry() {
        let service = GamificationService()
        service.visitedCountry("Romania")
        XCTAssertTrue(service.userProfile.countriesVisited.contains("Romania"))
        // Visiting same country again should not add duplicate
        service.visitedCountry("Romania")
        XCTAssertEqual(service.userProfile.countriesVisited.filter { $0 == "Romania" }.count, 1)
    }

    // MARK: - Travel Token Service Tests

    @MainActor
    func testTravelTokenServiceInit() {
        let service = TravelTokenService()
        XCTAssertGreaterThan(service.balance, 0)
        XCTAssertFalse(service.transactions.isEmpty)
    }

    @MainActor
    func testEarnTokens() {
        let service = TravelTokenService()
        let initialBalance = service.balance
        service.earnTokens(amount: 10.0, description: "Test earn")
        XCTAssertEqual(service.balance, initialBalance + 10.0, accuracy: 0.01)
    }

    @MainActor
    func testSpendTokensSuccess() {
        let service = TravelTokenService()
        let initialBalance = service.balance
        let success = service.spendTokens(amount: 5.0, description: "Test spend")
        XCTAssertTrue(success)
        XCTAssertEqual(service.balance, initialBalance - 5.0, accuracy: 0.01)
    }

    @MainActor
    func testSpendTokensInsufficientFunds() {
        let service = TravelTokenService()
        let success = service.spendTokens(amount: 99999.0, description: "Too much")
        XCTAssertFalse(success)
    }

    @MainActor
    func testBonusTokens() {
        let service = TravelTokenService()
        let initialBalance = service.balance
        service.bonusTokens(amount: 3.0, description: "Test bonus")
        XCTAssertEqual(service.balance, initialBalance + 3.0, accuracy: 0.01)
    }

    @MainActor
    func testRedeemItem() {
        let service = TravelTokenService()
        service.earnTokens(amount: 100.0, description: "Load up")
        let items = service.redeemableItems
        XCTAssertFalse(items.isEmpty)
        let success = service.redeemItem(items[0])
        XCTAssertTrue(success)
    }

    // MARK: - Aura AI Service Tests

    @MainActor
    func testAuraAIServiceInit() {
        let service = AuraAIService()
        XCTAssertFalse(service.isScanning)
        XCTAssertEqual(service.emotionalState, .calm)
        XCTAssertTrue(service.scanHistory.isEmpty)
    }

    @MainActor
    func testAuraAIScanStartStop() {
        let service = AuraAIService()
        service.startScanning()
        XCTAssertTrue(service.isScanning)
        service.stopScanning()
        XCTAssertFalse(service.isScanning)
    }

    @MainActor
    func testAuraAIEmotionalState() {
        let service = AuraAIService()

        // Calm driving
        service.updateEmotionalState(speed: 50, acceleration: 0.5, braking: false, timeOfDay: 14)
        XCTAssertEqual(service.emotionalState, .calm)

        // Stressed driving
        service.updateEmotionalState(speed: 150, acceleration: 5.0, braking: true, timeOfDay: 2)
        XCTAssertEqual(service.emotionalState, .stressed)
    }

    @MainActor
    func testAuraAIStatistics() {
        let service = AuraAIService()
        XCTAssertEqual(service.averageRoadHealth, 0)
        XCTAssertEqual(service.averageConfidence, 0)
        XCTAssertEqual(service.hazardCount, 0)
    }

    // MARK: - Driving Emotional State Tests

    func testDrivingEmotionalStateIcons() {
        for state in DrivingEmotionalState.allCases {
            XCTAssertFalse(state.iconName.isEmpty)
            XCTAssertFalse(state.colorName.isEmpty)
        }
    }

    // MARK: - Hazard Type Tests

    func testHazardTypeIcons() {
        for hazard in HazardType.allCases {
            XCTAssertFalse(hazard.iconName.isEmpty)
        }
    }

    // MARK: - Weekly Challenge Tests

    func testWeeklyChallengeProgress() {
        let challenge = WeeklyChallenge(
            title: "Test",
            description: "Test challenge",
            targetValue: 10,
            currentValue: 5,
            xpReward: 100,
            tokenReward: 5.0,
            expiresAt: Date().addingTimeInterval(86400)
        )
        XCTAssertEqual(challenge.progress, 0.5, accuracy: 0.01)
        XCTAssertFalse(challenge.isComplete)
    }

    func testWeeklyChallengeComplete() {
        let challenge = WeeklyChallenge(
            title: "Done",
            description: "Done challenge",
            targetValue: 5,
            currentValue: 5,
            xpReward: 100,
            tokenReward: 5.0,
            expiresAt: Date().addingTimeInterval(86400)
        )
        XCTAssertTrue(challenge.isComplete)
        XCTAssertEqual(challenge.progress, 1.0)
    }
}
