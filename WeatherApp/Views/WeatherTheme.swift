import SwiftUI

/// The mood of the screen: one background gradient per kind of weather, plus a day and a night sky
/// for the screens that have no forecast yet (W-06, H-02).
///
/// The colours are fixed, not light/dark pairs, and each theme says which colour scheme it needs
/// (`colorScheme`): every theme except `.day` is dark and tuned for white text (roughly 4.5:1 or
/// better); `.day` is light and tuned for dark text. The values are estimates and should be checked
/// on a device, also with "Increase Contrast" on.
enum WeatherTheme: Equatable, CaseIterable {
    /// Not a weather: the light background of the start, loading and error screens by day.
    case day
    /// Not a weather: the dark background of the start, loading and error screens at night.
    case night
    case sunny
    case cloudy
    case rain
    case snow
    case storm

    /// Top-to-bottom gradient; slightly lighter at the bottom so the list reads as lying on a horizon.
    var gradient: LinearGradient {
        let (top, bottom) = colors
        return LinearGradient(colors: [top, bottom], startPoint: .top, endPoint: .bottom)
    }

    /// The scheme the screen must use with this theme, so text and materials are readable on the
    /// gradient. Only the day sky is light; one value for both means they can't disagree.
    var colorScheme: ColorScheme {
        self == .day ? .light : .dark
    }

    /// What moves behind the text for this theme, drawn in this order. Storm is rain, only denser and
    /// with a third cloud: no lightning, because flashes can be a problem for people sensitive to light.
    /// Counts are starting values, to be tuned on a device; at most 80 elements per theme.
    var layers: [WeatherLayer] {
        switch self {
        case .day: [.sunGlow, .clouds(count: 2)]
        case .night: [.stars(count: 55)]
        case .sunny: [.sunGlow, .clouds(count: 1)]
        case .cloudy: [.clouds(count: 4)]
        case .rain: [.clouds(count: 2), .rain(count: 40)]
        case .snow: [.clouds(count: 2), .snow(count: 36)]
        case .storm: [.clouds(count: 3), .rain(count: 70)]
        }
    }

    /// Seconds between frames: the shortest of the layers' intervals, so the fastest layer looks smooth
    /// and a theme with only slow layers (night: stars) costs less.
    var frameInterval: Double {
        layers.map(\.minimumInterval).min() ?? 1
    }

    /// The sky for the screens that have no forecast: day from 06:00 up to 18:00 local time, else night.
    /// The clock hour, not sunrise and sunset: there is no place (and no sun data) on the start screen.
    /// Date and calendar are parameters, so a test can use any time and time zone.
    static func sky(at date: Date, calendar: Calendar = .current) -> WeatherTheme {
        let hour = calendar.component(.hour, from: date)
        return (6..<18).contains(hour) ? .day : .night
    }

    private var colors: (top: Color, bottom: Color) {
        switch self {
        case .day: (Color(red: 0.42, green: 0.70, blue: 0.95), Color(red: 0.78, green: 0.90, blue: 1.00))
        case .night: (Color(red: 0.05, green: 0.07, blue: 0.20), Color(red: 0.16, green: 0.16, blue: 0.40))
        case .sunny: (Color(red: 0.08, green: 0.30, blue: 0.65), Color(red: 0.20, green: 0.48, blue: 0.82))
        case .cloudy: (Color(red: 0.28, green: 0.33, blue: 0.40), Color(red: 0.40, green: 0.45, blue: 0.52))
        case .rain: (Color(red: 0.16, green: 0.22, blue: 0.34), Color(red: 0.28, green: 0.36, blue: 0.50))
        case .snow: (Color(red: 0.28, green: 0.40, blue: 0.58), Color(red: 0.36, green: 0.48, blue: 0.64))
        case .storm: (Color(red: 0.14, green: 0.12, blue: 0.26), Color(red: 0.28, green: 0.24, blue: 0.44))
        }
    }
}

extension View {
    /// Frosted-glass row background: the gradient shows through, text stays readable.
    /// Used on every list section so the cards look the same on all screens.
    func frostedRows() -> some View {
        listRowBackground(Rectangle().fill(.ultraThinMaterial))
    }
}
