import Foundation
import CoreLocation
import MapKit

// MARK: - Map Region
struct MapRegionData: Identifiable, Codable {
    let id: UUID
    let name: String
    let centerLatitude: Double
    let centerLongitude: Double
    let spanLatitude: Double
    let spanLongitude: Double
    let zoomLevel: Int
    let country: String
    let isDownloaded: Bool
    let downloadedAt: Date?
    let sizeInMB: Double
    
    init(
        id: UUID = UUID(),
        name: String,
        centerLatitude: Double,
        centerLongitude: Double,
        spanLatitude: Double = 0.5,
        spanLongitude: Double = 0.5,
        zoomLevel: Int = 15,
        country: String,
        isDownloaded: Bool = false,
        downloadedAt: Date? = nil,
        sizeInMB: Double = 0
    ) {
        self.id = id
        self.name = name
        self.centerLatitude = centerLatitude
        self.centerLongitude = centerLongitude
        self.spanLatitude = spanLatitude
        self.spanLongitude = spanLongitude
        self.zoomLevel = zoomLevel
        self.country = country
        self.isDownloaded = isDownloaded
        self.downloadedAt = downloadedAt
        self.sizeInMB = sizeInMB
    }
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: centerLatitude, longitude: centerLongitude)
    }
    
    var region: MKCoordinateRegion {
        MKCoordinateRegion(
            center: coordinate,
            span: MKCoordinateSpan(latitudeDelta: spanLatitude, longitudeDelta: spanLongitude)
        )
    }
}

// MARK: - European Regions (Presets)
extension MapRegionData {
    static let europeanCapitals: [MapRegionData] = [
        MapRegionData(name: "Paris", centerLatitude: 48.8566, centerLongitude: 2.3522, country: "France"),
        MapRegionData(name: "Berlin", centerLatitude: 52.5200, centerLongitude: 13.4050, country: "Germany"),
        MapRegionData(name: "Rome", centerLatitude: 41.9028, centerLongitude: 12.4964, country: "Italy"),
        MapRegionData(name: "Madrid", centerLatitude: 40.4168, centerLongitude: -3.7038, country: "Spain"),
        MapRegionData(name: "Vienna", centerLatitude: 48.2082, centerLongitude: 16.3738, country: "Austria"),
        MapRegionData(name: "Amsterdam", centerLatitude: 52.3676, centerLongitude: 4.9041, country: "Netherlands"),
        MapRegionData(name: "Prague", centerLatitude: 50.0755, centerLongitude: 14.4378, country: "Czech Republic"),
        MapRegionData(name: "Budapest", centerLatitude: 47.4979, centerLongitude: 19.0402, country: "Hungary"),
        MapRegionData(name: "Bucharest", centerLatitude: 44.4268, centerLongitude: 26.1025, country: "Romania"),
        MapRegionData(name: "Warsaw", centerLatitude: 52.2297, centerLongitude: 21.0122, country: "Poland"),
    ]
}
