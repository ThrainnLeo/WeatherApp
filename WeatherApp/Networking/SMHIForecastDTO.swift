import Foundation

/// Mirrors the JSON from SMHI's snow1g point forecast. Values are kept exactly as SMHI
/// sends them (including the 9999 "missing" marker); `ForecastParser` interprets them.
///
/// Only the fields the app uses are declared. `Decodable` ignores all other JSON keys.
/// Property names are camelCase versions of SMHI's snake_case keys; the decoder converts
/// them with `.convertFromSnakeCase`.
nonisolated struct SMHIForecastDTO: Decodable, Sendable {
    let referenceTime: Date
    let geometry: Geometry
    let timeSeries: [TimeStep]

    struct Geometry: Decodable, Sendable {
        /// Note the order: [longitude, latitude].
        let coordinates: [Double]
    }

    struct TimeStep: Decodable, Sendable {
        let time: Date
        let intervalParametersStartTime: Date?
        let data: StepData
    }

    /// Optional so that one missing key doesn't make the whole response fail to decode.
    struct StepData: Decodable, Sendable {
        let airTemperature: Double?
        let symbolCode: Int?
        let windSpeed: Double?
        let windSpeedOfGust: Double?
        let windFromDirection: Double?
        let precipitationAmountMean: Double?
        let probabilityOfPrecipitation: Double?
        let relativeHumidity: Double?
    }
}
