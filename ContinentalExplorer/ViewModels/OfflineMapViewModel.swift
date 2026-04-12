import SwiftUI
import Combine

// MARK: - Offline Map View Model
@MainActor
final class OfflineMapViewModel: ObservableObject {
    
    // MARK: - Published
    @Published var availableRegions: [MapRegionData] = []
    @Published var downloadedRegions: [MapRegionData] = []
    @Published var downloadProgress: [UUID: TileDownloadProgress] = [:]
    @Published var isDownloading: Bool = false
    @Published var storageUsed: String = "0 MB"
    @Published var storagePercentage: Double = 0
    @Published var searchText: String = ""
    @Published var selectedRegion: MapRegionData?
    @Published var showDeleteConfirmation: Bool = false
    @Published var regionToDelete: MapRegionData?
    
    // MARK: - Private
    private let tileManager: OfflineTileManager
    private var cancellables = Set<AnyCancellable>()
    
    init(tileManager: OfflineTileManager = OfflineTileManager()) {
        self.tileManager = tileManager
        setupBindings()
    }
    
    // MARK: - Bindings
    private func setupBindings() {
        tileManager.$availableRegions
            .assign(to: &$availableRegions)
        
        tileManager.$downloadedRegions
            .assign(to: &$downloadedRegions)
        
        tileManager.$downloadProgress
            .assign(to: &$downloadProgress)
        
        tileManager.$isDownloading
            .assign(to: &$isDownloading)
        
        tileManager.$totalStorageUsedMB
            .map { String(format: "%.1f MB", $0) }
            .assign(to: &$storageUsed)
        
        tileManager.objectWillChange
            .sink { [weak self] in
                guard let self else { return }
                self.storagePercentage = self.tileManager.storagePercentage
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Actions
    func downloadRegion(_ region: MapRegionData) {
        tileManager.downloadRegion(region)
    }
    
    func cancelDownload(_ regionID: UUID) {
        tileManager.cancelDownload(regionID: regionID)
    }
    
    func confirmDelete(_ region: MapRegionData) {
        regionToDelete = region
        showDeleteConfirmation = true
    }
    
    func deleteRegion() {
        guard let region = regionToDelete else { return }
        tileManager.deleteRegion(regionID: region.id)
        regionToDelete = nil
        showDeleteConfirmation = false
    }
    
    func checkForUpdates() {
        Task {
            await tileManager.checkForUpdates()
        }
    }
    
    // MARK: - Computed
    var filteredAvailableRegions: [MapRegionData] {
        guard !searchText.isEmpty else { return availableRegions }
        return availableRegions.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.country.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    func isRegionDownloaded(_ region: MapRegionData) -> Bool {
        downloadedRegions.contains { $0.id == region.id }
    }
    
    func progressFor(_ regionID: UUID) -> TileDownloadProgress? {
        downloadProgress[regionID]
    }
}
