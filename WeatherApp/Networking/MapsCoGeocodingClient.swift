import Foundation

/// Searches geocode.maps.co for places matching a name. Knows nothing about parsing.
nonisolated struct MapsCoGeocodingClient: GeocodingClient {
    /// Enough matches to choose from without a long list.
    static let resultLimit = 10

    private let apiKey: String?
    private let session: URLSession
    private let searchURL: String

    /// `apiKey` is `nil` when Secrets.plist has no usable key; searches then fail with
    /// `.apiKeyMissing` before anything is sent.
    init(
        apiKey: String? = Secrets.geocodeMapsAPIKey(),
        session: URLSession = SMHIAPIClient.makeSession(),
        searchURL: String = APIEnvironment.geocodeMapsSearchURL
    ) {
        self.apiKey = apiKey
        self.session = session
        self.searchURL = searchURL
    }

    func searchData(for query: String) async throws(WeatherError) -> Data {
        guard let apiKey else { throw .apiKeyMissing }
        guard let url = makeURL(for: query, apiKey: apiKey) else { throw .network }

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

    /// `URLComponents` percent-encodes the query, so "Malmö" or "Rio de Janeiro" are sent correctly.
    func makeURL(for query: String, apiKey: String) -> URL? {
        var components = URLComponents(string: searchURL)
        components?.queryItems = [
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "limit", value: String(Self.resultLimit)),
            URLQueryItem(name: "api_key", value: apiKey),
        ]
        return components?.url
    }
}
