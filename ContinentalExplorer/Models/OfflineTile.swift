import Foundation
import CoreLocation

// MARK: - Tile Status
enum TileStatus: String, Codable {
    case pending = "Pending"
    case downloading = "Downloading"
    case downloaded = "Downloaded"
    case failed = "Failed"
    case expired = "Expired"
    case updating = "Updating"
}

// MARK: - Offline Tile
struct OfflineTile: Identifiable, Codable {
    let id: UUID
    let x: Int
    let y: Int
    let zoomLevel: Int
    let regionID: UUID
    var status: TileStatus
    let createdAt: Date
    var lastUpdated: Date
    let sizeInBytes: Int64
    let checksum: String
    
    init(
        id: UUID = UUID(),
        x: Int,
        y: Int,
        zoomLevel: Int,
        regionID: UUID,
        status: TileStatus = .pending,
        createdAt: Date = Date(),
        lastUpdated: Date = Date(),
        sizeInBytes: Int64 = 0,
        checksum: String = ""
    ) {
        self.id = id
        self.x = x
        self.y = y
        self.zoomLevel = zoomLevel
        self.regionID = regionID
        self.status = status
        self.createdAt = createdAt
        self.lastUpdated = lastUpdated
        self.sizeInBytes = sizeInBytes
        self.checksum = checksum
    }
    
    var tileKey: String {
        "\(zoomLevel)/\(x)/\(y)"
    }
    
    var needsUpdate: Bool {
        let daysSinceUpdate = Calendar.current.dateComponents([.day], from: lastUpdated, to: Date()).day ?? 0
        return daysSinceUpdate > 7
    }
}

// MARK: - Download Progress
struct TileDownloadProgress: Identifiable {
    let id: UUID
    let regionName: String
    var totalTiles: Int
    var downloadedTiles: Int
    var failedTiles: Int
    var totalSizeInMB: Double
    var downloadedSizeInMB: Double
    var isComplete: Bool
    var isCancelled: Bool
    
    var progress: Double {
        guard totalTiles > 0 else { return 0 }
        return Double(downloadedTiles) / Double(totalTiles)
    }
    
    var remainingTiles: Int {
        totalTiles - downloadedTiles - failedTiles
    }
    
    init(
        id: UUID = UUID(),
        regionName: String,
        totalTiles: Int,
        downloadedTiles: Int = 0,
        failedTiles: Int = 0,
        totalSizeInMB: Double = 0,
        downloadedSizeInMB: Double = 0,
        isComplete: Bool = false,
        isCancelled: Bool = false
    ) {
        self.id = id
        self.regionName = regionName
        self.totalTiles = totalTiles
        self.downloadedTiles = downloadedTiles
        self.failedTiles = failedTiles
        self.totalSizeInMB = totalSizeInMB
        self.downloadedSizeInMB = downloadedSizeInMB
        self.isComplete = isComplete
        self.isCancelled = isCancelled
    }
}
