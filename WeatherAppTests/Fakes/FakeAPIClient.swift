import Foundation
import Synchronization
@testable import WeatherApp

/// Stands in for SMHI: returns prepared data or a prepared error, without any network,
/// and counts the requests so tests can check that a request was (or was not) made.
///
/// The repository runs off the main thread, so the counter is guarded by a `Mutex`.
nonisolated final class FakeAPIClient: WeatherAPIClient {
    private let result: Result<Data, WeatherError>
    private let calls = Mutex(0)

    init(_ result: Result<Data, WeatherError>) {
        self.result = result
    }

    var callCount: Int { calls.withLock { $0 } }

    func fetchForecastData(for coordinate: Coordinate) async throws(WeatherError) -> Data {
        calls.withLock { $0 += 1 }
        return try result.get()
    }
}
