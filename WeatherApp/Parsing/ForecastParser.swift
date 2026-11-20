import Foundation

/// Turns SMHI snow1g JSON into the app's `Forecast` model.
/// This is the only type that knows how SMHI's format looks.
///
/// `nonisolated` because the project isolates code to the main actor by default,
/// and parsing ~70 KB of JSON should be able to run off the main thread (W-15).
nonisolated struct ForecastParser {
    /// SMHI sends this number when a value is missing, instead of leaving the key out.
    static let missingValue: Double = 9999

    func parse(_ data: Data) throws(ForecastParserError) -> Forecast {
        let dto: SMHIForecastDTO
        do {
            dto = try makeDecoder().decode(SMHIForecastDTO.self, from: data)
        } catch {
            // The decoder's detailed error is replaced with our own small error type,
            // so the layers above don't depend on JSONDecoder.
            throw .invalidJSON
        }

        let coordinates = dto.geometry.coordinates
        guard coordinates.count == 2 else { throw .invalidJSON }

        let steps = dto.timeSeries
            .compactMap { makeStep(from: $0) }
            .sorted { $0.time < $1.time }
        guard !steps.isEmpty else { throw .noUsableTimeSteps }

        return Forecast(
            latitude: coordinates[1],
            longitude: coordinates[0],
            issuedAt: dto.referenceTime,
            steps: steps
        )
    }

    private func makeDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }

    /// Returns `nil` for a step the app can't display (no temperature or no symbol),
    /// so it is skipped instead of failing the whole forecast.
    private func makeStep(from dto: SMHIForecastDTO.TimeStep) -> ForecastStep? {
        let values = dto.data
        guard let temperature = present(values.airTemperature),
              let symbolCode = values.symbolCode,
              Double(symbolCode) != Self.missingValue
        else {
            return nil
        }

        return ForecastStep(
            time: dto.time,
            // Without an interval start we can't tell what period precipitation covers;
            // treating it as an instant is safer than guessing an hour.
            intervalStart: dto.intervalParametersStartTime ?? dto.time,
            temperature: temperature,
            condition: WeatherCondition(symbolCode: symbolCode),
            windSpeed: present(values.windSpeed),
            windGust: present(values.windSpeedOfGust),
            windDirection: present(values.windFromDirection),
            precipitation: present(values.precipitationAmountMean),
            precipitationProbability: present(values.probabilityOfPrecipitation),
            humidity: present(values.relativeHumidity)
        )
    }

    /// Treats SMHI's missing-value marker the same as a missing key.
    private func present(_ value: Double?) -> Double? {
        guard let value, value != Self.missingValue else { return nil }
        return value
    }
}
