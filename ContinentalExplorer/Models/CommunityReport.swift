import Foundation
import CoreLocation

// MARK: - Report Category
enum ReportCategory: String, Codable, CaseIterable {
    case police = "Police"
    case accident = "Accident"
    case hazard = "Road Hazard"
    case closure = "Road Closure"
    case construction = "Construction"
    case weather = "Bad Weather"
    case traffic = "Heavy Traffic"
    case animal = "Animal on Road"
    
    var iconName: String {
        switch self {
        case .police: return "shield.checkered"
        case .accident: return "car.side.front.open.fill"
        case .hazard: return "exclamationmark.triangle.fill"
        case .closure: return "xmark.circle.fill"
        case .construction: return "cone.striped.fill"
        case .weather: return "cloud.rain.fill"
        case .traffic: return "car.2.fill"
        case .animal: return "hare.fill"
        }
    }
    
    var severity: AlertSeverity {
        switch self {
        case .police: return .medium
        case .accident: return .high
        case .hazard: return .high
        case .closure: return .critical
        case .construction: return .low
        case .weather: return .medium
        case .traffic: return .low
        case .animal: return .medium
        }
    }
}

// MARK: - Alert Severity
enum AlertSeverity: Int, Codable, Comparable {
    case low = 0
    case medium = 1
    case high = 2
    case critical = 3
    
    static func < (lhs: AlertSeverity, rhs: AlertSeverity) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
    
    var label: String {
        switch self {
        case .low: return "Low"
        case .medium: return "Medium"
        case .high: return "High"
        case .critical: return "Critical"
        }
    }
}

// MARK: - Community Report
struct CommunityReport: Identifiable, Codable {
    let id: UUID
    let category: ReportCategory
    let coordinate: CLLocationCoordinate2D
    let description: String
    let reporterID: String
    let timestamp: Date
    let expiresAt: Date
    var upvotes: Int
    var downvotes: Int
    let isActive: Bool
    
    init(
        id: UUID = UUID(),
        category: ReportCategory,
        coordinate: CLLocationCoordinate2D,
        description: String = "",
        reporterID: String,
        timestamp: Date = Date(),
        expiresAt: Date = Date().addingTimeInterval(3600),
        upvotes: Int = 0,
        downvotes: Int = 0,
        isActive: Bool = true
    ) {
        self.id = id
        self.category = category
        self.coordinate = coordinate
        self.description = description
        self.reporterID = reporterID
        self.timestamp = timestamp
        self.expiresAt = expiresAt
        self.upvotes = upvotes
        self.downvotes = downvotes
        self.isActive = isActive
    }
    
    var reliability: Double {
        let total = upvotes + downvotes
        guard total > 0 else { return 0.5 }
        return Double(upvotes) / Double(total)
    }
    
    var isExpired: Bool {
        Date() > expiresAt
    }
    
    // MARK: - Codable
    enum CodingKeys: String, CodingKey {
        case id, category, latitude, longitude, description, reporterID
        case timestamp, expiresAt, upvotes, downvotes, isActive
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        category = try container.decode(ReportCategory.self, forKey: .category)
        let latitude = try container.decode(Double.self, forKey: .latitude)
        let longitude = try container.decode(Double.self, forKey: .longitude)
        coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        description = try container.decode(String.self, forKey: .description)
        reporterID = try container.decode(String.self, forKey: .reporterID)
        timestamp = try container.decode(Date.self, forKey: .timestamp)
        expiresAt = try container.decode(Date.self, forKey: .expiresAt)
        upvotes = try container.decode(Int.self, forKey: .upvotes)
        downvotes = try container.decode(Int.self, forKey: .downvotes)
        isActive = try container.decode(Bool.self, forKey: .isActive)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(category, forKey: .category)
        try container.encode(coordinate.latitude, forKey: .latitude)
        try container.encode(coordinate.longitude, forKey: .longitude)
        try container.encode(description, forKey: .description)
        try container.encode(reporterID, forKey: .reporterID)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encode(expiresAt, forKey: .expiresAt)
        try container.encode(upvotes, forKey: .upvotes)
        try container.encode(downvotes, forKey: .downvotes)
        try container.encode(isActive, forKey: .isActive)
    }
}
