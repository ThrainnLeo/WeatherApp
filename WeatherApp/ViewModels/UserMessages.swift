import Foundation

/// All texts the user sees about errors, in one place so wording stays consistent.
enum UserMessages {
    static func message(for error: WeatherError) -> String {
        switch error {
        case .offline:
            "You're offline. Connect to the internet and try again."
        // Neutral wording where the same error can come from SMHI or from the place search.
        case .timeout:
            "The server didn't answer in time. Try again."
        case .outsideForecastArea:
            "SMHI only has forecasts for the Nordic area. Try a place in Sweden or a neighbouring country."
        case .http(let code):
            "The server had a problem (error \(code)). Try again later."
        case .decoding:
            "The answer from the server couldn't be read. Try again later."
        case .network, .cancelled:
            "Couldn't reach the server. Check your connection and try again."
        case .apiKeyMissing:
            "Place search isn't set up. Add your geocode.maps.co key to Secrets.plist, or search by coordinates."
        case .apiKeyRejected:
            "The place search key was rejected. Check the key in Secrets.plist."
        case .rateLimited:
            "Too many searches in a short time. Wait a moment and try again."
        }
    }

    static func noPlacesFound(for query: String) -> String {
        "No places found for “\(query)”."
    }

    static let emptyPlaceQuery = "Type a place name, e.g. Stockholm."

    static func message(for error: CoordinateInputError) -> String {
        switch error {
        case .notANumber(.latitude):
            "Enter the latitude as a number, e.g. 59.33."
        case .notANumber(.longitude):
            "Enter the longitude as a number, e.g. 18.07."
        case .outOfRange(.latitude):
            "Latitude must be between −90 and 90."
        case .outOfRange(.longitude):
            "Longitude must be between −180 and 180."
        }
    }

    /// Banner shown above cached data (W-10). Includes the date if the data is not from today,
    /// so "14:15" can't be misread as today's 14:15.
    static func staleBanner(reason: WeatherError, fetchedAt: Date, now: Date, calendar: Calendar = .current) -> String {
        let time = calendar.isDate(fetchedAt, inSameDayAs: now)
            ? fetchedAt.formatted(date: .omitted, time: .shortened)
            : fetchedAt.formatted(date: .abbreviated, time: .shortened)
        let prefix = reason == .offline ? "Offline" : "Couldn't update"
        return "\(prefix) – showing data from \(time)."
    }
}
