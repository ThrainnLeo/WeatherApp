import Foundation

/// A forecast as stored in the cache, together with when it was downloaded.
nonisolated struct CachedForecast: Codable, Equatable, Sendable {
    let forecast: Forecast
    /// When the app received this forecast. Used for "Offline – showing data from 14:15".
    let fetchedAt: Date
}
