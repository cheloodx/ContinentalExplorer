import CoreData

// MARK: - Persistence Controller
/// Manages CoreData stack for offline map tile storage
final class PersistenceController {
    static let shared = PersistenceController()
    
    let container: NSPersistentContainer
    
    // MARK: - Preview
    static var preview: PersistenceController = {
        let controller = PersistenceController(inMemory: true)
        let viewContext = controller.container.viewContext
        
        // Create sample offline tiles
        for i in 0..<10 {
            let tile = OfflineTileEntity(context: viewContext)
            tile.id = UUID()
            tile.x = Int32(i)
            tile.y = Int32(i)
            tile.zoomLevel = 15
            tile.regionID = UUID()
            tile.status = TileStatus.downloaded.rawValue
            tile.createdAt = Date()
            tile.lastUpdated = Date()
            tile.sizeInBytes = 15360
            tile.checksum = "abc\(i)"
        }
        
        // Create sample region
        let region = OfflineRegionEntity(context: viewContext)
        region.id = UUID()
        region.name = "Paris"
        region.country = "France"
        region.centerLatitude = 48.8566
        region.centerLongitude = 2.3522
        region.spanLatitude = 0.5
        region.spanLongitude = 0.5
        region.zoomLevel = 15
        region.isDownloaded = true
        region.downloadedAt = Date()
        region.sizeInMB = 45.2
        
        try? viewContext.save()
        return controller
    }()
    
    // MARK: - Init
    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "ContinentalExplorer")
        
        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }
        
        container.loadPersistentStores { description, error in
            if let error = error as NSError? {
                // In production, handle this gracefully
                print("CoreData error: \(error), \(error.userInfo)")
            }
        }
        
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }
    
    // MARK: - Save
    func save() {
        let context = container.viewContext
        guard context.hasChanges else { return }
        
        do {
            try context.save()
        } catch {
            print("CoreData save error: \(error)")
        }
    }
    
    // MARK: - Background Context
    func newBackgroundContext() -> NSManagedObjectContext {
        container.newBackgroundContext()
    }
}
