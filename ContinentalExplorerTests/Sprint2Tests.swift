import XCTest
@testable import ContinentalExplorer

// MARK: - Sprint 2 Tests
final class Sprint2Tests: XCTestCase {

    // MARK: - WebSocket Message Types
    func testWebSocketMessageTypeRawValues() {
        XCTAssertEqual(WebSocketMessageType.communityAlert.rawValue, "community_alert")
        XCTAssertEqual(WebSocketMessageType.radarUpdate.rawValue, "radar_update")
        XCTAssertEqual(WebSocketMessageType.reportSubmission.rawValue, "report_submission")
        XCTAssertEqual(WebSocketMessageType.reportAck.rawValue, "report_ack")
        XCTAssertEqual(WebSocketMessageType.userPresence.rawValue, "user_presence")
        XCTAssertEqual(WebSocketMessageType.heartbeat.rawValue, "heartbeat")
        XCTAssertEqual(WebSocketMessageType.heartbeatAck.rawValue, "heartbeat_ack")
        XCTAssertEqual(WebSocketMessageType.locationUpdate.rawValue, "location_update")
        XCTAssertEqual(WebSocketMessageType.alertExpired.rawValue, "alert_expired")
        XCTAssertEqual(WebSocketMessageType.voteUpdate.rawValue, "vote_update")
    }

    // MARK: - WebSocket Message Creation
    func testWebSocketMessageInitWithType() {
        let message = WebSocketMessage(type: .heartbeat, payload: "ping")
        XCTAssertEqual(message.type, "heartbeat")
        XCTAssertEqual(message.payload, "ping")
        XCTAssertFalse(message.messageID.isEmpty)
    }

    func testWebSocketMessageInitWithString() {
        let date = Date()
        let message = WebSocketMessage(type: "custom", payload: "data", timestamp: date, messageID: "test-id")
        XCTAssertEqual(message.type, "custom")
        XCTAssertEqual(message.payload, "data")
        XCTAssertEqual(message.timestamp, date)
        XCTAssertEqual(message.messageID, "test-id")
    }

    // MARK: - WebSocket Message Codable
    func testWebSocketMessageCodable() throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let original = WebSocketMessage(type: .communityAlert, payload: "test-payload")
        let data = try encoder.encode(original)
        let decoded = try decoder.decode(WebSocketMessage.self, from: data)

