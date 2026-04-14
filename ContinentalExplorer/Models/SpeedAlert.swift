import Foundation
import CoreLocation

// MARK: - Speed Alert
struct SpeedAlert: Identifiable, Codable {
    let id: UUID
    let speedLimit: Int
    let coordinate: CLLocationCoordinate2D
    let radius: CLLocationDistance
    let roadName: String
    let country: String
    let isActive: Bool
    let lastUpdated: Date
    
    init(
        id: UUID = UUID(),
        speedLimit: Int,
        coordinate: CLLocationCoordinate2D,
        radius: CLLocationDistance = 500,
        roadName: String,
        country: String,
        isActive: Bool = true,
        lastUpdated: Date = Date()
    ) {
        self.id = id
        self.speedLimit = speedLimit
        self.coordinate = coordinate
        self.radius = radius
        self.roadName = roadName
        self.country = country
        self.isActive = isActive
        self.lastUpdated = lastUpdated
    }
    
    // MARK: - Codable
    enum CodingKeys: String, CodingKey {
        case id, speedLimit, latitude, longitude, radius, roadName, country, isActive, lastUpdated
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        speedLimit = try container.decode(Int.self, forKey: .speedLimit)
        let latitude = try container.decode(Double.self, forKey: .latitude)
        let longitude = try container.decode(Double.self, forKey: .longitude)
        coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        radius = try container.decode(CLLocationDistance.self, forKey: .radius)
        roadName = try container.decode(String.self, forKey: .roadName)
        country = try container.decode(String.self, forKey: .country)
        isActive = try container.decode(Bool.self, forKey: .isActive)
        lastUpdated = try container.decode(Date.self, forKey: .lastUpdated)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(speedLimit, forKey: .speedLimit)
        try container.encode(coordinate.latitude, forKey: .latitude)
        try container.encode(coordinate.longitude, forKey: .longitude)
        try container.encode(radius, forKey: .radius)
        try container.encode(roadName, forKey: .roadName)
        try container.encode(country, forKey: .country)
        try container.encode(isActive, forKey: .isActive)
        try container.encode(lastUpdated, forKey: .lastUpdated)
    }
}

// MARK: - Speed Status
enum SpeedStatus {
    case safe
    case warning
    case danger
    
    var description: String {
        switch self {
        case .safe: return "Within Limit"
        case .warning: return "Approaching Limit"
        case .danger: return "Over Limit"
        }
    }
}
