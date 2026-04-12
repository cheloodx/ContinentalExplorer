import SwiftUI

// MARK: - Offline Map Manager View
/// UI for managing offline map tile downloads and storage
struct OfflineMapManagerView: View {
    @StateObject private var viewModel = OfflineMapViewModel()
    @EnvironmentObject private var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                themeManager.backgroundColor
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: DesignTokens.Spacing.lg) {
                        // Storage indicator
                        storageCard
                        
                        // Downloaded regions
                        if !viewModel.downloadedRegions.isEmpty {
                            downloadedSection
                        }
                        
                        // Available regions
                        availableSection
                    }
                    .padding(DesignTokens.Spacing.md)
                }
            }
            .navigationTitle("Offline Maps")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(DesignTokens.Colors.primaryAccent)
                }
                
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        viewModel.checkForUpdates()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .foregroundStyle(DesignTokens.Colors.primaryAccent)
                    }
                }
            }
            .toolbarBackground(themeManager.surfaceColor, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .searchable(text: $viewModel.searchText, prompt: "Search regions...")
            .alert("Delete Region", isPresented: $viewModel.showDeleteConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    viewModel.deleteRegion()
                }
            } message: {
                if let region = viewModel.regionToDelete {
                    Text("Delete offline maps for \(region.name)? This will free up \(String(format: "%.1f MB", region.sizeInMB)).")
                }
            }
        }
    }
    
    // MARK: - Storage Card
    private var storageCard: some View {
        VStack(spacing: DesignTokens.Spacing.sm) {
            HStack {
                Image(systemName: "internaldrive.fill")
                    .foregroundStyle(DesignTokens.Colors.primaryAccent)
                
                Text("Storage")
                    .font(Typography.bodySemiBold(.md))
                    .foregroundStyle(DesignTokens.Colors.textPrimary)
                
                Spacer()
                
                Text(viewModel.storageUsed)
                    .font(Typography.body(.sm))
                    .foregroundStyle(DesignTokens.Colors.textSecondary)
            }
            
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(DesignTokens.Colors.surfaceSecondary)
                        .frame(height: 8)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(storageColor)
                        .frame(
                            width: geometry.size.width * min(viewModel.storagePercentage, 1.0),
                            height: 8
                        )
                        .animation(.easeInOut, value: viewModel.storagePercentage)
                }
            }
            .frame(height: 8)
        }
        .padding(DesignTokens.Spacing.md)
        .background(DesignTokens.Colors.surfacePrimary)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.md))
    }
    
    private var storageColor: Color {
        if viewModel.storagePercentage > 0.9 { return DesignTokens.Colors.danger }
        if viewModel.storagePercentage > 0.7 { return DesignTokens.Colors.warning }
        return DesignTokens.Colors.primaryAccent
    }
    
    // MARK: - Downloaded Section
    private var downloadedSection: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            Text("Downloaded")
                .font(Typography.headline(.h5))
                .foregroundStyle(DesignTokens.Colors.textPrimary)
            
            ForEach(viewModel.downloadedRegions) { region in
                DownloadedRegionCard(region: region) {
                    viewModel.confirmDelete(region)
                }
            }
        }
    }
    
    // MARK: - Available Section
    private var availableSection: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            Text("Available Regions")
                .font(Typography.headline(.h5))
                .foregroundStyle(DesignTokens.Colors.textPrimary)
            
            ForEach(viewModel.filteredAvailableRegions) { region in
                AvailableRegionCard(
                    region: region,
                    isDownloaded: viewModel.isRegionDownloaded(region),
                    progress: viewModel.progressFor(region.id)
                ) {
                    viewModel.downloadRegion(region)
                } onCancel: {
                    viewModel.cancelDownload(region.id)
                }
            }
        }
    }
}

// MARK: - Downloaded Region Card
struct DownloadedRegionCard: View {
    let region: MapRegionData
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: DesignTokens.Spacing.md) {
            Image(systemName: "map.fill")
                .font(.system(size: 20))
                .foregroundStyle(DesignTokens.Colors.success)
                .frame(width: 40, height: 40)
                .background(DesignTokens.Colors.success.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.sm))
            
            VStack(alignment: .leading, spacing: 2) {
                Text(region.name)
                    .font(Typography.bodySemiBold(.sm))
                    .foregroundStyle(DesignTokens.Colors.textPrimary)
                
                HStack {
                    Text(region.country)
                    Text("•")
                    Text(String(format: "%.1f MB", region.sizeInMB))
                }
                .font(Typography.body(.xs))
                .foregroundStyle(DesignTokens.Colors.textSecondary)
            }
            
            Spacer()
            
            Button(action: onDelete) {
                Image(systemName: "trash.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(DesignTokens.Colors.danger)
            }
            .buttonStyle(.plain)
        }
        .padding(DesignTokens.Spacing.md)
        .background(DesignTokens.Colors.surfacePrimary)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.md))
    }
}

// MARK: - Available Region Card
struct AvailableRegionCard: View {
    let region: MapRegionData
    let isDownloaded: Bool
    let progress: TileDownloadProgress?
    let onDownload: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        HStack(spacing: DesignTokens.Spacing.md) {
            Image(systemName: "map")
                .font(.system(size: 20))
                .foregroundStyle(DesignTokens.Colors.primaryAccent)
                .frame(width: 40, height: 40)
                .background(DesignTokens.Colors.primaryAccent.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.sm))
            
            VStack(alignment: .leading, spacing: 2) {
                Text(region.name)
                    .font(Typography.bodySemiBold(.sm))
                    .foregroundStyle(DesignTokens.Colors.textPrimary)
                
                Text(region.country)
                    .font(Typography.body(.xs))
                    .foregroundStyle(DesignTokens.Colors.textSecondary)
                
                if let progress = progress, !progress.isComplete {
                    ProgressView(value: progress.progress)
                        .tint(DesignTokens.Colors.primaryAccent)
                        .padding(.top, 4)
                }
            }
            
            Spacer()
            
            if let progress = progress, !progress.isComplete && !progress.isCancelled {
                Button(action: onCancel) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(DesignTokens.Colors.textTertiary)
                }
                .buttonStyle(.plain)
            } else if !isDownloaded {
                Button(action: onDownload) {
                    Image(systemName: "arrow.down.circle.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(DesignTokens.Colors.primaryAccent)
                }
                .buttonStyle(.plain)
            } else {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(DesignTokens.Colors.success)
            }
        }
        .padding(DesignTokens.Spacing.md)
        .background(DesignTokens.Colors.surfacePrimary)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.md))
    }
}

#Preview {
    OfflineMapManagerView()
        .environmentObject(ThemeManager())
}
