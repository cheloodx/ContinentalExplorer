import Foundation
import Combine

// MARK: - WebSocket Message Types
enum WebSocketMessageType: String, Codable {
    case communityAlert = "community_alert"
    case radarUpdate = "radar_update"
    case reportSubmission = "report_submission"
    case reportAck = "report_ack"
    case userPresence = "user_presence"
    case heartbeat = "heartbeat"
    case heartbeatAck = "heartbeat_ack"
    case locationUpdate = "location_update"
    case alertExpired = "alert_expired"
    case voteUpdate = "vote_update"
}

// MARK: - WebSocket Message
struct WebSocketMessage: Codable {
    let type: String
    let payload: String
    let timestamp: Date
    let messageID: String

    init(type: WebSocketMessageType, payload: String, messageID: String = UUID().uuidString) {
        self.type = type.rawValue
        self.payload = payload
        self.timestamp = Date()
        self.messageID = messageID
    }

    init(type: String, payload: String, timestamp: Date, messageID: String = UUID().uuidString) {
        self.type = type
        self.payload = payload
        self.timestamp = timestamp
        self.messageID = messageID
    }
}

// MARK: - User Presence
struct UserPresence: Codable, Identifiable {
    let userID: String
    let coordinate: CodableCoordinate
    let isActive: Bool
    let lastSeen: Date

    var id: String { userID }
}

// MARK: - Codable Coordinate
struct CodableCoordinate: Codable {
    let latitude: Double
    let longitude: Double
}

// MARK: - Vote Update
struct VoteUpdate: Codable {
    let reportID: String
    let upvotes: Int
    let downvotes: Int
}

// MARK: - Connection State
enum WebSocketConnectionState: Equatable {
    case disconnected
    case connecting
    case connected
    case reconnecting(attempt: Int)
    case failed(String)

    var isConnected: Bool {
        if case .connected = self { return true }
        return false
    }

    var statusText: String {
        switch self {
        case .disconnected: return "Offline"
        case .connecting: return "Connecting..."
        case .connected: return "Live"
        case .reconnecting(let attempt): return "Reconnecting (\(attempt))..."
        case .failed(let error): return "Failed: \(error)"
        }
    }

    var statusIcon: String {
        switch self {
        case .disconnected: return "wifi.slash"
        case .connecting: return "wifi.exclamationmark"
        case .connected: return "wifi"
        case .reconnecting: return "arrow.clockwise"
        case .failed: return "xmark.circle"
        }
    }

    var statusColor: String {
        switch self {
        case .connected: return "success"
        case .connecting, .reconnecting: return "warning"
        case .disconnected, .failed: return "danger"
        }
    }
}

// MARK: - Connection Quality
enum ConnectionQuality: String {
    case excellent = "Excellent"
    case good = "Good"
    case fair = "Fair"
    case poor = "Poor"
    case none = "No Connection"

    var barCount: Int {
        switch self {
        case .excellent: return 4
        case .good: return 3
        case .fair: return 2
        case .poor: return 1
        case .none: return 0
        }
    }
}

// MARK: - WebSocket Service
@MainActor
final class WebSocketService: ObservableObject {

    // MARK: - Published
    @Published var connectionState: WebSocketConnectionState = .disconnected
    @Published var connectionQuality: ConnectionQuality = .none
    @Published var lastMessage: WebSocketMessage?
    @Published var messageCount: Int = 0
    @Published var nearbyUsersCount: Int = 0
    @Published var latencyMs: Int = 0
    @Published var isAutoReconnectEnabled: Bool = true

    // MARK: - Subjects (Combine publishers for real-time data streams)
    let alertSubject = PassthroughSubject<CommunityReport, Never>()
    let radarUpdateSubject = PassthroughSubject<RadarAlert, Never>()
    let reportAckSubject = PassthroughSubject<String, Never>()
    let presenceSubject = PassthroughSubject<UserPresence, Never>()
    let alertExpiredSubject = PassthroughSubject<String, Never>()
    let voteUpdateSubject = PassthroughSubject<VoteUpdate, Never>()
    let connectionStateSubject = PassthroughSubject<WebSocketConnectionState, Never>()

    // MARK: - Private
    private var webSocketTask: URLSessionWebSocketTask?
    private var session: URLSession?
    private var cancellables = Set<AnyCancellable>()
    private var reconnectAttempts = 0
    private let maxReconnectAttempts = 10
    private let baseReconnectDelay: TimeInterval = 1.0
    private let maxReconnectDelay: TimeInterval = 30.0
    private var heartbeatTimer: Timer?
    private let heartbeatInterval: TimeInterval = 15.0
    private var lastHeartbeatSentAt: Date?
    private var heartbeatTimeoutTimer: Timer?
    private let heartbeatTimeout: TimeInterval = 10.0
    private var serverURL: String?
    private var pendingMessages: [WebSocketMessage] = []
    private let maxPendingMessages = 50
    private var connectionGeneration: Int = 0
    private var reconnectWorkItem: DispatchWorkItem?

