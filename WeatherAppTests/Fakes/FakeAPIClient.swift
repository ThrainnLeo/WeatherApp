import Foundation
@testable import WeatherApp

/// Stands in for SMHI: returns prepared data or a prepared error, without any network.
nonisolated struct FakeAPIClient: WeatherAPIClient {
    let result: Result<Data, WeatherError>

    init(_ result: Result<Data, WeatherError>) {
        self.result = result
    }

    func fetchForecastData(for coordinate: Coordinate) async throws(WeatherError) -> Data {
        try result.get()
    }
}
