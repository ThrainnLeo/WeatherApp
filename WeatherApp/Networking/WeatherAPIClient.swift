import Foundation

/// Downloads raw forecast JSON. A protocol so tests can replace the network with a fake.
nonisolated protocol WeatherAPIClient: Sendable {
    func fetchForecastData(for coordinate: Coordinate) async throws(WeatherError) -> Data
}
