import Foundation

/// Fetches forecast JSON from SMHI. Knows nothing about parsing or caching.
nonisolated struct SMHIAPIClient: WeatherAPIClient {
    private let session: URLSession
    private let baseURL: String

    init(session: URLSession = SMHIAPIClient.makeSession(), baseURL: String = APIEnvironment.smhiForecastBaseURL) {
        self.session = session
        self.baseURL = baseURL
    }

    /// The default 60 s timeout feels like a frozen app; after 15 s we give up and show cached data.
    static func makeSession() -> URLSession {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 15
        return URLSession(configuration: configuration)
    }

    func fetchForecastData(for coordinate: Coordinate) async throws(WeatherError) -> Data {
        guard let url = makeURL(for: coordinate) else {
            // Only possible if the base URL itself is malformed.
            throw .network
        }

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(from: url)
        } catch let error as URLError {
            throw WeatherError(error)
        } catch is CancellationError {
            throw .cancelled
        } catch {
            throw .network
        }

        guard let httpResponse = response as? HTTPURLResponse else { throw .network }
        if let error = WeatherError.fromHTTP(status: httpResponse.statusCode, body: data) {
            throw error
        }
        return data
    }

    func makeURL(for coordinate: Coordinate) -> URL? {
        let longitude = Self.format(coordinate.longitude)
        let latitude = Self.format(coordinate.latitude)
        return URL(string: "\(baseURL)/geotype/point/lon/\(longitude)/lat/\(latitude)/data.json")
    }

    /// SMHI answers 404 for more than 6 decimals and for a decimal comma. The locale is fixed
    /// to POSIX because a Swedish-language phone would otherwise format 18.07 as "18,07".
    private static func format(_ degrees: Double) -> String {
        degrees.formatted(
            .number
                .precision(.fractionLength(0...6))
                .grouping(.never)
                .locale(Locale(identifier: "en_US_POSIX"))
        )
    }
}
