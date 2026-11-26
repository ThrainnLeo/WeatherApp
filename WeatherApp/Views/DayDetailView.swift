import SwiftUI

/// The full forecast for one day (W-02), opened by tapping a row in "Next 7 days".
///
/// No ViewModel: the day is already loaded and this screen has no state or actions, it only draws.
struct DayDetailView: View {
    let day: DailyForecast

    var body: some View {
        List {
            // Summary sits directly on the gradient, like the main screen's hero block.
            Section {
                summary
            }
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)

            Section("Forecast") {
                ForEach(day.steps, id: \.time) { step in
                    DetailStepRowView(step: step)
                }
            }
            .frostedRows()
        }
        .scrollContentBackground(.hidden)
        .background {
            // Gradient only: the main screen is the one with moving layers.
            WeatherBackground(theme: day.condition.theme, isAnimated: false)
        }
        .navigationTitle(day.date.formatted(.dateTime.weekday(.wide).day().month(.wide)))
        .navigationBarTitleDisplayMode(.inline)
    }

    private var summary: some View {
        VStack(spacing: 6) {
            Image(systemName: day.condition.symbolName)
                .symbolRenderingMode(.multicolor)
                .font(.system(size: 44))
                .accessibilityHidden(true)

            Text(day.condition.text)
                .font(.title3)

            Text("High \(TemperatureText.format(day.maxTemperature)) · Low \(TemperatureText.format(day.minTemperature))")
                .font(.headline)

            HStack(spacing: 16) {
                if let precipitation = day.precipitation {
                    Label("\(precipitation.formatted(.number.precision(.fractionLength(1)))) mm", systemImage: "drop.fill")
                }
                if let wind = day.maxWindSpeed {
                    Label("Up to \(wind.formatted(.number.precision(.fractionLength(0)))) m/s", systemImage: "wind")
                }
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .accessibilityElement(children: .combine)
    }
}

#Preview("Later day, 6 h steps") {
    // A typical later day: four 6-hour steps; the last one is missing wind and humidity.
    let midnight = Calendar.current.startOfDay(for: .now).addingTimeInterval(3 * 86_400)
    let steps = [1, 7, 13, 19].map { hour in
        let time = midnight.addingTimeInterval(Double(hour) * 3600)
        let hasAllValues = hour != 19
        return ForecastStep(
            time: time,
            intervalStart: time.addingTimeInterval(-6 * 3600),
            temperature: [-3.4, -1.0, 1.6, 0.2][[1, 7, 13, 19].firstIndex(of: hour) ?? 0],
            condition: hour == 13 ? .lightSnowfall : .overcast,
            windSpeed: hasAllValues ? 4.6 : nil,
            windGust: hasAllValues ? 9.1 : nil,
            windDirection: hasAllValues ? 306 : nil,
            precipitation: 0.4,
            precipitationProbability: 60,
            humidity: hasAllValues ? 91 : nil
        )
    }
    let day = DailyForecast(
        date: midnight, minTemperature: -3.4, maxTemperature: 1.6, condition: .lightSnowfall,
        precipitation: 1.6, maxWindSpeed: 4.6, steps: steps
    )
    return NavigationStack {
        DayDetailView(day: day)
    }
    .preferredColorScheme(.dark)
}
