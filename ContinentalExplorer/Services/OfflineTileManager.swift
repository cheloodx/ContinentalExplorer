import Foundation
import CoreData
import Combine
import CoreLocation

// MARK: - Offline Tile Manager
@MainActor
final class OfflineTileManager: ObservableObject {
    
    // MARK: - Published
    @Published var downloadProgress: [UUID: TileDownloadProgress] = [:]
    @Published var availableRegions: [MapRegionData] = MapRegionData.europeanCapitals
    @Published var downloadedRegions: [MapRegionData] = []
    @Published var totalStorageUsedMB: Double = 0
    @Published var isDownloading: Bool = false
    
    // MARK: - Private
    private let persistenceController: PersistenceController
    private var cancellables = Set<AnyCancellable>()
    private var activeTasks: [UUID: Task<Void, Never>] = [:]
    
    // MARK: - Configuration
    private let maxConcurrentDownloads = 4
    private let tileExpirationDays = 7
    private let maxStorageMB: Double = 2048
    
    init(persistenceController: PersistenceController = .shared) {
        self.persistenceController = persistenceController
        loadDownloadedRegions()
    }
    
    // MARK: - Download Management
    func downloadRegion(_ region: MapRegionData) {
        guard !isDownloading(regionID: region.id) else { return }
        
        isDownloading = true
        
        let totalTiles = calculateTileCount(for: region)
        let progress = TileDownloadProgress(
            id: region.id,
            regionName: region.name,
            totalTiles: totalTiles,
            totalSizeInMB: Double(totalTiles) * 0.015
        )
        downloadProgress[region.id] = progress
        
        let task = Task {
            await performDownload(region: region, totalTiles: totalTiles)
        }
        activeTasks[region.id] = task
    }
    
    func cancelDownload(regionID: UUID) {
        activeTasks[regionID]?.cancel()
        activeTasks.removeValue(forKey: regionID)
        downloadProgress[regionID]?.isCancelled = true
        
        if activeTasks.isEmpty {
            isDownloading = false
        }
    }
    
    func deleteRegion(regionID: UUID) {
        downloadedRegions.removeAll { $0.id == regionID }
        deleteTiles(for: regionID)
        // Also delete the region entity from CoreData
        let context = persistenceController.container.viewContext
        let request: NSFetchRequest<OfflineRegionEntity> = OfflineRegionEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", regionID as CVarArg)
        if let entities = try? context.fetch(request) {
            for entity in entities {
                context.delete(entity)
            }
            try? context.save()
        }
        recalculateStorage()
    }
    
    func checkForUpdates() async {
        for region in downloadedRegions {
            guard let downloadedAt = region.downloadedAt else { continue }
            let daysSinceDownload = Calendar.current.dateComponents(
                [.day], from: downloadedAt, to: Date()
            ).day ?? 0
            
            if daysSinceDownload >= tileExpirationDays {
                downloadRegion(region)
            }
        }
    }
    
    // MARK: - Private Methods
    private func performDownload(region: MapRegionData, totalTiles: Int) async {
        for tileIndex in 0..<totalTiles {
            guard !Task.isCancelled else { break }
            
            let tileCoords = calculateTileCoordinates(index: tileIndex, region: region)
            let tile = OfflineTile(
                x: tileCoords.x,
                y: tileCoords.y,
                zoomLevel: region.zoomLevel,
                regionID: region.id,
                status: .downloading
            )
            
            await saveTile(tile)
            
            // Simulate download delay
            try? await Task.sleep(nanoseconds: 10_000_000)
            
            downloadProgress[region.id]?.downloadedTiles = tileIndex + 1
            downloadProgress[region.id]?.downloadedSizeInMB = Double(tileIndex + 1) * 0.015
        }
        
        guard !Task.isCancelled else { return }
        
        let downloadedRegion = MapRegionData(
            id: region.id,
            name: region.name,
            centerLatitude: region.centerLatitude,
            centerLongitude: region.centerLongitude,
            spanLatitude: region.spanLatitude,
            spanLongitude: region.spanLongitude,
            zoomLevel: region.zoomLevel,
            country: region.country,
            isDownloaded: true,
            downloadedAt: Date(),
            sizeInMB: Double(totalTiles) * 0.015
        )
        
        downloadedRegions.removeAll { $0.id == downloadedRegion.id }
        downloadedRegions.append(downloadedRegion)

        // Persist the region entity to CoreData so it survives app restart
        // Delete any existing entity with the same ID first to prevent duplicates on re-download
        let context = persistenceController.container.viewContext
        let existingRequest: NSFetchRequest<OfflineRegionEntity> = OfflineRegionEntity.fetchRequest()
        existingRequest.predicate = NSPredicate(format: "id == %@", downloadedRegion.id as CVarArg)
        if let existing = try? context.fetch(existingRequest) {
            for entity in existing {
                context.delete(entity)
            }
        }
        let regionEntity = OfflineRegionEntity(context: context)
        regionEntity.id = downloadedRegion.id
        regionEntity.name = downloadedRegion.name
        regionEntity.country = downloadedRegion.country
        regionEntity.centerLatitude = downloadedRegion.centerLatitude
        regionEntity.centerLongitude = downloadedRegion.centerLongitude
        regionEntity.spanLatitude = downloadedRegion.spanLatitude
        regionEntity.spanLongitude = downloadedRegion.spanLongitude
        regionEntity.zoomLevel = Int32(downloadedRegion.zoomLevel)
        regionEntity.isDownloaded = true
        regionEntity.downloadedAt = downloadedRegion.downloadedAt
        regionEntity.sizeInMB = downloadedRegion.sizeInMB
        try? context.save()

        downloadProgress[region.id]?.isComplete = true
        activeTasks.removeValue(forKey: region.id)
        
        if activeTasks.isEmpty {
            isDownloading = false
        }
        
        recalculateStorage()
    }
    
