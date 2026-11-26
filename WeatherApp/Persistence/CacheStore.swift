import Foundation

/// Remembers the last successful forecast per place. A protocol so tests can use an in-memory fake
/// and so the storage can change (e.g. to SwiftData) without touching the repository.
nonisolated protocol CacheStore: Sendable {
    func save(_ cached: CachedForecast, for coordinate: Coordinate)
    func load(for coordinate: Coordinate) -> CachedForecast?
    /// Forgets every saved forecast (the "Clear saved forecasts" setting, W-04).
    func removeAll()
}
