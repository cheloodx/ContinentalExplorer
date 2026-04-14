import Foundation
import MapKit
import Combine

// MARK: - Search Result
struct PlaceSearchResult: Identifiable, Equatable {
    let id = UUID()
    let title: String
    let subtitle: String
    let coordinate: CLLocationCoordinate2D
    let mapItem: MKMapItem?
    let category: PlaceCategory

    static func == (lhs: PlaceSearchResult, rhs: PlaceSearchResult) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Place Category
enum PlaceCategory: String, CaseIterable {
    case gasStation = "Gas Station"
    case restaurant = "Restaurant"
    case parking = "Parking"
    case hospital = "Hospital"
    case hotel = "Hotel"
    case charger = "EV Charger"
    case atm = "ATM"
    case pharmacy = "Pharmacy"

    var iconName: String {
        switch self {
        case .gasStation: return "fuelpump.fill"
        case .restaurant: return "fork.knife"
        case .parking: return "p.square.fill"
        case .hospital: return "cross.fill"
        case .hotel: return "bed.double.fill"
        case .charger: return "bolt.car.fill"
        case .atm: return "banknote.fill"
        case .pharmacy: return "pills.fill"
        }
    }

    var searchQuery: String {
        switch self {
        case .gasStation: return "gas station"
        case .restaurant: return "restaurant"
        case .parking: return "parking"
        case .hospital: return "hospital"
        case .hotel: return "hotel"
        case .charger: return "ev charging station"
        case .atm: return "atm"
        case .pharmacy: return "pharmacy"
        }
    }

    var tintColor: String {
        switch self {
        case .gasStation: return "#FF6B6B"
        case .restaurant: return "#FFB68D"
        case .parking: return "#4CD6FF"
        case .hospital: return "#FF4444"
        case .hotel: return "#B68DFF"
        case .charger: return "#00D68F"
        case .atm: return "#FFD700"
        case .pharmacy: return "#00D68F"
        }
    }
}

// MARK: - Places Search Service
@MainActor
final class PlacesSearchService: ObservableObject {
    @Published var searchText: String = ""
    @Published var searchResults: [PlaceSearchResult] = []
    @Published var isSearching: Bool = false
    @Published var recentSearches: [PlaceSearchResult] = []
    @Published var categoryResults: [PlaceSearchResult] = []

    private var searchCancellable: AnyCancellable?
    private var completer = MKLocalSearchCompleter()
    private var completionResults: [MKLocalSearchCompletion] = []

    init() {
        setupSearchDebounce()
    }

    private func setupSearchDebounce() {
        searchCancellable = $searchText
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] query in
                guard let self = self else { return }
                if query.isEmpty {
                    self.searchResults = []
                    self.isSearching = false
                } else {
                    Task { await self.performSearch(query: query) }
                }
            }
    }

    func performSearch(query: String) async {
        isSearching = true
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        request.resultTypes = [.address, .pointOfInterest]

        do {
            let search = MKLocalSearch(request: request)
            let response = try await search.start()
            searchResults = response.mapItems.map { item in
                PlaceSearchResult(
                    title: item.name ?? "Unknown",
                    subtitle: item.placemark.formattedAddress,
                    coordinate: item.placemark.coordinate,
                    mapItem: item,
                    category: .restaurant
                )
            }
        } catch {
            searchResults = []
        }
        isSearching = false
    }

    func searchByCategory(_ category: PlaceCategory, near coordinate: CLLocationCoordinate2D) async {
        isSearching = true
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = category.searchQuery
        request.region = MKCoordinateRegion(
            center: coordinate,
            latitudinalMeters: 5000,
            longitudinalMeters: 5000
        )

        do {
            let search = MKLocalSearch(request: request)
            let response = try await search.start()
            categoryResults = response.mapItems.map { item in
                PlaceSearchResult(
                    title: item.name ?? "Unknown",
                    subtitle: item.placemark.formattedAddress,
                    coordinate: item.placemark.coordinate,
                    mapItem: item,
                    category: category
                )
            }
        } catch {
            categoryResults = []
        }
        isSearching = false
    }

    func addToRecent(_ result: PlaceSearchResult) {
        recentSearches.removeAll { $0.id == result.id }
        recentSearches.insert(result, at: 0)
        if recentSearches.count > 10 {
            recentSearches = Array(recentSearches.prefix(10))
        }
    }

    func clearSearch() {
        searchText = ""
        searchResults = []
    }
}

// MARK: - MKPlacemark Extension
extension MKPlacemark {
    var formattedAddress: String {
        let components = [
            thoroughfare,
            subThoroughfare,
            locality,
            administrativeArea,
            countryCode
        ].compactMap { $0 }
        return components.joined(separator: ", ")
    }
}
