import Foundation

/// Every way loading a forecast can fail, as the ViewModel sees it.
///
/// Low-level errors (URLError, HTTP status codes, parser errors) are classified here,
/// in plain functions that don't need a network, so the rules can be unit tested.
nonisolated enum WeatherError: Error, Equatable, Sendable {
    /// The device has no internet connection.
    case offline
    /// The server did not answer within the request timeout.
    case timeout
    /// The request was cancelled, e.g. because a newer search replaced it. Not shown to the user.
    case cancelled
    /// Any other connection problem (server unreachable, DNS, TLS, …).
    case network
    /// SMHI has no forecast for this point (it only covers the Nordic area).
    case outsideForecastArea
    /// The server answered with a non-2xx status code.
    case http(Int)
    /// The response could not be turned into a forecast.
    case decoding

    init(_ error: URLError) {
        switch error.code {
        case .notConnectedToInternet, .networkConnectionLost, .dataNotAllowed, .internationalRoamingOff:
            self = .offline
        case .timedOut:
            self = .timeout
        case .cancelled:
            self = .cancelled
        default:
            self = .network
        }
    }

    init(_ error: ForecastParserError) {
        // The UI shows the same message for every parser failure, so the detail is dropped here.
        self = .decoding
    }

    /// Returns `nil` for a successful status (200–299), otherwise the matching error.
    static func fromHTTP(status: Int, body: Data) -> WeatherError? {
        guard !(200...299).contains(status) else { return nil }

        // SMHI uses 404 both for points outside its area (plain text body) and for
        // malformed URLs (HTML page). Only the first means "outside forecast area";
        // the second is our own bug and should not be disguised as a geography problem.
        if status == 404, String(decoding: body, as: UTF8.self).contains("out of bounds") {
            return .outsideForecastArea
        }
        return .http(status)
    }
}
