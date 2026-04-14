import XCTest
@testable import ContinentalExplorer
import CoreLocation

final class ContinentalExplorerTests: XCTestCase {
    
    // MARK: - Design Token Tests
    
    func testDesignTokenColors() {
        // Verify primary accent color is defined
        let primaryAccent = DesignTokens.Colors.primaryAccent
        XCTAssertNotNil(primaryAccent)
        
        let secondaryAccent = DesignTokens.Colors.secondaryAccent
        XCTAssertNotNil(secondaryAccent)
        
        let backgroundDark = DesignTokens.Colors.backgroundDark
        XCTAssertNotNil(backgroundDark)
    }
    
    func testDesignTokenSpacing() {
        XCTAssertEqual(DesignTokens.Spacing.xs, 4)
        XCTAssertEqual(DesignTokens.Spacing.sm, 8)
        XCTAssertEqual(DesignTokens.Spacing.md, 16)
        XCTAssertEqual(DesignTokens.Spacing.lg, 24)
        XCTAssertEqual(DesignTokens.Spacing.xl, 32)
    }
    
    // MARK: - Model Tests
    
    func testSpeedAlertCreation() {
        let coordinate = CLLocationCoordinate2D(latitude: 48.8566, longitude: 2.3522)
        let alert = SpeedAlert(
            speedLimit: 50,
            coordinate: coordinate,
            roadName: "Boulevard Haussmann",
            country: "France"
        )
        
        XCTAssertEqual(alert.speedLimit, 50)
        XCTAssertEqual(alert.roadName, "Boulevard Haussmann")
        XCTAssertEqual(alert.country, "France")
        XCTAssertTrue(alert.isActive)
    }
    
    func testRadarAlertTypes() {
        XCTAssertEqual(RadarType.allCases.count, 5)
        XCTAssertEqual(RadarType.fixed.rawValue, "Fixed")
        XCTAssertEqual(RadarType.mobile.rawValue, "Mobile")
        XCTAssertEqual(RadarType.average.rawValue, "Average Speed")
    }
    
    func testRadarAlertCreation() {
        let alert = RadarAlert(
            type: .fixed,
            coordinate: CLLocationCoordinate2D(latitude: 48.8584, longitude: 2.2945),
            speedLimit: 50,
            country: "France"
        )
        
        XCTAssertEqual(alert.type, .fixed)
        XCTAssertEqual(alert.speedLimit, 50)
        XCTAssertTrue(alert.isVerified)
    }
    
    func testCommunityReportReliability() {
        var report = CommunityReport(
            category: .police,
            coordinate: CLLocationCoordinate2D(latitude: 48.86, longitude: 2.30),
            reporterID: "test_user"
        )
        
        // No votes = 0.5 reliability
        XCTAssertEqual(report.reliability, 0.5)
        
        // Add upvotes
        report.upvotes = 8
        report.downvotes = 2
        XCTAssertEqual(report.reliability, 0.8)
    }
    
    func testCommunityReportExpiration() {
        let report = CommunityReport(
            category: .hazard,
            coordinate: CLLocationCoordinate2D(latitude: 52.52, longitude: 13.40),
            reporterID: "test_user",
            expiresAt: Date().addingTimeInterval(-100)
        )
        
        XCTAssertTrue(report.isExpired)
    }
    
    func testReportCategories() {
        XCTAssertEqual(ReportCategory.allCases.count, 8)
        XCTAssertEqual(ReportCategory.police.severity, .medium)
        XCTAssertEqual(ReportCategory.accident.severity, .high)
        XCTAssertEqual(ReportCategory.closure.severity, .critical)
    }
    
    func testAlertSeverityComparable() {
        XCTAssertTrue(AlertSeverity.low < AlertSeverity.medium)
        XCTAssertTrue(AlertSeverity.medium < AlertSeverity.high)
        XCTAssertTrue(AlertSeverity.high < AlertSeverity.critical)
    }
    
    // MARK: - Map Region Tests
    
