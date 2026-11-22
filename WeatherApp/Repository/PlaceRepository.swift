import Foundation

/// The ViewModel's entry point for place search: download → parse. No cache: a place search
/// needs the network anyway, and the forecast for a chosen place is cached by `WeatherRepository`.
nonisolated struct PlaceRepository: Sendable {
    private let client: any GeocodingClient
    private let parser: GeocodingParser

    init(client: any GeocodingClient, parser: GeocodingParser = GeocodingParser()) {
        self.client = client
        self.parser = parser
    }

    /// `@concurrent` so parsing runs off the main thread, like `WeatherRepository` (W-15).
    @concurrent
    func search(_ query: String) async throws(WeatherError) -> [Place] {
        let data = try await client.searchData(for: query)
        do {
            return try parser.parse(data)
        } catch {
            throw WeatherError(error)
        }
    }
}
