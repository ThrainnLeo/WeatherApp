import SwiftUI

/// The mood of the screen: one background gradient per kind of weather, plus a night sky for
/// the screens that have no forecast yet (W-06, H-02).
///
/// The colours are fixed, not light/dark pairs: the app always uses the dark colour scheme
/// (see `SearchView`), so white text is always on a dark-enough background.
/// The values are tuned for white text (roughly 4.5:1 or better) and should be checked on a device,
/// also with "Increase Contrast" on.
enum WeatherTheme: Equatable {
    /// Not a weather: the background of the start, loading and error screens, before there is a forecast.
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

    private var colors: (top: Color, bottom: Color) {
        switch self {
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
