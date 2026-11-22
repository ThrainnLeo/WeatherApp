import Foundation

/// Turns a `Forecast` (UTC steps) into "current + hourly today + daily for the next days" (W-07),
/// using calendar days in the time zone of the injected calendar (the user's by default).
///
/// The calendar and `now` are passed in instead of read inside, so the result only depends
/// on the inputs and tests can say "it is 22 Nov, 16:05, in Stockholm".
nonisolated struct ForecastGrouper {
    /// How many days after today get a daily summary.
    static let dayCount = 7

    private let calendar: Calendar

    init(calendar: Calendar = .current) {
        self.calendar = calendar
    }

    func group(_ forecast: Forecast, now: Date) -> GroupedForecast {
        // The step for the hour we are in still counts as "now"; everything earlier is the past,
        // which only happens with cached data from an earlier fetch.
        let startOfCurrentHour = calendar.dateInterval(of: .hour, for: now)?.start ?? now
        let remaining = forecast.steps.filter { $0.time >= startOfCurrentHour }

        let today = remaining.filter { calendar.isDate($0.time, inSameDayAs: now) }

        let startOfToday = calendar.startOfDay(for: now)
        let days = (1...Self.dayCount).compactMap { offset -> DailyForecast? in
            // Adding calendar days (not 24 h) keeps daylight-saving days (23 or 25 h) correct.
            guard let dayStart = calendar.date(byAdding: .day, value: offset, to: startOfToday) else {
                return nil
            }
            return makeDay(startingAt: dayStart, from: remaining)
        }

        return GroupedForecast(current: remaining.first, today: today, days: days)
    }

    /// Returns `nil` for a day without steps, so it is skipped rather than shown empty.
    private func makeDay(startingAt dayStart: Date, from steps: [ForecastStep]) -> DailyForecast? {
        let daySteps = steps.filter { calendar.isDate($0.time, inSameDayAs: dayStart) }
        let temperatures = daySteps.map(\.temperature)
        guard let minTemperature = temperatures.min(),
              let maxTemperature = temperatures.max(),
              let middayStep = stepClosestToMidday(in: daySteps, dayStart: dayStart)
        else {
            return nil
        }

        // Precipitation belongs to the period it fell in, so it is grouped by the middle of each
        // step's interval, not by `time`. Otherwise a 13:00→01:00 step would move a whole
        // evening's rain to the next day.
        let amounts = steps
            .filter { calendar.isDate(intervalMidpoint(of: $0), inSameDayAs: dayStart) }
            .compactMap(\.precipitation)

        return DailyForecast(
            date: dayStart,
            minTemperature: minTemperature,
            maxTemperature: maxTemperature,
            condition: middayStep.condition,
            precipitation: amounts.isEmpty ? nil : amounts.reduce(0, +),
            maxWindSpeed: daySteps.compactMap(\.windSpeed).max(),
            steps: daySteps
        )
    }

    private func stepClosestToMidday(in steps: [ForecastStep], dayStart: Date) -> ForecastStep? {
        let midday = calendar.date(bySettingHour: 12, minute: 0, second: 0, of: dayStart) ?? dayStart
        return steps.min { first, second in
            abs(first.time.timeIntervalSince(midday)) < abs(second.time.timeIntervalSince(midday))
        }
    }

    private func intervalMidpoint(of step: ForecastStep) -> Date {
        let length = step.time.timeIntervalSince(step.intervalStart)
        return step.intervalStart.addingTimeInterval(length / 2)
    }
}
