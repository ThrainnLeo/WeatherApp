import Foundation
import SwiftUI
import Testing
@testable import WeatherApp

/// `WeatherTheme` lives on the main actor (the module's default), so the tests do too.
@MainActor
struct WeatherThemeTests {
    // MARK: - S1: where day turns into night

    @Test(arguments: [
        (hour: 0, minute: 0, isDay: false),
        (hour: 5, minute: 59, isDay: false),
        (hour: 6, minute: 0, isDay: true),
        (hour: 17, minute: 59, isDay: true),
        (hour: 18, minute: 0, isDay: false),
    ])
    func dayRunsFrom0600UpTo1800(hour: Int, minute: Int, isDay: Bool) throws {
        let calendar = try makeCalendar(timeZone: "Europe/Stockholm")
        let date = try makeDate(hour: hour, minute: minute, in: calendar)

        #expect(WeatherTheme.sky(at: date, calendar: calendar) == (isDay ? .day : .night))
    }

    // MARK: - S2: the calendar's time zone is really used

    @Test func sameMomentIsDayInStockholmAndNightInUTC() throws {
        let utc = try makeCalendar(timeZone: "UTC")
        let stockholm = try makeCalendar(timeZone: "Europe/Stockholm")
        // 05:00 UTC on 24 Nov is 06:00 in Stockholm (UTC+1 in winter).
        let moment = try makeDate(hour: 5, minute: 0, in: utc)

        #expect(WeatherTheme.sky(at: moment, calendar: utc) == .night)
        #expect(WeatherTheme.sky(at: moment, calendar: stockholm) == .day)
    }

    // MARK: - S3: only the day sky is light

    @Test func dayIsLight() {
        #expect(WeatherTheme.day.colorScheme == .light)
    }

    @Test(arguments: [WeatherTheme.night, .sunny, .cloudy, .rain, .snow, .storm])
    func everyOtherThemeIsDark(theme: WeatherTheme) {
        #expect(theme.colorScheme == .dark)
    }

    // MARK: - Helpers

    private func makeCalendar(timeZone identifier: String) throws -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try #require(TimeZone(identifier: identifier))
        return calendar
    }

    private func makeDate(hour: Int, minute: Int, in calendar: Calendar) throws -> Date {
        let components = DateComponents(year: 2026, month: 11, day: 24, hour: hour, minute: minute)
        return try #require(calendar.date(from: components))
    }
}
