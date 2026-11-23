import Foundation

/// Stores the favourites as one JSON array in `UserDefaults`, in the order the user added them.
nonisolated struct UserDefaultsFavoritesStore: FavoritesStore {
    static let key = "favorites"

    private let defaults: UserDefaults

    /// Tests pass a throwaway `UserDefaults(suiteName:)` so they never touch the app's real data.
    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func load() -> [Place] {
        guard let data = defaults.data(forKey: Self.key) else { return [] }
        // Corrupt data, or data saved by an older app version with a different `Place`,
        // gives an empty list instead of a crash.
        return (try? JSONDecoder().decode([Place].self, from: data)) ?? []
    }

    func save(_ places: [Place]) {
        // A failed save only means the change is lost at the next launch;
        // the list in memory is still right for this session.
        guard let data = try? JSONEncoder().encode(places) else { return }
        defaults.set(data, forKey: Self.key)
    }
}