    private let jsonEncoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()

    private let jsonDecoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()

    // MARK: - Connection
    func connect(to urlString: String) {
        serverURL = urlString

        guard let url = URL(string: urlString) else {
            updateConnectionState(.failed("Invalid URL"))
            return
        }

        reconnectWorkItem?.cancel()
        reconnectWorkItem = nil
        disconnect(clearURL: false)
        updateConnectionState(.connecting)

        let configuration = URLSessionConfiguration.default
        configuration.waitsForConnectivity = true
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 300
        session = URLSession(configuration: configuration)

        webSocketTask = session?.webSocketTask(with: url)
        webSocketTask?.maximumMessageSize = 1024 * 1024
        webSocketTask?.resume()

        connectionGeneration += 1
        let currentGeneration = connectionGeneration

        // Start listening for messages immediately
        receiveMessage(generation: currentGeneration)

        // Verify connection with a ping before transitioning to .connected
        webSocketTask?.sendPing { [weak self] error in
            Task { @MainActor in
                guard let self = self else { return }
                guard currentGeneration == self.connectionGeneration else { return }
                if let error = error {
                    self.handleDisconnection(error: error)
                } else {
                    self.updateConnectionState(.connected)
                    self.reconnectAttempts = 0
                    self.connectionQuality = .good
                    self.startHeartbeat()
                    self.flushPendingMessages()
                }
            }
        }
    }

    func disconnect(clearURL: Bool = true) {
        reconnectWorkItem?.cancel()
        reconnectWorkItem = nil
        stopHeartbeat()
        webSocketTask?.cancel(with: .goingAway, reason: "User disconnected".data(using: .utf8))
        webSocketTask = nil
        session?.invalidateAndCancel()
        session = nil

        updateConnectionState(.disconnected)
        connectionQuality = .none
        nearbyUsersCount = 0

        if clearURL {
            serverURL = nil
        }
    }

    private func updateConnectionState(_ state: WebSocketConnectionState) {
        connectionState = state
        connectionStateSubject.send(state)
    }

    // MARK: - Send Messages
    func send(message: WebSocketMessage) async throws {
        guard connectionState.isConnected else {
            queuePendingMessage(message)
            return
        }

        let data = try jsonEncoder.encode(message)
        guard let string = String(data: data, encoding: .utf8) else { return }
        try await webSocketTask?.send(.string(string))
    }

    func submitReport(_ report: CommunityReport) async {
        do {
            let payloadData = try jsonEncoder.encode(report)
            guard let payload = String(data: payloadData, encoding: .utf8) else { return }

            let message = WebSocketMessage(type: .reportSubmission, payload: payload)
            try await send(message: message)
        } catch {
            print("[WebSocket] Failed to submit report: \(error)")
        }
    }

    func sendLocationUpdate(latitude: Double, longitude: Double) async {
        let coordinate = CodableCoordinate(latitude: latitude, longitude: longitude)
        do {
            let payloadData = try jsonEncoder.encode(coordinate)
            guard let payload = String(data: payloadData, encoding: .utf8) else { return }

            let message = WebSocketMessage(type: .locationUpdate, payload: payload)
            try await send(message: message)
        } catch {
            print("[WebSocket] Failed to send location update: \(error)")
        }
    }

    func sendVote(reportID: String, isUpvote: Bool) async {
        let update = VoteUpdate(
            reportID: reportID,
            upvotes: isUpvote ? 1 : 0,
            downvotes: isUpvote ? 0 : 1
        )
        do {
            let payloadData = try jsonEncoder.encode(update)
            guard let payload = String(data: payloadData, encoding: .utf8) else { return }

            let message = WebSocketMessage(type: .voteUpdate, payload: payload)
            try await send(message: message)
        } catch {
            print("[WebSocket] Failed to send vote: \(error)")
        }
    }

    // MARK: - Receive
    private func receiveMessage(generation: Int) {
        webSocketTask?.receive { [weak self] result in
            Task { @MainActor in
                guard let self = self else { return }
                // Ignore callbacks from previous connection generations
                guard generation == self.connectionGeneration else { return }
                switch result {
                case .success(let message):
                    self.handleMessage(message)
                    self.receiveMessage(generation: generation)
                case .failure(let error):
                    self.handleDisconnection(error: error)
                }
            }
        }
    }

    private func handleMessage(_ message: URLSessionWebSocketTask.Message) {
        switch message {
        case .string(let text):
            processTextMessage(text)
        case .data(let data):
            if let text = String(data: data, encoding: .utf8) {
                processTextMessage(text)
            }
        @unknown default:
            break
        }
    }

    private func processTextMessage(_ text: String) {
        guard let data = text.data(using: .utf8),
              let wsMessage = try? jsonDecoder.decode(WebSocketMessage.self, from: data) else {
            return
        }

        lastMessage = wsMessage
        messageCount += 1
        routeMessage(wsMessage)
    }

