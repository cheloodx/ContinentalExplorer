import Foundation
import AVFoundation
import Combine

// MARK: - Voice Guidance Service
@MainActor
final class VoiceGuidanceService: ObservableObject {
    @Published var isEnabled: Bool = true
    @Published var isSpeaking: Bool = false
    @Published var volume: Float = 1.0
    @Published var selectedLanguage: VoiceLanguage = .english

    private let synthesizer = AVSpeechSynthesizer()
    private var lastSpokenStep: String = ""

    enum VoiceLanguage: String, CaseIterable {
        case english = "en-US"
        case romanian = "ro-RO"
        case french = "fr-FR"
        case german = "de-DE"
        case spanish = "es-ES"
        case italian = "it-IT"

        var displayName: String {
            switch self {
            case .english: return "English"
            case .romanian: return "Romana"
            case .french: return "Francais"
            case .german: return "Deutsch"
            case .spanish: return "Espanol"
            case .italian: return "Italiano"
            }
        }
    }

    init() {
        setupAudioSession()
    }

    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .voicePrompt, options: [.duckOthers, .interruptSpokenAudioAndMixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            // Audio session setup failed
        }
    }

    func speak(_ text: String, allowRepeat: Bool = false) {
        guard isEnabled, allowRepeat || text != lastSpokenStep else { return }
        lastSpokenStep = text

        synthesizer.stopSpeaking(at: .immediate)

        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: selectedLanguage.rawValue)
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 0.9
        utterance.volume = volume
        utterance.pitchMultiplier = 1.0
        utterance.preUtteranceDelay = 0.1

        isSpeaking = true
        synthesizer.speak(utterance)

        DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
            self?.isSpeaking = false
        }
    }

    func speakNavigationStep(instruction: String, distance: String) {
        let text = "In \(distance), \(instruction)"
        speak(text)
    }

    func speakRerouting() {
        speak("Rerouting")
    }

    func speakArrival() {
        speak("You have arrived at your destination")
    }

    func speakSpeedWarning() {
        speak("Speed limit exceeded", allowRepeat: true)
    }

    func speakRadarAlert(distance: String) {
        speak("Speed camera ahead in \(distance)")
    }

    func stopSpeaking() {
        synthesizer.stopSpeaking(at: .immediate)
        isSpeaking = false
    }

    func toggle() {
        isEnabled.toggle()
        if !isEnabled {
            stopSpeaking()
        }
    }
}
