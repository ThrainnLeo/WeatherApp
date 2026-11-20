import Foundation
import Testing
@testable import WeatherApp

struct ForecastParserTests {
    let parser = ForecastParser()

    // MARK: - Real data

    @Test func parsesRealStockholmSample() throws {
        let forecast = try parser.parse(loadFixture("smhi_stockholm_sample"))

        #expect(forecast.steps.count == 8)
        // SMHI sends [lon, lat]; checking both catches a swapped order.
        #expect(forecast.latitude == 59.33036)
        #expect(forecast.longitude == 18.077207)
        #expect(forecast.issuedAt == utcDate(2026, 11, 20, 14, 15))

        let first = try #require(forecast.steps.first)
        #expect(first.time == utcDate(2026, 11, 20, 15))
        #expect(first.intervalStart == utcDate(2026, 11, 20, 14))
        #expect(first.temperature == 1.3)
        #expect(first.condition == .moderateSnowfall)
        #expect(first.windSpeed == 3.9)
        #expect(first.precipitation == 0.7)
    }

    // MARK: - Missing values

    @Test func missingWindSpeedBecomesNilButStepIsKept() throws {
        let json = forecastJSON([step(time: "2026-11-20T10:00:00Z", windSpeed: 9999)])

        let forecast = try parser.parse(json)

        let only = try #require(forecast.steps.first)
        #expect(forecast.steps.count == 1)
        #expect(only.windSpeed == nil)
        #expect(only.temperature == 5.0)
    }

    @Test func stepWithMissingTemperatureIsSkipped() throws {
        let json = forecastJSON([
            step(time: "2026-11-20T10:00:00Z", temperature: 9999),
            step(time: "2026-11-20T11:00:00Z", temperature: 4.0),
        ])

        let forecast = try parser.parse(json)

        #expect(forecast.steps.count == 1)
        #expect(forecast.steps.first?.time == utcDate(2026, 11, 20, 11))
    }

    // MARK: - Ordering

    @Test func stepsInReverseOrderComeBackSorted() throws {
        let json = forecastJSON([
            step(time: "2026-11-20T12:00:00Z"),
            step(time: "2026-11-20T11:00:00Z"),
            step(time: "2026-11-20T10:00:00Z"),
        ])

        let forecast = try parser.parse(json)

        #expect(forecast.steps.map(\.time) == [
            utcDate(2026, 11, 20, 10),
            utcDate(2026, 11, 20, 11),
            utcDate(2026, 11, 20, 12),
        ])
    }

    // MARK: - Errors

    @Test func nonJSONBodyThrowsInvalidJSON() {
        let html = Data("<html><body><h1>404 Not Found</h1></body></html>".utf8)

        #expect(throws: ForecastParserError.invalidJSON) {
            try parser.parse(html)
        }
    }

    @Test func emptyTimeSeriesThrowsNoUsableTimeSteps() {
        let json = forecastJSON([])

        #expect(throws: ForecastParserError.noUsableTimeSteps) {
            try parser.parse(json)
        }
    }

    // MARK: - Weather condition mapping

    @Test(arguments: zip([1, 27, 42], [WeatherCondition.clearSky, .heavySnowfall, .unknown]))
    func weatherConditionMapsSymbolCode(code: Int, expected: WeatherCondition) {
        #expect(WeatherCondition(symbolCode: code) == expected)
    }
}

// MARK: - Helpers

/// Used only to find the test bundle, where the JSON fixture is copied.
private final class TestBundleToken {}

private func loadFixture(_ name: String) throws -> Data {
    let bundle = Bundle(for: TestBundleToken.self)
    let url = try #require(bundle.url(forResource: name, withExtension: "json"))
    return try Data(contentsOf: url)
}

/// Builds the expected date independently of the parser's ISO 8601 decoding.
private func utcDate(_ year: Int, _ month: Int, _ day: Int, _ hour: Int, _ minute: Int = 0) -> Date {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = .gmt
    let components = DateComponents(year: year, month: month, day: day, hour: hour, minute: minute)
    return calendar.date(from: components) ?? .distantPast
}

/// A minimal SMHI response around the given time steps.
private func forecastJSON(_ steps: [String]) -> Data {
    let json = """
    {
      "referenceTime": "2026-11-20T09:00:00Z",
      "geometry": { "type": "Point", "coordinates": [18.07, 59.33] },
      "timeSeries": [\(steps.joined(separator: ","))]
    }
    """
    return Data(json.utf8)
}

/// One SMHI time step with only the fields the parser reads.
private func step(time: String, temperature: Double = 5.0, windSpeed: Double = 3.0, symbolCode: Int = 1) -> String {
    """
    {
      "time": "\(time)",
      "intervalParametersStartTime": "\(time)",
      "data": { "air_temperature": \(temperature), "wind_speed": \(windSpeed), "symbol_code": \(symbolCode) }
    }
    """
}
