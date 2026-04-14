import Foundation

// MARK: - Travel Token
struct TravelToken: Codable, Identifiable {
    let id: UUID
    let amount: Double
    let type: TokenTransactionType
    let description: String
    let timestamp: Date
    let relatedAchievementID: UUID?

    init(
        id: UUID = UUID(),
        amount: Double,
        type: TokenTransactionType,
        description: String,
        timestamp: Date = Date(),
        relatedAchievementID: UUID? = nil
    ) {
        self.id = id
        self.amount = amount
        self.type = type
        self.description = description
        self.timestamp = timestamp
        self.relatedAchievementID = relatedAchievementID
    }

    var formattedAmount: String {
        let prefix = type == .spent ? "-" : "+"
        return "\(prefix)\(String(format: "%.1f", amount)) CT"
    }

    var isPositive: Bool {
        type != .spent
    }
}

// MARK: - Token Transaction Type
enum TokenTransactionType: String, Codable {
    case earned = "Earned"
    case spent = "Spent"
    case bonus = "Bonus"
    case referral = "Referral"

    var iconName: String {
        switch self {
        case .earned: return "arrow.down.circle.fill"
        case .spent: return "arrow.up.circle.fill"
        case .bonus: return "gift.fill"
        case .referral: return "person.2.fill"
        }
    }
}

// MARK: - Road Health Rating
enum RoadHealthRating: String, Codable, CaseIterable {
    case excellent = "Excellent"
    case good = "Good"
    case fair = "Fair"
    case poor = "Poor"
    case dangerous = "Dangerous"

    var score: Int {
        switch self {
        case .excellent: return 5
        case .good: return 4
        case .fair: return 3
        case .poor: return 2
        case .dangerous: return 1
        }
    }

    var iconName: String {
        switch self {
        case .excellent: return "checkmark.shield.fill"
        case .good: return "shield.fill"
        case .fair: return "exclamationmark.shield.fill"
        case .poor: return "xmark.shield.fill"
        case .dangerous: return "exclamationmark.triangle.fill"
        }
    }

    var colorName: String {
        switch self {
        case .excellent: return "success"
        case .good: return "info"
        case .fair: return "warning"
        case .poor: return "danger"
        case .dangerous: return "danger"
        }
    }
}

// MARK: - Road Scan Result
struct RoadScanResult: Codable, Identifiable {
    let id: UUID
    let rating: RoadHealthRating
    let surfaceType: String
    let hazards: [String]
    let confidence: Double
    let latitude: Double
    let longitude: Double
    let timestamp: Date
    let roadName: String

    init(
        id: UUID = UUID(),
        rating: RoadHealthRating,
        surfaceType: String = "Asphalt",
        hazards: [String] = [],
        confidence: Double = 0.85,
        latitude: Double,
        longitude: Double,
        timestamp: Date = Date(),
        roadName: String = ""
    ) {
        self.id = id
        self.rating = rating
        self.surfaceType = surfaceType
        self.hazards = hazards
        self.confidence = confidence
        self.latitude = latitude
        self.longitude = longitude
        self.timestamp = timestamp
        self.roadName = roadName
    }

    var confidencePercentage: String {
        String(format: "%.0f%%", confidence * 100)
    }
}
