import SwiftUI
import MapKit

// MARK: - Search Bar View (Waze-style)
struct SearchBarView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @ObservedObject var searchService: PlacesSearchService
    let onSelectResult: (PlaceSearchResult) -> Void
    let onDismiss: () -> Void

    @FocusState private var isSearchFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            // Search Input
            searchInputBar

            if !searchService.searchText.isEmpty || isSearchFocused {
                // Results
                searchResultsList
            } else {
                // Categories + Recents
                categoriesAndRecents
            }
        }
        .background(DesignTokens.Colors.surfacePrimary)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.lg))
        .shadow(color: .black.opacity(0.3), radius: 12, y: 4)
        .padding(.horizontal, DesignTokens.Spacing.md)
    }

    // MARK: - Search Input
    private var searchInputBar: some View {
        HStack(spacing: DesignTokens.Spacing.sm) {
            Button(action: onDismiss) {
                Image(systemName: "arrow.left")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(DesignTokens.Colors.textSecondary)
            }

            Image(systemName: "magnifyingglass")
                .foregroundStyle(DesignTokens.Colors.textTertiary)
                .font(.system(size: 16))

            TextField("Search destination", text: $searchService.searchText)
                .font(Typography.body(.md))
                .foregroundStyle(DesignTokens.Colors.textPrimary)
                .focused($isSearchFocused)
                .autocorrectionDisabled()

            if !searchService.searchText.isEmpty {
                Button {
                    searchService.clearSearch()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(DesignTokens.Colors.textTertiary)
                }
            }

            if searchService.isSearching {
                ProgressView()
                    .tint(DesignTokens.Colors.primaryAccent)
                    .scaleEffect(0.8)
            }
        }
        .padding(.horizontal, DesignTokens.Spacing.md)
        .padding(.vertical, DesignTokens.Spacing.sm + 4)
        .onAppear { isSearchFocused = true }
    }

    // MARK: - Results
    private var searchResultsList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(searchService.searchResults) { result in
                    SearchResultRow(result: result) {
                        searchService.addToRecent(result)
                        onSelectResult(result)
                    }
                }
            }
        }
        .frame(maxHeight: 400)
    }

    // MARK: - Categories & Recents
    private var categoriesAndRecents: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            // Quick Categories
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: DesignTokens.Spacing.sm) {
                    ForEach(PlaceCategory.allCases, id: \.self) { category in
                        CategoryChip(category: category) {
                            searchService.searchText = category.searchQuery
                        }
                    }
                }
                .padding(.horizontal, DesignTokens.Spacing.md)
            }
            .padding(.vertical, DesignTokens.Spacing.sm)

            // Recent Searches
            if !searchService.recentSearches.isEmpty {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                    Text("RECENT")
                        .font(Typography.body(.xs))
                        .foregroundStyle(DesignTokens.Colors.textTertiary)
                        .padding(.horizontal, DesignTokens.Spacing.md)

                    ForEach(searchService.recentSearches) { result in
                        SearchResultRow(result: result, isRecent: true) {
                            onSelectResult(result)
                        }
                    }
                }
            }

            Spacer().frame(height: DesignTokens.Spacing.md)
        }
    }
}

// MARK: - Search Result Row
struct SearchResultRow: View {
    let result: PlaceSearchResult
    var isRecent: Bool = false
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: DesignTokens.Spacing.md) {
                Image(systemName: isRecent ? "clock" : "mappin.circle.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(
                        isRecent ? DesignTokens.Colors.textTertiary : DesignTokens.Colors.primaryAccent
                    )
                    .frame(width: 32)

                VStack(alignment: .leading, spacing: 2) {
                    Text(result.title)
                        .font(Typography.bodyMedium(.md))
                        .foregroundStyle(DesignTokens.Colors.textPrimary)
                        .lineLimit(1)

                    Text(result.subtitle)
                        .font(Typography.body(.sm))
                        .foregroundStyle(DesignTokens.Colors.textTertiary)
                        .lineLimit(1)
                }

                Spacer()

                Image(systemName: "arrow.up.left")
                    .font(.system(size: 14))
                    .foregroundStyle(DesignTokens.Colors.textTertiary)
            }
            .padding(.horizontal, DesignTokens.Spacing.md)
            .padding(.vertical, DesignTokens.Spacing.sm + 2)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Category Chip
struct CategoryChip: View {
    let category: PlaceCategory
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: DesignTokens.Spacing.xs) {
                Image(systemName: category.iconName)
                    .font(.system(size: 18))
                    .foregroundStyle(Color(hex: category.tintColor))
                    .frame(width: 44, height: 44)
                    .background(Color(hex: category.tintColor).opacity(0.15))
                    .clipShape(Circle())

                Text(category.rawValue)
                    .font(Typography.body(.xxs))
                    .foregroundStyle(DesignTokens.Colors.textSecondary)
                    .lineLimit(1)
            }
            .frame(width: 64)
        }
        .buttonStyle(.plain)
    }
}
