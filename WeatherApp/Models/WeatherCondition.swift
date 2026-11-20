import Foundation

/// The weather condition for one forecast step.
///
/// Raw values are SMHI's Wsymb2 symbol codes (1–27), so the parser can map a code
/// with `init(symbolCode:)`. Display text and icons are added later in the UI layer.
nonisolated enum WeatherCondition: Int, Codable, Sendable {
    // Raw value 0 is not an SMHI code. It is used for any code we don't recognise,
    // so a new code from SMHI shows "unknown" instead of failing the whole forecast.
    case unknown = 0

    case clearSky = 1
    case nearlyClearSky = 2
    case variableCloudiness = 3
    case halfclearSky = 4
    case cloudySky = 5
    case overcast = 6
    case fog = 7
    case lightRainShowers = 8
    case moderateRainShowers = 9
    case heavyRainShowers = 10
    case thunderstorm = 11
    case lightSleetShowers = 12
    case moderateSleetShowers = 13
    case heavySleetShowers = 14
    case lightSnowShowers = 15
    case moderateSnowShowers = 16
    case heavySnowShowers = 17
    case lightRain = 18
    case moderateRain = 19
    case heavyRain = 20
    case thunder = 21
    case lightSleet = 22
    case moderateSleet = 23
    case heavySleet = 24
    case lightSnowfall = 25
    case moderateSnowfall = 26
    case heavySnowfall = 27

    init(symbolCode: Int) {
        self = WeatherCondition(rawValue: symbolCode) ?? .unknown
    }
}