    private func routeMessage(_ message: WebSocketMessage) {
        guard let messageType = WebSocketMessageType(rawValue: message.type) else { return }

        switch messageType {
        case .communityAlert:
            if let data = message.payload.data(using: .utf8),
               let report = try? jsonDecoder.decode(CommunityReport.self, from: data) {
                alertSubject.send(report)
            }

        case .radarUpdate:
            if let data = message.payload.data(using: .utf8),
               let alert = try? jsonDecoder.decode(RadarAlert.self, from: data) {
                radarUpdateSubject.send(alert)
            }

        case .reportAck:
            reportAckSubject.send(message.messageID)

        case .userPresence:
            if let data = message.payload.data(using: .utf8),
               let presence = try? jsonDecoder.decode(UserPresence.self, from: data) {
                presenceSubject.send(presence)
            }

        case .alertExpired:
            alertExpiredSubject.send(message.payload)

        case .voteUpdate:
            if let data = message.payload.data(using: .utf8),
               let update = try? jsonDecoder.decode(VoteUpdate.self, from: data) {
                voteUpdateSubject.send(update)
            }

        case .heartbeatAck:
            handleHeartbeatResponse()

        case .heartbeat:
            Task {
                let ackMessage = WebSocketMessage(type: .heartbeatAck, payload: "pong")
                try? await send(message: ackMessage)
            }

        case .reportSubmission, .locationUpdate:
            break
        }
    }

    // MARK: - Heartbeat (Ping/Pong)
    private func startHeartbeat() {
        stopHeartbeat()
        heartbeatTimer = Timer.scheduledTimer(withTimeInterval: heartbeatInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.sendHeartbeat()
            }
        }
    }

    private func stopHeartbeat() {
        heartbeatTimer?.invalidate()
        heartbeatTimer = nil
        heartbeatTimeoutTimer?.invalidate()
        heartbeatTimeoutTimer = nil
    }

    private func sendHeartbeat() {
        let message = WebSocketMessage(type: .heartbeat, payload: "ping")
        lastHeartbeatSentAt = Date()

        Task {
            try? await send(message: message)
        }

        heartbeatTimeoutTimer?.invalidate()
        heartbeatTimeoutTimer = Timer.scheduledTimer(withTimeInterval: heartbeatTimeout, repeats: false) { [weak self] _ in
            Task { @MainActor in
                self?.handleHeartbeatTimeout()
            }
        }
    }

    private func handleHeartbeatResponse() {
        heartbeatTimeoutTimer?.invalidate()
        heartbeatTimeoutTimer = nil

        if let lastSent = lastHeartbeatSentAt {
            let latency = Int(Date().timeIntervalSince(lastSent) * 1000)
            latencyMs = latency
            updateConnectionQuality(latency: latency)
        }
    }

    private func handleHeartbeatTimeout() {
        connectionQuality = .poor

        if isAutoReconnectEnabled {
            handleDisconnection(error: NSError(
                domain: "WebSocket",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Heartbeat timeout"]
            ))
        }
    }

    private func updateConnectionQuality(latency: Int) {
        switch latency {
        case 0..<50:
            connectionQuality = .excellent
        case 50..<150:
            connectionQuality = .good
        case 150..<300:
            connectionQuality = .fair
        default:
            connectionQuality = .poor
        }
    }

    // MARK: - Reconnection (Exponential Backoff with Jitter)
    private func handleDisconnection(error: Error) {
        // Guard against duplicate reconnection scheduling
        if case .reconnecting = connectionState { return }

        stopHeartbeat()
        connectionQuality = .none

        guard isAutoReconnectEnabled,
              reconnectAttempts < maxReconnectAttempts,
              let url = serverURL else {
            updateConnectionState(.failed(error.localizedDescription))
            return
        }

        reconnectAttempts += 1
        updateConnectionState(.reconnecting(attempt: reconnectAttempts))

        let delay = min(
            baseReconnectDelay * pow(2.0, Double(reconnectAttempts - 1)),
            maxReconnectDelay
        )
        let jitter = Double.random(in: 0...delay * 0.3)
        let totalDelay = delay + jitter

        let workItem = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            Task { @MainActor in
                self.connect(to: url)
            }
        }
        reconnectWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + totalDelay, execute: workItem)
    }

    func manualReconnect() {
        reconnectAttempts = 0
        if let url = serverURL {
            connect(to: url)
        }
    }

    // MARK: - Pending Messages Queue
    private func queuePendingMessage(_ message: WebSocketMessage) {
        if pendingMessages.count >= maxPendingMessages {
            pendingMessages.removeFirst()
        }
        pendingMessages.append(message)
    }

    private func flushPendingMessages() {
        let messages = pendingMessages
        pendingMessages.removeAll()

        Task {
            for message in messages {
                try? await send(message: message)
                try? await Task.sleep(nanoseconds: 50_000_000)
            }
        }
    }
}
