import Foundation
import CoreLocation
import Combine

// MARK: - Aura AI Service (Road Health Scan)
@MainActor
final class AuraAIService: ObservableObject {

    // MARK: - Published
    @Published var isScanning: Bool = false
    @Published var currentRating: RoadHealthRating = .good
    @Published var scanHistory: [RoadScanResult] = []
    @Published var confidenceLevel: Double = 0.0
    @Published var detectedHazards: [DetectedHazard] = []
    @Published var emotionalState: DrivingEmotionalState = .calm
    @Published var stressLevel: Double = 0.0

    // MARK: - Private
    private var cancellables = Set<AnyCancellable>()
    private var scanTimer: Timer?
    private let scanInterval: TimeInterval = 5.0
    private let maxHistoryItems = 50

    init() {}

    // MARK: - Road Health Scanning
    func startScanning() {
        guard !isScanning else { return }
        isScanning = true

        scanTimer = Timer.scheduledTimer(withTimeInterval: scanInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.performScan()
            }
        }
    }

    func stopScanning() {
        isScanning = false
        scanTimer?.invalidate()
        scanTimer = nil
    }

    private func performScan() {
        // Simulated CoreML road health analysis
        // In production, this would use camera feed + CoreML model
        let ratings: [RoadHealthRating] = [.excellent, .good, .good, .fair, .good, .excellent]
        let randomRating = ratings.randomElement() ?? .good
        let confidence = Double.random(in: 0.72...0.98)

        var hazards: [String] = []
        if Double.random(in: 0...1) < 0.15 {
            let possibleHazards = ["Pothole", "Crack", "Uneven surface", "Water pooling", "Debris"]
            hazards = [possibleHazards.randomElement() ?? "Pothole"]
        }

        currentRating = randomRating
        confidenceLevel = confidence

        let result = RoadScanResult(
            rating: randomRating,
            surfaceType: "Asphalt",
            hazards: hazards,
            confidence: confidence,
            latitude: 48.8566 + Double.random(in: -0.01...0.01),
            longitude: 2.3522 + Double.random(in: -0.01...0.01),
            roadName: sampleRoadNames.randomElement() ?? "Unknown Road"
        )

        scanHistory.insert(result, at: 0)
        if scanHistory.count > maxHistoryItems {
            scanHistory = Array(scanHistory.prefix(maxHistoryItems))
        }

        // Update hazard detections
        if !hazards.isEmpty {
            for hazard in hazards {
                let detected = DetectedHazard(
                    type: HazardType(rawValue: hazard) ?? .pothole,
                    confidence: confidence,
                    latitude: result.latitude,
                    longitude: result.longitude,
                    roadName: result.roadName
                )
                detectedHazards.insert(detected, at: 0)
                if detectedHazards.count > 20 {
                    detectedHazards = Array(detectedHazards.prefix(20))
                }
            }
        }
    }

    // MARK: - Emotional Analysis
    func updateEmotionalState(speed: Double, acceleration: Double, braking: Bool, timeOfDay: Int) {
        // Simulated emotional state analysis
        // In production, this would use CoreML with sensor data
        var stress: Double = 0.0

        // Speed factor
        if speed > 120 { stress += 0.3 }
        else if speed > 80 { stress += 0.1 }

        // Acceleration factor
        if abs(acceleration) > 3.0 { stress += 0.2 }

        // Braking factor
        if braking { stress += 0.15 }

        // Time of day factor (night driving adds stress)
        if timeOfDay < 6 || timeOfDay > 22 { stress += 0.1 }

        stressLevel = min(stress, 1.0)

        if stressLevel > 0.7 {
            emotionalState = .stressed
        } else if stressLevel > 0.4 {
            emotionalState = .focused
        } else if stressLevel > 0.2 {
            emotionalState = .alert
        } else {
            emotionalState = .calm
        }
    }

    // MARK: - Statistics
    var averageRoadHealth: Double {
        guard !scanHistory.isEmpty else { return 0 }
        let total = scanHistory.reduce(0) { $0 + $1.rating.score }
        return Double(total) / Double(scanHistory.count)
    }

    var averageConfidence: Double {
        guard !scanHistory.isEmpty else { return 0 }
        return scanHistory.reduce(0.0) { $0 + $1.confidence } / Double(scanHistory.count)
    }

    var hazardCount: Int {
        detectedHazards.count
    }

    // MARK: - Sample Data
    private let sampleRoadNames = [
        "Avenue des Champs-Élysées",
        "Autobahn A1",
        "Strada Victoriei",
        "Via Roma",
        "Calle Gran Vía",
        "Ringstraße",
        "Boulevard Saint-Germain",
        "Kurfürstendamm",
    ]
}

// MARK: - Detected Hazard
struct DetectedHazard: Identifiable {
    let id = UUID()
    let type: HazardType
    let confidence: Double
    let latitude: Double
    let longitude: Double
    let roadName: String
    let timestamp = Date()
}

// MARK: - Hazard Type
enum HazardType: String, CaseIterable {
    case pothole = "Pothole"
    case crack = "Crack"
    case unevenSurface = "Uneven surface"
    case waterPooling = "Water pooling"
    case debris = "Debris"

    var iconName: String {
        switch self {
        case .pothole: return "circle.slash"
        case .crack: return "line.diagonal"
        case .unevenSurface: return "waveform.path"
        case .waterPooling: return "drop.fill"
        case .debris: return "exclamationmark.triangle.fill"
        }
    }
}

// MARK: - Driving Emotional State
enum DrivingEmotionalState: String, CaseIterable {
    case calm = "Calm"
    case alert = "Alert"
    case focused = "Focused"
    case stressed = "Stressed"

    var iconName: String {
        switch self {
        case .calm: return "face.smiling"
        case .alert: return "eye.fill"
        case .focused: return "brain.head.profile"
        case .stressed: return "exclamationmark.circle.fill"
        }
    }

    var colorName: String {
        switch self {
        case .calm: return "success"
        case .alert: return "info"
        case .focused: return "warning"
        case .stressed: return "danger"
        }
    }
}
