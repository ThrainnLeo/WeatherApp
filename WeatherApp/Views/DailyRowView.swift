import SwiftUI

/// One day in the "Next 7 days" list: weekday, symbol, precipitation, min / max (W-06).
struct DailyRowView: View {
    let day: DailyForecast

    var body: some View {
        HStack(spacing: 12) {
            Text(day.date.formatted(.dateTime.weekday(.wide)))
                .frame(maxWidth: .infinity, alignment: .leading)

            Image(systemName: day.condition.symbolName)
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(day.condition.symbolColor)
                .font(.title3)
                .frame(width: 32)
                .accessibilityLabel(day.condition.text)

            if let precipitation = day.precipitation, precipitation >= 0.1 {
                Text("\(precipitation.formatted(.number.precision(.fractionLength(1)))) mm")
                    .font(.caption)
                    .foregroundStyle(.blue)
                    .frame(width: 56, alignment: .trailing)
            } else {
                Spacer().frame(width: 56)
            }

            Text("\(TemperatureText.format(day.minTemperature)) / \(TemperatureText.format(day.maxTemperature))")
                .monospacedDigit()
                .frame(width: 84, alignment: .trailing)
        }
        .accessibilityElement(children: .combine)
    }
}