    private func calculateTileCount(for region: MapRegionData) -> Int {
        let tilesPerAxis = Int(pow(2.0, Double(min(region.zoomLevel, 5))))
        return tilesPerAxis * tilesPerAxis
    }
    
    private func calculateTileCoordinates(index: Int, region: MapRegionData) -> (x: Int, y: Int) {
        let tilesPerAxis = Int(pow(2.0, Double(min(region.zoomLevel, 5))))
        let x = index % tilesPerAxis
        let y = index / tilesPerAxis
        return (x, y)
    }
    
    private func isDownloading(regionID: UUID) -> Bool {
        guard let progress = downloadProgress[regionID] else { return false }
        return !progress.isComplete && !progress.isCancelled
    }
    
    private func saveTile(_ tile: OfflineTile) async {
        let context = persistenceController.container.viewContext
        let entity = OfflineTileEntity(context: context)
        entity.id = tile.id
        entity.x = Int32(tile.x)
        entity.y = Int32(tile.y)
        entity.zoomLevel = Int32(tile.zoomLevel)
        entity.regionID = tile.regionID
        entity.status = tile.status.rawValue
        entity.createdAt = tile.createdAt
        entity.lastUpdated = tile.lastUpdated
        entity.sizeInBytes = tile.sizeInBytes
        entity.checksum = tile.checksum
        
        try? context.save()
    }
    
    private func deleteTiles(for regionID: UUID) {
        let context = persistenceController.container.viewContext
        let request: NSFetchRequest<OfflineTileEntity> = OfflineTileEntity.fetchRequest()
        request.predicate = NSPredicate(format: "regionID == %@", regionID as CVarArg)
        
        if let tiles = try? context.fetch(request) {
            for tile in tiles {
                context.delete(tile)
            }
            try? context.save()
        }
    }
    
    private func loadDownloadedRegions() {
        let context = persistenceController.container.viewContext
        let request: NSFetchRequest<OfflineRegionEntity> = OfflineRegionEntity.fetchRequest()
        
        if let entities = try? context.fetch(request) {
            downloadedRegions = entities.compactMap { entity in
                guard let id = entity.id, let name = entity.name, let country = entity.country else {
                    return nil
                }
                return MapRegionData(
                    id: id,
                    name: name,
                    centerLatitude: entity.centerLatitude,
                    centerLongitude: entity.centerLongitude,
                    spanLatitude: entity.spanLatitude,
                    spanLongitude: entity.spanLongitude,
                    zoomLevel: Int(entity.zoomLevel),
                    country: country,
                    isDownloaded: true,
                    downloadedAt: entity.downloadedAt,
                    sizeInMB: entity.sizeInMB
                )
            }
        }
        recalculateStorage()
    }
    
    private func recalculateStorage() {
        totalStorageUsedMB = downloadedRegions.reduce(0) { $0 + $1.sizeInMB }
    }
    
    var storagePercentage: Double {
        totalStorageUsedMB / maxStorageMB
    }
    
    var formattedStorageUsed: String {
        String(format: "%.1f MB / %.0f MB", totalStorageUsedMB, maxStorageMB)
    }
}
