import Foundation
import Observation

/// The user's favourite places and the actions on them (W-03). Every change is saved straight away,
/// so nothing is lost if the app is closed.
@Observable
@MainActor
final class FavoritesViewModel {
    /// In the order the user added them.
    private(set) var favorites: [Place]

    private let store: any FavoritesStore
    private let repository: WeatherRepository

    init(store: any FavoritesStore, repository: WeatherRepository) {
        self.store = store
        self.repository = repository
        favorites = store.load()
    }

    /// The temperature for the current hour from the saved forecast, or `nil` if the place has no
    /// cached forecast or it is too old (decision 5: no network request, so it also works offline).
    func lastKnownTemperature(for place: Place, now: Date = Date()) -> Double? {
        guard let cached = repository.cachedForecast(for: place.coordinate) else { return nil }
        // A step's values apply to its time; the step of the hour we are in still counts as now.
        let startOfHour = now.addingTimeInterval(-3600)
        return cached.forecast.steps.first { $0.time > startOfHour }?.temperature
    }

    func isFavorite(_ place: Place) -> Bool {
        favorites.contains { Self.isSamePlace($0, place) }
    }

    /// Adds the place, or removes it if it is already a favourite (the star button).
    func toggle(_ place: Place) {
        if let index = favorites.firstIndex(where: { Self.isSamePlace($0, place) }) {
            favorites.remove(at: index)
        } else {
            favorites.append(place)
        }
        store.save(favorites)
    }

    /// Swipe to delete in the list. `IndexSet` is what SwiftUI's `onDelete` hands over.
    func remove(at offsets: IndexSet) {
        // Highest index first, so removing one item doesn't shift the positions of the others.
        // (SwiftUI's `remove(atOffsets:)` would need `import SwiftUI` in a ViewModel.)
        for index in offsets.sorted(by: >) where favorites.indices.contains(index) {
            favorites.remove(at: index)
        }
        store.save(favorites)
    }

    /// Two places are the same favourite if their coordinates match when rounded to 2 decimals
    /// (about 1 km), the same rule as the forecast cache. A city found once by name and once by
    /// coordinates then gives one favourite, not two. Known limit of rounding: two points a few
    /// hundred metres apart can still round differently if they lie on each side of a boundary
    /// (59.334 → 59.33, 59.336 → 59.34).
    static func isSamePlace(_ first: Place, _ second: Place) -> Bool {
        rounded(first.coordinate.latitude) == rounded(second.coordinate.latitude)
            && rounded(first.coordinate.longitude) == rounded(second.coordinate.longitude)
    }

    private static func rounded(_ degrees: Double) -> Double {
        (degrees * 100).rounded() / 100
    }
}