    func testMapRegionCreation() {
        let region = MapRegionData(
            name: "Paris",
            centerLatitude: 48.8566,
            centerLongitude: 2.3522,
            country: "France"
        )
        
        XCTAssertEqual(region.name, "Paris")
        XCTAssertEqual(region.coordinate.latitude, 48.8566, accuracy: 0.001)
        XCTAssertEqual(region.coordinate.longitude, 2.3522, accuracy: 0.001)
    }
    
    func testEuropeanCapitalsPresets() {
        let capitals = MapRegionData.europeanCapitals
        XCTAssertEqual(capitals.count, 10)
        XCTAssertTrue(capitals.contains { $0.name == "Paris" })
        XCTAssertTrue(capitals.contains { $0.name == "Bucharest" })
        XCTAssertTrue(capitals.contains { $0.name == "Berlin" })
    }
    
    // MARK: - Offline Tile Tests
    
    func testOfflineTileKey() {
        let tile = OfflineTile(x: 5, y: 10, zoomLevel: 15, regionID: UUID())
        XCTAssertEqual(tile.tileKey, "15/5/10")
    }
    
    func testTileDownloadProgress() {
        let progress = TileDownloadProgress(
            regionName: "Paris",
            totalTiles: 100,
            downloadedTiles: 50
        )
        
        XCTAssertEqual(progress.progress, 0.5)
        XCTAssertEqual(progress.remainingTiles, 50)
        XCTAssertFalse(progress.isComplete)
    }
    
    // MARK: - Theme Tests
    
    @MainActor
    func testThemeManagerDefaults() {
        let manager = ThemeManager()
        XCTAssertEqual(manager.currentTheme, .dark)
        XCTAssertFalse(manager.isEcoModeEnabled)
        XCTAssertFalse(manager.isAnimationReduced)
    }
    
    @MainActor
    func testEcoModeToggle() {
        let manager = ThemeManager()
        
        manager.toggleEcoMode()
        XCTAssertTrue(manager.isEcoModeEnabled)
        XCTAssertEqual(manager.currentTheme, .eco)
        XCTAssertTrue(manager.isAnimationReduced)
        
        manager.toggleEcoMode()
        XCTAssertFalse(manager.isEcoModeEnabled)
        XCTAssertEqual(manager.currentTheme, .dark)
    }
    
    // MARK: - WebSocket Tests
    
    func testWebSocketConnectionState() {
        XCTAssertTrue(WebSocketConnectionState.connected.isConnected)
        XCTAssertFalse(WebSocketConnectionState.disconnected.isConnected)
        XCTAssertFalse(WebSocketConnectionState.connecting.isConnected)
        XCTAssertEqual(WebSocketConnectionState.connected.statusText, "Live")
    }
    
    // MARK: - Codable Tests
    
    func testSpeedAlertCodable() throws {
        let coordinate = CLLocationCoordinate2D(latitude: 48.8566, longitude: 2.3522)
        let alert = SpeedAlert(
            speedLimit: 130,
            coordinate: coordinate,
            roadName: "A1 Autoroute",
            country: "France"
        )
        
        let data = try JSONEncoder().encode(alert)
        let decoded = try JSONDecoder().decode(SpeedAlert.self, from: data)
        
        XCTAssertEqual(decoded.speedLimit, 130)
        XCTAssertEqual(decoded.roadName, "A1 Autoroute")
        XCTAssertEqual(decoded.coordinate.latitude, 48.8566, accuracy: 0.001)
    }
    
    func testRadarAlertCodable() throws {
        let alert = RadarAlert(
            type: .mobile,
            coordinate: CLLocationCoordinate2D(latitude: 52.52, longitude: 13.40),
            speedLimit: 100,
            country: "Germany"
        )
        
        let data = try JSONEncoder().encode(alert)
        let decoded = try JSONDecoder().decode(RadarAlert.self, from: data)
        
        XCTAssertEqual(decoded.type, .mobile)
        XCTAssertEqual(decoded.speedLimit, 100)
        XCTAssertEqual(decoded.country, "Germany")
    }
}
