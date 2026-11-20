import Foundation

/// A complete forecast for one place, as the rest of the app sees it.
nonisolated struct Forecast: Codable, Equatable, Sendable {
    /// Coordinates of the grid point SMHI used, which can differ slightly from the request.
    let latitude: Double
    let longitude: Double
    /// When SMHI's forecast run was made. Shown as "updated at" when cached data is displayed.
    let issuedAt: Date
    /// Forecast steps, sorted by time.
    let steps: [ForecastStep]
}
