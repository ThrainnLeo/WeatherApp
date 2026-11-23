import SwiftUI

/// One forecast step on the detail screen: time (span), condition, temperature, wind, rain, humidity.
struct DetailStepRowView: View {
    let step: ForecastStep

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(timeSpan)
                    .font(.subheadline.weight(.semibold))
                    .monospacedDigit()
                Text(step.condition.text)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Image(systemName: step.condition.symbolName)
                .symbolRenderingMode(.multicolor)
                .font(.title2)
                .frame(width: 36)
                .accessibilityHidden(true)

            VStack(alignment: .trailing, spacing: 2) {
                Text(TemperatureText.format(step.temperature))
                    .font(.title3.weight(.semibold))
                // Values SMHI didn't send (`nil`) are left out rather than shown as 0.
                ForEach(detailLines, id: \.self) { line in
                    Text(line)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 2)
        .accessibilityElement(children: .combine)
    }

    /// "13:00" for an hourly step, "07:00–13:00" for a longer one. Later days have 6–12 h steps;
    /// without the span, "1.2 mm" would look like one hour's rain.
    private var timeSpan: String {
        let end = step.time.formatted(date: .omitted, time: .shortened)
        guard step.time.timeIntervalSince(step.intervalStart) > 3600 else { return end }
        let start = step.intervalStart.formatted(date: .omitted, time: .shortened)
        return "\(start)–\(end)"
    }

    private var detailLines: [String] {
        var lines: [String] = []

        if let windSpeed = step.windSpeed {
            var wind = "Wind \(windSpeed.formatted(.number.precision(.fractionLength(0)))) m/s"
            if let direction = step.windDirection {
                wind += " \(CompassDirection.abbreviation(forDegrees: direction))"
            }
            if let gust = step.windGust {
                wind += " · gusts \(gust.formatted(.number.precision(.fractionLength(0))))"
            }
            lines.append(wind)
        }

        // SMHI's amount is all precipitation (rain, sleet and snow as water), so the text avoids "rain".
        switch (step.precipitation, step.precipitationProbability) {
        case let (amount?, chance?):
            lines.append("\(amount.formatted(.number.precision(.fractionLength(1)))) mm · \(chance.formatted(.number.precision(.fractionLength(0)))) % chance")
        case let (amount?, nil):
            lines.append("\(amount.formatted(.number.precision(.fractionLength(1)))) mm")
        case let (nil, chance?):
            lines.append("\(chance.formatted(.number.precision(.fractionLength(0)))) % chance of precipitation")
        case (nil, nil):
            break
        }

        if let humidity = step.humidity {
            lines.append("Humidity \(humidity.formatted(.number.precision(.fractionLength(0)))) %")
        }
        return lines
    }
}
