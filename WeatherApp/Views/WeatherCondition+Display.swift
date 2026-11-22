import SwiftUI

/// How each SMHI condition is shown: an SF Symbol, a colour and a short English text (W-06).
extension WeatherCondition {
    /// Used with `.hierarchical` rendering. `.multicolor` draws clouds white, which disappears
    /// on a white list background.
    var symbolColor: Color {
        switch self {
        case .clearSky, .nearlyClearSky, .variableCloudiness, .halfclearSky: .orange
        case .cloudySky, .overcast, .fog, .unknown: .gray
        case .lightRainShowers, .moderateRainShowers, .heavyRainShowers,
             .lightRain, .moderateRain, .heavyRain,
             .lightSleetShowers, .moderateSleetShowers, .heavySleetShowers,
             .lightSleet, .moderateSleet, .heavySleet: .blue
        case .lightSnowShowers, .moderateSnowShowers, .heavySnowShowers,
             .lightSnowfall, .moderateSnowfall, .heavySnowfall: .cyan
        case .thunderstorm, .thunder: .purple
        }
    }

    var symbolName: String {
        switch self {
        case .clearSky, .nearlyClearSky: "sun.max.fill"
        case .variableCloudiness, .halfclearSky: "cloud.sun.fill"
        case .cloudySky, .overcast: "cloud.fill"
        case .fog: "cloud.fog.fill"
        case .lightRainShowers, .lightRain: "cloud.drizzle.fill"
        case .moderateRainShowers, .moderateRain: "cloud.rain.fill"
        case .heavyRainShowers, .heavyRain: "cloud.heavyrain.fill"
        case .thunderstorm: "cloud.bolt.rain.fill"
        case .thunder: "cloud.bolt.fill"
        case .lightSleetShowers, .moderateSleetShowers, .heavySleetShowers,
             .lightSleet, .moderateSleet, .heavySleet: "cloud.sleet.fill"
        case .lightSnowShowers, .moderateSnowShowers, .lightSnowfall, .moderateSnowfall: "cloud.snow.fill"
        case .heavySnowShowers, .heavySnowfall: "snowflake"
        case .unknown: "questionmark.circle"
        }
    }

    var text: String {
        switch self {
        case .clearSky: "Clear sky"
        case .nearlyClearSky: "Nearly clear sky"
        case .variableCloudiness: "Variable cloudiness"
        case .halfclearSky: "Partly cloudy"
        case .cloudySky: "Cloudy"
        case .overcast: "Overcast"
        case .fog: "Fog"
        case .lightRainShowers: "Light rain showers"
        case .moderateRainShowers: "Rain showers"
        case .heavyRainShowers: "Heavy rain showers"
        case .thunderstorm: "Thunderstorm"
        case .lightSleetShowers: "Light sleet showers"
        case .moderateSleetShowers: "Sleet showers"
        case .heavySleetShowers: "Heavy sleet showers"
        case .lightSnowShowers: "Light snow showers"
        case .moderateSnowShowers: "Snow showers"
        case .heavySnowShowers: "Heavy snow showers"
        case .lightRain: "Light rain"
        case .moderateRain: "Rain"
        case .heavyRain: "Heavy rain"
        case .thunder: "Thunder"
        case .lightSleet: "Light sleet"
        case .moderateSleet: "Sleet"
        case .heavySleet: "Heavy sleet"
        case .lightSnowfall: "Light snow"
        case .moderateSnowfall: "Snow"
        case .heavySnowfall: "Heavy snow"
        case .unknown: "Unknown"
        }
    }
}
