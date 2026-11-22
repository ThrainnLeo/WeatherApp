import Foundation
import Testing
@testable import WeatherApp

struct WeatherErrorTests {
    // MARK: - E1, E2: URLError

    @Test func noInternetIsOffline() {
        #expect(WeatherError(URLError(.notConnectedToInternet)) == .offline)
    }

    @Test func timedOutIsTimeout() {
        #expect(WeatherError(URLError(.timedOut)) == .timeout)
    }

    // MARK: - E3, E4, E5: HTTP status

    @Test func notFoundOutOfBoundsIsOutsideForecastArea() {
        // The exact body SMHI sends for Paris.
        let body = Data("Requested point is out of bounds".utf8)

        #expect(WeatherError.fromHTTP(status: 404, body: body) == .outsideForecastArea)
    }

    @Test func notFoundHTMLPageIsHTTP404() {
        // What SMHI sends for a malformed URL, e.g. a decimal comma.
        let body = Data("<!DOCTYPE html><html><head><title>404 Not Found</title></head></html>".utf8)

        #expect(WeatherError.fromHTTP(status: 404, body: body) == .http(404))
    }

    @Test func serverErrorIsHTTP500() {
        #expect(WeatherError.fromHTTP(status: 500, body: Data()) == .http(500))
    }

    // MARK: - E6, E7: place search key and limits

    @Test func unauthorizedIsAPIKeyRejected() {
        // What geocode.maps.co answers for a missing or wrong key.
        let body = Data("Missing API Key".utf8)

        #expect(WeatherError.fromHTTP(status: 401, body: body) == .apiKeyRejected)
    }

    @Test func tooManyRequestsIsRateLimited() {
        #expect(WeatherError.fromHTTP(status: 429, body: Data()) == .rateLimited)
    }
}
