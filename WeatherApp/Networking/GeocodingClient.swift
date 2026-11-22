import Foundation

/// Downloads raw place-search JSON. A protocol so tests can replace the network with a fake.
nonisolated protocol GeocodingClient: Sendable {
    func searchData(for query: String) async throws(WeatherError) -> Data
}
