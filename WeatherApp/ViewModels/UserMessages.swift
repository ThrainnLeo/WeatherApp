import Foundation

/// All texts the user sees about errors, in one place so wording stays consistent.
enum UserMessages {
    static func message(for error: WeatherError) -> String {
        switch error {
        case .offline:
            "You're offline. Connect to the internet and try again."
        case .timeout:
            "SMHI didn't answer in time. Try again."
        case .outsideForecastArea:
            "SMHI only has forecasts for the Nordic area. Try a place in Sweden or a neighbouring country."
        case .http(let code):
            "SMHI's server had a problem (error \(code)). Try again later."
        case .decoding:
            "The forecast couldn't be read. Try again later."
        case .network, .cancelled:
            "Couldn't reach SMHI. Check your connection and try again."
        }
    }

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
