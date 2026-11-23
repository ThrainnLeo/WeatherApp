import SwiftUI

/// A grey outline of the forecast, shown while loading, so the layout doesn't jump when the data arrives (H-02).
///
/// Built from the real views with made-up values and `.redacted`, so it can't drift away from
/// the real layout. The values never reach the screen as text: redaction hides them.
struct ForecastSkeletonView: View {
    private static let step = ForecastStep(
        time: .now, intervalStart: .now, temperature: 10, condition: .cloudySky,
        windSpeed: 4, windGust: nil, windDirection: nil,
        precipitation: nil, precipitationProbability: nil, humidity: nil
    )

    private static let days: [DailyForecast] = (1...7).map { offset in
        DailyForecast(
            date: Date.now.addingTimeInterval(Double(offset) * 86_400),
            minTemperature: 4, maxTemperature: 12, condition: .cloudySky,
            precipitation: nil, maxWindSpeed: nil, steps: []
        )
    }

    var body: some View {
        Section {
            CurrentConditionsView(title: "Loading", step: Self.step, high: 12, low: 4)
                // One spoken label instead of a screen reader walking through made-up numbers.
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Loading forecast")
        }
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
        .redacted(reason: .placeholder)

        Section("Today") {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(0..<6, id: \.self) { _ in
                        HourlyItemView(step: Self.step)
                    }
                }
                .padding(.vertical, 4)
            }
            .scrollDisabled(true)
            .accessibilityHidden(true)
        }
        .frostedRows()
        .redacted(reason: .placeholder)

        Section("Next 7 days") {
            ForEach(Self.days) { day in
                DailyRowView(day: day)
                    .accessibilityHidden(true)
            }
        }
        .frostedRows()
        .redacted(reason: .placeholder)
    }
}
