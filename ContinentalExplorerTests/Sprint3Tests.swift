import XCTest
@testable import ContinentalExplorer

// MARK: - Sprint 3 Tests

final class Sprint3Tests: XCTestCase {

    // MARK: - ManeuverType Tests
    func testManeuverTypeIcons() {
        XCTAssertEqual(ManeuverType.straight.rawValue, "arrow.up")
        XCTAssertEqual(ManeuverType.turnLeft.rawValue, "arrow.turn.up.left")
        XCTAssertEqual(ManeuverType.turnRight.rawValue, "arrow.turn.up.right")
        XCTAssertEqual(ManeuverType.uTurn.rawValue, "arrow.uturn.down")
        XCTAssertEqual(ManeuverType.arrive.rawValue, "flag.checkered")
    }

    func testManeuverTypeDisplayNames() {
        XCTAssertEqual(ManeuverType.straight.displayName, "Continue straight")
        XCTAssertEqual(ManeuverType.turnLeft.displayName, "Turn left")
        XCTAssertEqual(ManeuverType.turnRight.displayName, "Turn right")
        XCTAssertEqual(ManeuverType.arrive.displayName, "Arrive")
    }

    // MARK: - NavigationMode Tests
    func testNavigationModes() {
        XCTAssertEqual(NavigationMode.idle.rawValue, "Idle")
        XCTAssertEqual(NavigationMode.previewing.rawValue, "Preview")
        XCTAssertEqual(NavigationMode.navigating.rawValue, "Navigating")
        XCTAssertEqual(NavigationMode.arrived.rawValue, "Arrived")
        XCTAssertEqual(NavigationMode.rerouting.rawValue, "Rerouting")
    }

    // MARK: - TransportMode Tests
    func testTransportModes() {
        XCTAssertEqual(TransportMode.car.rawValue, "Car")
        XCTAssertEqual(TransportMode.walking.rawValue, "Walking")
        XCTAssertEqual(TransportMode.car.iconName, "car.fill")
        XCTAssertEqual(TransportMode.walking.iconName, "figure.walk")
    }

    // MARK: - PlaceCategory Tests
    func testPlaceCategoryIcons() {
        XCTAssertEqual(PlaceCategory.gasStation.iconName, "fuelpump.fill")
        XCTAssertEqual(PlaceCategory.restaurant.iconName, "fork.knife")
        XCTAssertEqual(PlaceCategory.parking.iconName, "p.square.fill")
        XCTAssertEqual(PlaceCategory.hospital.iconName, "cross.fill")
        XCTAssertEqual(PlaceCategory.charger.iconName, "bolt.car.fill")
    }

    func testPlaceCategorySearchQueries() {
        XCTAssertEqual(PlaceCategory.gasStation.searchQuery, "gas station")
        XCTAssertEqual(PlaceCategory.restaurant.searchQuery, "restaurant")
        XCTAssertEqual(PlaceCategory.pharmacy.searchQuery, "pharmacy")
    }

    func testPlaceCategoryCount() {
        XCTAssertEqual(PlaceCategory.allCases.count, 8)
    }

    // MARK: - MapDisplayStyle Tests
    func testMapDisplayStyles() {
        XCTAssertEqual(MapDisplayStyle.standard.rawValue, "Standard")
        XCTAssertEqual(MapDisplayStyle.satellite.rawValue, "Satellite")
        XCTAssertEqual(MapDisplayStyle.hybrid.rawValue, "Hybrid")
        XCTAssertEqual(MapDisplayStyle.terrain.rawValue, "Terrain")
    }

    func testMapDisplayStyleIcons() {
        XCTAssertEqual(MapDisplayStyle.standard.iconName, "map.fill")
        XCTAssertEqual(MapDisplayStyle.satellite.iconName, "globe.americas.fill")
        XCTAssertEqual(MapDisplayStyle.hybrid.iconName, "square.stack.3d.up.fill")
        XCTAssertEqual(MapDisplayStyle.terrain.iconName, "mountain.2.fill")
    }

    func testMapDisplayStyleCount() {
        XCTAssertEqual(MapDisplayStyle.allCases.count, 4)
    }

    // MARK: - VoiceLanguage Tests
    func testVoiceLanguages() {
        XCTAssertEqual(VoiceGuidanceService.VoiceLanguage.english.rawValue, "en-US")
        XCTAssertEqual(VoiceGuidanceService.VoiceLanguage.romanian.rawValue, "ro-RO")
        XCTAssertEqual(VoiceGuidanceService.VoiceLanguage.french.rawValue, "fr-FR")
        XCTAssertEqual(VoiceGuidanceService.VoiceLanguage.german.rawValue, "de-DE")
    }

    func testVoiceLanguageDisplayNames() {
        XCTAssertEqual(VoiceGuidanceService.VoiceLanguage.english.displayName, "English")
        XCTAssertEqual(VoiceGuidanceService.VoiceLanguage.romanian.displayName, "Romana")
    }

    func testVoiceLanguageCount() {
        XCTAssertEqual(VoiceGuidanceService.VoiceLanguage.allCases.count, 6)
    }

    // MARK: - ReportSubmissionStatus Tests
    func testReportSubmissionStatusEquality() {
        XCTAssertEqual(ReportSubmissionStatus.idle, ReportSubmissionStatus.idle)
        XCTAssertEqual(ReportSubmissionStatus.submitting, ReportSubmissionStatus.submitting)
        XCTAssertEqual(ReportSubmissionStatus.success, ReportSubmissionStatus.success)
        XCTAssertNotEqual(ReportSubmissionStatus.idle, ReportSubmissionStatus.submitting)
    }

    // MARK: - AlertFeedItem Tests
    func testAlertFeedItemTimeAgo() {
        let recentItem = AlertFeedItem(
            title: "Test",
            subtitle: "Sub",
            iconName: "car",
            severity: .low,
            timestamp: Date()
        )
        XCTAssertEqual(recentItem.timeAgo, "Just now")
    }

    // MARK: - SpeedStatus Tests
    func testSpeedStatusDescription() {
        XCTAssertEqual(SpeedStatus.safe.description, "Within Limit")
        XCTAssertEqual(SpeedStatus.warning.description, "Approaching Limit")
        XCTAssertEqual(SpeedStatus.danger.description, "Over Limit")
    }

    // MARK: - Destination Tests
    func testDestinationEquality() {
        let d1 = Destination(name: "A", address: "B", coordinate: .init(latitude: 0, longitude: 0), mapItem: nil)
        let d2 = Destination(name: "A", address: "B", coordinate: .init(latitude: 0, longitude: 0), mapItem: nil)
        // Different IDs
        XCTAssertNotEqual(d1, d2)
        // Same instance
        XCTAssertEqual(d1, d1)
    }
}
