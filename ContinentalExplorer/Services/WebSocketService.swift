import Foundation
import Combine

// MARK: - WebSocket Message
struct WebSocketMessage: Codable {
    let type: String
    let payload: String
    let timestamp: Date
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
        case .disconnected: return "Disconnected"
        case .connecting: return "Connecting..."
        case .connected: return "Live"
        case .reconnecting(let attempt): return "Reconnecting (\(attempt))..."
        case .failed(let error): return "Failed: \(error)"
        }
    }
}

// MARK: - WebSocket Service
@MainActor
final class WebSocketService: ObservableObject {
    
    // MARK: - Published
    @Published var connectionState: WebSocketConnectionState = .disconnected
    @Published var lastMessage: WebSocketMessage?
    @Published var messageCount: Int = 0
    
    // MARK: - Private
    private var webSocketTask: URLSessionWebSocketTask?
    private var session: URLSession?
    private var cancellables = Set<AnyCancellable>()
    private var reconnectAttempts = 0
    private let maxReconnectAttempts = 5
    private let reconnectDelay: TimeInterval = 2.0
    
    // MARK: - Subjects
    let alertSubject = PassthroughSubject<CommunityReport, Never>()
    let radarUpdateSubject = PassthroughSubject<RadarAlert, Never>()
    
    // MARK: - Connection
    func connect(to urlString: String) {
        guard let url = URL(string: urlString) else {
            connectionState = .failed("Invalid URL")
            return
        }
        
        connectionState = .connecting
        
        let configuration = URLSessionConfiguration.default
        configuration.waitsForConnectivity = true
        session = URLSession(configuration: configuration)
        
        webSocketTask = session?.webSocketTask(with: url)
        webSocketTask?.resume()
        
        connectionState = .connected
        reconnectAttempts = 0
        
        receiveMessage()
    }
    
    func disconnect() {
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil
        connectionState = .disconnected
    }
    
    // MARK: - Send
    func send(message: WebSocketMessage) async throws {
        let data = try JSONEncoder().encode(message)
        guard let string = String(data: data, encoding: .utf8) else { return }
        try await webSocketTask?.send(.string(string))
    }
    
    // MARK: - Receive
    private func receiveMessage() {
        webSocketTask?.receive { [weak self] result in
            Task { @MainActor in
                switch result {
                case .success(let message):
                    self?.handleMessage(message)
                    self?.receiveMessage()
                case .failure(let error):
                    self?.handleDisconnection(error: error)
                }
            }
        }
    }
    
    private func handleMessage(_ message: URLSessionWebSocketTask.Message) {
        switch message {
        case .string(let text):
            if let data = text.data(using: .utf8),
               let wsMessage = try? JSONDecoder().decode(WebSocketMessage.self, from: data) {
                lastMessage = wsMessage
                messageCount += 1
                routeMessage(wsMessage)
            }
        case .data(let data):
            if let wsMessage = try? JSONDecoder().decode(WebSocketMessage.self, from: data) {
                lastMessage = wsMessage
                messageCount += 1
                routeMessage(wsMessage)
            }
        @unknown default:
            break
        }
    }
    
    private func routeMessage(_ message: WebSocketMessage) {
        switch message.type {
        case "community_alert":
            if let data = message.payload.data(using: .utf8),
               let report = try? JSONDecoder().decode(CommunityReport.self, from: data) {
                alertSubject.send(report)
            }
        case "radar_update":
            if let data = message.payload.data(using: .utf8),
               let alert = try? JSONDecoder().decode(RadarAlert.self, from: data) {
                radarUpdateSubject.send(alert)
            }
        default:
            break
        }
    }
    
    // MARK: - Reconnection
    private func handleDisconnection(error: Error) {
        guard reconnectAttempts < maxReconnectAttempts else {
            connectionState = .failed("Max reconnection attempts reached")
            return
        }
        
        reconnectAttempts += 1
        connectionState = .reconnecting(attempt: reconnectAttempts)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + reconnectDelay * Double(reconnectAttempts)) { [weak self] in
            self?.webSocketTask?.resume()
            self?.receiveMessage()
        }
    }
}