        XCTAssertEqual(decoded.type, original.type)
        XCTAssertEqual(decoded.payload, original.payload)
        XCTAssertEqual(decoded.messageID, original.messageID)
    }

    // MARK: - Connection State
    func testConnectionStateIsConnected() {
        XCTAssertTrue(WebSocketConnectionState.connected.isConnected)
        XCTAssertFalse(WebSocketConnectionState.disconnected.isConnected)
        XCTAssertFalse(WebSocketConnectionState.connecting.isConnected)
        XCTAssertFalse(WebSocketConnectionState.reconnecting(attempt: 1).isConnected)
        XCTAssertFalse(WebSocketConnectionState.failed("error").isConnected)
    }

    func testConnectionStateStatusText() {
        XCTAssertEqual(WebSocketConnectionState.disconnected.statusText, "Offline")
        XCTAssertEqual(WebSocketConnectionState.connecting.statusText, "Connecting...")
        XCTAssertEqual(WebSocketConnectionState.connected.statusText, "Live")
        XCTAssertEqual(WebSocketConnectionState.reconnecting(attempt: 3).statusText, "Reconnecting (3)...")
        XCTAssertEqual(WebSocketConnectionState.failed("timeout").statusText, "Failed: timeout")
    }

    func testConnectionStateIcons() {
        XCTAssertEqual(WebSocketConnectionState.disconnected.statusIcon, "wifi.slash")
        XCTAssertEqual(WebSocketConnectionState.connected.statusIcon, "wifi")
        XCTAssertEqual(WebSocketConnectionState.reconnecting(attempt: 1).statusIcon, "arrow.clockwise")
        XCTAssertEqual(WebSocketConnectionState.failed("err").statusIcon, "xmark.circle")
    }

    func testConnectionStateColors() {
        XCTAssertEqual(WebSocketConnectionState.connected.statusColor, "success")
        XCTAssertEqual(WebSocketConnectionState.connecting.statusColor, "warning")
        XCTAssertEqual(WebSocketConnectionState.reconnecting(attempt: 1).statusColor, "warning")
        XCTAssertEqual(WebSocketConnectionState.disconnected.statusColor, "danger")
        XCTAssertEqual(WebSocketConnectionState.failed("err").statusColor, "danger")
    }

    // MARK: - Connection Quality
    func testConnectionQualityBarCount() {
        XCTAssertEqual(ConnectionQuality.excellent.barCount, 4)
        XCTAssertEqual(ConnectionQuality.good.barCount, 3)
        XCTAssertEqual(ConnectionQuality.fair.barCount, 2)
        XCTAssertEqual(ConnectionQuality.poor.barCount, 1)
        XCTAssertEqual(ConnectionQuality.none.barCount, 0)
    }

    // MARK: - User Presence
    func testUserPresenceCodable() throws {
        let presence = UserPresence(
            userID: "user-123",
            coordinate: CodableCoordinate(latitude: 48.8566, longitude: 2.3522),
            isActive: true,
            lastSeen: Date()
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let data = try encoder.encode(presence)
        let decoded = try decoder.decode(UserPresence.self, from: data)

        XCTAssertEqual(decoded.userID, "user-123")
        XCTAssertEqual(decoded.coordinate.latitude, 48.8566)
        XCTAssertEqual(decoded.coordinate.longitude, 2.3522)
        XCTAssertTrue(decoded.isActive)
        XCTAssertEqual(decoded.id, "user-123")
    }

    // MARK: - Vote Update
    func testVoteUpdateCodable() throws {
        let update = VoteUpdate(reportID: "report-456", upvotes: 10, downvotes: 2)

        let data = try JSONEncoder().encode(update)
        let decoded = try JSONDecoder().decode(VoteUpdate.self, from: data)

        XCTAssertEqual(decoded.reportID, "report-456")
        XCTAssertEqual(decoded.upvotes, 10)
        XCTAssertEqual(decoded.downvotes, 2)
    }

    // MARK: - Codable Coordinate
    func testCodableCoordinate() throws {
        let coord = CodableCoordinate(latitude: 52.5200, longitude: 13.4050)

        let data = try JSONEncoder().encode(coord)
        let decoded = try JSONDecoder().decode(CodableCoordinate.self, from: data)

        XCTAssertEqual(decoded.latitude, 52.5200)
        XCTAssertEqual(decoded.longitude, 13.4050)
    }

    // MARK: - Alert Sound Type
    func testAlertSoundTypeRawValues() {
        XCTAssertEqual(AlertSoundType.radarFixed.rawValue, "radar_fixed")
        XCTAssertEqual(AlertSoundType.communityAlert.rawValue, "community_alert")
        XCTAssertEqual(AlertSoundType.speedWarning.rawValue, "speed_warning")
        XCTAssertEqual(AlertSoundType.reportConfirm.rawValue, "report_confirm")
        XCTAssertEqual(AlertSoundType.connectionLost.rawValue, "connection_lost")
        XCTAssertEqual(AlertSoundType.connectionRestored.rawValue, "connection_restored")
    }

    func testAlertSoundTypeSystemSoundIDs() {
        // Verify all sound types return a non-zero system sound ID
        let allTypes: [AlertSoundType] = [
            .radarFixed, .radarMobile, .radarAverage,
            .communityAlert, .speedWarning, .speedDanger,
            .reportConfirm, .connectionLost, .connectionRestored
        ]

        for type in allTypes {
            XCTAssertGreaterThan(type.systemSoundID, 0, "\(type.rawValue) should have a valid system sound ID")
        }
    }

    // MARK: - Alert Feed Item
    func testAlertFeedItemCreation() {
        let item = AlertFeedItem(
            id: UUID(),
            title: "Police Checkpoint",
            subtitle: "Near highway exit 12",
            iconName: "shield.checkered",
            severity: .medium,
            category: .community,
            timestamp: Date(),
            isNew: true
        )

        XCTAssertEqual(item.title, "Police Checkpoint")
        XCTAssertEqual(item.category, .community)
        XCTAssertTrue(item.isNew)
    }

    // MARK: - Report Submission Status
    func testReportSubmissionStatusEquality() {
        XCTAssertEqual(AlertViewModel.ReportSubmissionStatus.idle, .idle)
        XCTAssertEqual(AlertViewModel.ReportSubmissionStatus.submitting, .submitting)
        XCTAssertEqual(AlertViewModel.ReportSubmissionStatus.success, .success)
        XCTAssertEqual(AlertViewModel.ReportSubmissionStatus.failed("err"), .failed("err"))
        XCTAssertNotEqual(AlertViewModel.ReportSubmissionStatus.idle, .submitting)
        XCTAssertNotEqual(AlertViewModel.ReportSubmissionStatus.failed("a"), .failed("b"))
    }

    // MARK: - Connection State Equality
    func testConnectionStateEquality() {
        XCTAssertEqual(WebSocketConnectionState.connected, .connected)
        XCTAssertEqual(WebSocketConnectionState.disconnected, .disconnected)
        XCTAssertEqual(WebSocketConnectionState.reconnecting(attempt: 2), .reconnecting(attempt: 2))
        XCTAssertNotEqual(WebSocketConnectionState.reconnecting(attempt: 1), .reconnecting(attempt: 2))
        XCTAssertEqual(WebSocketConnectionState.failed("err"), .failed("err"))
        XCTAssertNotEqual(WebSocketConnectionState.failed("a"), .failed("b"))
    }
}
