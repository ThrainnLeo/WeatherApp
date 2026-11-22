import Foundation
import Testing
@testable import WeatherApp

/// All tests run "in Stockholm" with a fixed clock, so they give the same result
/// on any machine, in any time zone, at any time of day.
struct ForecastGrouperTests {
    let grouper = ForecastGrouper(calendar: stockholmCalendar)
    /// Sunday 22 Nov 2026, 16:05 in Stockholm (15:05 UTC).
    let now = local(2026, 11, 22, 16, 5)

    // MARK: - G1: time zone

    @Test func stepAt2300UTCBelongsToNextLocalDay() {
        let lateEvening = step(at: utc(2026, 11, 23, 22))   // 23:00 on 23 Nov in Stockholm
        let midnight = step(at: utc(2026, 11, 23, 23))      // 00:00 on 24 Nov in Stockholm

        let grouped = grouper.group(forecast([lateEvening, midnight]), now: now)

        #expect(grouped.days.map(\.date) == [local(2026, 11, 23), local(2026, 11, 24)])
        #expect(grouped.days.first?.steps == [lateEvening])
        #expect(grouped.days.last?.steps == [midnight])
    }

    // MARK: - G2: today's hours

    @Test func todayHoldsStepsFromCurrentHourToMidnight() {
        let pastHour = step(at: local(2026, 11, 22, 15))
        let currentHour = step(at: local(2026, 11, 22, 16))
        let lastHourToday = step(at: local(2026, 11, 22, 23))
        let tomorrow = step(at: local(2026, 11, 23, 0))

        let grouped = grouper.group(forecast([pastHour, currentHour, lastHourToday, tomorrow]), now: now)

        #expect(grouped.today == [currentHour, lastHourToday])
    }

    // MARK: - G3, G4: daily summary

    @Test func dailyMinAndMaxCoverAllStepsOfTheDay() throws {
        let steps = [
            step(at: local(2026, 11, 23, 6), temperature: 3),
            step(at: local(2026, 11, 23, 12), temperature: -1),
            step(at: local(2026, 11, 23, 18), temperature: 5),
        ]

        let day = try #require(grouper.group(forecast(steps), now: now).days.first)

        #expect(day.minTemperature == -1)
        #expect(day.maxTemperature == 5)
    }

    @Test func dailyConditionComesFromStepNearestMidday() throws {
        let steps = [
            step(at: local(2026, 11, 23, 6), condition: .fog),
            step(at: local(2026, 11, 23, 11), condition: .lightRain),
            step(at: local(2026, 11, 23, 18), condition: .clearSky),
        ]

        let day = try #require(grouper.group(forecast(steps), now: now).days.first)

        #expect(day.condition == .lightRain)
    }

    // MARK: - G5: precipitation across midnight

    @Test func rainOfStepCrossingMidnightCountsForEarlierDay() throws {
        // The real SMHI pattern for later days: 12 h steps ending at 13:00 and 01:00.
        let steps = [
            step(at: local(2026, 11, 23, 13), precipitation: 0.5, intervalStart: local(2026, 11, 23, 1)),
            step(at: local(2026, 11, 24, 1), precipitation: 2.0, intervalStart: local(2026, 11, 23, 13)),
            step(at: local(2026, 11, 24, 13), precipitation: 1.0, intervalStart: local(2026, 11, 24, 1)),
        ]

        let days = grouper.group(forecast(steps), now: now).days

        #expect(days.map(\.precipitation) == [2.5, 1.0])
    }

    // MARK: - G6: number of days

    @Test func atMostSevenDaysAndEmptyDaysAreSkipped() {
        // One step at noon on each of the 10 days after today, except 25 Nov.
        let steps = (23...32)
            .filter { $0 != 25 }
            .map { day in step(at: local(2026, 11, day, 12)) }

        let days = grouper.group(forecast(steps), now: now).days

        // The 7 days after today are 23–29 Nov; 25 Nov has no data, so 6 remain.
        #expect(days.map(\.date) == [23, 24, 26, 27, 28, 29].map { local(2026, 11, $0) })
    }

    // MARK: - G7: old cached data

    @Test func pastStepsAreIgnoredAndCurrentIsFirstRemainingStep() {
        let twoDaysAgo = step(at: local(2026, 11, 20, 12))
        let thisMorning = step(at: local(2026, 11, 22, 10))
        let currentHour = step(at: local(2026, 11, 22, 16))
        let nextHour = step(at: local(2026, 11, 22, 17))

        let grouped = grouper.group(forecast([twoDaysAgo, thisMorning, currentHour, nextHour]), now: now)

        #expect(grouped.current == currentHour)
        #expect(grouped.today == [currentHour, nextHour])
        #expect(grouped.days.isEmpty)
    }

    // MARK: - G8: daylight saving time

    @Test func daylightSavingDayWith25HoursIsGroupedCorrectly() {
        // Clocks go back from 03:00 to 02:00 on Sunday 25 Oct 2026, so that day has 25 hours:
        // from 22:00 UTC on 24 Oct to 23:00 UTC on 25 Oct.
        let firstHourOfDSTDay = utc(2026, 10, 24, 22)
        let dstDay = (0..<25).map { hour in step(at: firstHourOfDSTDay.addingTimeInterval(Double(hour) * 3600)) }
        let nextMidnight = step(at: utc(2026, 10, 25, 23))
        let saturdayNoon = local(2026, 10, 24, 12)

        let days = grouper.group(forecast(dstDay + [nextMidnight]), now: saturdayNoon).days

        #expect(days.map(\.date) == [local(2026, 10, 25), local(2026, 10, 26)])
        #expect(days.map(\.steps.count) == [25, 1])
    }
}

// MARK: - Helpers

private let stockholmCalendar: Calendar = {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "Europe/Stockholm") ?? .gmt
    return calendar
}()

private let utcCalendar: Calendar = {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = .gmt
    return calendar
}()

/// A wall-clock time in Stockholm.
private func local(_ year: Int, _ month: Int, _ day: Int, _ hour: Int = 0, _ minute: Int = 0) -> Date {
    let components = DateComponents(year: year, month: month, day: day, hour: hour, minute: minute)
    return stockholmCalendar.date(from: components) ?? .distantPast
}

/// A time in UTC, the way SMHI sends it.
private func utc(_ year: Int, _ month: Int, _ day: Int, _ hour: Int) -> Date {
    utcCalendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour)) ?? .distantPast
}

private func step(
    at time: Date,
    temperature: Double = 0,
    condition: WeatherCondition = .clearSky,
    precipitation: Double? = nil,
    intervalStart: Date? = nil
) -> ForecastStep {
    ForecastStep(
        time: time,
        intervalStart: intervalStart ?? time.addingTimeInterval(-3600),
        temperature: temperature,
        condition: condition,
        windSpeed: nil,
        windGust: nil,
        windDirection: nil,
        precipitation: precipitation,
        precipitationProbability: nil,
        humidity: nil
    )
}

private func forecast(_ steps: [ForecastStep]) -> Forecast {
    Forecast(latitude: 59.33, longitude: 18.07, issuedAt: .distantPast, steps: steps)
}
