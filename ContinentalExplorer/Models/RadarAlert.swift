import Foundation
import CoreLocation

// MARK: - Radar Type
enum RadarType: String, Codable, CaseIterable {
    case fixed = "Fixed"
    case mobile = "Mobile"
    case average = "Average Speed"
    case redLight = "Red Light"
    case section = "Section Control"
    
    var iconName: String {
        switch self {
        case .fixed: return "camera.fill"
        case .mobile: return "camera.metering.spot"
        case .average: return "camera.metering.matrix"
        case .redLight: return "light.beacon.max.fill"
        case .section: return "ruler.fill"
        }
    }
    
    var alertSound: String {
        switch self {
        case .fixed: return "radar_fixed"
        case .mobile: return "radar_mobile"
        case .average: return "radar_average"
        case .redLight: return "radar_redlight"
        case .section: return "radar_section"
        }
    }
}

// MARK: - Radar Alert
struct RadarAlert: Identifiable, Codable {
    let id: UUID
    let type: RadarType
    let coordinate: CLLocationCoordinate2D
    let speedLimit: Int
    let direction: Double
    let isVerified: Bool
    let reportCount: Int
    let lastReported: Date
    let country: String
    
    init(
        id: UUID = UUID(),
        type: RadarType,
        coordinate: CLLocationCoordinate2D,
        speedLimit: Int,
        direction: Double = 0,
        isVerified: Bool = true,
        reportCount: Int = 1,
        lastReported: Date = Date(),
        country: String
    ) {
        self.id = id
        self.type = type
        self.coordinate = coordinate
        self.speedLimit = speedLimit
        self.direction = direction
        self.isVerified = isVerified
        self.reportCount = reportCount
        self.lastReported = lastReported
        self.country = country
    }
    
    // MARK: - Codable
    enum CodingKeys: String, CodingKey {
        case id, type, latitude, longitude, speedLimit, direction
        case isVerified, reportCount, lastReported, country
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        type = try container.decode(RadarType.self, forKey: .type)
        let latitude = try container.decode(Double.self, forKey: .latitude)
        let longitude = try container.decode(Double.self, forKey: .longitude)
        coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        speedLimit = try container.decode(Int.self, forKey: .speedLimit)
        direction = try container.decode(Double.self, forKey: .direction)
        isVerified = try container.decode(Bool.self, forKey: .isVerified)
        reportCount = try container.decode(Int.self, forKey: .reportCount)
        lastReported = try container.decode(Date.self, forKey: .lastReported)
        country = try container.decode(String.self, forKey: .country)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(type, forKey: .type)
        try container.encode(coordinate.latitude, forKey: .latitude)
        try container.encode(coordinate.longitude, forKey: .longitude)
        try container.encode(speedLimit, forKey: .speedLimit)
        try container.encode(direction, forKey: .direction)
        try container.encode(isVerified, forKey: .isVerified)
        try container.encode(reportCount, forKey: .reportCount)
        try container.encode(lastReported, forKey: .lastReported)
        try container.encode(country, forKey: .country)
    }
}
