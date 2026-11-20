import Foundation

/// Stores cached forecasts as JSON in `UserDefaults`, one entry per place.
nonisolated struct UserDefaultsCacheStore: CacheStore {
    private let defaults: UserDefaults

    /// Tests pass a throwaway `UserDefaults(suiteName:)` so they never touch the app's real data.
    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func save(_ cached: CachedForecast, for coordinate: Coordinate) {
        // A failed save only means there is no offline copy next time;
        // it must not turn a successful download into an error.
        guard let data = try? JSONEncoder().encode(cached) else { return }
        defaults.set(data, forKey: Self.key(for: coordinate))
    }

    func load(for coordinate: Coordinate) -> CachedForecast? {
        guard let data = defaults.data(forKey: Self.key(for: coordinate)) else { return nil }
        // Corrupt data, or data saved by an older app version with a different model,
        // is treated the same as no cache instead of crashing.
        return try? JSONDecoder().decode(CachedForecast.self, from: data)
    }

    /// Rounded to 2 decimals (about 1 km), so the same city found twice with slightly
    /// different coordinates shares one cache entry. `String(format:)` always uses a decimal point.
    static func key(for coordinate: Coordinate) -> String {
        String(format: "forecast.%.2f,%.2f", coordinate.latitude, coordinate.longitude)
    }
}
