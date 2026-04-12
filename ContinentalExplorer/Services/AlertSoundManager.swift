import Foundation
import AVFoundation
import UIKit
import Combine

// MARK: - Alert Sound Type
enum AlertSoundType: String {
    case radarFixed = "radar_fixed"
    case radarMobile = "radar_mobile"
    case radarAverage = "radar_average"
    case communityAlert = "community_alert"
    case speedWarning = "speed_warning"
    case speedDanger = "speed_danger"
    case reportConfirm = "report_confirm"
    case connectionLost = "connection_lost"
    case connectionRestored = "connection_restored"

    var systemSoundID: SystemSoundID {
        switch self {
        case .radarFixed, .radarMobile, .radarAverage:
            return 1005
        case .communityAlert:
            return 1007
        case .speedWarning:
            return 1006
        case .speedDanger:
            return 1073
        case .reportConfirm:
            return 1001
        case .connectionLost:
            return 1053
        case .connectionRestored:
            return 1054
        }
    }
}

// MARK: - Haptic Type
enum HapticType {
    case light
    case medium
    case heavy
    case success
    case warning
    case error
    case selection
}

// MARK: - Alert Sound Manager
@MainActor
final class AlertSoundManager: ObservableObject {

    // MARK: - Published
    @Published var isSoundEnabled: Bool = true
    @Published var isHapticEnabled: Bool = true
    @Published var volume: Float = 0.8

    // MARK: - Private
    private let impactLight = UIImpactFeedbackGenerator(style: .light)
    private let impactMedium = UIImpactFeedbackGenerator(style: .medium)
    private let impactHeavy = UIImpactFeedbackGenerator(style: .heavy)
    private let notificationFeedback = UINotificationFeedbackGenerator()
    private let selectionFeedback = UISelectionFeedbackGenerator()
    private var lastSoundPlayedAt: Date?
    private let minimumSoundInterval: TimeInterval = 2.0

    init() {
        prepareHaptics()
    }

    // MARK: - Prepare
    private func prepareHaptics() {
        impactLight.prepare()
        impactMedium.prepare()
        impactHeavy.prepare()
        notificationFeedback.prepare()
        selectionFeedback.prepare()
    }

    // MARK: - Play Sound
    func playAlert(sound: AlertSoundType) {
        guard isSoundEnabled else { return }

        // Throttle sounds to avoid spamming
        if let lastPlayed = lastSoundPlayedAt,
           Date().timeIntervalSince(lastPlayed) < minimumSoundInterval {
            return
        }

        AudioServicesPlaySystemSound(sound.systemSoundID)
        lastSoundPlayedAt = Date()
    }

    // MARK: - Haptic Feedback
    func triggerHaptic(_ type: HapticType) {
        guard isHapticEnabled else { return }

        switch type {
        case .light:
            impactLight.impactOccurred()
        case .medium:
            impactMedium.impactOccurred()
        case .heavy:
            impactHeavy.impactOccurred()
        case .success:
            notificationFeedback.notificationOccurred(.success)
        case .warning:
            notificationFeedback.notificationOccurred(.warning)
        case .error:
            notificationFeedback.notificationOccurred(.error)
        case .selection:
            selectionFeedback.selectionChanged()
        }
    }

    // MARK: - Combined Alerts
    func alertReceived(severity: AlertSeverity) {
        switch severity {
        case .low:
            playAlert(sound: .communityAlert)
            triggerHaptic(.light)
        case .medium:
            playAlert(sound: .communityAlert)
            triggerHaptic(.medium)
        case .high:
            playAlert(sound: .radarFixed)
            triggerHaptic(.heavy)
        case .critical:
            playAlert(sound: .speedDanger)
            triggerHaptic(.error)
        }
    }

    func radarDetected(type: RadarType) {
        switch type {
        case .fixed:
            playAlert(sound: .radarFixed)
            triggerHaptic(.heavy)
        case .mobile:
            playAlert(sound: .radarMobile)
            triggerHaptic(.heavy)
        case .average:
            playAlert(sound: .radarAverage)
            triggerHaptic(.medium)
        case .redLight:
            playAlert(sound: .radarFixed)
            triggerHaptic(.warning)
        case .section:
            playAlert(sound: .radarAverage)
            triggerHaptic(.medium)
        }
    }

    func speedAlert(status: SpeedStatus) {
        switch status {
        case .safe:
            break
        case .warning:
            playAlert(sound: .speedWarning)
            triggerHaptic(.warning)
        case .danger:
            playAlert(sound: .speedDanger)
            triggerHaptic(.error)
        }
    }

    func reportSubmitted() {
        playAlert(sound: .reportConfirm)
        triggerHaptic(.success)
    }

    func connectionChanged(isConnected: Bool) {
        if isConnected {
            playAlert(sound: .connectionRestored)
            triggerHaptic(.success)
        } else {
            playAlert(sound: .connectionLost)
            triggerHaptic(.error)
        }
    }
}
